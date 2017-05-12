use strict;
use warnings;
use utf8;
use Test::More;

use Perl::MinimumVersion::Fast;

my $p = Perl::MinimumVersion::Fast->new('t/sample/Padre-SVN.pm');
is($p->minimum_version, '5.008');

done_testing;

