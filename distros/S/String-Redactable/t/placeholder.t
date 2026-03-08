use v5.20;

use Test::More;
no warnings;

use String::Redactable;

my $class;
BEGIN { $class = require './Makefile.PL' }

my $method = 'placeholder';

subtest 'sanity' => sub {
	use_ok $class;
	can_ok $class, $method;
	};

subtest 'warnings enabled' => sub {
	use warnings;
	my $warnings;
	local $SIG{__WARN__} = sub { $warnings = $_[0] };
	my $s = $class->$method;
	like $warnings, qr/Possible/, 'saw warning';
	};

subtest 'all warnings disabled' => sub {
	no warnings;
	my $warnings;
	local $SIG{__WARN__} = sub { $warnings = $_[0] };
	ok ! defined $warnings, 'there were no warnings';
	my $s = $class->$method;
	};

subtest 'module warnings disabled' => sub {
	no warnings ($class);
	my $warnings;
	local $SIG{__WARN__} = sub { $warnings = $_[0] };

	my $s = $class->$method;
	ok ! defined $warnings, 'there were no warnings';
	};

done_testing();
