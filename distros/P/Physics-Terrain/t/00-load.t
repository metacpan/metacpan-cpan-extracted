#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

my @modules = qw/
	Physics::Terrain
	Physics::Terrain::Snapshot
/;

plan tests => scalar(@modules) + 5;

use_ok($_) for @modules;

# Every module carries $VERSION and they are asserted to agree: a POD version
# one ahead of the distribution shipped once elsewhere and nothing caught it.
my %version;
no strict 'refs';
$version{${"${_}::VERSION"}}++ for @modules;
use strict 'refs';

is scalar(keys %version), 1,
	'every module carries the same $VERSION (' . join(', ', keys %version) . ')';

is Physics::Terrain->abi_version, 1, 'the C table is ABI 1';
ok Physics::Terrain::_abi_ptr() != 0, 'the table has an address';
is Physics::Terrain::LEFT() | Physics::Terrain::RIGHT() | Physics::Terrain::JUMP(), 7, 'the three input bits';
is Physics::Terrain::FLYING(), 3, 'the modes count to flying';

diag("Testing Physics::Terrain $Physics::Terrain::VERSION, Perl $], $^X");
