package Plack::App::MCCS;

# ABSTRACT: Minify, Compress, Cache-control and Serve static files from Plack applications

our $VERSION = "1.000000";
$VERSION = eval $VERSION;

use strict;
use warnings;
use parent qw/Plack::Component/;

use autodie;
use Cwd ();
use Fcntl qw/:flock/;
use File::Spec::Unix;
use HTTP::Date;
use Module::Load::Conditional qw/can_load/;
use Plack::MIME;
use Plack::Util;

use Plack::Util::Accessor qw/root defaults types encoding _can_minify_css _can_minify_js _can_gzip min_cache_dir/;

=head1 NAME

Plack::App::MCCS - Minify, Compress, Cache-control and Serve static files from Plack applications

=head1 EXTENDS

L<Plack::Component>

=head1 SYNOPSIS

	# in your app.psgi:
	use Plack::Builder;
	use Plack::App::MCCS;

	my $app = sub { ... };

	# be happy with the defaults:
	builder {
		mount '/static' => Plack::App::MCCS->new(root => '/path/to/static_files')->to_app;
		mount '/' => $app;
	};

	# or tweak the app to suit your needs:
	builder {
		mount '/static' => Plack::App::MCCS->new(
			root => '/path/to/static_files',
			min_cache_dir => 'min_cache',
			defaults => {
				valid_for => 86400,
				cache_control => ['private'],
			},
			types => {
				'.htc' => {
					content_type => 'text/x-component',
					valid_for => 360,
					cache_control => ['no-cache', 'must-revalidate'],
				},
			},
		)->to_app;
		mount '/' => $app;
	};

	# or use the supplied middleware
	builder {
		enable 'Plack::Middleware::MCCS',
			path => qr{^/static/},
			root => '/path/to/static_files'; # all other options are supported
		$app;
	};

=head1 DESCRIPTION

C<Plack::App::MCCS> is a L<Plack> application that serves static files
from a directory. It will prefer serving precompressed versions of files
if they exist and the client supports it, and also prefer minified versions
of CSS/JS files if they exist.

If L<IO::Compress::Gzip> is installed, C<MCCS> will also automatically
compress files that do not have a precompressed version and save the compressed
versions to disk (so it only happens once and not on every request to the
same file).

If L<CSS::Minifier::XS> and/or L<JavaScript::Minifier::XS> are installed,
it will also automatically minify CSS/JS files that do not have a preminified
version and save them to disk (once again, will only happen once per file).

This means C<MCCS> needs to have write privileges to the static files directory.
It would be better if files are preminified and precompressed, say automatically
in your build process (if such a process exists). However, at some projects
where you don't have an automatic build process, it is not uncommon to
forget to minify/precompress. That's where automatic minification/compression
is useful.

Most importantly, C<MCCS> will generate proper Cache Control headers for
every file served, including C<Last-Modified>, C<Expires>, C<Cache-Control>
and even C<ETag> (ETags are created automatically, once per file, and saved
to disk for future requests). It will appropriately respond with C<304 Not Modified>
for requests with headers C<If-Modified-Since> or C<If-None-Match> when
these cache validations are fulfilled, without actually having to read the
files' contents again.

C<MCCS> is active by default, which means that if there are some things
you I<don't> want it to do, you have to I<tell> it not to. This is on purpose,
because doing these actions is the whole point of C<MCCS>.

=head2 WAIT, AREN'T THERE EXISTING PLACK MIDDLEWARES FOR THAT?

Yes and no. A similar functionality can be added to an application by using
the following Plack middlewares:

=over

=item * L<Plack::Middleware::Static> or L<Plack::App::File> - will serve static files

=item * L<Plack::Middleware::Static::Minifier> - will minify CSS/JS

=item * L<Plack::Middleware::Precompressed> - will serve precompressed .gz files

=item * L<Plack::Middleware::Deflater> - will compress representations with gzip/deflate algorithms

=item * L<Plack::Middleware::ETag> - will create ETags for files

=item * L<Plack::Middleware::ConditionalGET> - will handle C<If-None-Match> and C<If-Modified-Since>

=item * L<Plack::Middleware::Header> - will allow you to add cache control headers manually

=back

So why wouldn't I just use these middlewares? Here are my reasons:

=over

