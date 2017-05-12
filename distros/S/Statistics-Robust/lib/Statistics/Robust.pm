package Statistics::Robust;

use warnings;
use strict;

use base 'Exporter';

sub
_min
{
 my($x,$y) = @_;

 if( $x <= $y )
 {
  return $x; 
 }
 else
 {
  return $y;
 }
}

sub
_sum
{
 my($x) = @_;

 my $sum = 0;
 foreach my $val (@$x)
 {
  $sum += $val;
 }

 return $sum;
}

1;

=head1 NAME

Statistics::Robust - A Collection of Robust Statistical Methods

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

use Statistics::Robust;

=head1 AUTHOR

Walter Szeliga, C<< <walter at geology.cwu.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-robust at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Robust>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Robust


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Robust>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Robust>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Robust>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Robust>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Walter Szeliga, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Statistics::Robust
