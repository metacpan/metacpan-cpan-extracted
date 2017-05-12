use strict;
use warnings;
use Test::More tests => 8;
use PkgConfig;

my $version1 = PkgConfig::Version->new('1.2.3');
my $version2 = PkgConfig::Version->new('1.2.3.4');
my $version3 = PkgConfig::Version->new('1.2.3.3');

ok $version1 == $version1->clone, '==';
ok !($version1 != $version1),     '!=';

ok $version1 <= $version2, '<=';
ok $version2 >= $version1, '>=';

ok !($version1 >= $version2), '>=';
ok !($version2 <= $version1), '<=';

ok $version1 >= $version1->clone, '>=';
ok $version1 <= $version1->clone, '>=';
