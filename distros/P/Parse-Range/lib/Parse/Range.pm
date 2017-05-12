package Parse::Range;

our $VERSION = 0.96;

use strict;
use warnings;
use List::MoreUtils qw(uniq first_index);

use base qw(Exporter);

our @EXPORT_OK = qw(parse_range);

sub parse_range {
	my $in = join(',', @_);
	my $level = 0;
	my @range = ('');
	foreach my $char (split('', $in)) {
		$level++ if($char eq '(');
		$range[-1] .= $char if($char !~ /,/ || $char =~ /[\(\),]/ && $level != 0);
		$level-- if($char eq ')');
		push(@range, '') if($level == 0 && $char eq ',');
	}
	if($level != 0) {
		return $level < 0 ? parse_range(('(' x -$level) . $in) : parse_range($in . ')' x $level);
	}
	my @out = ();
	foreach my $range (@range) {
		$range =~ s/\s//gsm;
		my @except = ();
		if($range =~ /^\^(.*)$/) {
			push(@except, _parse_range($1));
		} else {
			push(@out, _parse_range($range));
		}
		@out = uniq(@out);
		foreach my $e (@except) { 
		 my $idx = first_index { $_ eq $e } @out;
		splice(@out, $idx, 1) if($idx != -1);
		}
	}
	return @out;
}

sub _parse_range {
	my $range = shift;
	if($range =~ /^(-?\d+)\-(-?\d+)$/ || $range =~ /^(-?\d+)\)?\-\((-\d+)\)?$/) {
		my($from, $to) = ($1, $2);
		($to, $from) = ($from, $to) if($from > $to);
		return eval $from.'..'.$to;
	} elsif($range =~ /^(-?\d+)$/) {
		return $1;
	} elsif($range =~ /^\((.*)\)$/) {
		return parse_range($1);
	} else { warn 'non-numeric range: \'' . $range. '\''; return () }
}

1;

__END__

=head1 NAME

Parse::Range - Parse text range definitions

=head1 SYNOPSIS

  use Parse::Range qw(parse_range);
  
  my @range = parse_range('1,3,5-7');
  # @range = qw(1 3 5 6 7);
  
  @range = parse_range('1-7,^2,^4');
  # @range = qw(1 3 5 6 7);
  
  @range = parse_range('1-7,^(2,4)');
  # @range = qw(1 3 5 6 7);
  
=head1 DESCRIPTION

This module parses range definitions and returns an array of individual numbers. 

It is intended to be used in command line applications where the user should be able to select
one or more options from a list or in any other application where such a situation occurs.

=head1 FUNCTIONS

By default no functions are exported.

=head2 parse_range

The one and only function this module provides. It accepts one or more strings which are 
concatenated by a comma. Ranges, blocks and numbers are expected to be seperated
by comma.

Now the parsing takes place. Strings can be nested to any depth using parentheses. 
Not matching parentheses are being repaired if possible.
Ranges can be expressed using the minus sign C<->. Use C<^> to exclude numbers or ranges from the current range. 
Negative numbers are expressed using the minus sign. This is a valid expression C<-4--2> which will
result in an array from minus four to minus two. C<(-4)-(-2)> works as well.
The string is parsed from left to right.


=head1 EXAMPLES

  parse_range('1-7,^(2,4)');
  
This will first add the numbers from one to seven to the range and then exclude the numbers 
two and 4. The result is C<1 3 5 6 7>.

  parse_range('^(2,4),1-7');

This is the same example as above except that it is the other way round. The exception of two and four
is a noop in this case because there is no range from which to exclude the numbers. The result is
therefore C<1 2 3 4 5 6 7>.
 
   parse_range('1-9,^(5-9,^(8-9))');
 
This is a more advanced example. From a range from one to nine we exclude a block which consists
of a range from five to nine from which eight and nine are excluded.
The result is C<1 2 3 4 8 9>.
 

=head1 AUTHOR

Moritz Onken, C<< <onken at netcubed.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Parse-Range at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-Range>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::Range


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Range>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-Range>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-Range>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-Range/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Moritz Onken, all rights reserved.

=cut

  

