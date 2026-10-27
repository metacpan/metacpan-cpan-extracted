package Mojolicious::Plugin::Buffer;

use strict;
use warnings;
use autodie qw(:all);

use Mojo::Base 'Mojolicious::Plugin';

# Mojo::Base turns on the unicode_strings feature, under which \s matches the
# bytes \xA0 and \x85.  Those bytes occur inside UTF-8 characters ("a" with a
# grave accent is C3 A0), so the white-space squasher would cut characters in
# half.  Every pattern in this file is about ASCII markup, media types, digits
# or HTTP tokens, so make \s, \w and \d ASCII-only throughout.
use re '/a';

use Carp qw(croak);
use File::Spec ();
use Mojo::Date;
use Mojo::IOLoop;
use Mojo::Loader qw(load_class);
use Mojo::Util qw(encode gzip md5_sum split_header trim);
use Mojolicious::Plugin::Buffer::I18N qw(i18n);
use Mojolicious::Plugin::Buffer::Lock::File;
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Return::Set qw(set_return);
use Scalar::Util qw(looks_like_number refaddr);
use Sub::Private { mode => 'enforce' };
use Sub::Protected;
use Time::HiRes ();

use version; our $VERSION = version->declare('0.001.0');

# ---------------------------------------------------------------------------
# Constants.  Nothing below this block should contain a bare number or a
# protocol string; if it does, it belongs up here.
# ---------------------------------------------------------------------------

# HTTP status codes the plugin reasons about
Readonly::Scalar my $HTTP_MIN_FINAL => 200;	# below this, an interim response
Readonly::Scalar my $HTTP_OK => 200;
Readonly::Scalar my $HTTP_NOT_MODIFIED => 304;
Readonly::Scalar my $HTTP_UNAVAILABLE => 503;

# No Content, Partial Content and Not Modified carry no entity to rework
Readonly::Hash my %BODYLESS_STATUS => map { $_ => 1 } (204, 206, 304);

# Only these methods are revalidated and cached
Readonly::Hash my %SAFE_METHODS => map { $_ => 1 } qw(GET HEAD);

# Only these media types are rewritten by the HTML optimiser
Readonly::Hash my %HTML_TYPES => map { $_ => 1 } qw(text/html application/xhtml+xml);

# Cache-Control directives that stop a request using, or a response being
# stored in, the server-side cache.  max-age only counts when it is zero.
Readonly::Hash my %REQUEST_NO_CACHE => map { $_ => 1 } qw(no-store no-cache private max-age);
Readonly::Hash my %RESPONSE_NO_STORE => map { $_ => 1 } qw(no-store private);

# Headers that describe one delivery rather than the page, so they are never
# stored with a cache entry
Readonly::Hash my %UNSTORED_HEADERS => map { lc($_) => 1 } qw(
	Connection Content-Encoding Content-Length Date ETag Keep-Alive
	Last-Modified Server Set-Cookie Transfer-Encoding X-Cache
);

# Response header that reports what the cache did
Readonly::Scalar my $X_CACHE => 'X-Cache';
Readonly::Scalar my $HIT => 'HIT';
Readonly::Scalar my $MISS => 'MISS';

# Prefixes keep our keys apart from anything else in a shared cache
Readonly::Scalar my $KEY_PREFIX => 'buffer:';
Readonly::Scalar my $MTIME_KEY_PREFIX => 'buffer:template-mtime:';

# Timings, in seconds
Readonly::Scalar my $DEFAULT_LOCK_TIMEOUT => 10;
Readonly::Scalar my $DEFAULT_MTIME_DURATION => 10;
Readonly::Scalar my $DEFAULT_CACHE_DURATION => '10 minutes';
Readonly::Scalar my $MIN_WAITER_DELAY => 0.05;	# a waiter always gets one tick
Readonly::Scalar my $SHARED_POLL_INTERVAL => 0.1;	# how often a cross-worker waiter looks
Readonly::Scalar my $RETRY_AFTER => 1;

# How deep the template mtime scan goes.  It is the loop guard of last
# resort: where stat() reports no inode (Windows before Perl 5.38) a
# symlink loop can only be told apart by its ever-longer path.
Readonly::Scalar my $MAX_SCAN_DEPTH => 32;

Readonly::Scalar my $DEFAULT_MIN_COMPRESS_SIZE => 32;
Readonly::Scalar my $OPTIMISE_AGGRESSIVE => 2;	# optimise_content level that touches JavaScript

# Stash keys.  'buffer' is the documented per-response override; the
# dotted ones are private bookkeeping; mojo.finished belongs to Mojolicious.
Readonly::Scalar my $STASH_OVERRIDE => 'buffer';
Readonly::Scalar my $STASH_FLIGHT => 'buffer.flight';
Readonly::Scalar my $STASH_STORED => 'buffer.stored';
Readonly::Scalar my $STASH_FROM_CACHE => 'buffer.from_cache';
Readonly::Scalar my $STASH_WAITER => 'buffer.cache_waiter';
Readonly::Scalar my $STASH_CHECKED => 'buffer.cache_checked';
Readonly::Scalar my $STASH_KEY => 'buffer.cache_key';
Readonly::Scalar my $STASH_MTIME => 'buffer.application_mtime';
Readonly::Scalar my $STASH_FINISHED => 'mojo.finished';

# Content codings: how to produce each one, which optional module it needs,
# and the legacy names clients still send
Readonly::Hash my %ENCODERS => (
	gzip => sub { gzip($_[0]) },
	br => sub { require IO::Compress::Brotli; IO::Compress::Brotli::bro($_[0]) },
	zstd => sub { require Compress::Zstd; Compress::Zstd::compress(\$_[0]) },
);
Readonly::Hash my %ENCODING_MODULE => (br => 'IO::Compress::Brotli', zstd => 'Compress::Zstd');
Readonly::Hash my %ENCODING_ALIAS => ('x-gzip' => 'gzip');

# Same-site links rewritten by rewrite_links, as [element, attribute]
Readonly::Array my @LINK_ATTRIBUTES => (['a', 'href'], ['img', 'src']);

# Elements whose content is significant white space or code, which the
# white-space squasher must never touch
Readonly::Scalar my $VERBATIM_ELEMENT => qr{(<(pre|textarea|script|style)\b[^>]*>)(.*?)(</\2\s*>)}is;

# Server preference order for content codings
Readonly::Array my @DEFAULT_ENCODINGS => qw(br zstd gzip);

# Media types worth compressing
Readonly::Array my @DEFAULT_COMPRESSIBLE_TYPES => (
	qr{^text/},
	qr{^application/(?:ecmascript|javascript|json|ld\+json|xhtml\+xml|xml)$},
	qr{^image/svg\+xml$},
);

# Types that must never be buffered and compressed, even though they
# match one of the rules above
Readonly::Array my @DEFAULT_EXCLUDED_TYPES => (qr{^text/event-stream$});

# Every option and its default.  register() shallow-copies the array
# references, because Readonly makes nested data read-only too.
Readonly::Hash my %DEFAULTS => (
	compress_content => 1,	# compress responses with gzip/br/zstd
	optimise_content => 0,	# 1 = squash HTML, 2 = also be aggressive with JavaScript
	rewrite_links => 1,	# make same-site absolute links relative
	generate_etag => 1,
	generate_304 => 1,
	trust_last_modified => 0,	# also answer If-Modified-Since when an ETag exists
	last_modified => 1,	# 0 = off, 1 = newest app/template mtime, epoch, date string or coderef
	template_mtime_cache => undef,	# cache object for the template mtime scan
	template_mtime_cache_duration => $DEFAULT_MTIME_DURATION,
	min_compress_size => $DEFAULT_MIN_COMPRESS_SIZE,
	encodings => [@DEFAULT_ENCODINGS],
	compressible_types => [@DEFAULT_COMPRESSIBLE_TYPES],
	excluded_types => [@DEFAULT_EXCLUDED_TYPES],
	cache => undef,	# a CHI-like cache object
	cache_duration => $DEFAULT_CACHE_DURATION,
	cache_key => undef,	# string or coderef, overriding the generated key
	cache_single_flight => 1,	# let one request build a missing entry, others wait
	cache_lock_timeout => $DEFAULT_LOCK_TIMEOUT,	# seconds before waiters give up
	cache_lock => undef,	# pluggable lock backend object
	cache_lock_dir => undef,	# directory of shared lock files, for multiple workers
	vary_by => ['cookie'],	# request headers that become part of the cache key
	messages => undef,	# overrides for the message catalog
);

# Params::Validate::Strict schema for each option.  The keys of this hash
# are the complete list of options; anything else is rejected.
Readonly::Scalar my $FLAG => {type => 'scalar', optional => 1};
Readonly::Scalar my $DURATION => {type => 'string', min => 1, optional => 1};
Readonly::Hash my %OPTION_SCHEMA => (
	compress_content => $FLAG,
	optimise_content => {type => 'integer', min => 0, max => $OPTIMISE_AGGRESSIVE, optional => 1},
	rewrite_links => $FLAG,
	generate_etag => $FLAG,
	generate_304 => $FLAG,
	trust_last_modified => $FLAG,
	last_modified => [{type => 'scalar'}, {type => 'coderef'}],
	template_mtime_cache => {type => 'object', can => [qw(get set)], optional => 1},
	template_mtime_cache_duration => $DURATION,
	min_compress_size => {type => 'integer', min => 0},
	encodings => {type => 'arrayref'},
	compressible_types => {type => 'arrayref'},
	excluded_types => {type => 'arrayref'},
	cache => {type => 'object', can => [qw(get set remove)], optional => 1},
	cache_duration => $DURATION,
	cache_key => [{type => 'string'}, {type => 'coderef'}],
	cache_single_flight => $FLAG,
	cache_lock_timeout => {
		type => 'number',
		matches => qr/^\d+(?:\.\d+)?$/,
		callback => sub { !defined($_[0]) || ($_[0] > 0) },	# undef means the default
		optional => 1,
	},
	cache_lock => {type => 'object', can => [qw(acquire release)], optional => 1},
	cache_lock_dir => {type => 'string', min => 1, optional => 1},
	vary_by => {
		type => 'arrayref',
		callback => sub { !grep { !defined($_) || ref($_) || !length($_) } @{$_[0]} },
	},
	messages => {type => 'hashref', optional => 1},
);

# Options whose error message is shared; every other option has its own
# option_<name> message, falling back to option_invalid
Readonly::Hash my %OPTION_MESSAGE => map { $_ => 'option_flag' }
	qw(compress_content rewrite_links generate_etag generate_304 trust_last_modified cache_single_flight);

# Options that can be declared for a group of pages, either as a route
# default, which lands in the stash,
#     $r->get('/about' => {trust_last_modified => 1} => sub {...});
#     $r->under('/docs')->to(optimise_content => 1);
# or by the controller itself, which its namespace inherits:
#     sub buffer_optimise_content { 1 }
Readonly::Array my @GROUP_OPTIONS => qw(compress_content optimise_content rewrite_links trust_last_modified);

# Whether each optional module loads, remembered for the life of the process
my %AVAILABLE;

=head1 NAME

Mojolicious::Plugin::Buffer - Optimise, compress and validate Mojolicious responses

=head1 VERSION

Version 0.001.0

=cut

=head1 SYNOPSIS

=head2 1. The smallest set-up

One line gives every page compression, an C<ETag>, a C<Last-Modified>
header and C<304 Not Modified> answers:

    use Mojolicious::Lite;

    plugin 'Buffer';

    get '/' => sub {
	my $c = shift;
	$c->render(template => 'index');
    };

    app->start;

=head2 2. Smaller HTML

Also remove extra white space from HTML pages.  Install L<HTML::Packer> to
remove comments and shrink embedded CSS as well:

    plugin 'Buffer' => {optimise_content => 1};

=head2 3. A server-side cache for slow pages

Keep finished pages in a cache, so a slow action runs once and later
visitors get the stored copy.  Call the helper I<first> in the action, but
I<after> any check that decides who may see the page:

    use CHI;

    plugin 'Buffer' => {cache => CHI->new(driver => 'File', root_dir => '/var/cache/myapp')};

    get '/report' => sub {
	my $c = shift;

	# Access checks come first: a cached page is sent without them
	return $c->reply->not_found unless $c->session('user');

	return if $c->buffer_is_cached;    # sent from the cache: stop here

	$c->render(text => slow_report());  # only runs on a miss
    };

=head2 4. Several workers on one machine

With L<hypnotoad> there are several worker processes.  Share the cache
between them, and give them a lock directory, so only one worker builds a
missing page:

    plugin 'Buffer' => {
	cache          => CHI->new(driver => 'File', root_dir => '/var/cache/myapp'),
	cache_lock_dir => '/var/lib/myapp/buffer-locks',
    };

For workers on several machines, see L</Multiple hosts>.

=head2 5. One response is different

Put a C<buffer> value in the stash.  C<0> leaves the response alone; a hash
changes some options for this response only:

    get '/download' => sub {
	my $c = shift;
	$c->stash(buffer => 0);    # already compressed: do not touch it
	$c->render(data => $zip_file, format => 'zip');
    };

    get '/raw' => sub {
	my $c = shift;
	$c->stash(buffer => {optimise_content => 0});
	$c->render(template => 'raw');
    };

=head2 6. A whole section is different

Some options can be set once for a group of routes:

    my $docs = app->routes->under('/docs')->to(optimise_content => 1);
    $docs->get('/intro' => sub { shift->render(template => 'docs/intro') });

=head2 7. Pages in several languages

Add C<Accept-Language> to the cache key, so each language is stored
separately:

    plugin 'Buffer' => {
	cache   => $cache,
	vary_by => ['cookie', 'accept-language'],
    };

=head2 8. Translate the "busy" message

While one request builds a page, a request that waits too long gets
C<503 Service Unavailable> with a short text.  Change the text with
C<messages>:

    plugin 'Buffer' => {
	cache    => $cache,
	messages => {retry_later => "Bitte versuchen Sie es gleich noch einmal.\n"},
    };

=head2 9. A full application

    package MyApp;
    use Mojo::Base 'Mojolicious';
    use CHI;

    sub startup {
	my $self = shift;

	$self->plugin('Buffer', {
	    optimise_content => 1,
	    cache            => CHI->new(driver => 'File', root_dir => '/var/cache/myapp'),
	    cache_lock_dir   => '/var/lib/myapp/buffer-locks',
	    cache_duration   => '10 minutes',
	    vary_by          => [],    # these pages are the same for everyone
	});

	$self->routes->get('/')->to('pages#home');
    }

    1;

=head1 DESCRIPTION

C<Mojolicious::Plugin::Buffer> makes the pages of a L<Mojolicious>
application smaller and faster to deliver, without changes to your actions.
It is the Mojolicious version of L<CGI::Buffer> and L<FCGI::Buffer>.

=head2 What it does

After your action has made a page, and before the page is sent, the plugin
can:

=over 4

=item * B<make HTML smaller> by removing extra white space and, with
L<HTML::Packer>, comments and extra characters in embedded CSS and
JavaScript.  It also shortens links to your own site;

=item * B<compress the page> with Brotli, Zstandard or gzip, whichever the
browser accepts and the server has installed;

=item * B<add headers that let browsers reuse a copy they already have>
(C<ETag> and C<Last-Modified>), and answer "you already have this" with a
short C<304 Not Modified> reply instead of the whole page;

=item * B<set the correct C<Content-Length>> after all of these changes;

=item * B<keep finished pages in a server-side cache>, if you ask it to, so
that a slow action does not have to run again for the next visitor (see
L</buffer_is_cached>).

=back

=head2 How it works, in plain words

=over 4

=item 1. When the application starts, L</register> checks your options and
installs a I<hook>: a small function that Mojolicious calls for every
response, after the action has finished (C<after_dispatch>).

=item 2. A request arrives and your action runs.  If the action calls
L</buffer_is_cached> and a fresh copy of the page is in the cache, the copy
is sent and the action stops early.

=item 3. Otherwise the action makes the page as usual.

=item 4. The hook looks at the finished response.  It leaves alone anything
it should not touch: streamed responses, static files, empty bodies,
statuses that have no body (1xx, 204, 206, 304), responses that are already
compressed, and media types listed in L</excluded_types>.

=item 5. For an HTML page it removes white space, if L</optimise_content>
is on.

=item 6. It compresses the page for this browser, if the media type is in
L</compressible_types>.

=item 7. It stores the I<uncompressed> page in the cache, if the action
called L</buffer_is_cached> and the page may be stored.

=item 8. It adds the C<ETag> and C<Last-Modified> headers.  If the browser
already has this version, it sends C<304 Not Modified> with no body and
stops.

=item 9. Otherwise it puts the compressed (or plain) page into the
response, sets C<Content-Length>, and the page is sent.

=back

Error pages such as C<404> go through the same steps, but only C<200>
responses get an C<ETag> or are stored in the cache.

The plugin works through a hook, so it also sees responses built with
C<< $c->res->body >> rather than C<< $c->render >>.  Unlike the CGI modules
it needs no source filter and no C<END> block.

=head2 Words used in this document

=over 4

=item cache

A store that keeps finished pages for a while, for example L<CHI>.  The
plugin needs an object with C<get>, C<set> and C<remove> methods.

=item cache key

The name under which a page is kept in the cache.  By default it is made
from the host, path, query string and the request headers listed in
L</vary_by>.

=item ETag

