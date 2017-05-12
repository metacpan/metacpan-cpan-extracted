#!perl -T

use 5.008;
use strict;
use warnings 'all';

use Test::More 0.94;
use Test::Exception;

if ($Test::More::VERSION =~ m{\A 2\.00 0[67] \z}mosx) {
	plan skip_all => 'subtests broken with Test::More 2.00_06 and _07';
	exit 0;
}

plan tests => 6;

use Nagios::Plugin::OverHTTP::PerformanceData;

# Short-hand
my $perf_class = 'Nagios::Plugin::OverHTTP::PerformanceData';

###########################################################################
# BASIC NEW TESTS
subtest 'New tests' => sub {
	plan tests => 3;

	# New ok with some arguments
	my $data = new_ok $perf_class => [
		label => 'test',
		value => 6,
	];

	# New ok with performance string
	$data = new_ok $perf_class => ['test=6'];

	# New failes
	dies_ok { $perf_class->new($data); } 'One argument non-string fails';
};

###########################################################################
# PARSING TESTS
subtest 'Parse test' => sub {
	plan tests => 3;

	subtest 'test=1s;2;3;4;5' => sub {
		plan tests => 8;

		my $data;

		lives_ok {
			$data = $perf_class->new('test=1s;2;3;4;5');
		} 'Parse data string';

		is $data->label, 'test', 'Label correct';
		is $data->value, 1, 'Value correct';
		is $data->units, 's', 'Units are correct';
		is $data->warning_threshold, '2', 'Warning correct';
		is $data->critical_threshold, '3', 'Critical correct';
		is $data->minimum_value, '4', 'Minimum correct';
		is $data->maximum_value, '5', 'Maximum correct';
	};

	subtest 'wat' => sub {
		plan tests => 1;

		dies_ok { $perf_class->new('wat'); } 'Fail';
	};

	subtest 'novalue=' => sub {
		plan tests => 1;

		dies_ok { $perf_class->new('novalue='); } 'Fail';
	};
};

###########################################################################
# PARSING QUOTED LABELS
subtest 'Parse quoted label' => sub {
	plan tests => 4;

	lives_and {
		is $perf_class->new(q{'test'=4})->label, q{test};
	} 'Parse basic quoted label';

	lives_and {
		is $perf_class->new(q{'te=st'=4})->label, q{te=st};
	} 'Internal equal sign';

	lives_and {
		is $perf_class->new(q{'don''t'=4})->label, q{don't};
	} 'Parse label with internal quote';

	dies_ok {
		$perf_class->new(q{'don't'=4});
	} 'Label with bad internal quote';
};

###########################################################################
# THRESHOLD HANDLING
subtest 'Threshold handling' => sub {
	plan tests => 16;

	my $data = $perf_class->new(q{test=15s;~:10;0:20});

	ok $data->is_warning, 'Should be warning';
	ok !$data->is_critical, 'Not critical';
	ok !$data->is_ok, 'Not ok';

	ok $data->is_within_range('10'), 'Within range 10';
	ok !$data->is_within_range('20'), 'Not within range 20';
	ok !$data->is_within_range('10:'), 'Not within range 10:';
	ok !$data->is_within_range('~:15'), 'Not within range ~:15';
	ok !$data->is_within_range('15:15'), 'Not within range 15:15';
	ok $data->is_within_range('20:30'), 'Within range 20:30';
	ok $data->is_within_range('@10:15'), 'Within range @10:15';
	ok !$data->is_within_range('@20:30'), 'Not within range @20:30';
	ok !$data->is_within_range('@10:12'), 'Not within range @10:12';
	dies_ok { $data->is_within_range('OUW@#$#%') } 'Bad range fails';

	subtest q{test=25s;~:10;0:20} => sub {
		plan tests => 3;

		my $data = $perf_class->new(q{test=25s;~:10;0:20});

		ok $data->is_warning, '25s is warning';
		ok $data->is_critical, '25s is critical';
		ok !$data->is_ok, '25s not ok';
	};

	subtest q{test=-5s;10;0:20} => sub {
		plan tests => 3;

		my $data = $perf_class->new(q{test=-5s;10;-10:20});

		ok $data->is_warning, '-5s is warning';
		ok !$data->is_critical, '-5s not critical';
		ok !$data->is_ok, '-5s not ok';
	};

	subtest q{test=5s} => sub {
		plan tests => 3;

		my $data = $perf_class->new(q{test=5s});

		ok !$data->is_warning, 'No warning if no warning threshold';
		ok !$data->is_critical, 'No critical if no critical threshold';
		ok $data->is_ok, 'ok if no thresholds';
	};
};

###########################################################################
# TO STRING
subtest 'To performance string' => sub {
	my %tests= (
		q{test=2s} => q{'test'=2s},
		q{'test'''=3s;~20;:20;;} => q{'test'''=3s;~20;:20},
		q{test=2} => q{'test'=2},
		q{test=2;1;1;0;10} => q{'test'=2;1;1;0;10},
	);

	plan tests => scalar keys %tests;

	foreach my $string (keys %tests) {
		# Convert the string
		my $convert = $perf_class->new($string)->to_string;

		is $convert, $tests{$string}, "Test $string";
	}
};

###########################################################################
# SPLIT
subtest 'Split test' => sub {
	my @expect = (
		q{time=2s},
		q{'quote'=3s;2;1;;;},
		q{'don''t'=2;},
		q{'space anyone?'=76},
		q{'broken'quote=3.4s},
	);

	plan tests => 1;

	# Split them after joining
	my @items = $perf_class->split_performance_string(join q{ }, @expect);

	is_deeply \@items, \@expect, 'Split worked correctly';
};

exit 0;
