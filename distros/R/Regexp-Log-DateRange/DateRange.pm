# $Id: DateRange.pm,v 1.2 2005/04/19 15:33:02 dk Exp $

package Regexp::Log::DateRange;
use strict;
use vars qw($VERSION %templates);

$VERSION = '0.02';

%templates = ( 
	syslog => [
		[ '\\s+', 1, 12, [ qw(. jan feb mar apr may jun jul aug sep oct nov dec)]],
		[ '\\s+', 1, 31, undef, '0?'],
		[ '\\:', 0, 23, undef, '0?' ],
		[ '\\:', 0, 59, undef, '0?' ],
	],
);

sub new
{
	my ( $class, $template, $date1, $date2) = @_;

	unless ( ref($template)) {
		die "Template '$template' doesn't exist\n"
			unless $templates{$template};
		$template = $templates{$template};
	}

	# some sanity checks
	my $n = @$template;
	die "template is empty\n" unless $n;
	die "date [@$date1] is not valid\n" unless $n == @$date1;
	die "date [@$date2] is not valid\n" unless $n == @$date2;

	for ( my $i = 0; $i < $n; $i++) {
		next if $date1->[$i] == $date2->[$i];
		last if $date1->[$i] < $date2->[$i];
		( $date2, $date1) = ( $date1, $date2);
		last;
	}
	
	# build 'alignment' vectors; for example, for the right range,
	# 2499 would give 0111, for the left, 1150 would give 0001
	my ( @w1, @w2);
	my ( $last1, $last2) = ( 1, 1);
	for ( my $i = $#$date1; $i > 0; $i--) {
		$w1[$i-1] = $last1 & (( $date1->[$i] == $template->[$i]->[1] ) ? 1 : 0);
		$w2[$i-1] = $last2 & (( $date2->[$i] == $template->[$i]->[2] ) ? 1 : 0);
		$last1 = $w1[$i-1];
		$last2 = $w2[$i-1];
	}
	my $tree = range2tree( $template, $date1, $date2, \@w1, \@w2, 0);
	return tree2re( $template, $tree, 0);
}

# 1,2,3 => (?:1|2|3)
sub re_group
{
	if ( 0 == @_) {
		return '';
	} elsif ( 1 == @_) {
		return $_[0];
	} else {
		return '(?:'.join('|', @_).')';
	}
}

# 8 .. 13 => (?:0?8|9)|1[0123]
sub match_range
{
	my ( $from, $to, $digit_prefix) = @_;

	my @tens;
	for my $x ( $from .. $to) {
		my $ten = int( $x / 10);
		unless ( defined $tens[$ten]) {
			my $mod = int( $x % 10);
			$tens[$ten] = [ $mod, $mod];
		} else {
			$tens[$ten]->[1]++;
		}
	}
	
	my @q;
	my $last_range = '';
	my @branges;
	for ( my $i = 0; $i < @tens; $i++) {
		next unless defined $tens[$i];
		my $range = ( $tens[$i]->[0] == $tens[$i]->[1] ) ? 
			$tens[$i]->[0] : 
			"[$tens[$i]->[0]-$tens[$i]->[1]]";
		if ( $i) {
			if ( $range eq $last_range) {
				push @branges, $i;
				$q[-1] = "[$branges[0]-$branges[-1]]$range";
			} else {
				$last_range = $range;
				push @q, "$i$range";
				@branges = ($i);
			}
		} else {
			push @q, "$digit_prefix$range";
		}
	}

	
	my $ret = re_group(@q);
	$ret =~ s/\[0-9\]/\\d/g;
	return $ret;
}

