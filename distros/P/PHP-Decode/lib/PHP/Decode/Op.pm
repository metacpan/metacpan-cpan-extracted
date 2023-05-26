#
# PHP operators
# https://www.php.net/manual/en/language.operators.php
#
package PHP::Decode::Op;

use strict;
use warnings;
use PHP::Decode::Array qw(is_int_index);
use PHP::Decode::Parser qw(:all);

our $VERSION = '0.41';

sub to_num {
	my ($val) = @_;

	if ($val =~ /^([+-]?[0-9\.]+)/) {
		return $1 + 0;
	}
	return 0;
}

sub is_numval_or_null {
	my ($s) = @_;

	if ($s =~ /^(\#num\d+|\#null)$/) {
		return 1;
	}
	return 0;
}

sub unary {
	my ($parser, $op, $val) = @_;
	my $result;
	my $to_str = 0;

	if ($val =~ /^#const\d+$/) {
		#printf ">> exec-op: %s %s -> skip for const\n", $op, $val;
		return;
	}
	my $s = $parser->{strmap}{$val};

	if (is_array($val)) {
		my $arr = $parser->{strmap}{$val};
		if ($op ne '!') {
			#printf ">> exec-op: %s %s -> skip arr not allowed for op\n", $op, $val;
			return;
		}
		$s = $arr->empty() ? 0 : 1;
	}

	if ($op eq '++') {
		if ($val =~ /^#num\d+$/) {
			$result = int($s);
			$result++;
		} else {
			# in php/perl ++str/str++ returns next ASCII-String
			# https://php.net/manual/en/language.operators.increment.php
			#
			$result = ++$s;
			$to_str = 1;
		}
	} elsif ($op eq '--') {
		if ($val =~ /^#num\d+$/) {
			$result = int($s);
			$result--;
		} else {
			# in php --str/str-- returns the same ASCII-String
			#
			$result = $s;
			$to_str = 1;
		}
	} elsif ($op eq '~') {
		if ($val =~ /^#num\d+$/) {
			$result = ~int($s); 
		} else {
			$result = ~$s; 
			$to_str = 1;
		}
	} elsif ($op eq '!') {
		$result = $s ? 0 : 1; 
	} elsif ($op eq 'not') {
		$result = not $s ? 0 : 1;
	} elsif ($op eq '-') {
		$result = -int($s);
	} elsif ($op eq '+') {
		$result = int($s);
	} else {
		return;
	}
	my $k;
	if ($to_str) {
		$k = $parser->setstr($result);
	} else {
		$k = $parser->setnum($result);
	}
	return ($k, $result);
}

sub binary {
	my ($parser, $val1, $op, $val2) = @_;
	my $result;
	my $to_str = 0;
	my $s1;
	my $s2;

	if (($val1 =~ /^#const\d+$/) || ($val2 =~ /^#const\d+$/)) {
		#printf ">> exec-op: %s %s %s -> skip for const\n", $val1, $op, $val2;
		return;
	}

	if ($val1 eq '#null') {
		if ($val2 eq '#null') {
			$s1 = '';
			$s2 = '';
		} elsif ($val2 =~ /^#num\d+$/) {
			$s1 = 0;
			$s2 = $parser->{strmap}{$val2};
		} elsif (is_array($val2)) {
			my $arr = $parser->{strmap}{$val2};
			$s1 = 0;
			$s2 = $arr->empty() ? 0 : 1;
		} else {
			$s1 = '';
			$s2 = $parser->{strmap}{$val2};
		}
	} elsif ($val2 eq '#null') {
		if ($val1 =~ /^#num\d+$/) {
			$s1 = $parser->{strmap}{$val1};
			$s2 = 0;
		} elsif (is_array($val1)) {
			my $arr = $parser->{strmap}{$val1};
			$s1 = $arr->empty() ? 0 : 1;
			$s2 = 0;
		} else {
			$s1 = $parser->{strmap}{$val1};
			$s2 = '';
		}
	} else {
		$s1 = $parser->{strmap}->{$val1};
		$s2 = $parser->{strmap}->{$val2};

		# todo: array comparisions
		# https://www.php.net/manual/en/language.operators.comparison.php
		#
		if (is_array($val1)) {
			my $arr = $parser->{strmap}{$val1};
			$s1 = $arr->empty() ? 0 : 1;
		}
		if (is_array($val2)) {
			my $arr = $parser->{strmap}{$val2};
			$s2 = $arr->empty() ? 0 : 1;
		}
	}

	# if arguments to bitwise ops (& | ^ ~ << >>) are
	# strings, then the op is performend on all the chars.
	#
	# https://php.net/manual/en/language.operators.bitwise.php
	#
	# perl does also a bitwise op on a character by character
	# bases for strings:
	#   "a" ^  " " flips case.
	#   "a" |  " " sets lower case.
	#   "a" & ~" " sets upper case.
	#   "a" &  " " sets to space.
	#
	# arithmetic operations on strings parse the numeric start
	# of the string and convert it to number like in perl.
	# ('2xx' -> 2, 'xxx' -> 0)
	#
	# Boolean operators in perl return 1 for true and the empty
	# string for false when evaluated in string context (like printf)
	#
	# In string context arrays are converted to the string "Array".
	#
	if ($op eq '+') {
		if (is_numval_or_null($val1) && is_numval_or_null($val2)) {
			$result = $s1 + $s2; 
		} else {
			no warnings 'numeric';
			#print ">>> $s1 + $s2\n";
			$result = $s1 + $s2; 
		}
	} elsif ($op eq '-') {
		$result = $s1 - $s2; 
	} elsif ($op eq '*') {
		$result = $s1 * $s2; 
	} elsif ($op eq '/') {
		if (int($s2) != 0) {
			$result = $s1 / $s2; 
		} else {
			$result = $s1; 
		}
	} elsif ($op eq '%') {
		if (int($s2) != 0) {
			$result = $s1 % $s2; 
		} else {
			$result = $s1; 
		}
	} elsif (($op eq '==') || ($op eq '!=')) {
		# calc '==' first and then invert for '!='
		#
		# for php loose/strong comparisions see:
		# https://php.net/manual/en/types.comparisons.php#types.comparisions-loose
		#
		if (is_numval($val1) && is_numval($val2)) {
			$result = ($s1 == $s2) ? 1 : 0;
		} elsif (is_array($val1) && is_array($val2)) {
			$result = (array_compare($parser, $val1, $val2) == 0) ? 1 : 0;
		} elsif (is_array($val1) && !is_array($val2) && !is_null($val2)) {
			$result = 0; # array is always greater
		} elsif (!is_array($val1) && is_array($val2) && !is_null($val1)) {
			$result = 0; # array is always greater
		} elsif (is_numval($val1) && !is_numval($val2)) {
			$result = ($s1 == to_num($s2)) ? 1 : 0;
		} elsif (!is_numval($val1) && is_numval($val2)) {
			$result = (to_num($s1) == $s2) ? 1 : 0;
		} else {
			$result = ($s1 eq $s2) ? 1 : 0;
		}
#printf ">>>> CMP: %s == %s\n", $s1, $s2;
		$result = 1 - $result if ($op eq '!=');
	} elsif (($op eq '<') || ($op eq '>=')) {
		# calc '<' first and then invert for '>='
		#
		if (is_numval($val1) && is_numval($val2)) {
			$result = ($s1 < $s2) ? 1 : 0;
		} elsif (is_array($val1) && is_array($val2)) {
			$result = (array_compare($parser, $val1, $val2) < 0) ? 1 : 0;
		} elsif (is_array($val1) && !is_array($val2) && !is_null($val2)) {
			$result = 0; # array is always greater
		} elsif (!is_array($val1) && is_array($val2) && !is_null($val1)) {
			$result = 1; # array is always greater
		} elsif (is_numval($val1) && !is_numval($val2)) {
			$result = ($s1 < to_num($s2)) ? 1 : 0;
		} elsif (!is_numval($val1) && is_numval($val2)) {
			$result = (to_num($s1) < $s2) ? 1 : 0;
		} else {
			$result = ($s1 lt $s2) ? 1 : 0;
		}
		$result = 1 - $result if ($op eq '>=');
	} elsif (($op eq '>') || ($op eq '<=')) {
		# calc '>' first and then invert for '<='
		#
		if (is_numval($val1) && is_numval($val2)) {
			$result = ($s1 > $s2) ? 1 : 0;
		} elsif (is_array($val1) && is_array($val2)) {
			$result = (array_compare($parser, $val1, $val2) > 0) ? 1 : 0;
		} elsif (is_array($val1) && !is_array($val2) && !is_null($val2)) {
			$result = 1; # array is always greater
		} elsif (!is_array($val1) && is_array($val2) && !is_null($val1)) {
			$result = 0; # array is always greater
		} elsif (is_numval($val1) && !is_numval($val2)) {
			$result = ($s1 > to_num($s2)) ? 1 : 0;
		} elsif (!is_numval($val1) && is_numval($val2)) {
			$result = (to_num($s1) > $s2) ? 1 : 0;
		} else {
			$result = ($s1 gt $s2) ? 1 : 0;
		}
		$result = 1 - $result if ($op eq '<=');
	} elsif (($op eq '===') || ($op eq '!==')) {
		# calc '===' first and then invert for '!=='
		# '' and 0 and #null are different here
		if (is_null($val1) && is_null($val2)) {
			$result = 1;
		} elsif (is_array($val1) && is_array($val2)) {
			# also check types of array elements here
			$result = (array_compare($parser, $val1, $val2, 1) == 0) ? 1 : 0;
		} elsif (is_array($val1) && !is_array($val2) && !is_null($val2)) {
			$result = 0; # types differ
		} elsif (!is_array($val1) && is_array($val2) && !is_null($val1)) {
			$result = 0; # types differ
		} elsif (is_null($val1) || is_null($val2)) {
			$result = 0;
		} elsif (is_numval($val1) && is_numval($val2)) {
			$result = ($s1 == $s2) ? 1 : 0;
		} else {
			$result = ($s1 eq $s2) ? 1 : 0;
		}
		$result = 1 - $result if ($op eq '!==');
	} elsif ($op eq '<=>') {
		if (is_null($val1) && is_null($val2)) {
			$result = 0;
		} elsif (is_array($val1) && is_array($val2)) {
			$result = array_compare($parser, $val1, $val2);
		} elsif (is_array($val1) && !is_array($val2)) {
			$result = 1; # array is always greater
		} elsif (!is_array($val1) && is_array($val2)) {
			$result = -1; # array is always greater
		} elsif (is_null($val1) || is_null($val2)) {
			if (($s1 eq '') || ($s2 eq '')) {
				$result = $s1 cmp $s2;
			} else {
				$result = $s1 <=> $s2;
			}
		} elsif (is_numval($val1) && is_numval($val2)) {
			$result = $s1 <=> $s2;
		} else {
			$result = $s1 cmp $s2;
		}
	} elsif ($op eq '&&') {
		$result = ($s1 && $s2) ? 1 : 0;
	} elsif ($op eq '||') {
		$result = ($s1 || $s2) ? 1 : 0;
	} elsif ($op eq 'and') {
		$result = ($s1 and $s2) ? 1 : 0;
	} elsif ($op eq 'or') {
		$result = ($s1 or $s2) ? 1 : 0;
	} elsif ($op eq 'xor') {
		$result = ($s1 xor $s2) ? 1 : 0;
	} elsif ($op eq '.') {
		$s1 = 'Array' if is_array($val1);
		$s2 = 'Array' if is_array($val2);
		$result = $s1 . $s2; 
		$to_str = 1;
	} elsif ($op eq '^') {
		if (is_numval_or_null($val1) && is_numval_or_null($val2)) {
			$result = int($s1) ^ int($s2); 
		} else {
			$result = $s1 ^ $s2; 
			$to_str = 1;
		}
	} elsif ($op eq '&') {
		if (is_numval_or_null($val1) && is_numval_or_null($val2)) {
			$result = int($s1) & int($s2); 
		} else {
			$result = $s1 & $s2; 
			$to_str = 1;
		}
	} elsif ($op eq '|') {
		if (is_numval_or_null($val1) && is_numval_or_null($val2)) {
			$result = int($s1) | int($s2); 
		} else {
			$result = $s1 | $s2; 
			$to_str = 1;
		}
	} elsif ($op eq '<<') {
		if (is_numval_or_null($val1) && is_numval_or_null($val2)) {
			$result = int($s1) << int($s2); 
		} else {
			$result = $s1 << $s2; 
			$to_str = 1;
		}
	} elsif ($op eq '>>') {
		if (is_numval_or_null($val1) && is_numval_or_null($val2)) {
			$result = int($s1) >> int($s2); 
		} else {
			$result = $s1 >> $s2; 
			$to_str = 1;
		}
	} elsif ($op eq '?:') {
		$result = ($s1) ? $val1 : $val2;
		return ($result, undef);
	} elsif ($op eq '??') {
		$result = ($s1) ? $val1 : $val2;
		return ($result, undef);
	} else {
		return;
	}
	my $k;
	if ($to_str) {
		if ($op eq '.') {
			# save space for memory hungry ops like repeated strconcat
			#
			$k = $parser->setstr_norev($result);
		} else {
			$k = $parser->setstr($result);
		}
	} else {
		$k = $parser->setnum($result);
	}
	return ($k, $result);
}

# check if array has just const elements
#
sub array_is_const {
	my ($parser, $a) = @_;

	unless (is_array($a)) {
		return;
	}
	my $arr = $parser->{strmap}{$a};
	my $keys = $arr->get_keys();
	foreach my $k (@$keys) {
		unless (is_int_index($k) || is_strval($k)) {
			return 0;
		}
		my $val = $arr->val($k);
		if (defined $val) {
			unless (is_strval($val)) {
				return 0 if !is_array($val);
				return 0 if !&array_is_const($parser, $val);
			}
		}
	}
	return 1;
}

# compare two arrays
#
sub array_compare {
	my ($parser, $a, $b, $check_types) = @_;

	unless (is_array($a) && is_array($b)) {
		return;
	}
	my $arr_a = $parser->{strmap}{$a};
	my $keys_a = $arr_a->get_keys();
	my $arr_b = $parser->{strmap}{$b};
	my $keys_b = $arr_b->get_keys();

	my $cmp = (scalar @$keys_a) - (scalar @$keys_b);
	if ($cmp != 0) {
		return $cmp;
	}

	for (my $i=0; $i < scalar @$keys_a; $i++) {
		my $va = $arr_a->get($keys_a->[$i]);
		my $vb = $arr_b->get($keys_b->[$i]);

		my ($val, $result) = binary($parser, $va, '<=>', $vb);
		if ($result != 0) {
			return $result;
		}
		if ($check_types) {
			($val, $result) = binary($parser, $va, '===', $vb);
			if ($result != 0) {
				return $result;
			}
		}
	}
	return 0;
}

1;

__END__

=head1 NAME

PHP::Decode::Op

=head1 SYNOPSIS

  # PHP operations on parsed objects

  my $val1 = $parser->setnum('2');
  my $val2 = $parser->setnum('3');
  my $res = PHP::Decode::Op::binary($parser, $val1, '+', $val2);

  $res = PHP::Decode::Op::unary($parser, '-', $parser->set_num($res));

  my $arr1 = $parser->newarr();
  my $arr2 = $parser->newarr();
  $arr1->set(undef, $val1);
  $arr2->set(undef, $val2);
  $res = PHP::Decode::Op::array_compare($parser, $arr1->{name}, $arr2->{name});

  $res = PHP::Decode::Op::array_is_const($parser, $arr1->{name});

  my $num = PHP::Decode::Op::to_num('-6');

=head1 DESCRIPTION

The PHP::Decode::Op Module implements php operators on PHP::Decode::Parser objects

=head1 METHODS

=head2 binary

  $res = PHP::Decode::Op::binary($parser, $val1, $op, $val2);

Exec binary Operator.

=head2 unary

  $res = PHP::Decode::Op::unary($parser, $op, $val);

Exec unary Operator.

=head2 array_compare

  $res = PHP::Decode::Op::array_compare($parser, $array1, $array2, $check_types);

Compare two arrays.

=head1 SEE ALSO

Requires the L<PHP::Decode::Parser> & L<PHP::Decode::Array> Module.

=head1 AUTHORS

Barnim Dzwillo @ Strato AG

=cut
