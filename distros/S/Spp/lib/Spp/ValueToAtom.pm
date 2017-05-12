package Spp::ValueToAtom;

=head1 NAME

Spp::ValueToAtom - inflect Perl value to Spp atom.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

ValueToAtom module could inflect Perl data to Spp data:

    perl string => spp_str
    perl int    => spp_int
    perl array  => spp_array

Perhaps a little code snippet.

    use Spp::ValueToAtom qw(value_to_atom);

    my $spp_atom = ValueToAtom($host_value);

=head1 EXPORT

value_to_atom

=cut

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(value_to_atom);

use 5.020;
use Carp qw(croak);
use experimental qw(switch autoderef);

use Spp::Tools;

sub value_to_atom {
  my $value = shift;
  return ['int', $value] if is_int($value);
  return ['str', $value] if is_str($value);
  return array_to_atom($value) if is_array($value);
  return hash_to_atom($value)  if is_hash($value);
  error("Have not implement $value to Spp data");
}

sub values_to_atom {
  my $values = shift;
  my $atoms = [];
  for my $value (values $values) {
    push $atoms, value_to_atom($value);
  }
  return $atoms;
}

sub array_to_atom {
  my $array = shift;
  my $array_atoms = values_to_atom($array);
  return ['array', $array_atoms];
}

sub hash_to_atom {
  my $hash_value = shift;
  my $hash = [];
  for my $key (keys $hash_value) {
    my $value = $hash_value->{$key};
    push $hash, [['str', $key], value_to_atom($value)];
  }
  return ['hash', $hash];
}

=head1 AUTHOR

Michael Song, C<< <10435916 at qq.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-spp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spp::ValueToAtom

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Spp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spp>

=item * Search CPAN

L<http://search.cpan.org/dist/Spp/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Michael Song.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Spp::ValueToAtom
