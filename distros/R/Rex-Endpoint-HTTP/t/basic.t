use Mojo::Base -strict;

use Test::More tests => 2;
use Test::Mojo;

my $t = Test::Mojo->new('Rex::Endpoint::HTTP');
$t->get_ok('/')->status_is(200);
