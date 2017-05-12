use Test::More;
use Test::Mojo;
use MojoX::DirectoryListing;
use File::Copy;
require t::app1::Server7;
use strict;
use warnings;

diag 'building test filesystem';
mkdir 't/app1/public';
mkdir 't/app1/public/dir1';
mkdir 't/app1/public/dir2';

my $s71 = t::app1::Server7->new;
t::app1::Server7::serve_dir($s71, '/');
t::app1::Server7::serve_dir($s71, '/dir1',
			    header => "<h1>this is a header</h1>",
			    footer => "<h2>this is a footer</h2>");

t::app1::Server7::serve_dir($s71, '/dir2', 
			    header => "<h1>header for __DIR__</h1>",
			    footer => "<h1>__DIR__ footer for __DIR__</h1>");

my $t71 = Test::Mojo->new($s71);
$t71->get_ok('/test')->status_is(200)->content_is('Server7','Server7 active');
$t71->get_ok('/')->status_is(200)
    ->content_like( qr{Index of /}, 'default header' )
    ->content_unlike( qr/this is a header/ )
    ->content_unlike( qr/this is a footer/ )
    ->content_unlike( qr{header for /} )
    ->content_unlike( qr{/ footer for /} );
$t71->get_ok('/dir1')->status_is(200)
    ->content_unlike( qr{Index of /} )
    ->content_like( qr/this is a header/, 'user-specified header' )
    ->content_like( qr/this is a footer/, 'user-specified footer' )
    ->content_like( qr/this is a header.*this is a footer/s,
		    'header appears before footer' )
    ->content_unlike( qr{header for /dir1} )
    ->content_unlike( qr{/dir1 footer for /dir1} );
$t71->get_ok('/dir2')->status_is(200)
    ->content_unlike( qr{Index of /} )
    ->content_unlike( qr/this is a header/ )
    ->content_unlike( qr/this is a footer/ )
    ->content_like( qr{header for /dir2},
		    'user specified header with path name')
    ->content_like( qr{/dir2 footer for /dir2},
		    'user specified header with path name' );

END {
    diag 'tearing down test filesystem';
    unlink glob("t/app1/public/*");
    rmdir "t/app1/public/dir2";
    rmdir "t/app1/public/dir1";
    rmdir "t/app1/public";
}

done_testing();