=item * C<Static::Minifier> will not minify to disk, but will minify on every
request, even to the same file (unless you provide it with a cache, which
is not that better). This pointlessly increases the load on the server.

=item * C<Precompressed> is nice, but it relies on appending C<.gz> to every
request and sending it to the app. If the app returns C<404 Not Found>, it sends the request again
without the C<.gz> part. This might pollute your logs and I guess two requests
to get one file is not better than one request. You can circumvent that with regex matching, but that
isn't very comfortable.

=item * C<Deflater> will not compress to disk, but do that on every request.
So once again, this is a big load on the server for no real reason. It also
has a long standing bug where deflate responses fail on Firefox, which is
annoying.

=item * C<ETag> will calculate the ETag again on every request.

=item * C<ConditionalGET> does not prevent the requested file to be opened
for reading even if C<304 Not Modified> is to be returned (since that check is performed later).
I'm not sure if it affects performance in anyway, probably not.

=item * No possible combination of any of the aformentioned middlewares
seems to return proper (and configurable) Cache Control headers, so you
need to do that manually, possibly with L<Plack::Middleware::Header>,
which is not just annoying if different file types have different cache
settings, but doesn't even seem to work.

=item * I don't really wanna use so many middlewares just for this functionality.

=back

C<Plack::App::MCCS> attempts to perform all of this faster and better. Read
the next section for more info.

=head2 HOW DOES MCCS HANDLE REQUESTS?

When a request is handed to C<Plack::App::MCCS>, the following process
is performed:

=over

=item 1. Discovery:

C<MCCS> will try to find the requested path in the root directory. If the
path is not found, C<404 Not Found> is returned. If the path exists but
is a directory, C<403 Forbidden> is returned (directory listings might be
supported in the future).

=item 2. Examination:

C<MCCS> will try to find the content type of the file, either by its extension
(relying on L<Plack::MIME> for that), or by a specific setting provided
to the app by the user (will take precedence). If not found (or file has
no extension), C<text/plain> is assumed (which means you should give your
files proper extensions if possible).

