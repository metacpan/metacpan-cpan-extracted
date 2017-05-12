use Mojo::Base -strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::Mojo;
use Test::More;

my $t = Test::Mojo->new( 'MyApp' );

$t->get_ok('/params/?id=1&api[user]=t00r&api[passwd]=q1w2e3')->content_like(qr/id:1;user:t00r;passwd:q1w2e3/);

done_testing();