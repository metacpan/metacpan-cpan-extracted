use strict;
use warnings;

use Test::More 1;
my $class  = 'Set::CrossProduct';

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT( "$class did not compile" );
	};

subtest warnings_off => sub {
	no warnings;
	my $warning;
	local $SIG{__WARN__} = sub { $warning = $_[0] };
	my $cross = $class->new( [ [qw(1 2 3)] ] );
	ok ! defined $cross,  "a single set returns undef";
	is $warning, undef, "there is no warning when warnings are not enabled (good)";
	};

subtest warnings_on => sub {
	use warnings;
	my $warning;
	local $SIG{__WARN__} = sub { $warning = $_[0] };
	my $cross = $class->new( [ [qw(1 2 3)] ] );
	ok ! defined $cross,  "a single set returns undef";
	like $warning, qr/You need at least two sets/, 'warning matches the expected pattern';
	};

done_testing();