C<MCCS> will also determine for how long to allow browsers/proxy caches/whatever
caches to cache the file. By default, it will set a representation as valid
for 86400 seconds (i.e. one day). However, this can be changed in two ways:
either by setting a different default when creating an instance of the
application (see more info at the C<new()> method's documentation below),
or by setting a specific value for certain file types. Also, C<MCCS>
by default sets the C<public> option for the C<Cache-Control> header,
meaning caches are allowed to save responses even when authentication is
performed. You can change that the same way.

=item 3. Minification

If the content type is C<text/css> or C<application/javascript>, C<MCCS>
will try to find a preminified version of it on disk (directly, not with
a second request). If found, this version will be marked for serving.
If not found, and L<CSS::Minifier::XS> or L<JavaScript::Minifier:XS> are
installed, C<MCCS> will minify the file, save the minified version to disk,
and mark it as the version to serve. Future requests to the same file will
see the minified version and not minify again.

C<MCCS> searches for files that end with C<.min.css> and C<.min.js>, and
that's how it creates them too. So if a request comes to C<style.css>,
C<MCCS> will look for C<style.min.css>, possibly creating it if not found.
The request path remains the same (C<style.css>) though, even internally.
If a request comes to C<style.min.css> (which you don't really want when
using C<MCCS>), the app will not attempt to minify it again (so you won't
get things like C<style.min.min.css>).

If C<min_cache_dir> is specified, it will do all its searching and storing of
generated minified files within C<root>/C<$min_cache_dir> and ignore minified
files outside that directory.

=item 4. Compression

If the client supports gzip encoding (deflate to be added in the future, probably),
as noted with the C<Accept-Encoding> header, C<MCCS> will try to find a precompressed
version of the file on disk. If found, this version is marked for serving.
If not found, and L<IO::Compress::Gzip> is installed, C<MCCS> will compress
the file, save the gzipped version to disk, and mark it as the version to
serve. Future requests to the same file will see the compressed version and
not compress again.

C<MCCS> searches for files that end with C<.gz>, and that's how it creates
them too. So if a request comes to C<style.css> (and it was minified in
the previous step), C<MCCS> will look for C<style.min.css.gz>, possibly
creating it if not found. The request path remains the same (C<style.css>) though,
even internally.

=item 5. Cache Validation

If the client provided the C<If-Modified-Since> header, C<MCCS>
will determine if the file we're serving has been modified after the supplied
date, and return C<304 Not Modified> immediately if not.

Unless the file has the 'no-store' cache control option, and if the client
provided the C<If-None-Match> header, C<MCCS> will look for
a file that has the same name as the file we're going to serve, plus an
C<.etag> suffix, such as C<style.min.css.gz.etag> for example. If found,
the contents of this file is read and compared with the provided ETag. If
the two values are equal, C<MCCS> will immediately return C<304 Not Modified>.

=item 6. ETagging

If an C<.etag> file wasn't found in the previous step (and the file we're
serving doesn't have the 'no-store' cache control option), C<MCCS> will create
one from the file's inode, last modification date and size. Future requests
to the same file will see this ETag file, so it is not created again.

=item 7. Headers and Cache-Control

C<MCCS> now sets headers, especially cache control headers, as appropriate:

C<Content-Encoding> is set to C<gzip> if a compressed version is returned.

C<Content-Length> is set with the size of the file in bytes.

C<Content-Type> is set with the type of the file (if a text file, charset string is appended,
e.g. C<text/css; charset=UTF-8>).

C<Last-Modified> is set with the last modification date of the file in HTTP date format.

C<Expires> is set with the date in which the file will expire (determined in
stage 2), in HTTP date format.

C<Cache-Control> is set with the number of seconds the representation is valid for
(unless caching of the file is not allowed) and other options (determined in stage 2).

C<Etag> is set with the ETag value (if exists).

C<Vary> is set with C<Accept-Encoding>.

=item 8. Serving

The file handle is returned to the Plack handler/server for serving.

=back

=head2 HOW DO WEB CACHES WORK ANYWAY?

If you need more information on how caches work and cache control headers,
read L<this great article|http://www.mnot.net/cache_docs/>.

=head1 CLASS METHODS

=head2 new( %opts )

Creates a new instance of this module. C<%opts> I<must> have the following keys:

B<root> - the path to the root directory where static files reside.

C<%opts> I<may> have the following keys:

B<encoding> - the character set to append to content-type headers when text
files are returned. Defaults to UTF-8.

B<defaults> - a hash-ref with some global defaults, the following options
are supported:

=over

=item * B<valid_for>: the default number of seconds caches are allowed to save a response.

=item * B<cache_control>: takes an array-ref of options for the C<Cache-Control>
header (all except for C<max-age>, which is automatically calculated from
the resource's C<valid_for> setting).

=item * B<minify>: give this option a false value (0, empty string, C<undef>)
if you don't want C<MCCS> to automatically minify CSS/JS files (it will still
look for preminified versions though).

=item * B<compress>: like C<minify>, give this option a false value if
you don't want C<MCCS> to automatically compress files (it will still look
for precompressed versions).

=item * B<etag>: as above, give this option a false value if you don't want
C<MCCS> to automatically create and save ETags. Note that this will mean
C<MCCS> will NOT handle ETags at all (so if the client sends the C<If-None-Match>
header, C<MCCS> will ignore it).

=back

B<min_cache_dir> - For unminified files, by default minified files are generated
in the same directory as the original file. If this attribute is specified they
are instead generated within C<root>/C<$min_cache_dir>, and minified files
outside that directory are ignored, unless requested directly. This can make it
easier to filter out generated files when validating a deployment.

Giving C<minify>, C<compress> and C<etag> false values is useful during
development, when you don't want your project to be "polluted" with all
those .gz, .min and .etag files.

B<types> - a hash-ref with file extensions that may be served (keys must
begin with a dot, so give '.css' and not 'css'). Every extension takes
a hash-ref that might have B<valid_for> and B<cache_control> as with the
C<defaults> option, but also B<content_type> with the content type to return
for files with this extension (useful when L<Plack::MIME> doesn't know the
content type of a file).

