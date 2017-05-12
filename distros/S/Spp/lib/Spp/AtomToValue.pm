package Spp::AtomToValue;

=head1 NAME

Spp::AtomToValue - Spp Atom to Perl value

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Spp::AtomToValue;

    my $foo = Spp::AtomToValue->new();
    ...

=head1 EXPORT

atom_to_value atoms_to_value

=cut

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(atom_to_value atoms_to_value);

use 5.020;
use Carp qw(croak);
use experimental qw(switch autoderef);
use Spp::Tools;

## reflect Spp atom to Perl value
sub atom_to_value {
  my $atom = shift;
  my ($type, $value) = @{ $atom };
  given ($type) {
    when ('int')   { $value }
    when ('str')   { $value }
    when ('array') { atoms_to_value($value) }
    when ('hash')  { hash_to_value($value)  }
    default { error("Could not get atom type: $type value") }
  }
}

sub atoms_to_value {
  my $atoms = shift;
  my $values = [];
  for my $atom (values $atoms) {
    push $values, atom_to_value($atom);
  }
  return $values;
}

sub hash_to_value {
  my $spp_hash = shift;
  my $hash_value = {};
  for my $pair (values $spp_hash) {
    my ($key, $value) = @{ $pair };
    if (is_spp_str($key)) {
      my $key_value  = atom_to_value($key);
      my $value_value = atom_to_value($value);
      $hash_value->{$key_value} = $value_value;
    } else {
      error("Spp only support str key hash to value");
    }
  }
  return $hash_value;
}

=head1 AUTHOR

Michael Song, C<< <10435916 at qq.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-spp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spp::AtomToValue

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

1; # End of Spp::AtomToValue