A short fingerprint of the page, sent in a header.  A browser that has a
copy sends the fingerprint back; if it still matches, the server answers
C<304>.

=item 304 Not Modified

A reply with no body that means "the copy you have is still correct".

=item content coding

The compression method of a response, such as C<gzip> or C<br> (Brotli).
The browser lists what it accepts in C<Accept-Encoding>.

=item worker

One of several copies of the application that a server such as
L<hypnotoad> runs at the same time.  Workers do not share memory.

=item single-flight

When many requests ask for the same missing page at once, only one of them
builds it; the others wait and then get the result.

=item stash

Mojolicious's per-request hash of values, C<< $c->stash >>.  The plugin
reads its per-response options from C<< $c->stash('buffer') >>.

=back

=head1 OPTIONS

All options can be given to C<plugin()> and, except where noted, overridden
per request through the C<buffer> stash value.  Options given to C<plugin()>
are validated when the plugin is registered; values in the C<buffer> stash
are not, and an unusable one falls back to its default where that is safe.
A few options describe a section of a site rather than one page and can be
declared once for it; see L</Declaring options for a group of pages>.

=head2 Declaring options for a group of pages

    # one route
    $r->get('/about' => {optimise_content => 1} => sub {...});

    # everything beneath an under route
    my $docs = $r->under('/docs')->to(optimise_content => 1);
    $docs->get('/intro' => sub {...});

    # a controller, and through a base class its whole namespace
    package MyApp::Controller::Docs;
    use Mojo::Base 'Mojolicious::Controller';
    has buffer_optimise_content => 1;

A route default is an ordinary stash value, so C<< $app->defaults(...) >> and
a C<before_action> that sets one work as well.  The controller form is a
method named C<buffer_> followed by the option name, and is only consulted
when the stash says nothing: C<has> is the declarative way to write it, and a
plain C<sub buffer_optimise_content { 1 }> covers a value that depends on the
request.  A controller method that dies is logged at debug level and
ignored, so the plugin option stays in force.

The most specific declaration wins:

=over 4

=item 1. the C<buffer> stash, for a single response

=item 2. a route default, which includes one an C<under> route sets

=item 3. the controller declaration

=item 4. the plugin option

=back

A route default of C<0> therefore opts one page back out of a group that has
the option on, and the C<buffer> stash overrides both.

Only the options that describe the content of a section are declarable:

=over 4

=item L</compress_content> - a section serving files that are already
compressed

=item L</optimise_content> - a static section that is always minified

=item L</rewrite_links> - a section whose HTML is used elsewhere, so its
absolute links must survive

=item L</trust_last_modified> - a section that renders templates and nothing
else

=back

Everything else, including L</generate_etag> and L</generate_304>, stays a
per-response or per-application decision; those sections say why.  Any option
can still be set for one response through the C<buffer> stash.

F<examples/grouped-sections> is a runnable site with one section declared on
an C<under> route and one declared in a controller.

=head2 compress_content

Compress eligible responses, defaults to 1.  Set to 0 to only optimise (and
remember that the plugin turns off L<Mojolicious::Renderer/compress>, so a
response will then not be compressed at all).  The encodings offered to
clients are controlled by L</encodings>.

It can be declared for a group of pages (see
L</Declaring options for a group of pages>), which is the point of a section
that serves files it has already compressed.

=head2 optimise_content

How hard to optimise HTML, defaults to 0 (off).  Registration rejects any
value other than 0, 1 or 2:

=over 4

=item 0 - leave the HTML alone

=item 1 - remove superfluous white space, rewrite same-site links and, when
L<HTML::Packer> is installed, remove comments and minify embedded CSS

=item 2 - as 1, plus aggressive JavaScript minification when L<HTML::Packer>
is installed, which can break scripts that rely on the
C<E<lt>!-- ... --E<gt>> hiding technique

=back

Optimisation only applies to C<text/html> and C<application/xhtml+xml>
responses.  The content of C<E<lt>preE<gt>>, C<E<lt>textareaE<gt>>,
C<E<lt>scriptE<gt>> and C<E<lt>styleE<gt>> elements is never touched by the
white-space squashing, because white space there is significant.
L<HTML::Packer> is optional: without it the white-space squashing and link
rewriting still run, but comments and embedded CSS and JavaScript are left
alone, as they are by L<CGI::Buffer> and L<FCGI::Buffer>.  Install
L<HTML::Packer> for the full effect.

It can be declared for a group of pages (see
L</Declaring options for a group of pages>), for a static section that is
always minified.

=head2 rewrite_links

When optimising, rewrite C<E<lt>a hrefE<gt>> and C<E<lt>img srcE<gt>> links that
point at the current site as absolute URLs into root-relative links, and
links to the current script with a query string into just the query string.
Defaults to 1.  Has no effect unless L</optimise_content> is enabled.  Only
double-quoted attribute values are recognised.

It can be declared for a group of pages (see
L</Declaring options for a group of pages>), which matters for a section
whose HTML is not used in place: a preview of a newsletter or a page rendered
for another site needs its absolute URLs kept while still being optimised
elsewhere.

=head2 generate_etag

Add an C<ETag> header to C<200> responses to C<GET> and C<HEAD> requests,
defaults to 1.  The tag is the MD5 of the response body before compression,
with a suffix for the content coding, so a gzip and an identity
representation of the same page have different tags.  An C<ETag> set by the
action is kept.

It is not declarable for a group of pages (see
L</Declaring options for a group of pages>): whether a digest is worth
computing is a decision for one endpoint, not a policy for a section.  Skip
the digest for one response with C<< $c->stash(buffer => {generate_etag => 0})
>>, or for the whole application with the plugin option.

=head2 generate_304

Answer "you already have this page" with C<304 Not Modified>, defaults to
1.  A browser that has a copy of a page asks the server whether its copy is
still correct.  It can ask in two ways:

=over 4

=item * C<If-None-Match>: "my copy has this C<ETag>".  This is exact,
because the C<ETag> is a fingerprint of the page itself.

=item * C<If-Modified-Since>: "my copy is from this date".  This is only a
guess, because the date (see L</last_modified>) describes your I<code and
templates>, not the data shown on the page.

=back

The plugin uses them like this:

=over 4

=item 1. If the request has C<If-None-Match>, only the C<ETag> decides.  The
date is ignored, as RFC 7232 requires.

=item 2. If the page has an C<ETag> (L</generate_etag> is on, the default),
C<If-Modified-Since> alone is I<not> trusted.  A database row can change
while the template stays the same, and a C<304> would then keep showing the
browser old data.  Browsers send C<If-None-Match> once they have seen an
C<ETag>, so they are not affected.

=item 3. If the page has no C<ETag>, or L</trust_last_modified> is on, the
date is used.

=back

It is not declarable for a group of pages (see
L</Declaring options for a group of pages>).  It decides whether a browser is
told that its copy is correct, and a section that could also turn it off
would contradict L</trust_last_modified>.  Use
C<< $c->stash(buffer => {generate_304 => 0}) >> where one endpoint must always
send a body.

=head2 last_modified

Add a C<Last-Modified> header, defaults to 1.  The header says when the page
last changed.  The value may be:

=over 4

=item 0 - do not add the header

=item 1 - the newest modification time of the application script (C<$0>)
and of every file and directory under the renderer's template paths.
Symbolic links are followed, each directory is read once, and the scan
stops 32 directories below a template path, which also ends a symbolic
link that points back up the tree.

=item a number - a Unix epoch (seconds since 1970)

=item a date string - anything L<Mojo::Date> can read, such as
C<'Sun, 06 Nov 1994 08:49:37 GMT'>

=item a code reference - called with the controller; it returns one of the
values above (a code reference that returns another code reference counts
as 0)

=back

Some rules:

=over 4

=item * The header is only added to C<200> responses to C<GET> and C<HEAD>.
A C<Last-Modified> header that the action set itself is kept.

=item * With the default (1), editing a template changes the date.
(Separately, and whatever this option says, the server-side cache throws
away entries built before the newest change to the script or a template;
see L</buffer_is_cached>.)

=item * The date describes the I<code>, not your data.  A change in the
database does not move it.  For pages built from data, use a code reference
that returns the data's own date, or set C<last_modified =E<gt> 0> and rely
on the C<ETag> (see L</generate_304> for why that is safe).

=item * The default looks at every template file on every request, unless
L</template_mtime_cache> is set.  For a large template tree, or an
application without templates, an epoch or a code reference is cheaper.
A server-side cache lookup also looks at the template files, whatever this
option says; see L</Last-Modified performance>.

=item * C<morbo> and C<hypnotoad> set C<$0> to your application script.
Under PSGI or another wrapper, C<$0> may be the wrapper instead; pass an
epoch or a code reference there.

=back

=head2 trust_last_modified

Also answer C<If-Modified-Since> when the page has an C<ETag>, defaults to 0.

By default the plugin does not trust the date when it has a fingerprint
(see L</generate_304>).  Turn this on only for pages that are built from the
application and its templates I<and nothing else>: no database, no session,
no other input that can change while the templates stay the same.  Then the
date is accurate, and clients that only send C<If-Modified-Since> can get a
C<304> too.  C<If-None-Match> still comes first, so a browser that sends the
C<ETag> is always answered correctly.

    plugin 'Buffer' => {
	trust_last_modified => 1,   # this application only renders templates
    };

Use it for one response with
C<< $c->stash(buffer => {trust_last_modified => 1}) >>, or declare it for a
group of pages (see L</Declaring options for a group of pages>), for a
section that renders templates and nothing else.  It has no effect when
L</generate_304> is off.  It cannot make a page safe; it only tells the
plugin that the templates really are the only input.

=head2 Last-Modified performance

The scan costs one C<stat()> per file and directory under the renderer's
paths.  On a tree of 10,000 templates in 100 directories, a request using the
default scan took about 40 milliseconds of CPU on the machine used for these
measurements, against about 1 millisecond for the same request with an
explicit epoch; that is roughly 4 microseconds per tree entry.  With
L</template_mtime_cache> in front of it, the same request also took about 1
millisecond, the cache lookup adding only a few tens of microseconds, so the
middle ground gives up roughly 2% of the scan's cost to keep template
awareness.  The numbers are indicative, not a promise, and a faster or slower
filesystem will move them.  Run F<benchmarks/last_modified.pl> with your own
tree size to measure all three variants.

Use an explicit epoch or a coderef when template changes do not need to move
C<Last-Modified>.  This removes the scan from ordinary responses, but not
from server-side cache lookups: L</buffer_is_cached> still scans, so that an
entry built from an old template is thrown away.  Use
L</template_mtime_cache> when you need template awareness but not a scan on
every request: it costs one cache lookup per request, covers both uses, and
bounds how long a template edit can be missed by its duration.

=head2 template_mtime_cache

An optional cache object understanding C<get()> and C<set()>, such as a
L<CHI> instance, used to remember the result of the template mtime scan.
Defaults to undef, which scans the renderer's template paths on every
request.  A per-worker cache avoids the scan without sharing anything:

    use CHI;
    plugin 'Buffer' => {
	template_mtime_cache => CHI->new(driver => 'Memory', datastore => {}),
    };

A shared cache, such as CHI's File or Memcached driver, also avoids the scan
for every worker.  Entries are keyed by the application class, the
application script and its mtime, and the renderer's template paths, and are
stored with L</template_mtime_cache_duration>.  A cache failure is logged at
debug level and the scan runs as usual, so a broken cache cannot stop a
response.

For a large tree this is the middle ground: it avoids the per-request scan
described under L</Last-Modified performance> while still noticing template
changes, at the cost of up to one duration of staleness.

The cached value is only refreshed when the entry expires.  A template edit
therefore is not noticed until then, and neither C<Last-Modified> nor the
cache invalidation described under L</last_modified> sees it immediately.
Keep L</template_mtime_cache_duration> short if templates change often.

This option and L</template_mtime_cache_duration> are read when the plugin is
registered; they cannot be overridden through the C<buffer> stash.

=head2 template_mtime_cache_duration

How long a template mtime is kept, defaults to 10 seconds.  It is passed to
the cache's C<set()>, so for L<CHI> it may be a number of seconds or a
human-readable duration.

=head2 min_compress_size

Do not compress bodies smaller than this many bytes, defaults to 32.  Must be
a non-negative integer.  Compression is also skipped if it would not make the
body smaller.

=head2 encodings

An arrayref of the content codings to offer, in server preference order.
Defaults to C<[qw(br zstd gzip)]>.  C<br> is only offered if
L<IO::Compress::Brotli> is installed and C<zstd> only if L<Compress::Zstd>
is installed; gzip is always available.  C<x-gzip> is accepted as a synonym
for C<gzip>.  Clients pick with the usual quality values, and C<identity> is
used when nothing acceptable is offered.

=head2 compressible_types