If you don't want something to be cached, you need to give the B<valid_for>
option (either in C<defaults> or for a specific file type) a value of either
zero, or preferably any number lower than zero, which will cause C<MCCS>
to set an C<Expires> header way in the past. You should also pass the B<cache_control>
option C<no_store> and probably C<no_cache>. When C<MCCS> encounteres the
C<no_store> option, it does not automatically add the C<max-age> option
to the C<Cache-Control> header.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# should we allow minification of files?
	unless ($self->defaults && exists $self->defaults->{minify} && !$self->defaults->{minify}) {
		# are we able to minify JavaScript? first attempt to load JavaScript::Minifier::XS,
		# if unable try JavaScript::Minifier which is pure perl but slower
		if (can_load(modules => { 'JavaScript::Minifier::XS' => 0.09 })) {
			$self->{_can_minify_js} = 1;
		}

		# are we able to minify CSS? like before, try to load XS module first
		if (can_load(modules => { 'CSS::Minifier::XS' => 0.08 })) {
			$self->{_can_minify_css} = 1;
		}
	}

	# should we allow compression of files?
	unless ($self->defaults && exists $self->defaults->{compress} && !$self->defaults->{compress}) {
		# are we able to gzip responses?
		if (can_load(modules => { 'IO::Compress::Gzip' => undef })) {
			$self->{_can_gzip} = 1;
		}
	}

	return $self;
}

=head1 OBJECT METHODS

=head2 call( \%env )

L<Plack> automatically calls this method to handle a request. This is where
the magic (or disaster) happens.

=cut

sub call {
	my ($self, $env) = @_;

	# find the request file (or return error if occured)
	my $file = $self->_locate_file($env->{PATH_INFO});
	return $file if ref $file && ref $file eq 'ARRAY'; # error occured

	# determine the content type and extension of the file
	my ($content_type, $ext) = $self->_determine_content_type($file);

	# determine cache control for this extension
	my ($valid_for, $cache_control, $should_etag) = $self->_determine_cache_control($ext);

	undef $should_etag
		if $self->defaults && exists $self->defaults->{etag} && !$self->defaults->{etag};

	# if this is a CSS/JS file, see if a minified representation of
	# it exists, unless the file name already has .min.css/.min.js,
	# in which case we assume it's already minified
	if ($file !~ m/\.min\.(css|js)$/ && ($content_type eq 'text/css' || $content_type eq 'application/javascript')) {
		my $new = $file;
		$new =~ s/\.(css|js)$/.min.$1/;
		$new = $self->_filename_in_min_cache_dir($new) if $self->min_cache_dir;
		my $min = $self->_locate_file($new);

		my $try_to_minify; # initially undef
		if ($min && !ref $min) {
			# yes, we found it, but is it still fresh? let's see
			# when was the source file modified and compare them

			# $slm = source file last modified date
			my $slm = (stat(($self->_full_path($file))[0]))[9];
			# $mlm = minified file last modified date
			my $mlm = (stat(($self->_full_path($min))[0]))[9];

			# if source file is newer than minified version,
			# we need to remove the minified version and try
			# to minify again, otherwise we can simply set the
			# minified version is the version to serve
			if ($slm > $mlm) {
				unlink(($self->_full_path($min))[0]);
				$try_to_minify = 1;
			} else {
				$file = $min;
			}
		} else {
			# minified version does not exist, let's try to
			# minify ourselves
			$try_to_minify = 1;
		}

		if ($try_to_minify) {
			# can we minify ourselves?
			if (($content_type eq 'text/css' && $self->_can_minify_css) || ($content_type eq 'application/javascript' && $self->_can_minify_js)) {
				# open the original file
				my $orig = $self->_full_path($file);
				open(my $ifh, '<:raw', $orig)
					|| return $self->return_403;

				# add ->path attribute to the file handle
				Plack::Util::set_io_path($ifh, Cwd::realpath($orig));

				# read the file's contents into $css
				my $body; Plack::Util::foreach($ifh, sub { $body .= $_[0] });

				# minify contents
				my $min = $content_type eq 'text/css' ? CSS::Minifier::XS::minify($body) : JavaScript::Minifier::XS::minify($body);

				# save contents to another file
				if ($min) {
					my $out = $self->_full_path($new);
					open(my $ofh, '>:raw', $out);
					flock($ofh, LOCK_EX);
					if ($ofh) {
						print $ofh $min;
						close $ofh;
						$file = $new;
					}
				}
			}
		}
	}

	# search for a gzipped version of this file if the client supports gzip
	if ($env->{HTTP_ACCEPT_ENCODING} && $env->{HTTP_ACCEPT_ENCODING} =~ m/gzip/) {
		my $comp = $self->_locate_file($file.'.gz');
		my $try_to_compress;
		if ($comp && !ref $comp) {
			# good, we found a compressed version, but is it
			# still fresh? like before let's compare its modification
			# date with the current file marked for serving

			# $slm = source file last modified date
			my $slm = (stat(($self->_full_path($file))[0]))[9];
			# $clm = compressed file last modified date
			my $clm = (stat(($self->_full_path($comp))[0]))[9];

			# if source file is newer than compressed version,
			# we need to remove the compressed version and try
			# to compress again, otherwise we can simply set the
			# compressed version is the version to serve
			if ($slm > $clm) {
				unlink(($self->_full_path($comp))[0]);
				$try_to_compress = 1;
			} else {
				$file = $comp;
			}
		} else {
			# compressed version not found, so let's try to compress
			$try_to_compress = 1;
		}

		if ($try_to_compress && $self->_can_gzip) {
			# we need to create a gzipped version by ourselves
			my $orig = $self->_full_path($file);
			my $out = $self->_full_path($file.'.gz');
			if (IO::Compress::Gzip::gzip($orig, $out)) {
				$file .= '.gz';
			} else {
				warn "failed gzipping $file: $IO::Compress::Gzip::GzipError";
			}
		}
	}

	# okay, time to serve the file (or not, depending on whether cache
	# validations exist in the request and are fulfilled)
	return $self->_serve_file($env, $file, $content_type, $valid_for, $cache_control, $should_etag);
}

