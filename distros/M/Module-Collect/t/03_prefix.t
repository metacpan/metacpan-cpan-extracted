use strict;
use warnings;
use Test::More tests => 2;

use File::Spec::Functions;

use Module::Collect;

my $collect = Module::Collect->new( path => catfile('t', 'plugins'), prefix => 'With' );
is_deeply [ sort { $a cmp $b } map { $_->{package} } @{ $collect->modules }], ['With::Comment', 'With::Pod'];
is scalar(@{ $collect->modules }), 2;
