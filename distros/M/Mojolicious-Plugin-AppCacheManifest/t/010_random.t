
use Mojo::Base -strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use Test::Mojo;

use Mojo::Date;
use Mojo::Util qw( spurt );

use_ok( "MojoAppCacheTest" );

my $t = Test::Mojo->new( "MojoAppCacheTest" );

# set timeout for cache tests
$t->app->plugin( "AppCacheManifest" )->timeout( 60 * 5 );

# same body in all cases
my $body = <<EOF;
/some/where.png
may/be.txt
http://localhost/my/meh.jpg
test.css
file.css
foo.css
foo.pdf
bla.js
FALLBACK:
/ /ugh.html
SETTINGS:
prefer-online
NETWORK:
*
EOF

# corresponding file path
my $manifest = $t->app->home->rel_dir( "public" ) . "/random.appcache";
my $testcss = $t->app->home->rel_dir( "public" ) . "/test.css";

# make sure previous runs don't spoil the timing
unlink( $testcss );

# general check
$t->get_ok( "/random.appcache" )
  ->status_is( 200 )
  ->content_like( qr!\A CACHE [ ] MANIFEST \n
[#] [^\n]+ \n
\Q$body\E !x )
;

# get the times
my $mtime = ( stat( $manifest ) )[9];
my $mdate = Mojo::Date->new( $mtime );

# check for if modified since file modification time
$t->get_ok( "/random.appcache" => { "If-Modified-Since" => $mdate } )
  ->status_is( 304 )
  ->content_is( "" )
;

# update test.css
spurt "", $testcss;

# default cache timeout is not expired yet
$t->get_ok( "/random.appcache" => { "If-Modified-Since" => $mdate } )
  ->status_is( 304 )
  ->content_is( "" )
;

# touch file manifest to force an update
utime( time(), time(), $manifest );

# now should have content again
$t->get_ok( "/random.appcache" => { "If-Modified-Since" => $mdate } )
  ->status_is( 200 )
  ->content_like( qr!\A CACHE [ ] MANIFEST \n
[#] [^\n]+ \n
\Q$body\E !x )
;

# keep the tree clean
unlink( $testcss );

done_testing();

