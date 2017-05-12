
use Mojo::Base -strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use Test::Mojo;

use_ok( "MojoAppCacheTest" );

my $t = Test::Mojo->new( "MojoAppCacheTest" );


$t->get_ok( "/example-1a.appcache" )
  ->status_is( 200 )
  ->content_like( qr!\A CACHE [ ] MANIFEST \n
[#] [^\n]+ \n
\Qimages/sound-icon.png
images/background.png
style/default.css
NETWORK:
comm.cgi
\E !x )
;


$t->get_ok( "/example-1b.appcache" )
  ->status_is( 200 )
  ->content_like( qr!\A CACHE [ ] MANIFEST \n
[#] [^\n]+ \n
\Qstyle/default.css
images/sound-icon.png
images/background.png
NETWORK:
comm.cgi
\E !x )
;


$t->get_ok( "/example-2-absolute.appcache" )
  ->status_is( 200 )
  ->content_like( qr!\A CACHE [ ] MANIFEST \n
[#] [^\n]+ \n
\Q/main/home
/main/app.js
/settings/home
/settings/app.js
http://img.example.com/logo.png
http://img.example.com/check.png
http://img.example.com/cross.png
\E !x )
;


$t->get_ok( "/example-3-fallback.appcache" )
  ->status_is( 200 )
  ->content_like( qr!\A CACHE [ ] MANIFEST \n
[#] [^\n]+ \n
\QFALLBACK:
/ /offline.html
NETWORK:
*
\E !x )
;


done_testing();

