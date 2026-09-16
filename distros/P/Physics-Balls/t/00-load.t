#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

my @modules = qw/
	Physics::Balls
	Physics::Balls::Engine
	Physics::Balls::Error
	Physics::Balls::Ball
	Physics::Balls::Table
	Physics::Balls::World
	Physics::Balls::Strike
	Physics::Balls::Outcome
/;

plan tests => scalar(@modules) + 2;

use_ok($_) for @modules;

# Every module carries $VERSION and they are asserted to agree: a POD version
# one ahead of the distribution shipped once elsewhere and nothing caught it.
my %version;
no strict 'refs';
$version{${"${_}::VERSION"}}++ for @modules;
use strict 'refs';

is scalar(keys %version), 1,
	'every module carries the same $VERSION (' . join(', ', keys %version) . ')';

is Physics::Balls->abi_version, 1, 'the C table is ABI 1';

diag("Testing Physics::Balls $Physics::Balls::VERSION, Perl $], $^X");
