package Number::Compare::Date;
use Number::Compare;
use base qw(Number::Compare);
use Date::Parse;

use strict;
#use warnings;
use Carp qw(croak);

use vars qw($VERSION);
$VERSION = "0.02";

=head1 NAME

Number::Compare::Date - Like Number::Compare, but for epoch seconds

=head1 SYNOPSIS

  use Number::Compare::Date;

  my $y2k = Number::Compare::Date->new(">=2000-01-01");

  if ($y2k->(time))
    { print "Run for the hills, the y2k bug's gonna eat you " }

=head1 DESCRIPTION

A simple extension to Number::Compare that allows you to compare
dates against numbers (which should be epoch seconds.)  The value
that is compared can either be epoch seconds:

  my $perl583 = Number::Compare::Date->new("<1072915199");

Or it can be anything Date::Parse can recognise:

  my $perl583 = Number::Compare->new('<Wed, 31 Dec 2003 23:59:59');

If you don't use a comparison operator (C<< < >>, C<< <= >>, C<< >= >>
or C<< > >>), then the module will check if the date is equal.

See L<Date::Parse> for more formats.

=cut

sub parse_to_perl
{
  shift;
  my $test = shift;

  # get the test and the date bit separated
  my ($comparison, $target) =
  $test =~ m{^
	     ([<>]=?)?   # comparison
	     (.*?)       # value
	     $}ix
    or croak "don't understand '$test' as a test";

  # check that the comparison is defined
  $comparison ||= "==";

  # check if the target is all digits
  unless ($target =~ m/^\d+$/)
    { $target = str2time($target) }

  return "$comparison $target"
}

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copyright Profero 2003.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

Doesn't cope with anything outside the epoch range on your
machine.  Isn't DateTime compatible.

Bugs should be reported to the open source development team
at Profero via the CPAN RT system.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Number::Compare::Date>.

=head1 SEE ALSO

L<Date::Parse>, L<Number::Compare>

=cut

1;
