use Mojo::Base -strict;

use Test::Mojo;
use Test::More
    tests => 6
;

use Mojolicious::Lite;

plugin 'CSSCompressor';

my $t = Test::Mojo->new();

$t->get_ok( '/foo.css' )
  ->status_is( 200 )
  ->content_is( <<EOF )
body
{
	margin: 0 0 0 0;
}
EOF
;

$t->get_ok( '/foo-min.css' )
  ->status_is( 200 )
  ->content_is( 'body{margin:0}' )
;

__DATA__
@@ foo.css
body
{
	margin: 0 0 0 0;
}
