use strict;
use warnings;

use Test::More tests => 1;

use Routes::Tiny;

my $r = Routes::Tiny->new;
$r->add_route('/foo//bar');

ok(!$r->match('foo/bar'));
