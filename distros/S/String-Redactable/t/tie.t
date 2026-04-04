use v5.20;
use Test::More;
use Data::Dumper;

my $parent_class = require './Makefile.PL';
my $class = 'Tie::' . $parent_class;

subtest 'sanity' => sub {
	use_ok $class;
	can_ok $class, qw(new);

	local $SIG{__WARN__} = sub {};

	my $string = 'abcdef';
	isa_ok my $obj = $class->new('1234'), $class;
	};

subtest 'tie' => sub {
	use warnings;
	my $warnings;
	local $SIG{__WARN__} = sub { $warnings = $_[0] };
	my $warnings_re = qr/\APossible unintended/;

	my $original = 'abcdef';
	my $original_re;
	my $obj;
	my $tied_scalar;

	subtest 'tie' => sub {
		undef $warnings;
		ok ! defined $warnings, 'no warning at start' or diag $warnings;

		$original = 'abcdef';
		$obj = tie $tied_scalar, $class, $original;
		ok ! defined $warnings, 'no warning after tie' or diag $warnings;

		$original_re = qr/$original/;
		};

	subtest 'isa' => sub {
		undef $warnings;
		isa_ok $obj, $class;
		isa_ok tied($tied_scalar), $class;
		ok ! defined $warnings, 'no warning';
		};

	subtest 'interpolation' => sub {
		undef $warnings;
		my $dump = "$tied_scalar";
		like $warnings, $warnings_re, 'got warning';
		unlike $dump, $original_re, 'new string does not have redactable string';
		};

	subtest 'dumper' => sub {
		undef $warnings;
		ok ! defined $warnings, 'no warning at start' or diag $warnings;

		my $dump = Data::Dumper::Dumper($tied_scalar);
		like $warnings, $warnings_re, 'got warning';
		unlike $dump, $original_re, 'new string does not have redactable string';

		is tied($tied_scalar)->to_str_unsafe, $original, 'unsafe string has not changed';
		};

	subtest 'data structure' => sub {
		undef $warnings;
		ok ! defined $warnings, 'no warning at start' or diag $warnings;

		require JSON;
		my $data = { password => $tied_scalar };
		like $warnings, $warnings_re, 'got warning';
		};

	subtest 'unsafe' => sub {
		undef $warnings;
		ok ! defined $warnings, 'no warning at start' or diag $warnings;

		my $unsafe = tied($tied_scalar)->to_str_unsafe;

		is $unsafe, $original, 'the unsafe string is the same as the original';

		my $obj = tied($tied_scalar);
		};
	};

done_testing();