sub _locate_file {
	my ($self, $path) = @_;

	# does request have a sane path?
	$path ||= '';
	return $self->_bad_request_400
		if $path =~ m/\0/;

	my ($full, $path_arr) = $self->_full_path($path);

	# do not allow traveling up in the directory chain
	return $self->_forbidden_403
		if grep { $_ eq '..' } @$path_arr;

	if (-f $full) {
		# this is a file, is it readable?
		return -r $full ? $path : $self->_forbidden_403;
	} elsif (-d $full) {
		# this is a directory, we do not allow directory listing (yet)
		return $self->_forbidden_403;
	} else {
		# not found, return 404
		return $self->_not_found_404;
	}
}

sub _filename_in_min_cache_dir {
	my ($self, $file) = @_;
	my $min_cache_dir = File::Spec->catfile($self->root||".", $self->min_cache_dir);
	mkdir $min_cache_dir if !-d $min_cache_dir;
	$file =~ s@/@%2F@g;
	my $new = File::Spec::Unix->catfile($self->min_cache_dir, $file);
	return $new;
}

sub _determine_content_type {
	my ($self, $file) = @_;

	# determine extension of the file and see if application defines
	# a content type for this extension (will even override known types)
	my ($ext) = ($file =~ m/(\.[^.]+)$/);
	if ($ext && $self->types && $self->types->{$ext} && $self->types->{$ext}->{content_type}) {
		return ($self->types->{$ext}->{content_type}, $ext);
	}

	# okay, no specific mime defined, let's use Plack::MIME to find it
	# or fall back to text/plain
	return (Plack::MIME->mime_type($file) || 'text/plain', $ext)
}

sub _determine_cache_control {
	my ($self, $ext) = @_;

	# MCCS default values
	my $valid_for = 86400; # expire in 1 day by default
	my @cache_control = ('public'); # allow authenticated caching by default

	# user provided default values
	$valid_for = $self->defaults->{valid_for}
		if $self->defaults && defined $self->defaults->{valid_for};
	@cache_control = @{$self->defaults->{cache_control}}
		if $self->defaults && defined $self->defaults->{cache_control};

	# user provided extension specific settings
	if ($ext) {
		$valid_for = $self->types->{$ext}->{valid_for}
			if $self->types && $self->types->{$ext} && defined $self->types->{$ext}->{valid_for};
		@cache_control = @{$self->types->{$ext}->{cache_control}}
			if $self->types && $self->types->{$ext} && defined $self->types->{$ext}->{cache_control};
	}

	# unless cache control has no-store, prepend max-age to it
	my $cache = scalar(grep { $_ eq 'no-store' } @cache_control) ? 0 : 1;
	unshift(@cache_control, 'max-age='.$valid_for)
		if $cache;

	return ($valid_for, \@cache_control, $cache);
}