# Convert date range into a max-3-branch tree, where each branch is an alternative
# expansion rule, and is either a range or a value leaf; the value leaves can
# point deeper. For example, if matching date range 1 Apr - 3 June, the corresponding 
# structure would be something like
#
#   range (Apr-May)
#   value (June, 
#         range(1-3)
#   )
#
sub range2tree
{
	my ( $template, $d1, $d2, $w1, $w2, $depth) = @_;

	my ( $i, $left, $center, $right);
	my ( $r1, $r2) = ( $d1-> [$depth], $d2-> [$depth]);

#	print +('  ' x $depth), "$depth: $r1 $r2\n";

	if ( 
		( $w1->[$depth] and $w2->[$depth])
		or $depth >= $#$d1
	) {
		$center = {
			range => [ $r1 , $r2 ],
		};
#		print +('  ' x $depth), "T\n";
	} elsif ( $r1 < $r2) {
		my ( @d1, @d2);
		# if, say, in '123' vs '145', '2' < '4' where depth = 1,
		# then d1 = 129 and d2 = 140
		for ( $i = 0; $i <= $depth; $i++) {
			$d1[$i] = $d1->[$i];
			$d2[$i] = $d2->[$i];
		}
		for ( $i = $depth + 1; $i < @$d1; $i++) {
			$d1[$i] = $template-> [$i]->[2];
			$d2[$i] = $template-> [$i]->[1];
		}
		if ( $w1->[$depth]) {
			$r1--;
#			print +('  ' x $depth), "LT\n";
		} else {
#			print +('  ' x $depth), "$depth L > @$d1 : @d1 [@$w1]\n";
			$left = {
				next  => range2tree( $template, $d1, \@d1, $w1, [(1) x @d1], $depth + 1),
				value => $r1,
			};
#			print +('  ' x $depth), "$depth L <\n";
		}

		if ( $w2->[$depth]) {
#			print +('  ' x $depth), "RT\n";
			$r2++;
		} else {
#			print +('  ' x $depth), "$depth R > @d2 : @$d2 [@$w2]\n";
			$right = {
				next  => range2tree( $template, \@d2, $d2, [(1) x @d2], $w2, $depth + 1),
				value => $r2,
			};
#			print +('  ' x $depth), "$depth R <\n";
		}
		if ( $r1 + 1 < $r2) {
			$center = {
				range  => [ $r1 + 1 , $r2 - 1 ],
			};
#			print +('  ' x $depth), "$depth CT [ ", $r1+1, '  .. ', $r2-1, " ]\n";
		}
	} else {
		$center = {
			next  => range2tree( $template, $d1, $d2, $w1, $w2, $depth + 1),
			value => $r1,
		}
	}

	return [ 	
		$left ? $left : (), 
		$center ? $center : (), 
		$right ? $right : ()
	];
}

# converts a tree into a regexp
sub tree2re
{
	my ( $template, $tree, $depth) = @_;
	my @q;
	my $t = $template-> [$depth];
	for my $hash ( @$tree) {
		if ( exists $hash-> {value}) {
			my $v = $t->[3] ? 
				$t->[3]->[$hash->{value}] : 
				match_range( $hash->{value}, $hash->{value}, $t->[4]);
			push @q, $v .
				$t->[0] .
				tree2re( $template, $hash-> {next}, $depth + 1);
		} else {
			my $r = $t->[3] ? 
				re_group( map { $t->[3]->[$_] } 
					$hash-> {range}-> [0] .. $hash-> {range}-> [1] ) :
				match_range( @{$hash-> {range}}, $t->[4]);
			push @q, $r . $t->[0];
		}
	}

	return re_group(@q);
}

1;

__END__

=pod

=head1 NAME

Regexp::Log::DateRange - construct regexps for filtering log data by date range

=head1 SYNOPSIS

Code:

	use Regexp::Log::DateRange;
	my $rx = Regexp::Log::DateRange-> new('syslog', [qw(1 1 0 0)], [qw(3 18 13 59)]);
	print "Testing against $rx\n";
	$rx = qr/$rx/i;  # <-- note the 'i' qualifier
	for (
		'Feb  4 00:00:01',
		'May  4 00:00:01'
	) {
		print "Date '$_' ",  (m/$rx/ ? 'matched' : 'not matched'), "\n";
	}

Result:

	Testing against (?:(?:jan|feb)\s+|mar\s+(?:(?:0?[1-9]|1[0-7])\s+|18\s+(?:0?\d|1[0-3])\:))
	Date 'Feb  4 00:00:01' matched
	Date 'May  4 00:00:01' not matched

=head1 DESCRIPTION

