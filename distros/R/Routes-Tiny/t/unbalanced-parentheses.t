use strict;
use warnings;

use Test::More tests => 1;

use Routes::Tiny;

my $r = Routes::Tiny->new;

eval { $r->add_route('/(((('); };
ok($@ =~ qr/are not balanced/);
