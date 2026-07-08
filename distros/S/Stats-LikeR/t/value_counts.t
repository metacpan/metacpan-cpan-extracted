#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # die_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Gemini helped to write some of the tests
# Custom helper for floating-point comparisons
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	my $i = 0;
	foreach my $arg ($got, $expected, $test_name) {
		next if defined $arg;
		die "\$arg[$i] (see subroutine signature for name) isn't defined in $current_sub";
		$i++;
	}
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) {
		pass("$test_name: within $epsilon");
		return 1;
	} else {
		fail($test_name);
		diag("         got: $got\n    expected: $expected; diff = $diff");
		return 0;
	}
}
dies_ok {
	value_counts();
} 'value_counts: dies with no data';

dies_ok {
	value_counts(undef);
} 'value_counts: dies with undefined data';
#----
my $hash = value_counts('c');
my $n = scalar keys %{ $hash };
if ($n == 1) {
	pass('value_counts: has the correct # of hash keys');
} else {
	fail("value_counts: has $n hash keys, when it should have 1");
}
if (defined $hash->{'c'}) {
	pass('value_counts: "c" is defined');
} else {
	fail('value_counts: "c" is NOT defined');
}
is_approx( 1, $hash->{'c'}, 'value_counts: c = 1', 1e-13);
no_leaks_ok {
	value_counts('c');
} 'value_counts: no leaks when given scalar' unless $INC{'Devel/Cover.pm'};
#--------
$hash = value_counts(['a','b','b']);
$n = scalar keys %{ $hash };
if ($n == 2) {
	pass('value_counts: has the correct # of hash keys');
} else {
	fail("value_counts: has $n hash keys, when it should have 2");
}
is_approx(1, $hash->{'a'}, 'value_counts: key "a"', 1e-13);
is_approx(2, $hash->{'b'}, 'value_counts: key "a"', 1e-13);
no_leaks_ok {
	value_counts(['a','b','b']);
} 'value_counts: no leaks when given array reference' unless $INC{'Devel/Cover.pm'};
#--------------
$hash = value_counts('a','b','b');
$n = scalar keys %{ $hash };
if ($n == 2) {
	pass('value_counts: has the correct # of hash keys');
} else {
	fail("value_counts: has $n hash keys, when it should have 2");
}
is_approx(1, $hash->{'a'}, 'value_counts: key "a"', 1e-13);
is_approx(2, $hash->{'b'}, 'value_counts: key "a"', 1e-13);
no_leaks_ok {
	value_counts(['a','b','b']);
} 'value_counts: no leaks when given array reference' unless $INC{'Devel/Cover.pm'};
$hash = value_counts( { A => 'a', B => 'a', C => 'b' } );
$n = scalar keys %{ $hash };
if ($n == 2) {
	pass('value_counts: simple hash has the correct # of hash keys');
} else {
	fail("value_counts: simple hash has $n hash keys, when it should have 2");
}
is_approx($hash->{'a'}, 2, 'value_counts: simple hash "a" has correct #', 1e-13);
is_approx($hash->{'b'}, 1, 'value_counts: simple hash "b" has correct #', 1e-13);
no_leaks_ok {
	value_counts( { A => 'a', B => 'a', C => 'b' } );
} 'value_counts: no leaks when given simple hash' unless $INC{'Devel/Cover.pm'};
#--------
$hash = value_counts( {
	A => {
		a => 'x',
		b => 'z'
	},
	B => {
		a => 'x'
	},
	C => {
		a => 'y'
	}
}, 'a');
$n = scalar keys %{ $hash };
if ($n == 2) {
	pass('value_counts: 2D hash has the correct # of hash keys');
} else {
	fail("value_counts: 2D hash has $n hash keys, when it should have 2");
}
is_approx($hash->{'x'}, 2, 'value_counts: simple hash "a" has correct #', 1e-13);
is_approx($hash->{'y'}, 1, 'value_counts: simple hash "b" has correct #', 1e-13);
no_leaks_ok {
	$hash = value_counts( {
		A => {
			a => 'x',
			b => 'z'
		},
		B => {
			a => 'x'
		},
		C => {
			a => 'y'
		}
	}, 'a');
} 'value_counts: 2D hash with col/2nd key has no leaks' unless $INC{'Devel/Cover.pm'};

$hash = value_counts( {
	A => {
		a => 'x',
		b => 'z'
	},
	B => {
		a => 'x'
	},
	C => {
		a => 'y'
	}
}, 'c');
$n = scalar keys %{ $hash };
if ($n == 0) {
	pass('value_counts: 2D hash has the correct # of hash keys');
} else {
	fail("value_counts: 2D hash has $n hash keys, when it should have 0");
}
no_leaks_ok {
	value_counts( {
		A => {
			a => 'x',
			b => 'z'
		},
		B => {
			a => 'x'
		},
		C => {
			a => 'y'
		}
	}, 'c');
} 'value_counts: no leaks when given 2D hash and non-existent column name' unless $INC{'Devel/Cover.pm'};
# without specified key, "value_counts" goes through entire 2D hash
$hash = value_counts( {
	A => {
		a => 'x',
		b => 'z'
	},
	B => {
		a => 'x'
	},
	C => {
		a => 'y'
	}
});
$n = scalar keys %{ $hash };
if ($n == 3) { # a and b
	pass('value_counts: 2D hash w/o specific key has the correct # of hash keys');
} else {
	fail("value_counts: 2D hash w/o specific key has $n hash keys, when it should have 3");
}
my %correct = ('x' => 2, 'y' => 1, z => 1);
my %incorrect = grep { (defined $hash->{$_}) && ($hash->{$_} ne $correct{$_})} keys %correct;
$n = scalar keys %incorrect;
if ($n == 0) {
	pass('value_counts: all values from hash of arrays without key are correct');
} else {
	fail("value_counts: hash of array has $n incorrect hash keys");
}
# hash of arrays
$hash = value_counts({ 'a' => ['j', 't', 't'], 'b' => ['j', 't', 'v']}, 'a');
$n = scalar keys %{ $hash };
if ($n == 2) {
	pass('value_counts: hash of array has the correct # of hash keys');
} else {
	fail("value_counts: hash of array has $n hash keys, when it should have 0");
}
is_approx($hash->{'j'}, 1, 'value_counts: Hash of array got "j" correct', 1e-13);
is_approx($hash->{'t'}, 2, 'value_counts: Hash of array got "t" correct', 1e-13);
no_leaks_ok {
	value_counts({ 'a' => ['j', 't', 't'], 'b' => ['j', 't', 'v']}, 'a');
} 'value_counts: no leaks with HoA and key' unless $INC{'Devel/Cover.pm'};
$hash = value_counts({ 'a' => ['j', 't', 't'], 'b' => ['j', 't', 'v']});
$n = scalar keys %{ $hash };
if ($n == 3) {
	pass('value_counts: hash of array has the correct # of hash keys');
} else {
	fail("value_counts: hash of array has $n hash keys, when it should have 3");
}
%correct = (j => 2, t => 3, v => 1);
%incorrect = grep { (defined $hash->{$_}) && ($hash->{$_} ne $correct{$_})} keys %correct;
$n = scalar keys %incorrect;
if ($n == 0) {
	pass('value_counts: all values from hash of arrays without key are correct');
} else {
	fail("value_counts: hash of array has $n incorrect hash keys");
}
done_testing();
