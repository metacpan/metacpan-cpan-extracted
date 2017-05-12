package Set::Intersection;

use warnings;
use strict;

=head1 NAME

Set::Intersection - provides an API to get intersection (of set theory) of ARRAYs.

=head1 VERSION

Version 0.04;

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

  use Set::Intersection;

  my @arr1 = qw/3 1 4 1 5 9/;
  my @arr2 = qw/1 7 3 2 0 5/;
  my @intersection = get_intersection(\@arr1, \@arr2);
  # got (1, 3, 5) in @intersection

=head1 EXPORT

get_intersection

=cut

require Exporter;
our @ISA = qw/Exporter/;

our @EXPORT = qw/get_intersection/;

=head1 FUNCTIONS

=head2 C<get_intersection()>

    get_intersection([\%options,] [\@ARRAY[, \@ARRAY[, ...]]]);

Returns intersection set (as LIST) of all ARRAYs.

=over 4

=item *

The result LIST is uniqued and unordered.

=item *

If no ARRAYs are passed, the result LIST is empty.

=item *

If only one ARRAY is passed, the result LIST is same as that passed. (In this
case, elements won't be uniqued nor will the order bechanged.)

=item *

If you have C<undef> in any LIST, you'll be warned.

=back

=head3 C<%options>

    -preordered => BOOLEAN

To reduce calculation time, C<get_intersection()> sorts ARRAYs
by their length before calculating intersections.

This option tells that order of ARRAYs are well done,
and calculation of intersection will be based on left most ARRAY.

=cut

my %_default_opts = (
  -preordered => 0,
);

sub get_intersection
{
  my %opts;
  if ( ref($_[0]) =~ m{^HASH} ) {
    %opts = (%_default_opts, %{$_[0]});
    shift;
  }

  my @arrs = @_;
  return () if !@arrs;
  return @{$arrs[0]} if @arrs == 1;

  @arrs = sort { @$a <=> @$b } @arrs if !$opts{-preordered};

  my $head = shift @arrs;

  _intersection($head, @arrs);
}

sub _intersection
{
  my ($head, @left) = @_;

  my %h = map { $_ => undef } @$head;
  for my $l ( @left ) {
    %h = map { $_ => undef } grep { exists $h{$_} } @$l;
  }
  keys %h;
}

=head1 SEE ALSO

List::Compare, Set::Object

=head1 AUTHOR

turugina, C<< <turugina at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-list-intersection at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Set-Intersection>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Set::Intersection

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Set-Intersection>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Set-Intersection>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Set-Intersection>

=item * Search CPAN

L<http://search.cpan.org/dist/Set-Intersection/>

or

L<https://metacpan.org/pod/Set::Intersection>

=back


=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 turugina, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Set::Intersection

