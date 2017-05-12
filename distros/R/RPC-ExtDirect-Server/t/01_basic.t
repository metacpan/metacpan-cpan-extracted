# Test serving static content

use strict;
use warnings;

use Test::More tests => 13;

use lib 't/lib';
use RPC::ExtDirect::Server::Util;
use RPC::ExtDirect::Server::Test::Util;

my $have_libmagic = do { local $@; eval "require File::LibMagic" };

my $static_dir = 't/htdocs';

my ($host, $port) = maybe_start_server(static_dir => $static_dir);

ok $port, "Got host: $host and port: $port";

# Should be a redirect from directory to index.html
my $resp = get "http://$host:$port/dir";

is_status $resp, 301, 'Got 301';

# These are optional for when HTTP::Date is installed
SKIP: {
    eval "require HTTP::Date";

    skip "HTTP::Date not installed", 3 if $@;

    my $mtime = (stat "$static_dir/foo.txt")[9];

    $resp = get "http://$host:$port/foo.txt", {
        headers => {
            'If-Modified-Since' => HTTP::Date::time2str($mtime + 1),
        },
    };

    is_status $resp, 304, 'Got 304 for If-Modified-Since > mtime';

    $resp = get "http://$host:$port/foo.txt", {
        headers => {
            'If-Modified-Since' => HTTP::Date::time2str($mtime - 1),
        },
    };

    is_status $resp, 200, 'Got 200 for If-Modified-Since < mtime';
    is_content $resp, "foo\n", 'Got content for If-Modified-Since < mtime';
}

# Should get 403
$resp = get "http://$host:$port/../../etc/passwd";

is_status $resp, 403, 'Got 403';

# Should get 404
$resp = get "http://$host:$port/nonexisting/stuff";

is_status $resp, 404, 'Got 404';

# Get a (seemingly) non-text file
my $want_len = (stat "$static_dir/bar.png")[7];

$resp = get "http://$host:$port/bar.png";

is_status    $resp, 200,                           'Img got status';
like_content $resp, qr/foo/,                       'Img got content';

# File::LibMagic looks beyond file extension and detects correct MIME type
if ( $have_libmagic ) {
    like_header $resp, 'Content-Type', qr{text/plain}, 'Img got content type';
}
else {
    is_header $resp, 'Content-Type', 'image/png', 'Img got content type';
}

is_header    $resp, 'Content-Length', $want_len,   'Img got content length';

# Now get text file and check the type
$resp = get "http://$host:$port/foo.txt";

is_status   $resp, 200,                              'Text got status';
like_header $resp, 'Content-Type', qr/^text\/plain/, 'Text got content type';

