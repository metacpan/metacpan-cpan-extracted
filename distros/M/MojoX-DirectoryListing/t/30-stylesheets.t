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
mkdir 't/app1/public/dir3';

open my $fh_CSS1, '>', 't/app1/public/style1.css';
print $fh_CSS1 "\n";
close $fh_CSS1;

my $s71 = t::app1::Server7->new;
t::app1::Server7::serve_dir($s71, '/');
t::app1::Server7::serve_dir($s71, '/dir1', 
			    stylesheet => '/style1.css');
t::app1::Server7::serve_dir($s71, '/dir2', 
			    stylesheet => 'http://static.otherdomain.com/style1.css');
t::app1::Server7::serve_dir($s71, '/dir3', 
			    stylesheet => \qq[
body.directory-listing {
  font-family: "Lucida Grande", tahoma, sans-serif;
  font-size: 100%; margin: 0; width: 100%;
}
h1.directory-listing {
  background: #999;
  background: -webkit-gradient(linear, left top, left bottom, from(#E5A2C6), to(#2B6699));
  background: -moz-linear-gradient(top,  #E5A2C6,  #2B6699);
  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#E5A2C6', endColorstr='#2B6699');
  padding: 10px 0 10px 10px; margin: 0; color: white;
}
a.directory-listing-link   { color: #5C8DB8; }
hr.directory-listing       { border: solid silver 1px; width: 95%; }
.directory-listing-row, .directory-listing-header { font-family: Courier }
.directory-listing-name    { font-weight: bold; color: #346D9E; }
			    ] );

my $t71 = Test::Mojo->new($s71);
$t71->get_ok('/test')->status_is(200)->content_is('Server7','Server7 active');
$t71->get_ok('/')->status_is(200)
    ->content_like( qr/#A2C6E5/, 'can use default stylesheet' )
    ->content_unlike( qr|<link rel="stylesheet" href="/style1.css"| )
    ->content_unlike( qr|<link rel="stylesheet" href="http:| )
    ->content_unlike( qr/#E5A2C6/ );
$t71->get_ok('/dir1')->status_is(200)
    ->content_unlike( qr/#A2C6E5/ )
    ->content_like( qr|<link rel="stylesheet" href="/style1.css"|,
    		    'can use local URL for stylesheet' )
    ->content_unlike( qr|<link rel="stylesheet" href="http:| )
    ->content_unlike( qr/#E5A2C6/ );
$t71->get_ok('/dir2')->status_is(200)
    ->content_unlike( qr/#A2C6E5/ )
    ->content_unlike( qr|<link rel="stylesheet" href="/style1.css"| )
    ->content_like( qr|<link rel="stylesheet" href="http:|,
		    'can use foreign URL for stylesheet' )
    ->content_unlike( qr/#E5A2C6/ );
$t71->get_ok('/dir3')->status_is(200)
    ->content_unlike( qr/#A2C6E5/ )
    ->content_unlike( qr|<link rel="stylesheet" href="/style1.css"| )
    ->content_unlike( qr|<link rel="stylesheet" href="http:| )
    ->content_like( qr/#E5A2C6/,
    		    'can override style with string' );

END {
    diag 'tearing down test filesystem';
    unlink glob("t/app1/public/*");
    rmdir "t/app1/public/dir3";
    rmdir "t/app1/public/dir2";
    rmdir "t/app1/public/dir1";
    rmdir "t/app1/public";
}

done_testing();
