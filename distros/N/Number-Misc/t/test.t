#!/usr/bin/perl -w
use strict;
use Carp 'confess';
use Number::Misc ':all';
use Test::More;
plan tests => 31;

# debug tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# stubs for convenience
sub bool_comp;
sub comp;


#------------------------------------------------------------------------------
# tests
#
do {
	my ($name);
	
	# is_numeric
	$name = 'is_numeric';
	bool_comp is_numeric('3'),                       1, "$name: 3";
	bool_comp is_numeric('0003'),                    1, "$name: 0003";
	bool_comp is_numeric('0.003'),                   1, "$name: 0.003";
	bool_comp is_numeric('0.00.3'),                  0, "$name: 0.00.3";
	bool_comp is_numeric('3,003'),                   1, "$name: 3,003";
	bool_comp is_numeric('  3'),                     0, "$name:   3";
	bool_comp is_numeric(undef),                     0, "$name: undef";
	bool_comp is_numeric('3,003',  convertible=>1),  1, "$name: 3,003, convertible";
	bool_comp is_numeric('  3',    convertible=>1),  1, "$name: '  3', convertible";
	bool_comp is_numeric('0.00.3', convertible=>1),  0, "$name: 0.00.3, convertible";
	
	# to_number
	$name = 'to_number';
	comp to_number(' 3 '),                           3,     "$name: ' 3 '";
	comp to_number(' 3,000 '),                       3000,  "$name: ' 3,000 '";
	comp to_number('whatever'),                      undef, "$name: 'whatever'";
	comp to_number('whatever', always_number=>1),    0,     "$name: 'whatever', always_number";
	
	# commafie
	$name = 'to_number';
	comp commafie(2000),           '2,000',    "$name: 2000";
	comp commafie(2000.33),        '2,000.33', "$name: 2000.33";
	comp commafie(-2000),          '-2,000',   "$name: -2000";
	comp commafie(100),            '100',      "$name: 100";
	comp commafie(2000, sep=>'x'), '2x000',    "$name: 2000 with sep";
	
	# zero_pad
	$name = 'zero_pad';
	comp zero_pad(2, 3),   '002',         "$name: 2, 3";
	comp zero_pad(2, 10),  '0000000002',  "$name: 2, 10";
	comp zero_pad(444, 2), '444',         "$name: 444, 2";

	# rand_in_range
	RAND_LOOP: {
		for (1..100) {
			my $number = rand_in_range(-1, 10);
			
			if ( ($number < -1) || $number > 10 ) {
				ok 0, 'rand_in_range';
				last RAND_LOOP;
			}
		}
		
		ok 1, 'rand_in_range';
	}

	# is_even
	# Turning off warnings because some of the tests produce expected warnings.
	# I hate it when installations produce tons of warnings but I don't know
	# which of them is actually a problem.  The following tests product
	# warnings that aren't actually problems.
	do {
		$name = 'is_even';
		bool_comp is_even(1), 0, "$name: 1";
		bool_comp is_even(2), 1, "$name: 2";
		
		local $SIG{'__WARN__'} = sub {  };
		
		comp is_even(undef),  undef, "$name: undef";
		comp is_even('fred'), undef, "$name: fred";
	};

	# is_odd
	do {
		$name = 'is_even';
		bool_comp is_odd(1), 1, "$name: 1";
		bool_comp is_odd(2), 0, "$name: 2";
		
		local $SIG{'__WARN__'} = sub {  };
		
		comp is_odd(undef), undef,  "$name: undef";
		comp is_odd('fred'), undef, "$name: fred";
	};
};
#
# tests
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# comp
#
sub comp {
	my ($val1, $val2, $test_name) = @_;
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	# if both undef
	if ( (! defined $val1) && (! defined $val2) )
		{ ok 1, $test_name }
	
	# if first is not defined, false
	elsif (! defined $val1)
		{ ok 0, $test_name }
	
	# if second is not defined, false
	elsif (! defined $val2)
		{ ok 0, $test_name }
	
	# else if same
	elsif ($val1 eq $val2)
		{ ok 1, $test_name }
	
	# else not same
	else
		{ ok 0, $test_name }
}
#
# comp
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# bool_comp
#
sub bool_comp {
	my ($val1, $val2, $test_name) = @_;
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	# if both true
	if ( $val1 && $val2 )
		{ ok 1, $test_name }
	
	# if both false
	elsif ( (! $val1) && (! $val2) )
		{ ok 1, $test_name }
	
	# else not ok
	else
		{ ok 0, $test_name }
}
#
# bool_comp
#------------------------------------------------------------------------------

