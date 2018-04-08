use Test::More;

use Switch::Again qw/all/;

my $switch = switch
	sub {$_[0] == 1} => sub {
		return 'truth';
	},
	sub {$_[0] == 0} => sub {
		return 'lie';
	},
	default => sub {
		return 'unknown';
	};

my $test = $switch->(1);
is($test, 'truth');
$test = $switch->(0);
is($test, 'lie');
$test = $switch->(2);
is($test, 'unknown');

done_testing();