An arrayref of media types to compress, defaults to C<text/*>,
C<application/json>, C<application/javascript>, C<application/xml>,
C<application/xhtml+xml>, C<image/svg+xml> and a few close relatives.
Entries may be strings (matched exactly, case-insensitively) or regular
expressions.

=head2 excluded_types

An arrayref of media types that are never buffered, defaults to
C<text/event-stream>.  Entries may be strings or regular expressions.

=head2 cache

An optional cache object understanding C<get()>, C<set()> and C<remove()>,
such as a L<CHI> instance.  Defaults to undef, which disables the
server-side cache.  See L</buffer_is_cached> for the rules about what is
cached and how keys are made.

=head2 cache_duration

How long entries are kept in the cache, defaults to C<'10 minutes'>.  It is
passed to the cache's C<set()>, so for L<CHI> it may be a number of seconds
or a human-readable duration.

=head2 cache_key

A string, or a coderef called with the controller, that overrides the
generated cache key.  Useful when several URLs should share one entry, or
when the response depends on something the default key does not cover.  An
empty string, or a coderef returning nothing, falls back to the generated
key.

=head2 cache_single_flight

Only let one request at a time build a missing entry, defaults to 1.  When a
request misses the cache while another request in the same worker is already
building the same key, the second request waits for the first one to finish
and is then served the finished entry, without running the action.  This
matters for asynchronous actions: a synchronous action runs to completion
without the event loop doing anything else, so it cannot overlap with
another request in the same worker.

If the first request fails, produces a response that cannot be cached (for
example one that sets a cookie), or takes longer than L</cache_lock_timeout>,
the waiting request is answered with C<503 Service Unavailable> and
C<Retry-After: 1> rather than running the action itself.  Set to 0 to let
every concurrent miss run the action independently.

By default the in-flight table is per worker process, so with N L<hypnotoad>
workers a cold entry can still be built up to N times.  Set L</cache_lock> or
L</cache_lock_dir> to elect a single builder across processes instead.

=head2 cache_lock

An optional object that elects one process to build a missing entry, for
workers that cannot share a directory.  It must implement:

=over 4

=item acquire

    my ($guard, $error) = $lock->acquire($key);

Return a truthy guard if the lock was acquired, C<(undef, undef)> if another
process holds it, and C<(undef, $error)> if the backend failed.  On an error
the plugin logs the message and continues with a per-worker flight, so a
cache miss is still built.  An exception thrown by C<acquire> is treated as
an error.

The call is synchronous and runs before the action is allowed to continue.
A backend must therefore be quick and must not depend on the event loop; an
asynchronous Redis client is not suitable.

=item release

    $lock->release($guard);

Release a guard returned by C<acquire>.  The guard is opaque to the plugin.
Releasing a lock that has already expired is allowed.  If release fails, the
lock should expire on its own; the backend can return C<(0, $error)> so the
failure is logged.  A backend that returns nothing is treated as having
released the lock.

=back

The cache itself must still be shared between the workers.  The built-in
backends are L<Mojolicious::Plugin::Buffer::Lock::File>, selected with
L</cache_lock_dir>, and L<Mojolicious::Plugin::Buffer::Lock::Redis>.
C<cache_lock> cannot be combined with L</cache_lock_dir>, and is read when
the plugin is registered rather than per response.

=head2 cache_lock_timeout

How long a request may wait for another request, in this worker or another
one, to build the same entry.  Defaults to 10 seconds.  It also bounds how
long a key is considered to be in flight when the request building it never
finishes.  Fractional seconds are allowed, so C<0.5> is valid; zero and
negative values are rejected.

=head2 cache_lock_dir

A directory in which to keep lock files used to coalesce cache misses across
worker processes, defaults to undef, which limits single-flight to one worker.
This selects the built-in L<Mojolicious::Plugin::Buffer::Lock::File> backend
and is a shorthand for C<cache_lock =E<gt>
Mojolicious::Plugin::Buffer::Lock::File-E<gt>new(dir =E<gt> $dir)>.  The
plugin creates the directory if necessary.  It cannot be combined with
L</cache_lock>.

The workers must share this directory and the cache itself.  A per-worker
cache such as CHI's C<Memory> driver cannot be used, because a request in one
worker cannot see the entry built in another; disable any per-worker C<L1>
cache in front of a shared cache for the same reason.  Locks are non-blocking
C<flock>s on one small, empty file per cache key, so they are released
automatically if a worker dies.  The files are not removed, although they are
tiny and can be deleted while the application is stopped.  Use a private
directory.

This works for L<hypnotoad> workers on the same host, or on a shared
filesystem that implements C<flock> reliably.  For workers on different
hosts, use L</cache_lock> with
L<Mojolicious::Plugin::Buffer::Lock::Redis> instead.  It is read when the
plugin is registered, not per response.

=head2 vary_by

An arrayref of request header names that become part of the generated cache
key.  Defaults to C<['cookie']>, which keeps one client's session from being
served to another.  Set it to C<[]> for URL-only caching of pages that are
identical for every visitor, or add e.g. C<'accept-language'> when the
response varies by language.  Header names are case-insensitive.  Headers
listed here may also appear in the response's C<Vary> header; a response
that varies on anything else is not stored.

=head2 messages

A hash reference of message overrides, keyed by message key, used for every
error, log line and client-facing text the plugin produces, including the
body of the C<503> sent to a request that gave up waiting.  See
L<Mojolicious::Plugin::Buffer::I18N> for the keys, the placeholder syntax
and plural and gender variants:

    plugin 'Buffer' => {
	messages => {
	    retry_later => "Die Seite wird gerade erstellt, bitte versuchen Sie es gleich noch einmal.\n",
	},
    };

It is passed to the lock backend built from L</cache_lock_dir>.  It is read
when the plugin is registered, not per response.

=head1 METHODS

C<Mojolicious::Plugin::Buffer> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.  It also adds
the L</buffer_is_cached> helper to the application.

=head2 register

    $plugin->register(Mojolicious->new, {optimise_content => 1});

=head3 Purpose

Validate the options, install the C<after_dispatch> hook that reworks every
response, and add the L</buffer_is_cached> helper.  It is normally called for
you by C<< $app->plugin('Buffer', ...) >>.

=head3 Arguments

=over 4

=item C<$app> (positional, required)

The L<Mojolicious> application.

=item C<\%options> (positional, optional)

The options described under L</OPTIONS>, as a hash reference or a flat list.

=back

=head3 Returns

The plugin object, so calls can be chained.

=head3 Side effects

=over 4

=item * Turns off L<Mojolicious::Renderer/compress>, because this plugin does
the compression; see L</Interaction with the renderer>.

=item * Adds an C<after_dispatch> hook and a C<buffer_is_cached> helper.

=item * Creates L</cache_lock_dir> if it is given and missing.

=item * Loads the optional compression modules named by L</encodings>, and
logs at debug level when L</optimise_content> is on without L<HTML::Packer>.

=back

=head3 Example

    use Mojolicious::Lite;
    use CHI;

    plugin 'Buffer' => {
	optimise_content => 1,
	cache            => CHI->new(driver => 'File', root_dir => '/var/cache/myapp'),
	cache_lock_dir   => '/var/lib/myapp/buffer-locks',
	vary_by          => [],     # pages are the same for everyone
    };

    get '/' => sub {
	my $c = shift;
	return if $c->buffer_is_cached;
	$c->render(text => 'Hello');
    };

    app->start;

=head3 API SPECIFICATION

=head4 Input

    # Params::Get::get_params(undef, @_) after $app, then one
    # Params::Validate::Strict::validate_strict call per option
    {
	app                           => { type => 'object', can => [qw(hook helper renderer log)] },
	compress_content              => { type => 'scalar', optional => 1 },
	optimise_content              => { type => 'integer', min => 0, max => 2, optional => 1 },
	rewrite_links                 => { type => 'scalar', optional => 1 },
	generate_etag                 => { type => 'scalar', optional => 1 },
	generate_304                  => { type => 'scalar', optional => 1 },
	trust_last_modified           => { type => 'scalar', optional => 1 },
	last_modified                 => [ { type => 'scalar' }, { type => 'coderef' } ],
	template_mtime_cache          => { type => 'object', can => [qw(get set)], optional => 1 },
	template_mtime_cache_duration => { type => 'string', min => 1, optional => 1 },
	min_compress_size             => { type => 'integer', min => 0 },
	encodings                     => { type => 'arrayref' },   # of br|zstd|gzip|x-gzip
	compressible_types            => { type => 'arrayref' },   # of strings or qr//
	excluded_types                => { type => 'arrayref' },   # of strings or qr//
	cache                         => { type => 'object', can => [qw(get set remove)], optional => 1 },
	cache_duration                => { type => 'string', min => 1, optional => 1 },
	cache_key                     => [ { type => 'string' }, { type => 'coderef' } ],
	cache_single_flight           => { type => 'scalar', optional => 1 },
	cache_lock_timeout            => { type => 'number', optional => 1 },   # > 0
	cache_lock                    => { type => 'object', can => [qw(acquire release)], optional => 1 },
	cache_lock_dir                => { type => 'string', min => 1, optional => 1 },
	vary_by                       => { type => 'arrayref' },   # of non-empty strings
	messages                      => { type => 'hashref', optional => 1 },
    }

=head4 Output

    # Return::Set schema
    { type => 'object', isa => 'Mojolicious::Plugin::Buffer' }

=head3 MESSAGES

Every message croaks, from the caller's point of view.  The key is the
L<Mojolicious::Plugin::Buffer::I18N> key that can be overridden.

When several options are wrong, only one is reported: the first one when
the option names are sorted in ASCII order (for example C<cache> comes
before C<encodings>, and C<generate_304> before C<generate_etag>).  An
unknown option name is reported in the same way, at its place in that
order.  Fix it and register again to see the next problem.  The order is
fixed, so the same mistake always gives the same message.  The checks
that look at more than one option (C<cache_lock> together with
C<cache_lock_dir>, and unknown C<encodings> names) come after all of
these.

    Key                             Message (after "Mojolicious::Plugin::Buffer: ")     Resolution
    ------------------------------  --------------------------------------------------  ---------------------------------
    options_not_hash                options must be a hash reference                    Pass {...} or a key/value list
    unknown_option                  unknown option 'NAME'                               Check the spelling in OPTIONS
    option_flag                     NAME must be a true or false value                  Pass 0 or 1, not a reference
    option_optimise_content         optimise_content must be 0, 1 or 2                  Use one of the documented levels
    option_last_modified            last_modified must be 0, 1, an epoch, a date        Pass a scalar or a coderef
                                    string or a code reference
    option_min_compress_size        min_compress_size must be a non-negative integer    Pass e.g. 32
    option_encodings                encodings must be an array reference                Pass [qw(br gzip)]
    unknown_encoding                unknown encoding 'NAME'                             Use br, zstd, gzip or x-gzip
    option_compressible_types       compressible_types must be an array reference       Pass [qr{^text/}, ...]
    option_excluded_types           excluded_types must be an array reference           Pass [qr{^text/event-stream$}]
    option_vary_by                  vary_by must be an array reference of header names  Pass e.g. ['cookie']
    option_cache_key                cache_key must be a string or a code reference      Pass a string or sub
    option_cache                    cache must be an object understanding get(), set()  Pass a CHI object
                                    and remove()
    option_cache_duration           cache_duration must be a duration                   Pass e.g. '10 minutes'
    option_template_mtime_cache     template_mtime_cache must be an object              Pass a CHI object
                                    understanding get() and set()
    option_template_mtime_cache_duration
                                    template_mtime_cache_duration must be a duration    Pass e.g. 10
    option_cache_lock_timeout       cache_lock_timeout must be a positive number of     Pass e.g. 10 or 0.5
                                    seconds
    option_cache_lock               cache_lock must be an object with acquire() and     See cache_lock
                                    release() methods
    option_cache_lock_dir           cache_lock_dir must be a directory path             Pass a non-empty string
    lock_options_combined           cache_lock and cache_lock_dir cannot be combined    Use one of the two
    option_messages                 messages must be a hash reference                   Pass {key => 'text'}
    lock_dir_create_failed          cannot create cache_lock_dir 'DIR': OS ERROR        See Lock::File
    lock_dir_not_writable           cache_lock_dir 'DIR' is not a writable directory    See Lock::File

A failure to validate C<$app> itself is reported by L<Params::Validate::Strict>
and is not translated.

=head3 PSEUDOCODE

    accept the options as a hash reference or a key/value list
    check the application object
    adopt the messages option first, so later errors can be reworded
    start from the defaults
    for each option given, in sorted order:
        croak if it is unknown
        croak with its own message if its value does not fit its schema
    croak if both cache_lock and cache_lock_dir were given
    build the lock backend: the given object, or a file backend for the dir
    canonicalise encodings, croak on unknown ones, drop unavailable ones
    log once if optimisation is on without HTML::Packer
    turn off the renderer's own compression
    hook after_dispatch to rework every response
    add the buffer_is_cached helper
    return the plugin

=cut

sub register {
	my ($self, $app, @conf) = @_;

	# Mojolicious passes a hash reference; Params::Get also accepts a list
	my $conf = @conf ? eval { get_params(undef, @conf) } : {};
	croak $self->i18n('options_not_hash') unless ref($conf) eq 'HASH';
	validate_strict(
		schema => {app => {type => 'object', can => [qw(hook helper renderer log)]}},
		input => {app => $app},
	);

	# Messages first, so every later error can already be reworded
	$self->{messages} = $conf->{messages} if ref($conf->{messages}) eq 'HASH';

	# Sorted, so the same bad configuration always reports the same error
	my %options = map { $_ => _copy_default($DEFAULTS{$_}) } keys %DEFAULTS;
	for my $name (sort keys %$conf) {
		croak $self->i18n('unknown_option', {option => $name}) unless exists($OPTION_SCHEMA{$name});
		croak $self->i18n(_option_message($name), {option => $name}) unless _option_valid($name, $conf->{$name});
		$options{$name} = $conf->{$name};
	}

	$self->{options} = \%options;
	$self->{inflight} = {};
	$self->{lock} = $self->_build_lock(\%options);
	$options{encodings} = $self->_supported_encodings($options{encodings});

	# HTML::Packer is optional: without it the white-space squashing and link
	# rewriting still run, as they do in CGI::Buffer and FCGI::Buffer
	$self->_log($app, debug => 'log_no_packer')
		if $options{optimise_content} && !_module_available('HTML::Packer');

	# Mojolicious::Renderer gzips rendered output by default, before this
	# plugin ever sees it, which would stop optimisation and ETag generation
	# from working on anything bigger than 860 bytes.  Take over that job.
	$app->renderer->compress(0);

	$app->hook(after_dispatch => sub { $self->_process(shift) });

	# Opt-in server-side page cache, used from an action like this:
	#     return if $c->buffer_is_cached;
	$app->helper(buffer_is_cached => sub { $self->_is_cached(shift) });

	return set_return($self, {type => 'object'});
}

=head2 buffer_is_cached

    get '/expensive' => sub {
	my $c = shift;
	return if $c->buffer_is_cached;
	# ... expensive work ...
	$c->render(template => 'expensive');
    };

=head3 Purpose

A helper, added to the application by L</register>, that lets an action skip
its work when a finished copy of the page is already cached, or when another
request is already building it.

Look for a cached response and, if there is one, replay its status, headers
and body, add C<X-Cache: HIT>, finish the response and return true.  The
action only has to return; no rendering is needed on a hit.  On a miss it
adds C<X-Cache: MISS>, returns false, and the response is stored when it is
complete.

Only C<200> responses to C<GET> and C<HEAD> requests are cached.  Requests
with an C<Authorization> header or a C<Cache-Control> header containing
C<no-store>, C<no-cache>, C<private> or C<max-age=0> bypass the cache, as do
requests made while the C<NO_CACHE> or C<NO_STORE> environment variable is
set.  Responses that set a cookie, that are marked C<no-store> or
C<private>, or that vary on something not listed in L</vary_by>, are not
stored.  Entries created before the application script or any template file
or directory was last modified are treated as misses and removed.

The stored body is the optimised but uncompressed entity, so every hit is
compressed for the requesting client, gets its own C<ETag> and can still be
answered with C<304 Not Modified>.  The cache key is a digest of the
application class, host, path, query string and the values of the headers
listed in L</vary_by>; use L</cache_key> to replace it.  Query argument order
is significant.

Concurrent misses for the same key are coalesced within a worker, or across
workers when L</cache_lock> or L</cache_lock_dir> is set: while one request
is building an entry, later requests wait for it and replay the result
instead of running the action again.  The waiting requests are held
asynchronously, so this works for actions that themselves use the event
loop.  See L</cache_single_flight> for the failure and timeout behaviour.

Calling the helper more than once is harmless, but only the first call can
hit.  To disable the cache for one response, use
C<< $c->stash(buffer => {cache => undef}) >> before calling it.

=head3 Arguments

=over 4

=item C<$c> (implicit)

The controller the helper is called on.

=back

=head3 Returns

True when the response has been, or will be, sent by the plugin: a cache
hit, or a request now waiting for another one to build the entry.  False
when the action must do its work: a miss, a bypassed request, no cache, or a
cache that failed.

=head3 Side effects

=over 4

=item * On a hit: sets the status, headers and body and finishes the
response.

=item * On a miss: sets C<X-Cache: MISS>, and the response is stored in the
cache when it is complete.

=item * When waiting: calls C<render_later>; the response is finished later
from the event loop, with the entry or with C<503 Service Unavailable>.

=item * May take a shared lock through L</cache_lock>, released when the
response is complete or after L</cache_lock_timeout>.

=back

=head3 Example

    use Mojolicious::Lite;
    use CHI;

    plugin 'Buffer' => {cache => CHI->new(driver => 'Memory', global => 1)};

    get '/report' => sub {
	my $c = shift;
	return if $c->buffer_is_cached;

	# Only reached on a miss
	$c->render(text => expensive_report());
    };

=head3 API SPECIFICATION

=head4 Input

    { c => { type => 'object', isa => 'Mojolicious::Controller' } }

=head4 Output

    # Return::Set schema
    { type => 'boolean' }

=head3 MESSAGES

The helper never croaks.  It logs:

    Key                     Level  Meaning
    ----------------------  -----  -------------------------------------------------
    log_cache_hit           debug  The response was replayed from the cache
    log_cache_get_failed    error  The cache's get() died; the action runs normally
    log_stale_entry         debug  The entry predates the application or a template
    log_building            debug  This request will build the entry
    log_waiting             debug  This request waits for another one in the worker
    log_waiting_worker      debug  This request waits for another worker
    log_lock_failed         error  The lock backend failed; a local flight is used
    log_gave_up             debug  The wait timed out; a 503 was sent
    log_finish_waiter_failed error Replaying to a waiting request failed

=head3 PSEUDOCODE

    if the plugin is off for this response, return false
    if this request was already replayed or is already waiting, return true
    if this request is already building an entry, return false
    if there is no cache or the request may not use it, return false
    mark the request so the finished response is stored
    work out the key and look the entry up
    if the cache failed, return false
    if there is no fresh entry:
        set X-Cache: MISS
        if single-flight is off, return false
        if this worker is already building the key, wait for it, return true
        if a lock backend says another worker is building it, poll, return true
        start a flight for the key (holding the lock if one was taken)
        return false
    replay the entry and return true

=head2 i18n

    my $text = $plugin->i18n('retry_later');

=head3 Purpose

Look a message up in the catalog, applying the L</messages> option.  It is
the method from L<Mojolicious::Plugin::Buffer::I18N>, imported so that the
plugin and its backends share one implementation; that module documents it
in full.

=head3 Arguments

C<$key>, a message key, and an optional hash of placeholder values.

=head3 Returns

The text of the message, or the key itself if it is unknown.

=head3 Side effects

None.

=head3 Example

    my $plugin = $app->plugin('Buffer', messages => {log_cache_hit => 'HIT %{key}'});
    say $plugin->i18n('log_cache_hit', {key => 'buffer:abc'});   # HIT buffer:abc

=head3 API SPECIFICATION

=head4 Input

    {
	key  => { type => 'string', min => 1 },
	args => { type => 'hashref', optional => 1 },
    }

=head4 Output

    # Return::Set schema
    { type => 'string' }

=head3 MESSAGES

See L<Mojolicious::Plugin::Buffer::I18N/i18n>.

=cut

# ---------------------------------------------------------------------------
# Registration helpers
# ---------------------------------------------------------------------------

# Purpose:        Give register() its own copy of a default value.
# Entry criteria: Any value from %DEFAULTS.
# Exit status:    An unshared, writable array reference for an array
#                 reference; anything else unchanged.
# Side effects:   None.
sub _copy_default :Private {
	my $value = shift;

	return (ref($value) eq 'ARRAY') ? [@$value] : $value;
}

# Purpose:        Check one option value against its schema.
# Entry criteria: $name is a key of %OPTION_SCHEMA.
# Exit status:    1 if the value is acceptable, 0 otherwise.  undef is
#                 only acceptable for options marked optional, or offered
#                 a choice of types (last_modified, cache_key).
# Side effects:   None; the validator's exception is discarded because
#                 the caller reports a catalogued message instead.
sub _option_valid :Private {
	my ($name, $value) = @_;

	# Params::Validate::Strict lets undef through even for a required type,
	# which would let e.g. vary_by => undef drop the Cookie header from the
	# cache key without a word, so undef is decided here
	my $schema = $OPTION_SCHEMA{$name};
	my $may_be_undef = (ref($schema) eq 'ARRAY') || $schema->{optional};

	return ((defined($value) || $may_be_undef)
		&& eval { validate_strict(schema => {$name => $schema}, input => {$name => $value}); 1 }) ? 1 : 0;
}

# Purpose:        Find the catalog key that explains a bad option value.
# Entry criteria: $name is a known option.
# Exit status:    A message key that exists in the catalog.
# Side effects:   None.
sub _option_message :Private {
	my $name = shift;

	my $key = $OPTION_MESSAGE{$name} // "option_$name";
	return exists(Mojolicious::Plugin::Buffer::I18N->catalog->{$key}) ? $key : 'option_invalid';
}

# Purpose:        Choose the lock backend that makes single-flight span
#                 worker processes.
# Entry criteria: $options holds validated cache_lock/cache_lock_dir.
# Exit status:    The backend object, or undef for per-worker flights.
# Side effects:   Croaks if both were given; creates the lock directory.
sub _build_lock :Private {
	my ($self, $options) = @_;

	my ($backend, $dir) = @{$options}{qw(cache_lock cache_lock_dir)};
	croak $self->i18n('lock_options_combined') if defined($backend) && defined($dir);

	# cache_lock_dir is a shorthand for the built-in file backend
	return $backend // (defined($dir)
		? Mojolicious::Plugin::Buffer::Lock::File->new(dir => $dir, messages => $self->{messages})
		: undef);
}

# Purpose:        Turn the encodings option into the list actually offered.
# Entry criteria: $requested is an array reference.
# Exit status:    An array reference of canonical, unique, available codings
#                 in the order given.
# Side effects:   Croaks on an unknown coding; loads optional modules.
sub _supported_encodings :Private {
	my ($self, $requested) = @_;

	my (@encodings, %seen);
	for my $encoding (@$requested) {
		my $name = _canonical_encoding($encoding);
		croak $self->i18n('unknown_encoding', {encoding => $encoding // ''}) unless $ENCODERS{$name};

		# Keep the first mention, and skip codings whose module is missing
		next if $seen{$name}++;
		next if $ENCODING_MODULE{$name} && !_module_available($ENCODING_MODULE{$name});
		push @encodings, $name;
	}

	return \@encodings;
}

# Purpose:        Report whether an optional module can be loaded.
# Entry criteria: $module is a package name.
# Exit status:    1 if it loads, 0 if it is missing or fails to compile.
# Side effects:   Loads the module; caches the answer for the process.
sub _module_available :Private {
	my $module = shift;

	# An ambient $SIG{__DIE__} handler can swallow the die from an @INC hook
	# (Test::Without::Module uses one), which makes a hidden module look
	# loadable.  Probe with the default handler so the load decides.
	local $SIG{__DIE__};

	# load_class returns undef on success, 1 if missing, or an exception
	return $AVAILABLE{$module} //= load_class($module) ? 0 : 1;
}

# Purpose:        Write one catalogued line to the application log.
# Entry criteria: $level is a Mojo::Log level; $key is a catalog key.
# Exit status:    $self, for chaining.
# Side effects:   Logs.  The message is built lazily, only if the level is
#                 enabled, so debug lines cost nothing in production.
sub _log :Private {
	my ($self, $app, $level, $key, $args) = @_;

	# Exceptions arrive with a trailing newline that would split the line
	my %args = %{$args // {}};
	$args{error} = trim("$args{error}") if defined($args{error});

	$app->log->$level(sub { $self->i18n($key, \%args) });

	return $self;
}

# ---------------------------------------------------------------------------
# Per-response options
# ---------------------------------------------------------------------------

# Purpose:        Work out the options that apply to this response.
# Entry criteria: $c is the current controller.
# Exit status:    A new hash reference of options, or undef when the
#                 buffer stash is a false scalar (plugin off).
# Side effects:   Calls buffer_<name> controller methods.
sub _options_for :Private {
	my ($self, $c) = @_;

	my $override = $c->stash->{$STASH_OVERRIDE};
	return undef if defined($override) && !ref($override) && !$override;

	my %options = %{$self->{options}};
	%options = (%options, %$override) if ref($override) eq 'HASH';

	# A route default or a controller class can declare these for a whole
	# group of pages, with the buffer stash still the most specific place to
	# say otherwise
	for my $name (@GROUP_OPTIONS) {
		next if (ref($override) eq 'HASH') && exists($override->{$name});
		my $declared = $self->_declared_option($c, $name);
		$options{$name} = $declared if defined($declared);
	}

	return \%options;
}

# Purpose:        Read a group-level declaration for one option.
# Entry criteria: $name is one of @GROUP_OPTIONS.
# Exit status:    The declared scalar, or undef if nothing usable was
#                 declared.
# Side effects:   Calls the controller method; logs if it dies.
sub _declared_option :Private {
	my ($self, $c, $name) = @_;

	# Route defaults and under routes land in the stash
	my $stashed = $c->stash->{$name};
	return $stashed if defined($stashed) && !ref($stashed);

	my $method = "buffer_$name";
	return undef unless $c->can($method);

	my $declared = eval { $c->$method };
	if (my $error = $@) {
		# A broken declaration must not take the response down with it; the
		# plugin option stays in force instead
		$self->_log($c->app, debug => 'log_declaration_failed', {method => $method, error => $error});
		return undef;
	}

	return ref($declared) ? undef : $declared;
}

# ---------------------------------------------------------------------------
# The after_dispatch pipeline
# ---------------------------------------------------------------------------

# Purpose:        The after_dispatch hook.  Wraps the response pipeline so
#                 that a request which was building a cache entry always
#                 releases the requests waiting for it, whether it
#                 succeeded, failed, or produced something uncacheable.
# Entry criteria: $c is the finished controller.
# Exit status:    $self.  Re-throws any pipeline exception.
# Side effects:   Rewrites the response; answers waiting requests.
#                 Protected so a subclass can wrap it.
sub _process :Protected {
	my ($self, $c) = @_;

	my $flight = $c->stash->{$STASH_FLIGHT};
	my $ok = eval { $self->_process_response($c); 1 };
	my $error = $@;

	if ($flight) {
		eval { $self->_release_flight($c->app, $flight, $c->stash->{$STASH_STORED}); 1 }
			or $self->_log($c->app, error => 'log_release_failed', {error => $@});
	}

	# Re-throw unchanged.  croak() is deliberately not used: it would append
	# a second "at FILE line N" to a message that already has one.
	die $error unless $ok;

	return $self;
}

# Purpose:        Optimise, compress, cache and validate one response.
# Entry criteria: $c is the finished controller.
# Exit status:    $self.
# Side effects:   May replace the body and set Content-Encoding, Vary,
#                 ETag, Last-Modified and Content-Length; may store the
#                 response in the cache; may turn it into a 304.
sub _process_response :Private {
	my ($self, $c) = @_;

	my $options = $self->_options_for($c) or return $self;
	my $res = $c->res;

	# Only an in-memory, unencoded body with a known media type is ours
	my $body = _buffered_body($res) // return $self;
	my $type = _mime_type($res->headers->content_type);
	return $self if !defined($type) || _matches($type, $options->{excluded_types});

	# A replayed entry was optimised before it was stored
	my $from_cache = $c->stash->{$STASH_FROM_CACHE};
	$body = $self->_optimise_html($c, $options, $type, $body) unless $from_cache;

	# The ETag is calculated from the unencoded entity plus the content coding,
	# so gzip's changing timestamp can never alter it
	my $entity = $body;
	utf8::encode($entity) if utf8::is_utf8($entity);

	my $encoded = _matches($type, $options->{compressible_types})
		? $self->_compress($c, $options, $entity)
		: undef;

	# Populate the server-side cache with the unencoded entity, so that each
	# client still gets its own content coding and conditional response
	my $code = $res->code || 0;
	$self->_store_in_cache($c, $options, $entity, $code)
		if !$from_cache && $c->stash->{$STASH_CHECKED};

	return $self if $self->_answer_not_modified($c, $options, $entity, $encoded && $encoded->{encoding}, $code);

	# Both branches are bytes, so length() is the Content-Length
	my $final = $encoded ? $encoded->{body} : $entity;
	$res->body($final);
	$res->headers->content_length(length($final));

	return $self;
}

# Purpose:        Decide whether a response is one the plugin may rework,
#                 and fetch its body if so.
# Entry criteria: $res is a Mojo::Message::Response.
# Exit status:    The body, or undef for interim and bodyless statuses,
#                 bodies already encoded (e.g. by the renderer), multipart
#                 and streamed content, files on disk and empty bodies.
# Side effects:   None.
sub _buffered_body :Private {
	my $res = shift;

	my $code = $res->code || 0;
	my $content = $res->content;

	# Short-circuit order matters: a multipart body has no asset()
	my $ours = !($code && (($code < $HTTP_MIN_FINAL) || $BODYLESS_STATUS{$code}))
		&& !$res->headers->content_encoding
		&& !$content->is_multipart
		&& !$content->is_dynamic
		&& !$content->asset->is_file;

	my $body = $ours ? $content->asset->slurp : undef;
	return (defined($body) && length($body)) ? $body : undef;
}

# Purpose:        Apply optimise_content to HTML responses.
# Entry criteria: $type is the lower-cased media type.
# Exit status:    The optimised body if it is smaller, else the original.
# Side effects:   Logs the saving at debug level.
sub _optimise_html :Private {
	my ($self, $c, $options, $type, $body) = @_;

	my $optimised = ($options->{optimise_content} && $HTML_TYPES{$type})
		? $self->_optimise($body, $c, $options)
		: undef;

	# Keep the optimised body only if it really is smaller
	if (defined($optimised) && (length($optimised) < length($body))) {
		$self->_log($c->app, debug => 'log_optimised',
			{from => length($body), to => length($optimised), count => length($optimised)});
		$body = $optimised;
	}

	return $body;
}

# Purpose:        Compress the entity with the best coding the client
#                 accepts.
# Entry criteria: $entity is bytes of a compressible type.
# Exit status:    {encoding, body} when compression was used, else undef.
# Side effects:   Adds Vary: Accept-Encoding whenever compression is on, as
#                 the choice of representation depends on it even when
#                 identity wins; sets Content-Encoding when used; logs.
sub _compress :Private {
	my ($self, $c, $options, $entity) = @_;

	return undef unless $options->{compress_content};

	my $headers = $c->res->headers;
	_add_vary($headers);

	my $wanted = _negotiate_encoding($c->req->headers->accept_encoding, $options->{encodings});
	return undef unless defined($wanted) && (length($entity) >= ($options->{min_compress_size} // 0));

	my $result = _encode_body($wanted, $entity);
	if (defined($result->{error})) {
		$self->_log($c->app, error => 'log_compress_failed', {encoding => $wanted, error => $result->{error}});
		return undef;
	}

	# Compression that does not save anything is not worth the header
	return undef unless defined($result->{body}) && (length($result->{body}) < length($entity));

	$headers->content_encoding($wanted);
	$self->_log($c->app, debug => 'log_compressed',
		{encoding => $wanted, from => length($entity), to => length($result->{body}), count => length($result->{body})});

	return {encoding => $wanted, body => $result->{body}};
}

# Purpose:        Add the validators and, when they match the request,
#                 turn the response into 304 Not Modified.
# Entry criteria: $entity is the unencoded body; $encoding is the coding
#                 used or undef.
# Exit status:    1 if a 304 was produced, 0 otherwise.
# Side effects:   Sets Last-Modified and ETag on 200 GET/HEAD responses;
#                 on a match empties the body and changes the status.
sub _answer_not_modified :Private {
	my ($self, $c, $options, $entity, $encoding, $code) = @_;

	return 0 unless ($code == $HTTP_OK) && $SAFE_METHODS{$c->req->method};

	my $headers = $c->res->headers;
	my $last_modified = $self->_resolve_last_modified($options->{last_modified}, $c);
	$headers->last_modified(Mojo::Date->new($last_modified)->to_string)
		if defined($last_modified) && !$headers->last_modified;

	my $etag = $options->{generate_etag} ? _ensure_etag($headers, $entity, $encoding) : undef;
	return 0 unless $options->{generate_304} && _is_fresh($c->req->headers, $options, $etag, $last_modified);

	$self->_log($c->app, debug => defined($etag) ? 'log_not_modified_etag' : 'log_not_modified', {etag => $etag});
	$c->res->code($HTTP_NOT_MODIFIED);
	$c->res->body('');
	$headers->remove('Content-Length');

	return 1;
}

# Purpose:        Make sure the response has an entity tag.
# Entry criteria: $entity is bytes; $encoding is a coding name or undef.
# Exit status:    The tag in force: the action's own, or a new MD5 tag.
# Side effects:   Sets the ETag header when the action did not.
sub _ensure_etag :Private {
	my ($headers, $entity, $encoding) = @_;

	my $etag = $headers->etag;
	if (!defined($etag) || !length($etag)) {
		# The coding is part of the tag: gzip and identity differ
		$etag = '"' . md5_sum($entity . (defined($encoding) ? "\x00$encoding" : '')) . '"';
		$headers->etag($etag);
	}

	return $etag;
}

# Purpose:        Decide whether the client's copy is current (RFC 7232).
# Entry criteria: $req_headers are the request headers; $etag and
#                 $last_modified are what this response carries, or undef.
# Exit status:    1 if a 304 should be sent, 0 otherwise.
# Side effects:   None.
sub _is_fresh :Private {
	my ($req_headers, $options, $etag, $last_modified) = @_;

	my $if_none_match = $req_headers->if_none_match;
	my $fresh;

	if (defined($if_none_match)) {
		# If-None-Match takes precedence; If-Modified-Since is then ignored
		# even when there is no ETag to compare it with
		$fresh = defined($etag) && _etag_matches($if_none_match, $etag);
	} else {
		# Without an entity tag, If-Modified-Since is the only validator the
		# client can offer.  Last-Modified comes from the application and its
		# templates, not from the data a page was rendered from, so on its own
		# it cannot show that the representation is unchanged: a database row
		# or a stash value can move under a template that has not been
		# touched.  trust_last_modified is the opt-in for pages where that
		# cannot happen.
		my $trusted = !defined($etag) || $options->{trust_last_modified};
		my $since = $req_headers->if_modified_since;
		my $since_epoch = ($trusted && defined($last_modified) && defined($since))
			? eval { Mojo::Date->new($since)->epoch }
			: undef;
		$fresh = defined($since_epoch) && ($last_modified <= $since_epoch);
	}

	return $fresh ? 1 : 0;
}

# ---------------------------------------------------------------------------
# The server-side cache and single-flight
# ---------------------------------------------------------------------------

# Purpose:        The buffer_is_cached helper; see its POD.
# Entry criteria: $c is the controller the helper was called on.
# Exit status:    1 when the plugin answers the request, 0 when the action
#                 must run.
# Side effects:   See the POD.  Protected so a subclass can wrap it.
sub _is_cached :Protected {
	my ($self, $c) = @_;

	my $options = $self->_options_for($c) or return 0;
	my $stash = $c->stash;

	# Calling the helper more than once should not replay a response twice
	# or register the same request as a waiter again
	return 1 if $stash->{$STASH_FROM_CACHE} || $stash->{$STASH_WAITER};
	return 0 if $stash->{$STASH_FLIGHT};

	my $cache = $options->{cache};
	return 0 unless $cache && _request_cacheable($c);

	# From now on a miss should populate the cache at the end of the response
	$stash->{$STASH_CHECKED} = 1;
	my $key = $stash->{$STASH_KEY} = _cache_key($c, $options);

	my $lookup = $self->_lookup_entry($c, $cache, $key, 1);
	return 0 if $lookup->{failed};
	return $self->_cache_miss($c, $options, $key, $cache) unless $lookup->{entry};

	$self->_log($c->app, debug => 'log_cache_hit', {key => $key});
	return _replay_entry($c, $lookup->{entry});
}

# Purpose:        Fetch and validate an entry.
# Entry criteria: $cache understands get() and remove().
# Exit status:    {entry => $entry} for a fresh entry, {} for a miss, and
#                 {failed => 1} when the cache died, so the first lookup
#                 can tell a broken cache from a miss while pollers treat
#                 both as "not there yet".
# Side effects:   Removes an entry older than the application; logs.
sub _lookup_entry :Private {
	my ($self, $c, $cache, $key, $log_errors) = @_;

	my $entry = eval { $cache->get($key) };
	if (my $error = $@) {
		$self->_log($c->app, error => 'log_cache_get_failed', {error => $error}) if $log_errors;
		return {failed => 1};
	}

	return {} unless (ref($entry) eq 'HASH') && defined($entry->{body});

	# An entry created before the application was last changed may have been
	# produced by different code, so throw it away
	my $mtime = $self->_application_mtime($c);
	if (defined($mtime) && (($entry->{created} // 0) < $mtime)) {
		$self->_log($c->app, debug => 'log_stale_entry');
		eval { $cache->remove($key) };
		return {};
	}

	return {entry => $entry};
}

# Purpose:        Handle a miss: join an in-flight build of the same key,
#                 or become the request that builds and stores it.
# Entry criteria: The cache has no fresh entry for $key.
# Exit status:    1 if this request now waits, 0 if the action must run.
# Side effects:   Sets X-Cache: MISS; may take the shared lock; may start
#                 a flight or register a waiter.
sub _cache_miss :Private {
	my ($self, $c, $options, $key, $cache) = @_;

	$c->res->headers->header($X_CACHE => $MISS);
	return 0 unless $options->{cache_single_flight};

	# Include the cache object so that two caches with the same key do not
	# wait for each other
	my $id = refaddr($cache) . "\x00$key";
	my $flight = $self->{inflight}{$id};
	return $self->_join_flight($c, $flight) if $flight;

	# With a lock backend, elect one worker to build the entry and make the
	# others wait for it, even though they cannot share the flight table
	my $guard;
	if ($self->{lock}) {
		my $lock = $self->_acquire_lock($key);
		return $self->_join_shared_lock($c, $options, $key, $cache) if $lock->{busy};

		# On a backend error, carry on with a flight local to this worker
		$self->_log($c->app, error => 'log_lock_failed', {error => $lock->{error}}) if !$lock->{guard};
		$guard = $lock->{guard};
	}

	$self->_start_flight($c, $id, $key, $options, $guard);

	return 0;
}

# Purpose:        Register this request as the builder for a key.
# Entry criteria: No flight exists for $id.
# Exit status:    $self.
# Side effects:   Adds the flight, stores it in the stash, and arms a timer
#                 that releases it if the action never finishes.
sub _start_flight :Private {
	my ($self, $c, $id, $key, $options, $guard) = @_;

	my $timeout = _lock_timeout($options);
	my $flight = {
		id => $id,
		key => $key,
		deadline => Time::HiRes::time() + $timeout,
		waiters => {},
		lock => $guard,
	};

	# Do not keep the key reserved for ever if the action never finishes.
	# Capture the app, not $c, so the timer does not keep the controller.
	my $app = $c->app;
	$flight->{timer} = Mojo::IOLoop->timer($timeout => sub { $self->_expire_flight($app, $flight) });

	$self->{inflight}{$id} = $flight;
	$c->stash->{$STASH_FLIGHT} = $flight;
	$self->_log($app, debug => 'log_building', {key => $key});

	return $self;
}

# Purpose:        Hold a second request for the same key until the first
#                 one has finished.
# Entry criteria: $flight is the in-flight build this request joins.
# Exit status:    1 (the plugin will answer this request).
# Side effects:   Suppresses automatic rendering; arms a give-up timer.
sub _join_flight :Private {
	my ($self, $c, $flight) = @_;

	my $id = refaddr($c);
	return 1 if $flight->{waiters}{$id} || $c->stash->{$STASH_FINISHED};

	# The response has to be finished later, so suppress automatic rendering
	$c->stash->{$STASH_WAITER} = 1;
	$c->render_later;

	# Every waiter gets at least one tick, even past the deadline
	my $remaining = $flight->{deadline} - Time::HiRes::time();
	$remaining = $MIN_WAITER_DELAY if $remaining < $MIN_WAITER_DELAY;

	$flight->{waiters}{$id} = {
		c => $c,
		timer => Mojo::IOLoop->timer($remaining => sub { $self->_expire_waiter($flight, $id) }),
	};
	$self->_log($c->app, debug => 'log_waiting', {key => $flight->{key}});

	return 1;
}

# Purpose:        Give up on one waiter whose deadline passed.
# Entry criteria: Called from the waiter's timer.
# Exit status:    $self.
# Side effects:   Removes the waiter and answers it with a 503.
sub _expire_waiter :Private {
	my ($self, $flight, $id) = @_;

	my $waiter = delete($flight->{waiters}{$id});
	my $c = $waiter ? $waiter->{c} : undef;
	if ($c && !$c->stash->{$STASH_FINISHED}) {
		$self->_log($c->app, debug => 'log_gave_up');
		$self->_service_unavailable($c);
	}

	return $self;
}

# Purpose:        Wait for a request in another worker that holds the
#                 shared lock.  The builder cannot notify us, so poll the
#                 cache until the entry appears or the lock is gone.
# Entry criteria: The lock backend reported the key as held elsewhere.
# Exit status:    1 (the plugin will answer this request).
# Side effects:   Suppresses automatic rendering; installs a recurring
#                 timer that ends itself.
sub _join_shared_lock :Private {
	my ($self, $c, $options, $key, $cache) = @_;

	$c->stash->{$STASH_WAITER} = 1;
	$c->render_later;

	my $deadline = Time::HiRes::time() + _lock_timeout($options);
	$self->_log($c->app, debug => 'log_waiting_worker', {key => $key});

	my ($poll, $done);
	$poll = Mojo::IOLoop->recurring($SHARED_POLL_INTERVAL => sub {
		return if $done;

		# undef means "keep waiting"; anything else ends the poll
		my $outcome = $self->_poll_shared_lock($c, $key, $cache, $deadline) or return;
		$done = 1;
		Mojo::IOLoop->remove($poll);
		$self->_answer_waiter($c->app, $c, $outcome->{entry}) unless $outcome->{abandoned};
	});

	return 1;
}

# Purpose:        One poll of a cross-worker wait.
# Entry criteria: Called from _join_shared_lock's timer.
# Exit status:    undef to keep polling; {abandoned => 1} if the request
#                 was finished elsewhere; otherwise {entry => $entry},
#                 where a missing entry means "answer with a 503".
# Side effects:   May take and release the shared lock; logs.
sub _poll_shared_lock :Private {
	my ($self, $c, $key, $cache, $deadline) = @_;

	my $app = $c->app;
	return {abandoned => 1} if $c->stash->{$STASH_FINISHED};

	my $entry = $self->_lookup_entry($c, $cache, $key, 0)->{entry};
	if ($entry) {
		$self->_log($app, debug => 'log_filled_elsewhere');
		return {entry => $entry};
	}

	if (Time::HiRes::time() >= $deadline) {
		$self->_log($app, debug => 'log_gave_up_worker');
		return {};
	}

	# If the lock can be taken, the builder has finished.  Hold it while
	# checking again so that a new builder cannot start in between.
	my $lock = $self->_acquire_lock($key);
	return undef if $lock->{busy};
	if (!$lock->{guard}) {
		$self->_log($app, error => 'log_lock_failed', {error => $lock->{error}});
		return {};
	}

	my $late = $self->_lookup_entry($c, $cache, $key, 0)->{entry};
	$self->_release_lock_logged($app, $lock->{guard});
	$self->_log($app, debug => $late ? 'log_filled_elsewhere' : 'log_not_cached_elsewhere');

	return {entry => $late};
}

# Purpose:        Release a flight whose builder did not finish in time.
# Entry criteria: Called from the flight's timer.
# Exit status:    $self.
# Side effects:   Logs, then answers the waiters with a 503 and releases
#                 the shared lock.
sub _expire_flight :Private {
	my ($self, $app, $flight) = @_;

	if ($self->_is_current_flight($flight)) {
		$self->_log($app, debug => 'log_flight_expired');
		$self->_release_flight($app, $flight, undef);
	}

	return $self;
}

# Purpose:        Finish every request waiting for this key.  With a stored
#                 entry they are served it; without one (a failed or
#                 uncacheable response) they are told to retry rather than
#                 each running the action, which is what single-flight is
#                 meant to prevent.
# Entry criteria: $flight was started by _start_flight.
# Exit status:    $self.
# Side effects:   Removes the flight and its timers; answers waiters;
#                 releases the shared lock.
sub _release_flight :Private {
	my ($self, $app, $flight, $entry) = @_;

	# A flight is only released once, by whichever of the finished response
	# and the timeout comes first
	return $self unless $self->_is_current_flight($flight);

	delete($self->{inflight}{$flight->{id}});
	Mojo::IOLoop->remove($flight->{timer}) if defined($flight->{timer});

	my @waiters = values %{$flight->{waiters}};
	$flight->{waiters} = {};

	for my $waiter (@waiters) {
		Mojo::IOLoop->remove($waiter->{timer}) if defined($waiter->{timer});
		$self->_answer_waiter($app, $waiter->{c}, $entry,
			$entry ? 'log_serving_waiter' : 'log_uncacheable_flight');
	}

	my $guard = delete($flight->{lock});
	$self->_release_lock_logged($app, $guard) if $guard;

	return $self;
}

# Purpose:        Check that a flight is still the one registered for its
#                 key, rather than one released earlier.
# Entry criteria: $flight is a flight hash.
# Exit status:    1 or 0.
# Side effects:   None.
sub _is_current_flight :Private {
	my ($self, $flight) = @_;

	my $current = $self->{inflight}{$flight->{id}};
	return ($current && (refaddr($current) == refaddr($flight))) ? 1 : 0;
}

# Purpose:        Finish a request that was waiting for another one.
# Entry criteria: $entry is the stored entry, or undef for "retry later";
#                 $note is an optional log key.
# Exit status:    $self.
# Side effects:   Replays the entry or sends a 503; logs failures.  Skips
#                 requests that are already finished.
sub _answer_waiter :Private {
	my ($self, $app, $c, $entry, $note) = @_;

	# A client that went away, or was answered by a timeout, needs nothing
	if ($c && !$c->stash->{$STASH_FINISHED}) {
		$self->_log($app, debug => $note) if $note;
		my $ok = eval { $entry ? _replay_entry($c, $entry) : $self->_service_unavailable($c); 1 };
		$self->_log($app, error => 'log_finish_waiter_failed', {error => $@}) unless $ok;
	}

	return $self;
}

# Purpose:        Send a cached entry as this request's response.
# Entry criteria: $entry has body, and optionally status and headers.
# Exit status:    1.
# Side effects:   Replaces status, stored headers and body; adds
#                 X-Cache: HIT; finishes the response.
sub _replay_entry :Private {
	my ($c, $entry) = @_;

	my $res = $c->res;
	my $headers = $res->headers;
	$res->code($entry->{status} || $HTTP_OK);

	# The first stored value replaces whatever the action set; later values
	# of the same header are added, so multi-valued headers survive
	my %seen;
	for my $pair (@{$entry->{headers} || []}) {
		my ($name, $value) = @$pair;
		$headers->remove($name) unless $seen{lc($name)}++;
		$headers->add($name => $value);
	}

	$res->body($entry->{body});
	$headers->header($X_CACHE => $HIT);
	$c->stash->{$STASH_FROM_CACHE} = 1;

	# Finish the response; the action can just return now
	$c->rendered;

	return 1;
}

# Purpose:        Tell a waiting client to retry shortly.
# Entry criteria: $c has not been finished.
# Exit status:    1.
# Side effects:   Sends 503 with Retry-After and the retry_later text,
#                 encoded as UTF-8 so a translated message is safe.
sub _service_unavailable :Private {
	my ($self, $c) = @_;

	my $res = $c->res;
	my $headers = $res->headers;
	$res->code($HTTP_UNAVAILABLE);
	$headers->content_type('text/plain; charset=UTF-8');
	$headers->header('Cache-Control' => 'no-store');
	$headers->header('Retry-After' => $RETRY_AFTER);
	$headers->header($X_CACHE => $MISS);
	$res->body(encode('UTF-8', $self->i18n('retry_later')));
	$c->rendered;

	return 1;
}

# Purpose:        The effective wait limit for this response.
# Entry criteria: $options may hold an unvalidated stash override.
# Exit status:    A positive number of seconds; the default when the
#                 value is missing or unusable.
# Side effects:   None.
sub _lock_timeout :Private {
	my $options = shift;

	my $timeout = $options->{cache_lock_timeout};
	return (defined($timeout) && _option_valid('cache_lock_timeout', $timeout)) ? $timeout + 0 : $DEFAULT_LOCK_TIMEOUT;
}

# Purpose:        Call the lock backend's acquire().  A backend may die, so
#                 exceptions become errors and the caller can fall back to
#                 a per-worker flight rather than breaking the request.
# Entry criteria: $self->{lock} is set.
# Exit status:    {guard, error, busy}: busy is true when another process
#                 holds the lock and nothing went wrong.
# Side effects:   Whatever the backend does.
sub _acquire_lock :Private {
	my ($self, $key) = @_;

	my ($guard, $error);
	my $ok = eval { ($guard, $error) = $self->{lock}->acquire($key); 1 };
	$error = trim("$@") unless $ok;
	$guard = undef unless $ok && $guard;

	return {guard => $guard, error => $error, busy => (!$guard && !defined($error)) ? 1 : 0};
}

# Purpose:        Call the lock backend's release(), normalising its
#                 answer.
# Entry criteria: $guard came from _acquire_lock.
# Exit status:    {ok => 1} or {ok => 0, error => $text}.  A backend that
#                 returns nothing is treated as having released the lock.
# Side effects:   Whatever the backend does.
sub _release_lock :Private {
	my ($self, $guard) = @_;

	my ($released, $error);
	my $called = eval { ($released, $error) = $self->{lock}->release($guard); 1 };

	return !$called ? {ok => 0, error => trim("$@")}
		: (!defined($released) || $released) ? {ok => 1}
		: {ok => 0, error => $error // $self->i18n('unknown_error')};
}

# Purpose:        Release a shared lock, logging a failure.
# Entry criteria: $guard came from _acquire_lock.
# Exit status:    $self.
# Side effects:   Releases the lock; logs at error level on failure.
sub _release_lock_logged :Private {
	my ($self, $app, $guard) = @_;

	my $result = $self->_release_lock($guard);
	$self->_log($app, error => 'log_unlock_failed', {error => $result->{error}}) unless $result->{ok};

	return $self;
}

# Purpose:        Store a finished response in the cache.
# Entry criteria: $entity is the unencoded body; $code the status.
# Exit status:    $self.
# Side effects:   Writes the cache; sets X-Cache: MISS if unset; stores
#                 the entry in the stash for waiting requests; logs.
sub _store_in_cache :Private {
	my ($self, $c, $options, $entity, $code) = @_;

	my $cache = $options->{cache};
	return $self unless $cache && ($code == $HTTP_OK)
		&& _request_cacheable($c) && _response_cacheable($c->res, $options);

	my $key = $c->stash->{$STASH_KEY} // _cache_key($c, $options);
	my $entry = {
		body => $entity,
		status => $HTTP_OK,
		created => time,
		headers => _headers_to_store($c->res->headers),
	};

	my $duration = $options->{cache_duration} // $DEFAULT_CACHE_DURATION;
	if (!eval { $cache->set($key, $entry, $duration); 1 }) {
		$self->_log($c->app, error => 'log_cache_set_failed', {error => $@});
		return $self;
	}

	$self->_log($c->app, debug => 'log_cached', {key => $key});
	my $headers = $c->res->headers;
	$headers->header($X_CACHE => $MISS) unless defined($headers->header($X_CACHE));

	# Hand this entry to any request that was waiting for it
	$c->stash->{$STASH_STORED} = $entry;

	return $self;
}

# Purpose:        Compute the cache key for this request.
# Entry criteria: $options holds cache_key and vary_by.
# Exit status:    The custom key if one applies, else 'buffer:' and an MD5
#                 of the app class, host, path, query and vary_by values.
# Side effects:   Calls a cache_key coderef.
sub _cache_key :Private {
	my ($c, $options) = @_;

	my $custom = $options->{cache_key};
	$custom = $custom->($c) if ref($custom) eq 'CODE';
	return $custom if defined($custom) && !ref($custom) && length($custom);

	my $req = $c->req;
	my $url = $req->url;
	my @material = (
		ref($c->app),
		$url->host_port // $req->headers->host // '',
		$url->path->to_string,
		$url->query->to_string,
	);

	# Header names are case-insensitive, so the key uses the lower-cased name
	push @material, map { lc($_) . '=' . ($req->headers->header($_) // '') } @{$options->{vary_by} || []};

	# A digest keeps the key short, driver-safe and free of cookie data.
	# md5_sum dies on characters above 255, so hash the UTF-8 bytes.
	return $KEY_PREFIX . md5_sum(encode('UTF-8', join("\x00", @material)));
}

# Purpose:        Decide whether this request may use the cache at all.
# Entry criteria: $c is the current controller.
# Exit status:    1 or 0.
# Side effects:   None.
sub _request_cacheable :Private {
	my $c = shift;

	my $req = $c->req;

	# Authenticated responses are per-user, whatever the URL says
	return ($ENV{NO_CACHE} || $ENV{NO_STORE}) ? 0
		: !$SAFE_METHODS{$req->method} ? 0
		: $req->headers->authorization ? 0
		: _cache_control_forbids($req->headers->cache_control, \%REQUEST_NO_CACHE) ? 0
		: 1;
}

# Purpose:        Decide whether a finished response may be stored.
# Entry criteria: $res is the response; $options holds vary_by.
# Exit status:    1 or 0.
# Side effects:   None.
sub _response_cacheable :Private {
	my ($res, $options) = @_;

	my $headers = $res->headers;

	# The request headers the key covers, plus the coding we vary on anyway
	my %allowed = map { lc($_) => 1 } @{$options->{vary_by} || []}, 'accept-encoding';
	my @varies = grep { length } map { lc(trim($_)) } split(/,/, $headers->vary // '');

	# Never replay cookies that were meant for one client, nor a response
	# that varies on something the key does not cover: it would be served to
	# the wrong client
	my $cacheable = !$headers->set_cookie
		&& !_cache_control_forbids($headers->cache_control, \%RESPONSE_NO_STORE)
		&& !grep { !$allowed{$_} } @varies;

	return $cacheable ? 1 : 0;
}

# Purpose:        Check a Cache-Control value for forbidding directives.
# Entry criteria: $value is the header or undef; $directives is a set of
#                 lower-case directive names.
# Exit status:    1 if a listed directive is present (max-age only when
#                 it is zero), else 0.
# Side effects:   None.  Mojo::Util::split_header does the parsing, so
#                 quoted values and "no-cache-foo" are handled correctly.
sub _cache_control_forbids :Private {
	my ($value, $directives) = @_;

	my $forbidden = 0;
	for my $directive (@{split_header($value // '')}) {
		my ($name, $argument) = (lc($directive->[0]), $directive->[1]);
		next unless $directives->{$name};
		$forbidden = 1 if ($name ne 'max-age') || (defined($argument) && ($argument =~ /^0+$/));
	}

	return $forbidden;
}

# Purpose:        Pick the response headers worth storing with an entry.
# Entry criteria: $headers is a Mojo::Headers.
# Exit status:    An array reference of [name, value] pairs.
# Side effects:   None.
sub _headers_to_store :Private {
	my $headers = shift;

	my @pairs;
	for my $name (grep { !$UNSTORED_HEADERS{lc($_)} } @{$headers->names}) {
		push @pairs, map { [$name, $_] } @{$headers->every_header($name)};
	}

	return \@pairs;
}

# ---------------------------------------------------------------------------
# Modification times
# ---------------------------------------------------------------------------

# Purpose:        The application script's mtime.
# Entry criteria: None.
# Exit status:    An epoch, or undef if $0 is not a readable file.
# Side effects:   Remembers the answer for the life of the plugin: the
#                 running code does not change when the file does.
sub _script_mtime :Private {
	my $self = shift;

	if (!exists($self->{script_mtime})) {
		my $script = $0;
		my @stat = (defined($script) && length($script) && -f $script) ? stat($script) : ();
		$self->{script_mtime} = @stat ? $stat[9] : undef;
	}

	return $self->{script_mtime};
}

# Purpose:        The newest mtime of the application and the templates.
#                 Both Last-Modified and cache invalidation use this, so a
#                 template edit invalidates a page even though the
#                 application script has not changed.
# Entry criteria: $c is the current controller.
# Exit status:    An epoch, or undef if nothing could be stat()ed.
# Side effects:   Caches the answer in the stash for this request, and in
#                 template_mtime_cache if configured.
sub _application_mtime :Private {
	my ($self, $c) = @_;

	my $stash = $c->stash;

	# Once per request: the cache lookup and the replay both ask
	if (!exists($stash->{$STASH_MTIME})) {
		my $cache = $self->{options}{template_mtime_cache};
		my $cache_key = $cache ? $self->_template_mtime_cache_key($c) : undef;
		my $latest = $cache ? $self->_cached_mtime($c, $cache, $cache_key) : undef;

		# A miss, or no mtime cache at all, means walking the tree
		if (!defined($latest)) {
			$latest = $self->_scan_mtime($c);
			$self->_remember_mtime($c, $cache, $cache_key, $latest) if $cache && defined($latest);
		}
		$stash->{$STASH_MTIME} = $latest;
	}

	return $stash->{$STASH_MTIME};
}

# Purpose:        Read a previously scanned mtime from the mtime cache.
# Entry criteria: $cache understands get().
# Exit status:    An epoch, or undef on a miss, junk, or a cache failure.
# Side effects:   Logs a failure at debug level.
sub _cached_mtime :Private {
	my ($self, $c, $cache, $cache_key) = @_;

	my $cached = eval { $cache->get($cache_key) };
	$self->_log($c->app, debug => 'log_mtime_get_failed', {error => $@}) if $@;

	return (defined($cached) && ($cached =~ /^\d+$/)) ? $cached : undef;
}

# Purpose:        Store a scanned mtime in the mtime cache.
# Entry criteria: $cache understands set(); $latest is an epoch.
# Exit status:    $self.
# Side effects:   Writes the cache; logs failures at debug level, because
#                 a broken mtime cache only costs a scan.
sub _remember_mtime :Private {
	my ($self, $c, $cache, $cache_key, $latest) = @_;

	my $duration = $self->{options}{template_mtime_cache_duration} // $DEFAULT_MTIME_DURATION;
	my $stored = eval { $cache->set($cache_key, $latest, $duration) };
	if ($@) {
		$self->_log($c->app, debug => 'log_mtime_set_failed', {error => $@});
	} elsif (!$stored) {
		$self->_log($c->app, debug => 'log_mtime_not_stored');
	}

	return $self;
}

# Purpose:        Walk the script and every renderer path for the newest
#                 mtime.
# Entry criteria: $c is the current controller.
# Exit status:    An epoch, or undef.
# Side effects:   stat()s every file and directory under the paths.
sub _scan_mtime :Private {
	my ($self, $c) = @_;

	my $latest = $self->_script_mtime;
	my %seen;
	for my $dir (grep { defined($_) && length($_) } @{$c->app->renderer->paths || []}) {
		$latest = _latest_mtime($dir, $latest, \%seen);
	}

	return $latest;
}

# Purpose:        Key for the template mtime cache.
# Entry criteria: $c is the current controller.
# Exit status:    A key that changes with the app class, script, script
#                 mtime and template paths.
# Side effects:   None.
sub _template_mtime_cache_key :Private {
	my ($self, $c) = @_;

	my @parts = (ref($c->app), $0 // '', $self->_script_mtime // '', map { $_ // '' } @{$c->app->renderer->paths || []});

	return $MTIME_KEY_PREFIX . md5_sum(encode('UTF-8', join("\0", @parts)));
}

# Purpose:        Newest mtime in a tree.  Directory mtimes are included as
#                 well as file mtimes: editing a file moves the file's
#                 mtime, while adding, removing or renaming one moves its
#                 directory's.  stat() follows symlinks, and the seen set
#                 stops a symlink loop.
# Entry criteria: $path is a path; $latest the best so far or undef;
#                 $depth how many directories down the walk is (undef at
#                 the top).
# Exit status:    The newer of $latest and anything under $path.
# Side effects:   stat()s and reads directories; unreadable ones, and
#                 those deeper than $MAX_SCAN_DEPTH, are skipped.
sub _latest_mtime :Private {
	my ($path, $latest, $seen, $depth) = @_;

	my @stat = stat($path);
	return $latest unless @stat;

	$latest = $stat[9] if defined($stat[9]) && (!defined($latest) || ($stat[9] > $latest));
	return $latest unless -d _;

	# device:inode identifies a directory however it was reached.  Where
	# the inode is always 0 (Windows before Perl 5.38) that key would make
	# every directory after the first look already seen, so fall back to
	# the path, and let the depth limit end a loop through a symlink.
	my $id = $stat[1] ? "$stat[0]:$stat[1]" : File::Spec->canonpath($path);
	return $latest if $seen->{$id}++;
	$depth //= 0;
	return $latest if $depth >= $MAX_SCAN_DEPTH;

	# autodie makes an unreadable directory an exception; skipping it is the
	# right answer for a freshness check, so catch it here
	my $dh = eval { opendir(my $handle, $path); $handle } or return $latest;
	for my $entry (File::Spec->no_upwards(readdir($dh))) {
		$latest = _latest_mtime(File::Spec->catfile($path, $entry), $latest, $seen, $depth + 1);
	}
	eval { closedir($dh) };

	return $latest;
}

# Purpose:        Resolve the last_modified option to an epoch.
# Entry criteria: $option is 0, 1, an epoch, a date string or a coderef.
# Exit status:    An epoch, or undef for "no header".
# Side effects:   Calls a coderef; may scan the template tree.
sub _resolve_last_modified :Private {
	my ($self, $option, $c) = @_;

	# A coderef is called once; it cannot return another coderef
	my $value = (ref($option) eq 'CODE') ? $option->($c) : $option;

	# 0, undef and references mean "no header"; 1 means "work it out from
	# the application and its templates"; digits are an epoch; anything else
	# is a date string for Mojo::Date
	return (!$value || ref($value)) ? undef
		: ($value eq '1') ? $self->_application_mtime($c)
		: ($value =~ /^\d+$/) ? $value + 0
		: scalar(eval { Mojo::Date->new($value)->epoch });
}

# ---------------------------------------------------------------------------
# HTML optimisation
# ---------------------------------------------------------------------------

# Purpose:        Optimise an HTML body.
# Entry criteria: $options->{optimise_content} is the level.
# Exit status:    The optimised body; the squashed body if HTML::Packer is
#                 missing or fails.
# Side effects:   Logs a packer failure.  Protected so a subclass can use
#                 another minifier.
sub _optimise :Protected {
	my ($self, $body, $c, $options) = @_;

	my $level = $options->{optimise_content} || 0;
	return $body unless $level;

	$body = _squash($body);
	if ($options->{rewrite_links}) {
		my $rewritten = _rewrite_links($body, $c);
		$body = $rewritten if defined($rewritten);
	}

	# Without HTML::Packer comments and embedded CSS/JavaScript cannot be
	# minified, but the white-space squashing above is still worth keeping
	return $body unless _module_available('HTML::Packer');

	my $minified = eval { $self->_pack($body, $level) };
	if (my $error = $@) {
		$self->_log($c->app, error => 'log_packer_failed', {error => $error});
		return $body;
	}

	return $minified;
}

# Purpose:        Run HTML::Packer over a body.
# Entry criteria: HTML::Packer is available; $level is 1 or 2.
# Exit status:    The minified HTML.
# Side effects:   Creates and keeps one HTML::Packer per plugin instance;
#                 may die (the caller catches it).
sub _pack :Private {
	my ($self, $body, $level) = @_;

	my $packer_options = {
		remove_comments => 1,
		remove_newlines => 0,
		do_stylesheet => 'minify',
	};

	if ($level >= $OPTIMISE_AGGRESSIVE) {
		# Strip the <!-- ... //--> hiding technique, which the JavaScript
		# minifier would otherwise treat as code
		$packer_options->{do_javascript} = 'best';
		$body =~ s/(<script.*?>)\s*<!--/$1/gi;
		$body =~ s/\/\/-->\s*<\/script>/<\/script>/gi;
		$body =~ s/(<script.*?>)\s+/$1/gi;
	}

	# The packer holds no per-document state, so one per plugin will do
	$self->{packer} //= HTML::Packer->init;
	my $result = $self->{packer}->minify(\$body, $packer_options);

	return ($level >= $OPTIMISE_AGGRESSIVE) ? _merge_document_writes($result) : $result;
}

# Purpose:        Turn document.write("a"); document.write("b") into
#                 document.write("a"+"b").
# Entry criteria: $html is minified HTML.
# Exit status:    The rewritten HTML, stopping once it stops shrinking.
# Side effects:   None.
sub _merge_document_writes :Private {
	my $html = shift;

	my $old_length = length($html);
	while (1) {
		$html =~ s/<script\s*?type\s*?=\s*?"text\/javascript"\s*?>(.*?)document\.write\((.+?)\);\s*?document\.write\((.+?)\)/<script type="text\/JavaScript">${1}document.write($2+$3)/igs;
		my $new_length = length($html);
		last if $new_length >= $old_length;
		$old_length = $new_length;
	}

	return $html;
}

# Purpose:        Reduce output by removing superfluous white space.  This
#                 is the set of substitutions used by CGI::Buffer and
#                 FCGI::Buffer, with two corrections: a "+" at the start of
#                 a line is no longer deleted, and the content of pre,
#                 textarea, script and style elements is left alone.
# Entry criteria: $body is HTML.
# Exit status:    The squashed HTML.
# Side effects:   None.
sub _squash :Private {
	my $body = shift;

	my $vault = _protect_verbatim(\$body);

	# Any run of white space that holds a line break becomes that one line
	# break.  One pattern, so CRLF ("\r\n    <") loses its indentation as
	# well as LF does: the old (\s+|\r)\n alternative consumed the "\n" and
	# left the indentation after it behind.
	$body =~ s/\s*\n\s*/\n/g;
	$body =~ s/\<\/div\>\s+\<div/\<\/div\>\<div/gis;
	$body =~ s/(<div>\s+|\s+<div>)/<div>/gis;
	$body =~ s/\s+<\/div\>/\<\/div\>/gis;
	$body =~ s/\s+\<p\>|\<p\>\s+/\<p\>/im;
	$body =~ s/\s+\<\/p\>|\<\/p\>\s+/\<\/p\>/gis;
	$body =~ s/<html>\s+<head>/<html><head>/is;
	$body =~ s/\s*<\/head>\s+<body>\s*/<\/head><body>/is;
	$body =~ s/<html>\s+<body>/<html><body>/is;
	$body =~ s/<body>\s+/<body>/is;
	$body =~ s/\s+\<\/html/\<\/html/is;
	$body =~ s/\s+\<\/body/\<\/body/is;
	$body =~ s/\s(\<.+?\>\s\<.+?\>)/$1/;
	$body =~ s/\<p\>\s/\<p\>/gi;
	$body =~ s/\<\/p\>\s\<p\>/\<\/p\>\<p\>/gi;
	$body =~ s/\<\/tr\>\s\<tr\>/\<\/tr\>\<tr\>/gi;
	$body =~ s/\<\/td\>\s\<\/tr\>/\<\/td\>\<\/tr\>/gi;
	$body =~ s/\<\/td\>\s*\<td\>/\<\/td\>\<td\>/gis;
	$body =~ s/\<\/tr\>\s\<\/table\>/\<\/tr\>\<\/table\>/gi;
	$body =~ s/\<br\s?\/\>\s?\<p\>/\<p\>/gi;
	$body =~ s/\<br\>\s/\<br\>/gi;
	$body =~ s/\s+\<br/\<br/gi;
	$body =~ s/\<br\s?\/\>\s/\<br \/>/gi;
	$body =~ s/[ \t]+/ /gs;	# Don't use \s+, it would join lines
	$body =~ s/\s\<p\>/\<p\>/gi;
	$body =~ s/\s\<script/\<script/gi;
	$body =~ s/(<script>\s|\s<script>)/<script>/gis;
	$body =~ s/(<\/script>\s|\s<\/script>)/<\/script>/gis;
	$body =~ s/\<td\>\s/\<td\>/gi;
	$body =~ s/\s+\<a\shref="(.+?)"\>\s?/ <a href="$1">/gis;
	$body =~ s/\s?<a\shref=\s"(.+?)"\>/ <a href="$1">/gis;
	$body =~ s/\s+<\/a\>\s+/<\/a> /gis;
	$body =~ s/(\s?<hr>\s+|\s+<hr>\s?)/<hr>/gis;
	$body =~ s/<\/li>\s+<li>/<\/li><li>/gis;
	$body =~ s/<\/li>\s+<\/ul>/<\/li><\/ul>/gis;
	$body =~ s/<ul>\s+<li>/<ul><li>/gis;
	$body =~ s/\s+<\/li>/<\/li>/gis;
	$body =~ s/\<\/option\>\s+\<option/\<\/option\>\<option/gis;
	$body =~ s/<title>\s*(.+?)\s*<\/title>/<title>$1<\/title>/is;
	$body =~ s/<\/center>\s+<center>/ /gis;

	return _restore_verbatim($body, $vault);
}

