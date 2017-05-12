use strict;
use warnings;
use Test::More tests => 2;

use File::Spec::Functions;

use Module::Collect;

my $collect = Module::Collect->new( path => [ catfile('t', 'plugin1'), catfile('t', 'plugin2') ] );
is_deeply [ sort { $a cmp $b } map { $_->{package} } @{ $collect->modules }], ['One', 'Two', 'two2'];
is scalar(@{ $collect->modules }), 3;