sub _serve_file {
	my ($self, $env, $path, $content_type, $valid_for, $cache_control, $should_etag) = @_;

	# if we are serving a text file (including JSON/XML/JavaScript), append character
	# set to the content type
	$content_type .= '; charset=' . ($self->encoding || 'UTF-8')
		if $content_type =~ m!^(text/|application/(json|xml|javascript))!;

	# get the full path of the file
	my $file = $self->_full_path($path);

	# get file statistics
	my @stat = stat $file;

	# try to find the file's etag, unless no-store is on so we don't
	# care about it
	my $etag;
	if ($should_etag) {
		if (-f "${file}.etag" && -r "${file}.etag") {
			# we've found an etag file, and we can read it, but is it
			# still fresh? let's make sure its last modified date is
			# later than that of the file itself
			if ($stat[9] > (stat("${file}.etag"))[9]) {
				# etag is stale, try to delete it
				unlink "${file}.etag";
			} else {
				# read the etag file
				if (open(ETag, '<', "${file}.etag")) {
					flock(ETag, LOCK_SH);
					$etag = <ETag>;
					chomp($etag);
					close ETag;
				} else {
					warn "Can't open ${file}.etag for reading";
				}
			}
		} elsif (-f "${file}.etag") {
			warn "Can't open ${file}.etag for reading";
		}
	}

	# did the client send cache validations?
	if ($env->{HTTP_IF_MODIFIED_SINCE}) {
		# okay, client wants to see if resource was modified

		# IE sends wrong formatted value (i.e. "Thu, 03 Dec 2009 01:46:32 GMT; length=17936")
		# - taken from Plack::Middleware::ConditionalGET
		$env->{HTTP_IF_MODIFIED_SINCE} =~ s/;.*$//;
		my $since = HTTP::Date::str2time($env->{HTTP_IF_MODIFIED_SINCE});

		# if file was modified on or before $since, return 304 Not Modified
		return $self->_not_modified_304
			if $stat[9] <= $since;
	}
	if ($etag && $env->{HTTP_IF_NONE_MATCH} && $etag eq $env->{HTTP_IF_NONE_MATCH}) {
		return $self->_not_modified_304;
	}

	# okay, we need to serve the file
	# open it first
	open my $fh, '<:raw', $file
		|| return $self->return_403;

	# add ->path attribute to the file handle
	Plack::Util::set_io_path($fh, Cwd::realpath($file));

	# did we find an ETag file earlier? if not, let's create one (unless
	# we shouldn't due to no-store)
	if ($should_etag && !$etag) {
		# following code based on Plack::Middleware::ETag by Franck Cuny
		# P::M::ETag creates weak ETag if it sees the resource was
		# modified less than a second before the request. It seems
		# like it does that because there's a good chance the resource
		# will be modified again soon afterwards. I'm not gonna do
		# that because if MCCS minified/compressed by itself, it will
		# pretty much always mean the ETag will be created less than a
		# second after the file was modified, and I know it's not gonna
		# be modified again soon, so I see no reason to do that here

		# add inode to etag
		$etag .= join('-', sprintf("%x", $stat[2]), sprintf("%x", $stat[9]), sprintf("%x", $stat[7]));

		# save etag to a file
		if (open(ETag, '>', "${file}.etag")) {
			flock(ETag, LOCK_EX);
			print ETag $etag;
			close ETag;
		} else {
			undef $etag;
			warn "Can't open ETag file ${file}.etag for writing";
		}
	}

	# set response headers
	my $headers = [];
	push(@$headers, 'Content-Encoding' => 'gzip') if $path =~ m/\.gz$/;
	push(@$headers, 'Content-Length' => $stat[7]);
	push(@$headers, 'Content-Type' => $content_type);
	push(@$headers, 'Last-Modified' => HTTP::Date::time2str($stat[9]));
	push(@$headers, 'Expires' => $valid_for >= 0 ? HTTP::Date::time2str($stat[9]+$valid_for) : HTTP::Date::time2str(0));
	push(@$headers, 'Cache-Control' => join(', ', @$cache_control));
	push(@$headers, 'ETag' => $etag) if $etag;
	push(@$headers, 'Vary' => 'Accept-Encoding');

	# respond
	return [200, $headers, $fh];
}

