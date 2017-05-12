use strict;
use warnings;

use lib "lib";

use Test::More;
use Plack::Builder;
use Plack::Test;
use File::Spec;

use Plack::App::File;
use Plack::Middleware::DirIndex;
use Plack::Middleware::ErrorDocument;

BEGIN {
    use lib "t";
    require_ok "app_tests.pl";
}

my $root = File::Spec->catdir( "t", "root" );

my $app = Plack::App::File->new( { root => $root } )->to_app;
$app = Plack::Middleware::DirIndex->wrap($app);
$app
    = Plack::Middleware::ErrorDocument->wrap( $app, 404 => "$root/404.html" );

app_tests
    app   => $app,
    tests => [
    {   name    => 'Basic request',
        request => [ GET => '/index.html' ],
        content => 'Index',
        headers => { 'Content-Type' => 'text/html; charset=utf-8', },
    },
    {   name    => 'Index request',
        request => [ GET => '/' ],
        content => 'Index',
        headers => { 'Content-Type' => 'text/html; charset=utf-8', },
    },
    {   name    => 'Dir with no index file',
        request => [ GET => '/other/' ],
        content => '404 page',
        headers => { 'Content-Type' => 'text/html', },
    },
    ];

# Now test setting up alternative index (alt.html) file, not default
my $app2 = Plack::App::File->new( { root => $root } )->to_app;
$app2 = Plack::Middleware::DirIndex->wrap( $app2, dir_index => 'alt.html' );
$app2 = Plack::Middleware::ErrorDocument->wrap( $app2,
    404 => "$root/404.html" );

app_tests
    app   => $app2,
    tests => [
    {   name    => 'Dir with no matching index file (now)',
        request => [ GET => '/' ],
        content => '404 page',
        headers => { 'Content-Type' => 'text/html', },
    },
    {   name    => 'Basic request for alternative index file',
        request => [ GET => '/other/' ],
        content => 'Alt Index',
        headers => { 'Content-Type' => 'text/html; charset=utf-8', },
    },
    ];

done_testing;
