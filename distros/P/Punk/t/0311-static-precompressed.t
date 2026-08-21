#!perl
use 5.010;
use strict;
use warnings;
use File::Temp ();
use File::Spec ();
use Test::More;
use Punk ();

# Precompressed siblings (punk_sendfile.h, ps_serve_file). If style.css.gz
# sits next to style.css and the client accepts gzip, the sibling's BYTES are
# served under the original's IDENTITY - its Content-Type, its URL, its own
# cache entry. Nothing is compressed at request time, so this needs no zlib
# and costs one stat.

my $dir = File::Temp->newdir;
my $root = "$dir";

sub w {
    my ($name, $bytes, $mtime) = @_;
    my $p = File::Spec->catfile($root, $name);
    open my $fh, '>', $p or die "$p: $!";
    binmode $fh;
    print $fh $bytes;
    close $fh;
    utime $mtime, $mtime, $p if $mtime;
    return $p;
}

my $NOW = time;
# The identity file is the big one; the "compressed" siblings are just
# shorter distinct bytes - this tests file SELECTION, not any codec.
w('style.css',    'body { color: red }' x 100, $NOW - 100);
w('style.css.gz', 'PRETEND-GZIP-BYTES',        $NOW);
w('style.css.br', 'PRETEND-BR',                $NOW);
w('plain.txt',    'no siblings here',          $NOW);
# a sibling OLDER than its source: a stale build artefact
w('stale.js',     'console.log(1)' x 50,       $NOW);
w('stale.js.gz',  'OLD-GZIP',                  $NOW - 3600);

my $app = do {
    package Assets;
    use Punk;
    static '/s' => $root;
    __PACKAGE__->to_app;
};

