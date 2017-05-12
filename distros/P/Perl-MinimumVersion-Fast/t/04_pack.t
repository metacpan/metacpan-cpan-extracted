use strict;
use warnings;
use Test::More;

use Perl::MinimumVersion::Fast;

my $p = Perl::MinimumVersion::Fast->new(\'my $p = pack "L>", 1');
is($p->minimum_version, '5.010');

done_testing;
