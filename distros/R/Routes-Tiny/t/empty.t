use strict;
use warnings;

use Test::More tests => 2;

use Routes::Tiny;

my $r = Routes::Tiny->new;

ok($r);

ok(!$r->match('/'));