sub req {
    my ($path, $ae, %extra) = @_;
    open my $in, '<', \'';
    my $env = {
        REQUEST_METHOD => 'GET',
        PATH_INFO      => $path,
        QUERY_STRING   => '',
        SERVER_NAME    => 'localhost', SERVER_PORT => 80,
        HTTP_HOST      => 'localhost', 'psgi.url_scheme' => 'http',
        'psgi.input'   => $in,
        %extra,
    };
    $env->{HTTP_ACCEPT_ENCODING} = $ae if defined $ae;
    my $res = $app->($env);
    my %h = @{ $res->[1] };
    my $body = ref $res->[2] eq 'ARRAY' ? join('', @{ $res->[2] })
             : do { my $g = $res->[2]; local $/; my $b = <$g>; close $g; $b // '' };
    return ($res->[0], \%h, $body);
}

# ---- the identity response -------------------------------------------------

{
    my ($st, $h, $b) = req('/s/style.css', undef);
    is $st, 200, 'no Accept-Encoding: the plain file';
    ok !exists $h->{'Content-Encoding'}, '...with no Content-Encoding';
    is $b, 'body { color: red }' x 100, '...and the identity bytes';

    # Vary must be present even here. A shared cache that stored these bytes
    # without it would hand them to a client that asked for gzip.
    is $h->{Vary}, 'Accept-Encoding',
       'Vary is on the identity response too, not just the compressed one';
}

# ---- the sibling -----------------------------------------------------------

{
    my ($st, $h, $b) = req('/s/style.css', 'gzip');
    is $st, 200, 'a gzip client gets 200';
    is $h->{'Content-Encoding'}, 'gzip', '...tagged gzip';
    is $b, 'PRETEND-GZIP-BYTES', '...with the sibling bytes';
    is $h->{'Content-Length'}, length('PRETEND-GZIP-BYTES'),
       '...and the sibling length';

    # The Content-Type must come from the ORIGINAL path: ps_content_type must
    # never see the .gz suffix, or every compressed asset ships as
    # application/octet-stream and a browser refuses to apply it.
    like $h->{'Content-Type'}, qr{^text/css},
       'the Content-Type is the original file type, not the sibling suffix';
    is $h->{Vary}, 'Accept-Encoding', '...Vary present';
}

# ---- ETags separate the two representations --------------------------------

{
    my (undef, $plain) = req('/s/style.css', undef);
    my (undef, $gz)    = req('/s/style.css', 'gzip');
    isnt $plain->{ETag}, $gz->{ETag},
       'the identity and gzip representations have different ETags';
    like $gz->{ETag}, qr/-gzip"$/,
       'the compressed ETag is tagged with its encoding';
    unlike $plain->{ETag}, qr/-gzip/, 'the identity ETag is not';
}

# ---- brotli is preferred when both are offered and both exist --------------

{
    my (undef, $h, $b) = req('/s/style.css', 'br, gzip');
    is $h->{'Content-Encoding'}, 'br',
       'br wins over gzip when the client offers both';
    is $b, 'PRETEND-BR', '...serving the .br file';
    like $h->{ETag}, qr/-br"$/, '...with a br-tagged ETag';
}
{
    my (undef, $h) = req('/s/style.css', 'gzip');
    is $h->{'Content-Encoding'}, 'gzip',
       'gzip alone still selects the .gz sibling';
}

# ---- Accept-Encoding parsing ------------------------------------------------

{
    my (undef, $h) = req('/s/style.css', 'gzip;q=0');
    ok !exists $h->{'Content-Encoding'},
       'q=0 is an explicit refusal, not a weak preference';

    (undef, $h) = req('/s/style.css', 'gzip;q=0.0');
    ok !exists $h->{'Content-Encoding'}, 'q=0.0 likewise';

    (undef, $h) = req('/s/style.css', 'gzip;q=0.001');
    is $h->{'Content-Encoding'}, 'gzip', 'a small but nonzero q still accepts';

    (undef, $h) = req('/s/style.css', 'deflate');
    ok !exists $h->{'Content-Encoding'},
       'an encoding we have no sibling for is ignored';

    (undef, $h) = req('/s/style.css', '*');
    ok exists $h->{'Content-Encoding'}, 'a wildcard accepts';

    (undef, $h) = req('/s/style.css', 'identity');
    ok !exists $h->{'Content-Encoding'}, 'identity takes the plain file';

    (undef, $h) = req('/s/style.css', '');
    ok !exists $h->{'Content-Encoding'}, 'an empty header takes the plain file';

    (undef, $h) = req('/s/style.css', 'gzip, br');
    is $h->{'Content-Encoding'}, 'br',
       'preference is ours, not the order the client listed';
}

# ---- no sibling ------------------------------------------------------------

{
    my ($st, $h, $b) = req('/s/plain.txt', 'gzip');
    is $st, 200, 'a file with no sibling still serves';
    ok !exists $h->{'Content-Encoding'}, '...uncompressed';
    is $b, 'no siblings here', '...with its own bytes';
    is $h->{Vary}, 'Accept-Encoding', '...and Vary regardless';
}

# ---- the stale sibling -----------------------------------------------------

# A .gz older than its source is a build artefact nobody regenerated.
# Serving it would ship last week's asset forever, silently.
{
    my ($st, $h, $b) = req('/s/stale.js', 'gzip');
    is $st, 200, 'a stale sibling still gives a 200';
    ok !exists $h->{'Content-Encoding'},
       'a sibling older than its source is ignored, not served stale';
    is $b, 'console.log(1)' x 50, '...the current identity bytes are served';
}

# ---- conditional requests over the compressed representation ---------------

{
    my (undef, $h) = req('/s/style.css', 'gzip');
    my ($st) = req('/s/style.css', 'gzip', HTTP_IF_NONE_MATCH => $h->{ETag});
    is $st, 304, 'If-None-Match on the compressed ETag gives 304';

    # The identity ETag must NOT satisfy a gzip request: they are different
    # representations and a 304 here would leave the client with the wrong
    # bytes in cache.
    my (undef, $plain) = req('/s/style.css', undef);
    my ($st2) = req('/s/style.css', 'gzip', HTTP_IF_NONE_MATCH => $plain->{ETag});
    is $st2, 200,
       'the identity ETag does not satisfy a gzip request';
}

done_testing;