The module was written as a hack, for the task at hand, to scan a log file and
account for the lines within a date range. The initial trivial implementation,
for the log file conducted by syslog

  Feb  4 00:00:01 moof postfix/smtpd[1138]: connect from localhost[127.0.0.1]
  Feb  4 00:00:01 moof postfix/smtpd[1138]: BED3B70625: client=localhost[127.0.0.1]

is as simple as it gets, where the line filtering condition would be written as

   /^(\w+)\s+(\d+)\s+(\d\d):(\d\d)/ and $months{lc $1} < $some_month and $2 < 15

and so on and so on, - you get the idea. That was considered not fun enough,
and instead this module was written to construct a regexp that would tell
whether a date is within a particular date range - and to do it fast, too. In
the example below it is explained how to construct something along the lines of

  (?:(?:jan|feb)\s+|mar\s+(?:(?:0?[1-9]|1[0-7])\s+|18\s+(?:0?\d|1[0-3])\:))

that matches a given date range within a single call.

=head1 USAGE

The module sees date range as two integer arrays, where each integer is a date 
order, such that 

    [ 4, 1, 12, 00 ]

is 1st of April, 12:00 ( thus, the format allows constructing various range regexps,
not necessarily date range regexps only). Two such date arrays and a
template that defines the order and intermediate matching code, are enough to
generate a regexp sufficient for arbitrary multi-order range matching.

First, we select the date range. Say, these will be January 1 and March 18,
13:59.  The module doesn't do the actual date vs date array conversion, one has
to do it by other means; here I'll simply code a magic date converter:

	my $date1 = [ qw(1 1 0 0) ]; # my_magic_date_converter( 'Jan 1');
	my $date2 = [ qw(3 18 13 59) ]; # my_magic_date_converter( 'Mar 18 13:59');

Second, we select a template describing how to the match log entries. The
module currently contains the only template, C<'syslog'>, that defines the date
array item ranges and the regexp codes between these:

	syslog => [
		[ '\\s+', 1, 12, [ qw(. jan feb mar apr may jun jul aug sep oct nov dec)]],
		[ '\\s+', 1, 31, undef, '0?'],
		[ '\\:', 0, 23, undef, '0?' ],
		[ '\\:', 0, 59, undef, '0?' ],
	],

which does basically mean that first entry defines months, so that the final regexp must
match months and then match C<\s+>, then days, in the range 1-31, then
spaces again, then hours and minutes. The module doesn't provide the seconds
entry, but it is trivial to construct a template with one (the date array must
contain 5 elements then).

Finally, to construct a regexp ( all code together ):
	
	use Regexp::Log::DateRange;
	my $rx = Regexp::Log::DateRange-> new('syslog', [qw(1 1 0 0)], [qw(3 18 13 59)]);
	print "Testing against $rx\n";
	$rx = qr/$rx/i;  # <-- note the 'i' qualifier
	for (
		'Feb  4 00:00:01',
		'May  4 00:00:01'
	) {
		print "Date '$_' ",  (m/$rx/ ? 'matched' : 'not matched'), "\n";
	}

And the result is

	Testing against (?:(?:jan|feb)\s+|mar\s+(?:(?:0?[1-9]|1[0-7])\s+|18\s+(?:0?\d|1[0-3])\:))
	Date 'Feb  4 00:00:01' matched
	Date 'May  4 00:00:01' not matched

If the first parameter of C<new> is not a template array, the template is
looked up in the list of the existing templates ( that way, the module can be
easily extended for other log formats ). The result of C<new> is a string, that
is to be interpolated by C<qr//i>  - note the B<i>, the months names in log
files come in all cases.

The resulting regexp cannot be used to match the date correctness; as can be
seen in the example, a line beginning with C<May> is discarded very quickly and
is not checked in full.  One can rather think of these regexps as two tests,
telling if both the date is correct AND the date is withing the given range.

=head1 EXTENSIBILITY

The code should be extensible enough for defining other kinds of log formats,
by defining the match template. It is not possible though to extend it for as 
to catch the date elements in C<$1>, C<$2>, etc. 

=head1 COPYRIGHT

Copyright (c) 2005 catpipe Systems ApS. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik <dk@catpipe.net>

=cut