# Purpose:        Swap the content of white-space-sensitive elements for
#                 placeholders, so the squasher cannot change it.
# Entry criteria: $body_ref refers to the HTML.
# Exit status:    {marker, saved}: what _restore_verbatim needs.
# Side effects:   Rewrites $$body_ref in place.  The tags themselves stay,
#                 so white space around them is still squashed.
sub _protect_verbatim :Private {
	my $body_ref = shift;

	# A marker that does not already occur, so restoring is exact.  NUL
	# never matches \s, so no squash pattern can touch a placeholder.
	my $marker = "\x00MPB";
	$marker .= "\x00" while index($$body_ref, $marker) >= 0;

	my @saved;
	$$body_ref =~ s{$VERBATIM_ELEMENT}{
		push(@saved, $3);
		$1 . $marker . $#saved . $marker . $4;
	}ge;

	return {marker => $marker, saved => \@saved};
}

# Purpose:        Put back what _protect_verbatim took out.
# Entry criteria: $vault came from _protect_verbatim on this body.
# Exit status:    The HTML with every placeholder restored.
# Side effects:   None.
sub _restore_verbatim :Private {
	my ($body, $vault) = @_;

	my ($marker, $saved) = @{$vault}{qw(marker saved)};
	$body =~ s{\Q$marker\E(\d+)\Q$marker\E}{$saved->[$1]}g if @$saved;

	return $body;
}