sub _full_path {
	my ($self, $path) = @_;

	my $docroot = $self->root || '.';

	# break path into chain
	my @path = split('/', $path);
	if (@path) {
		shift @path if $path[0] eq '';
	} else {
		@path = ('.');
	}

	my $full = File::Spec::Unix->catfile($docroot, @path);
	return wantarray ? ($full, \@path) : $full;
}

sub _not_modified_304 {
	[304, [], []];
}

sub _bad_request_400 {
	[400, ['Content-Type' => 'text/plain', 'Content-Length' => 11], ['Bad Request']];
}

sub _forbidden_403 {
	[403, ['Content-Type' => 'text/plain', 'Content-Length' => 9], ['Forbidden']];
}

sub _not_found_404 {
	[404, ['Content-Type' => 'text/plain', 'Content-Length' => 9], ['Not Found']];
}

=head1 CAVEATS AND THINGS TO CONSIDER

=over

=item * You can't tell C<MCCS> to not minify/compress a specific file
type yet but only disable minification/compression altogether (in the
C<defaults> setting for the C<new()> method).

=item * Directory listings are not supported yet (not sure if they will be).

=item * Deflate compression is not supported yet (just gzip).

=item * Caching middlewares such as L<Plack::Middleware::Cache> and L<Plack::Middleware::Cached>
don't rely on Cache-Control headers (or so I understand) for
their expiration values, which makes them less useful for applications that
rely on C<MCCS>. You'll probably be better off with an external cache
like L<Varnish|https://www.varnish-cache.org/> if you want a cache on your application server. Even without
a server cache, your application should still appear faster for users due to
browser caching (and also server load should be decreased).

=item * C<Range> requests are not supported. See L<Plack::App::File::Range> if you need that.

=item * The app is mounted on a directory and can't be set to only serve
requests that match a certain regex. Use the L<middleware|Plack::Middleware::MCCS> for that.

=back

=head1 DIAGNOSTICS

This module doesn't throw any exceptions, instead returning HTTP errors
for the client and possibly issuing some C<warn>s. The following list should
help you to determine some potential problems with C<MCCS>:

=over

=item C<< "failed gzipping %s: %s" >>

This warning is issued when L<IO::Compress::Gzip> fails to gzip a file.
When it happens, C<MCCS> will simply not return a gzipped representation.

=item C<< "Can't open ETag file %s.etag for reading" >>

This warning is issued when C<MCCS> can't read an ETag file, probably because
it does not have enough permissions. The request will still be fulfilled,
but it won't have the C<ETag> header.

=item C<< "Can't open ETag file %s.etag for writing" >>

Same as before, but when C<MCCS> can't write an ETag file.

=item C<403 Forbidden> is returned for files that exist

If a request for a certain file results in a C<403 Forbidden> error, it
probably means C<MCCS> has no read permissions for that file.

=back

=head1 CONFIGURATION AND ENVIRONMENT

C<Plack::App::MCCS> requires no configuration files or environment variables.

=head1 DEPENDENCIES

C<Plack::App::MCCS> B<depends> on the following CPAN modules:

=over

=item * L<parent>

=item * L<Cwd>

=item * L<Fcntl>

=item * L<File::Spec::Unix>

=item * L<Getopt::Long>

=item * L<HTTP::Date>

=item * L<Module::Load::Conditional>

=item * L<Plack> (obviously)

=back

C<Plack::App::MCCS> will use the following modules if they exist, in order
to minify/compress files (if they are not installed, C<MCCS> will not be
able to minify/compress on its own):

=over

=item * L<CSS::Minifier::XS>

=item * L<JavaScript::Minifier::XS>

=item * L<IO::Compress::Gzip>

=back

=head1 INCOMPATIBILITIES WITH OTHER MODULES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Plack-App-MCCS@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-App-MCCS>.

=head1 SEE ALSO

L<Plack::Middleware::MCCS>, L<Plack::Middleware::Static>, L<Plack::App::File>, L<Plack::Builder>.

=head1 AUTHOR

Ido Perlmuter <ido@ido50.net>

=head1 ACKNOWLEDGMENTS

Some of this module's code is based on L<Plack::App::File> by Tatsuhiko Miyagawa
and L<Plack::Middleware::ETag> by Franck Cuny.

Christian Walde contributed new features and fixes for the 1.0.0 release.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2016, Ido Perlmuter C<< ido@ido50.net >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic>
and L<perlgpl|perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
__END__
