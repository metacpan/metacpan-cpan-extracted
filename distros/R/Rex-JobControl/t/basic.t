use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Rex::JobControl');
ok($t, "Got Object");

done_testing();