# Purpose:        Make links back to this site relative.
# Entry criteria: $body is HTML; $c is the current controller.
# Exit status:    The rewritten HTML, or undef when the request has no
#                 host to compare against.
# Side effects:   None.
sub _rewrite_links :Private {
	my ($body, $c) = @_;

	my $url = eval { $c->req->url->to_abs };
	my $host = $url ? $url->host : undef;
	return undef unless defined($host) && length($host);

	my $authority = $url->host_port // $host;
	my $origin = quotemeta(($url->scheme // 'http') . "://$authority");
	my $relative = quotemeta("//$authority");

	# The site root becomes "/", anything beneath it a root-relative path
	for my $link (@LINK_ATTRIBUTES) {
		my ($tag, $attribute) = @$link;
		$body =~ s{<$tag\s+?$attribute="$origin"}{<$tag $attribute="/"}gi;
		$body =~ s{<$tag\s+?$attribute="(?:$origin|$relative)/}{<$tag $attribute="/}gi;
	}

	# A link to the current page with a query string only needs the query
	# string, e.g. href="/search?q=perl" becomes href="?q=perl"
	my $path = $c->req->url->path->to_string;
	$body =~ s{<a\s+?href="\Q$path\E\?}{<a href="?}gi if length($path) > 1;

	return $body;
}

# ---------------------------------------------------------------------------
# Content coding
# ---------------------------------------------------------------------------

# Purpose:        Pick the best content coding from an Accept-Encoding
#                 header.
# Entry criteria: $supported is the server's list in preference order.
# Exit status:    A coding name, or undef when identity should be used.
# Side effects:   None.
sub _negotiate_encoding :Private {
	my ($accept, $supported) = @_;

	return undef unless defined($accept) && length($accept) && $supported && @$supported;

	# Highest q per coding, with "*" as the fallback for unlisted ones
	my (%quality, $wildcard);
	for my $coding (@{split_header($accept)}) {
		my ($token, undef, %params) = @$coding;
		next unless defined($token) && length($token);

		my $name = _canonical_encoding($token);
		my $q = _quality(\%params);
		if ($name eq '*') {
			$wildcard = $q;
		} elsif (!exists($quality{$name}) || ($q > $quality{$name})) {
			$quality{$name} = $q;
		}
	}

	# Server order breaks ties, so the first equal-best coding wins
	my ($best, $best_quality);
	for my $encoding (@$supported) {
		my $q = $quality{$encoding} // $wildcard // 0;
		next if $q <= 0;
		($best, $best_quality) = ($encoding, $q) if !defined($best_quality) || ($q > $best_quality);
	}

	return $best;
}

# Purpose:        Read the q parameter of one Accept-Encoding entry.
# Entry criteria: $params maps parameter names to values.
# Exit status:    A quality between 0 and 1; 1 if absent or unreadable.
# Side effects:   None.
sub _quality :Private {
	my $params = shift;

	my %lower = map { lc($_) => $params->{$_} } keys %$params;
	my $q = (defined($lower{q}) && looks_like_number($lower{q})) ? $lower{q} + 0 : 1;

	return ($q < 0) ? 0 : ($q > 1) ? 1 : $q;
}

# Purpose:        Normalise a content coding name.
# Entry criteria: Any value.
# Exit status:    The lower-cased name, with legacy aliases resolved.
# Side effects:   None.
sub _canonical_encoding :Private {
	my $name = lc(shift // '');

	return $ENCODING_ALIAS{$name} // $name;
}

# Purpose:        Compress bytes with one coding.
# Entry criteria: $encoding is a key of %ENCODERS.
# Exit status:    {body => $compressed} or {error => $text}.
# Side effects:   Loads the coding's module on first use.
sub _encode_body :Private {
	my ($encoding, $bytes) = @_;

	my $encoder = $ENCODERS{$encoding};
	my $body = eval {
		$encoder ? $encoder->($bytes) : croak(__PACKAGE__->i18n('unknown_encoding', {encoding => $encoding}));
	};

	return $@ ? {error => $@} : {body => $body};
}

# ---------------------------------------------------------------------------
# Small header helpers
# ---------------------------------------------------------------------------

# Purpose:        Compare If-None-Match with this response's tag, using
#                 the weak comparison RFC 7232 requires for it.
# Entry criteria: Both arguments are defined.
# Exit status:    1 if any listed tag, or "*", matches; else 0.
# Side effects:   None.
sub _etag_matches :Private {
	my ($if_none_match, $etag) = @_;

	(my $mine = $etag) =~ s{^W/}{};

	my $match = 0;
	for my $candidate (grep { length } map { trim($_) } split(/,/, $if_none_match)) {
		$candidate =~ s{^W/}{};
		$match ||= ($candidate eq '*') || ($candidate eq $mine);
	}

	return $match ? 1 : 0;
}

# Purpose:        Say that the representation depends on Accept-Encoding.
# Entry criteria: $headers is a Mojo::Headers.
# Exit status:    $headers.
# Side effects:   Appends Accept-Encoding to Vary unless already listed.
sub _add_vary :Private {
	my $headers = shift;

	my $listed = grep { lc(trim($_)) eq 'accept-encoding' } split(/,/, $headers->vary // '');
	$headers->append(Vary => 'Accept-Encoding') unless $listed;

	return $headers;
}

# Purpose:        Extract the media type from a Content-Type value.
# Entry criteria: Any value.
# Exit status:    The lower-cased type/subtype, or undef.
# Side effects:   None.
sub _mime_type :Private {
	my $content_type = shift;

	my ($type) = ($content_type // '') =~ m{^\s*([\w.+-]+/[\w.+-]+)};

	return defined($type) ? lc($type) : undef;
}

# Purpose:        Match a media type against a list of strings and regexes.
# Entry criteria: $type is lower-case; $patterns is an array reference.
# Exit status:    1 if any entry matches, else 0.
# Side effects:   None.
sub _matches :Private {
	my ($type, $patterns) = @_;

	my $found = 0;
	for my $pattern ((ref($patterns) eq 'ARRAY') ? @$patterns : ()) {
		$found ||= (ref($pattern) eq 'Regexp')
			? scalar($type =~ $pattern)
			: (defined($pattern) && (lc($pattern) eq $type));
	}

	return $found ? 1 : 0;
}

1;	# End of Mojolicious::Plugin::Buffer

=head1 DEPLOYMENT

=head2 Hypnotoad

L<hypnotoad> preloads the application before forking the workers, so the
plugin is registered once and every worker inherits the same cache object
and lock backend.  The cache storage, and the storage used by the lock
backend, must be shared and writable by the user that runs the workers.  The
example below uses L<CHI>, which must be installed in the application's
environment.

A complete application:

    package MyApp;
    use Mojo::Base 'Mojolicious';

    use CHI;

    sub startup {
	my $self = shift;

	$self->config(hypnotoad => {
	    listen   => ['http://*:8080'],
	    workers  => 4,
	    pid_file => '/var/lib/myapp/hypnotoad.pid',
	});

	$self->plugin('Buffer' => {
	    optimise_content => 1,
	    cache => CHI->new(
		driver    => 'File',
		root_dir  => '/var/cache/myapp/buffer',
		namespace => 'pages',
	    ),
	    cache_lock_dir => '/var/lib/myapp/buffer-locks',
	    cache_duration => '10 minutes',
	});

	$self->routes->get('/expensive' => sub {
	    my $c = shift;
	    return if $c->buffer_is_cached;

	    # ... expensive work ...

	    $c->render(template => 'expensive');
	});
    }

    1;

A runnable copy of this example, with its paths under C<examples/hypnotoad>,
is included as F<examples/hypnotoad>.

C<script/my_app> is the usual launcher:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    use MyApp;

    MyApp->new->start;

Create the directories as the deployment user and start the server:

    install -d -o www-data -g www-data -m 0750 /var/cache/myapp/buffer
    install -d -o www-data -g www-data -m 0750 /var/lib/myapp /var/lib/myapp/buffer-locks
    hypnotoad script/my_app

Replace C<www-data> with the unprivileged user that runs the workers; do not
run hypnotoad as root.  The plugin creates C<cache_lock_dir> if necessary,
but pre-creating it as the deployment user sets its ownership and
permissions.  The cache directory must be writable by that user too.  Use
C<hypnotoad -f script/my_app> in the foreground while testing, and
C<hypnotoad -s script/my_app> to stop it.

=head2 Cache and lock requirements

For workers on the same host, L<CHI>'s C<File> driver and the built-in file
lock backend work.  Do not use C<Memory>, and do not put a per-worker C<L1>
cache in front of the shared cache: a waiting worker would not see the entry
built by another worker and would eventually receive C<503 Service
Unavailable>.  A shared filesystem with reliable C<flock> can also be used
on several hosts.

=head2 Multiple hosts

Workers on different hosts need a shared cache and a lock backend that does
not rely on C<flock>.  This example uses CHI's Memcached driver for the cache
and L<Mojolicious::Plugin::Buffer::Lock::Redis> for the lock, with the
L<Redis> client:

    use CHI;
    use Mojolicious::Plugin::Buffer::Lock::Redis;
    use Redis;

    my $redis = sub {
	Redis->new(
	    server        => 'redis://redis.internal:6379',
	    cnx_timeout   => 1,
	    read_timeout  => 1,
	    write_timeout => 1,
	);
    };

    $app->plugin('Buffer' => {
	cache => CHI->new(
	    driver    => 'Memcached',
	    servers   => ['cache1.internal:11211', 'cache2.internal:11211'],
	    namespace => 'pages',
	),
	cache_lock => Mojolicious::Plugin::Buffer::Lock::Redis->new(
	    redis     => $redis,
	    namespace => 'myapp:buffer:',
	    ttl       => 60,
	),
	cache_duration => '10 minutes',
    });

The C<ttl> must be longer than L</cache_lock_timeout> and longer than the
slowest cached action.  If it expires while the builder is still working,
another worker can start building the same entry.  The Redis client is
called synchronously, so set short connect, read and write timeouts.  The
code reference is called once per worker, after the fork; a connection
created in C<startup> would be shared by every worker and must not be used.
CHI's Memcached driver needs L<Cache::Memcached::Fast>.

Only cache pages that are identical for every visitor.  The default key
includes the C<Cookie> header, not the contents of the session, so a page
that depends on the session needs L</cache_key> or a suitable L</vary_by>
list.  Entries are discarded when the application script or a template
changes, and otherwise expire after L</cache_duration>.

=head1 NOTES

=head2 Testing

The Redis lock backend has an optional live integration test.  It skips when
C<MPB_REDIS_URL> (or C<REDIS_SERVER>) is not set, or when neither L<Redis> nor
L<Redis::Fast> is installed.  Redis::Fast is used when it is the only client
available.  CI runs the test against a live Redis service with each client,
once with L<Redis> and once with only L<Redis::Fast> available (L<Redis>
hidden with L<Test::Without::Module>), and each run proves from the test
output which client it used, so both paths include the three-process crash
check described below rather than merely being wired up.  When either
variable is set, the test expects that server to be reachable; the value may
be a C<redis://> URL or a bare C<host:port>, so C<REDIS_SERVER> already in
the environment needs no rewriting:

    MPB_REDIS_URL=redis://127.0.0.1:6379 prove -Ilib t/76-live-redis.t
    REDIS_SERVER=127.0.0.1:6379 prove -Ilib t/76-live-redis.t

A server named by either variable must answer.  The variable says a live
Redis is there for this test, so an unreachable one fails the file, naming
the variable and the connection error, rather than skipping and looking like
a checkout with no Redis configured.  Unset both to skip the test.

That includes a three-process check of the crash path: a worker takes the
lock and is killed, another process stays blocked until the TTL expires,
takes the lock over, and a third process is blocked until that owner
releases it.  The crash test uses a two second lock TTL and waits for it to
run out rather than sleeping a fixed margin; set C<MPB_REDIS_TTL> to widen
that further on a heavily loaded machine.  The normal test suite does not
require a Redis server.

The private routines are guarded by L<Sub::Private> in C<enforce> mode and
L<Sub::Protected>.  Both stand aside while C<HARNESS_ACTIVE> is set, so the
white-box tests can reach them under C<prove>; F<t/16-encapsulation.t> turns
that bypass off to check the guards themselves.

=head2 Why a plugin?

L<CGI::Buffer> replaces C<STDOUT> with an in-memory buffer and does its work
in an C<END> block, and L<FCGI::Buffer> buffers each FastCGI request and does
its work in C<DESTROY>.  Neither trick is needed in Mojolicious: the response
already exists as an object before it is written, so the plugin can simply
hook C<after_dispatch> and rewrite it.  That gives the same effect without a
source filter, without reading C<$_>, and without depending on a specific
server or environment.

=head2 Interaction with the renderer

C<Mojolicious::Renderer> compresses rendered output with gzip by default
(C<compress> is on and C<min_compress_size> is 860 bytes).  That happens
before L<Mojolicious/"after_dispatch"> is emitted, which would leave this
plugin with nothing to optimise and no C<ETag> to generate on any page
larger than 860 bytes.  Registering this plugin therefore calls
C<< $app->renderer->compress(0) >>, and the plugin does the compression
instead - with gzip, Brotli or Zstandard as negotiated, and with the header
work the renderer does not do.  If you enable C<< $app->renderer->compress >>
after loading the plugin, those responses will be skipped by the plugin.

=head2 What is not implemented

C<save_to>, which rewrites dynamic pages into static ones, is a site
generation feature rather than a response filter and is not part of this
plugin.  The server-side cache is available as the opt-in
L</buffer_is_cached> helper described above.

=head1 COMMON PITFALLS

=head2 The C<buffer> stash: what each value means

=over 4

=item * C<< buffer =E<gt> 0 >> and C<< buffer =E<gt> '' >> turn the plugin
B<off> for this response.

=item * C<< buffer =E<gt> undef >> does B<not> turn it off.  undef means
"nothing set here", so the plugin options are used.

=item * C<< buffer =E<gt> {} >> keeps the plugin B<on> and changes nothing.

=back

=head2 The C<buffer> stash is merged one level deep only

The hash you put in the stash is laid over the plugin options one key at a
time.  A key you give replaces the whole plugin value for that key; nothing
inside it is merged.  So lists are replaced, not added to:

    plugin 'Buffer' => {encodings => [qw(br gzip)]};

    # This response may ONLY use br.  If Brotli is not installed, it is
    # not compressed at all, and an error is logged.
    $c->stash(buffer => {encodings => ['br']});

Values in the stash are not checked the way C<plugin()> options are, and
they are not filtered by which compression modules are installed.

=head2 undef in options

=over 4

=item * In the C<buffer> stash, an undef value is a real value.
C<< {compress_content =E<gt> undef} >> turns compression B<off> for that
response, and C<< {cache =E<gt> undef} >> turns the cache off.

=item * In a group declaration (a route default or C<buffer_NAME>
controller method), undef means "not declared", so the plugin option is
used.

=item * In C<plugin()> options, undef is accepted only where it means "use
the default" or "off":

    optimise_content and the true/false   off
      flags (compress_content,
      rewrite_links, generate_etag,
      generate_304, trust_last_modified,
      cache_single_flight)
    last_modified                         no Last-Modified header
    cache, cache_lock, cache_lock_dir,    not used
      template_mtime_cache
    cache_key                             the generated key
    cache_duration, cache_lock_timeout,   their default values
      template_mtime_cache_duration
    messages                              the built-in English texts

For C<encodings>, C<compressible_types>, C<excluded_types>, C<vary_by> and
C<min_compress_size>, undef is refused when the plugin is registered.  This
matters most for C<vary_by>: an undef there would have silently removed the
C<Cookie> header from the cache key.

=item * In C<messages>, undef does B<not> restore the built-in text.
C<< messages =E<gt> {retry_later =E<gt> undef} >> makes visitors see the
word C<retry_later>.  Leave the key out instead.  See
L<Mojolicious::Plugin::Buffer::I18N/COMMON PITFALLS>.

=back

=head2 Using the server-side cache safely

=over 4

=item * B<Check access before L</buffer_is_cached>.>  A cached page is sent
straight away and the rest of the action does not run.  Any login or
country check that comes later in the action is skipped on a hit.

=item * B<Personal pages need a personal key.>  C<< vary_by =E<gt> [] >>
makes the key the same for every visitor.  A page that shows a name, a
basket or anything else from the session is then shown to other visitors.
Keep the default C<['cookie']>, or set L</cache_key>.

=item * B<The cache must be shared by all workers.>  With several workers,
a per-worker cache such as CHI's C<Memory> driver means a waiting request
never sees the entry another worker built; after L</cache_lock_timeout>
it gets C<503 Service Unavailable>.

=item * B<Waiting requests get 503, not a second build.>  If the request
that is building a page fails, makes something that cannot be stored (for
example, it sets a cookie), or is slower than L</cache_lock_timeout>, the
requests waiting for it get C<503> with C<Retry-After: 1>.

=item * B<A Redis lock TTL must be longer than the slowest action>, or a
second worker starts building the same page.

=item * B<Template edits can be missed for a while> when
L</template_mtime_cache> is set: until its entry expires.

=back

=head2 Other pitfalls

=over 4

=item * B<Do not turn the renderer's compression back on.>  The plugin turns
off C<< $app->renderer->compress >>.  If you turn it on again, the renderer
compresses first, and the plugin then skips those responses: no
optimisation and no C<ETag>.

=item * B<Do not stream through the plugin.>  Responses written with
C<< $c->write >> are not buffered and are left alone.

=item * B<C<$c-E<gt>stash(buffer =E<gt> ...)> must be set before the action
ends.>  The plugin reads it in C<after_dispatch>.  To turn the cache off for
one request, set C<< {cache =E<gt> undef} >> I<before> calling
L</buffer_is_cached>.

=back

=head1 ENCODING

This section says which text may contain non-ASCII characters, such as
accented letters, other scripts and emoji.

=over 4

=item Response bodies

Any encoding works.  Pages rendered by Mojolicious are already UTF-8 bytes
when the plugin sees them.  A body that is still a Perl character string is
encoded to UTF-8 first.  Bodies in another character set, such as
ISO-8859-1 or Shift_JIS, are passed through unchanged; the plugin does not
convert them.

=item HTML optimisation

Safe for every UTF-8 character, including emoji.  The optimiser only
changes ASCII white space (space, tab, carriage return, line feed, form
feed) and ASCII markup.  A non-breaking space (U+00A0) is kept.

=item The C<ETag>

Made from the bytes of the body, so any content is fine.

=item Cache keys

A custom L</cache_key> may contain any characters, including emoji.  Keys
are encoded to UTF-8 before they are hashed for the lock backends.  The
generated key is an ASCII MD5 digest.  The cache itself receives a custom
key as it is; L<CHI>'s File and Memory drivers accept any characters, but
check this for other cache objects.

=item Request headers in L</vary_by>

Header I<names> are ASCII.  Header I<values> are used as raw bytes, so any
value is fine.

=item The C<503> text (C<retry_later>) and other messages

May contain any characters.  The C<503> body is sent as UTF-8 with
C<Content-Type: text/plain; charset=UTF-8>.  Log lines go through
L<Mojo::Log>, which writes them as UTF-8.

=item Error messages

The plugin's C<croak> messages are Perl character strings.  If you
translate them into a non-ASCII language and print them to C<STDERR>, give
C<STDERR> an encoding layer, or Perl warns "Wide character".

=item File paths (C<cache_lock_dir>)

Paths go to the operating system as bytes.  ASCII paths are always safe.
For a non-ASCII path, pass bytes that are already encoded the way your file
system expects, usually UTF-8.

=item Option names, encoding names and media types

These are ASCII words.

=back

=head1 LIMITATIONS

=over 4

=item * Only in-memory responses are processed.  Static files
(C<Mojo::Asset::File>) and streaming responses are left alone.

=item * The whole response is held in memory, more than once while it is
being optimised and compressed.  There is no size limit; a very large
generated body costs several times its size in a worker.

=item * Responses that already have a C<Content-Encoding>, for example from
C<$app-E<gt>renderer-E<gt>compress>, are not compressed again.

=item * Gzip, Brotli, Zstandard and identity representations have different
C<ETag>s, because the tag identifies the selected representation.  A client
that switches between content codings will therefore download the page once
for each coding.

=item * Because the body is buffered, the plugin must not be used for
responses that are streamed with C<$c-E<gt>write> (server-sent events,
long-polling and so on).  C<text/event-stream> is excluded by default.

=item * The HTML optimiser is a set of regular expressions inherited from
L<CGI::Buffer>, not an HTML parser.  It protects the content of
C<E<lt>preE<gt>>, C<E<lt>textareaE<gt>>, C<E<lt>scriptE<gt>> and
C<E<lt>styleE<gt>>, but white space made significant by CSS
(C<white-space: pre> on another element) is still collapsed, and some rules
(for example merging adjacent C<E<lt>centerE<gt>> blocks) change the
document slightly.  Use C<optimise_content =E<gt> 0> on pages where every
byte matters, or disable it per response with
C<$c-E<gt>stash(buffer =E<gt> {optimise_content =E<gt> 0})>.  Link rewriting
only recognises double-quoted attributes.

=item * The server-side cache is opt-in: a page is only stored if its action
calls L</buffer_is_cached>.  An action that forgets to call it is never
cached, and an action that calls it for a personalised page must supply a
L</cache_key> that distinguishes users (the default key only includes the
C<Cookie> header, not the session contents).

=item * The default key includes the C<Cookie> header, so each session gets
its own set of entries and anonymous visitors share them.  Sites that set an
analytics cookie on every visit will get little sharing; use
C<vary_by =E<gt> []> for genuinely public pages, or L</cache_key>.

=item * Single-flight is per worker by default.  Each C<hypnotoad> worker
keeps its own in-flight table, so a cold entry can be built once per worker;
set L</cache_lock> or L</cache_lock_dir> to coalesce across workers, with a
shared cache.  A request waiting on an in-flight response is answered with
C<503> if that response fails, cannot be cached, or exceeds
L</cache_lock_timeout>, rather than running the action a second time.  A
waiter in another worker polls the cache every 100 milliseconds, so it can
be answered up to that much later than the builder finishes.

=item * Entries are invalidated when the application script or a template
path changes, but not when data or configuration changes.  The TTL is the
backstop for those.

=item * Options in the C<buffer> stash and group declarations are not
validated the way C<plugin()> options are.  A bad C<cache_lock_timeout>
there falls back to the default; other bad values are used as given.

=item * The lock backend protocol returns two-element lists rather than
references.  That is the documented interface third-party backends already
implement, so it was kept.

=item * Every private routine is wrapped by L<Sub::Private> or
L<Sub::Protected>, which costs a C<caller> check on each call.  The plugin
makes a few hundred such calls per response, which is small next to MD5,
compression and template rendering, but it is not free.  The modules also
add L<Readonly>, L<Params::Validate::Strict> and their dependencies to what
was a Mojolicious-only plugin, and C<use autodie qw(:all)> requires
L<IPC::System::Simple> even though the plugin never runs an external
command.

=item * The C<503> text is chosen per application through L</messages>; it
is not negotiated from C<Accept-Language>.

=back

=head1 SEE ALSO

L<CGI::Buffer>, L<FCGI::Buffer>, L<CHI>, L<HTML::Packer>,
L<Mojolicious::Plugin>, L<Mojolicious::Plugin::Buffer::Lock::File>,
L<Mojolicious::Plugin::Buffer::Lock::Redis>,
L<Mojolicious::Plugin::Buffer::I18N>

=encoding utf8

=head1 FORMAL SPECIFICATION

This section describes the plugin in the Z notation, for readers who want
an exact model.  You do not need it to use the plugin.  C<now> is the
current time and C<mtime> is the newest modification time of the
application script and its templates.  C<Schema> maps each option name to
its L<Params::Validate::Strict> rule.

    [OPTION, VALUE, APP, KEY, Controller, Entry, Guard, Response]

    Known == dom Schema
    Valid == { o : Known; v : VALUE | v ∈ Schema(o) }

    Flight == [ waiters : ℙ Controller ; deadline : ℝ ; guard : Guard ∪ {⊥} ]

    ┌─ Plugin ────────────────────────────────────
    │ options : OPTION ⇸ VALUE
    │ inflight : KEY ⇸ Flight
    │ polling : Controller ⇸ (KEY × ℝ)
    │ lock : LockBackend ∪ {⊥}
    ├─────────────────────────────────────────────
    │ dom options = Known
    │ ∀ o : dom options • (o, options o) ∈ Valid
    │ ∀ k : dom inflight • (inflight k).deadline ≤ now + timeout
    └─────────────────────────────────────────────

    ┌─ Cache ─────────────────────────────────────
    │ store : KEY ⇸ Entry
    │ created : KEY ⇸ ℝ
    ├─────────────────────────────────────────────
    │ dom created = dom store
    └─────────────────────────────────────────────

    fresh : ℙ KEY
    fresh = { k : dom store | created k ≥ mtime }

=head2 register

    ┌─ Register ──────────────────────────────────
    │ ΔPlugin
    │ app? : APP ; conf? : OPTION ⇸ VALUE ; result! : Plugin
    ├─────────────────────────────────────────────
    │ dom conf? ⊆ Known
    │ ∀ o : dom conf? • (o, conf? o) ∈ Valid
    │ ∀ o : dom conf? • conf? o = ⊥ ⇒ undefAllowed(o)
    │ ¬(cache_lock ∈ dom conf? ∧ cache_lock_dir ∈ dom conf?)
    │ ran (conf? encodings) ⊆ {br, zstd, gzip, x-gzip}
    │ options′ = Defaults ⊕ conf?
    │ inflight′ = ∅ ∧ polling′ = ∅
    │ compress(renderer app?)′ = false
    │ after_dispatch ∈ hooks(app?)′ ∧ buffer_is_cached ∈ helpers(app?)′
    │ result! = θPlugin′
    └─────────────────────────────────────────────
    -- Any violated predicate: croak, and app? is unchanged

=head2 buffer_is_cached

C<cacheable(c)> holds when the plugin is on for this response, a cache is
configured, the method is C<GET> or C<HEAD>, and the request carries no
C<Authorization> header, no C<no-store>, C<no-cache>, C<private> or
C<max-age=0> directive, and C<NO_CACHE> and C<NO_STORE> are not set.
C<busy(k)> holds when the lock backend says another process holds C<k>.

    ┌─ BufferIsCached ────────────────────────────
    │ ΔPlugin ; ΔCache
    │ c? : Controller ; result! : 𝔹 ; response! : Response
    ├─────────────────────────────────────────────
    │ let k == key(c?) •
    │   ¬cacheable(c?) ⇒ result! = false
    │   cacheable(c?) ∧ k ∈ fresh ⇒
    │       response! = replay(store k) ∧ result! = true
    │   cacheable(c?) ∧ k ∉ fresh ⇒ store′ = {k} ⩤ store ∧ (
    │     ¬singleFlight ⇒ result! = false
    │     singleFlight ∧ k ∈ dom inflight ⇒
    │       (inflight′ k).waiters = (inflight k).waiters ∪ {c?}
    │       ∧ result! = true
    │     singleFlight ∧ k ∉ dom inflight ∧ busy(k) ⇒
    │       polling′ = polling ⊕ {c? ↦ (k, now + timeout)}
    │       ∧ result! = true
    │     singleFlight ∧ k ∉ dom inflight ∧ ¬busy(k) ⇒
    │       k ∈ dom inflight′ ∧ (inflight′ k).waiters = ∅
    │       ∧ result! = false )
    └─────────────────────────────────────────────

The building request finishes (the C<after_dispatch> hook), or its time
runs out.  C<e?> is the stored entry, or C<⊥> when the response could not be
stored or the build timed out.

    ┌─ FinishFlight ──────────────────────────────
    │ ΔPlugin
    │ k? : KEY ; e? : Entry ∪ {⊥}
    ├─────────────────────────────────────────────
    │ k? ∈ dom inflight
    │ ∀ w : (inflight k?).waiters •
    │     (e? ≠ ⊥ ⇒ response(w)′ = replay(e?))
    │   ∧ (e? = ⊥ ⇒ response(w)′ = 503)
    │ inflight′ = {k?} ⩤ inflight
    │ (inflight k?).guard ≠ ⊥ ⇒ released((inflight k?).guard)
    └─────────────────────────────────────────────

    ExpireFlight == [ FinishFlight | now ≥ (inflight k?).deadline ∧ e? = ⊥ ]

Every 0.1 seconds, each request waiting for another worker looks again:

    ┌─ PollTick ──────────────────────────────────
    │ ΔPlugin
    │ c? : dom polling
    ├─────────────────────────────────────────────
    │ let (k, d) == polling c? •
    │   k ∈ fresh ⇒ response(c?)′ = replay(store k)
    │                ∧ polling′ = {c?} ⩤ polling
    │   k ∉ fresh ∧ now ≥ d ⇒ response(c?)′ = 503
    │                ∧ polling′ = {c?} ⩤ polling
    │   k ∉ fresh ∧ now < d ∧ busy(k) ⇒ polling′ = polling
    │   k ∉ fresh ∧ now < d ∧ ¬busy(k) ⇒
    │       response(c?)′ = 503 ∧ polling′ = {c?} ⩤ polling
    └─────────────────────────────────────────────
    -- In the last case the lock is taken and the cache read once more
    -- before the 503, so an entry stored at that moment is still replayed

=head2 i18n

The same operation as L<Mojolicious::Plugin::Buffer::I18N/i18n>, where
C<overrides> is the L</messages> option.

=head1 STATE DIAGRAM

There are three pictures.  The numbers on the arrows are explained below
each picture.  In each explanation, the text in C<[ ]> is the condition and
the text after C</> is what happens.

=head2 A. One page in the server-side cache

This is the life of one cache key, seen by all workers together.

                 +---------------------+
                 |        EMPTY        |<-----------------------+
                 |  nothing is stored  |                        |
                 +---------------------+                        |
                   |        ^       ^                           |
                (1)|     (3)|    (4)|                           |
                   v        |       |                           |
                 +---------------------+      (5)               |
                 |      BUILDING       |-----------+            |
                 | one request builds; |           |            |
                 | others wait         |           v            |
                 +---------------------+    +--------------+    |
                   |                        |    CACHED    |    |
                (2)+----------------------->| fresh entry  |    |
                                            +--------------+    |
                                              |    ^      |     |
                                           (6)|    |(7)   |(8)  |
                                              v    |      v     |
                                            +--------------+    |
                                            |    STALE     |----+
                                            |  too old     | (9)
                                            +--------------+

    (1) a request calls buffer_is_cached  [no fresh entry, single-flight
        on, nobody else building]
        / X-Cache: MISS; this request becomes the builder; it takes the
          shared lock if one is configured; a timer of
          cache_lock_timeout starts
    (2) the builder's response is finished  [200, may be stored]
        / the uncompressed page is stored with cache_duration; every
          waiting request is answered from it; the lock is released
    (3) the builder's response is finished  [error, or not storable:
        it sets a cookie, is marked private or no-store, or varies on a
        header not in vary_by]
        / every waiting request gets 503 with Retry-After: 1; the lock
          is released
    (4) cache_lock_timeout passes before the builder finishes
        / waiting requests get 503; the lock is released.  If the
          builder finishes later and its page may be stored, it is still
          stored: that is arrow (5).
    (5) a late builder finishes  [200, may be stored]
        / the page is stored
    (6) the application script or a template file is changed
        / nothing happens yet; the entry is now older than the code
    (7) a request reads the entry  [it is fresh]
        / the stored page is replayed with X-Cache: HIT; it is
          compressed for this client and gets its own ETag
    (8) cache_duration passes
        / the cache forgets the entry
    (9) a request reads the entry  [it is older than the code]
        / the entry is removed; the request goes on as at (1)

    While BUILDING, a second request for the same key:
      - in the same worker: waits for (2), (3) or (4);
      - in another worker, with a shared lock: looks in the cache every
        0.1 seconds until the page appears, the lock is free, or
        cache_lock_timeout passes;
      - with cache_single_flight => 0: does not wait, and builds the page
        too.

=head2 B. One request that calls buffer_is_cached

                         buffer_is_cached
                                |
                                v
     +--------------+  (1)  +--------+  (5)  +-----------------+
     |  RUN ACTION  |<------| DECIDE |------>|     BUILDER     |
     |  not cached  |       +--------+       | the action runs;|
     +--------------+        |   |   |       | see picture C   |
                          (2)|   |   |(3)    +-----------------+
                             v   |   v
                      REPLAYED   |  +----------------+  (8)
                                 |  | WAITING_REMOTE |------> REPLAYED
                                 |  | polls the cache|  (9)
                                 |  | 10 times a sec |------> 503
                                 |  +----------------+
                                 |     |        ^
                              (4)|     +--(10)--+
                                 v
                        +----------------+  (6)
                        | WAITING_LOCAL  |------> REPLAYED
                        | same worker    |  (7)
                        +----------------+------> 503

    (1) [the plugin is off, no cache, method not GET or HEAD, an
        Authorization header, Cache-Control no-store, no-cache, private
        or max-age=0, NO_CACHE or NO_STORE set, or the cache's get() died]
        / returns false: the action runs normally
    (2) [a fresh entry exists]
        / status, headers and body are replayed; X-Cache: HIT; the
          response is finished; returns true
    (3) [no entry; another worker holds the shared lock]
        / render_later; X-Cache: MISS; returns true
    (4) [no entry; a request in this worker is building it]
        / render_later; X-Cache: MISS; returns true
    (5) [no entry; nobody is building it, or single-flight is off]
        / X-Cache: MISS; returns false.  If the lock backend failed, the
          error is logged and this worker builds without a shared lock.
    (6) the builder in this worker stored the page
        / the page is replayed with X-Cache: HIT
    (7) the builder failed, made something not storable, or
        cache_lock_timeout passed
        / 503 with Retry-After: 1 and the retry_later text
    (8) a poll finds the page in the cache
        / the page is replayed
    (9) a poll finds [cache_lock_timeout has passed], or [the lock is free
        but there is still no page], or [the lock backend failed]
        / 503 with Retry-After: 1
    (10) a poll finds [no page yet, and the lock is still held]
        / wait another 0.1 seconds

    Calling buffer_is_cached again in the same request returns the same
    answer and changes nothing.

=head2 C. What the after_dispatch hook does with every response

     response finished by the action
          |
          v
     +-----------------+  (1)
     | 1. CHECK        |-----------------------------------> sent as it is
     +-----------------+
          |
          v
     +-----------------+  [HTML and optimise_content on, and the result
     | 2. OPTIMISE     |   is smaller]  / white space removed, links
     +-----------------+   shortened.  Skipped for a replayed entry.
          |
          v
     +-----------------+  [compress_content on and type in
     | 3. COMPRESS     |   compressible_types] / Vary: Accept-Encoding;
     +-----------------+   then [client accepts a coding, body >=
          |                min_compress_size, result smaller]
          |                / body compressed, Content-Encoding set
          |
          v
     +-----------------+  [buffer_is_cached ran, it was not a hit, the
     | 4. STORE        |   status is 200, the response may be stored]
     +-----------------+   / the uncompressed page goes into the cache
          |
          v
     +-----------------+  (2)
     | 5. VALIDATE     |-----------------------------------> 304, no body
     +-----------------+
          |
          v
     +-----------------+
     | 6. SEND         |  the compressed or plain body; Content-Length
     +-----------------+
          |
          v
     if this request was the builder: answer every waiting request and
     release the shared lock (arrows (2) and (3) of picture A).  This
     also happens when a step above dies.

    (1) [the stash says buffer => 0, or the body is empty, streamed or a
        file, or the status is 1xx, 204, 206 or 304, or a
        Content-Encoding is already set, or the media type is unknown or
        in excluded_types]
    (2) [GET or HEAD, status 200, generate_304 on, and If-None-Match
        matches the ETag; or there is no ETag (or trust_last_modified is
        on) and If-Modified-Since is not older than Last-Modified]
        / 304 Not Modified is sent with no body

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
