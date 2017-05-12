package Spreadsheet::HTML::Engine;
use strict;
use warnings FATAL => 'all';

eval "use Spreadsheet::Engine";
our $NO_ENGINE = $@;

sub _apply {
    return $_[0] if $NO_ENGINE;
    my ($data,$formula) = @_;
    $formula = [ $formula ] unless ref $formula;
    my $sheet = _import( $data );
    $sheet->execute( $_ ) for @$formula;
    $sheet->recalc;
    return _export( $sheet );
}

sub _import {
    my $data = shift;
    my $sheet = Spreadsheet::Engine->new;
    for my $row (0 .. $#$data)  {
        for my $col (0 .. $#{ $data->[$row] }) {
            my $key = Spreadsheet::Engine::Sheet::number_to_col( $col + 1 ) . ( $row + 1 );
            my $val = $data->[$row][$col];
            my $type = $val =~ /\D/ ? 'v' : 'n';
            $sheet->execute( "set $key value $type $val" );
        }
    }
    return $sheet;
}

sub _export {
    my $sheet = shift;
    my @data;
    for my $row (0 .. $sheet->raw->{sheetattribs}{lastrow} - 1) {
        my @tmp;
        for my $col (0 .. $sheet->raw->{sheetattribs}{lastcol} - 1) {
            my $key = Spreadsheet::Engine::Sheet::number_to_col( $col + 1 ) . ( $row + 1 );
            push @tmp, $sheet->raw->{datavalues}{$key};
        }
        push @data, [@tmp];
        @tmp = ();
    }
    return \@data;
}

=head1 NAME

Spreadsheet::HTML::Engine - interface to Spreadsheet::Engine 

=head1 DESCRIPTION

This is a container for L<Spreadsheet::HTML>. This
package is not meant to be directly used. Instead,
use the Spreadsheet::HTML interface:

  use Spreadsheet::HTML;
  my $generator = Spreadsheet::HTML->new( apply => 'set B6 formula SUM(B2:B5)' );
  print $generator->generate();

  # or
  use Spreadsheet::HTML qw( generate );
  print generate( apply => 'set B6 formula SUM(B2:B5)' );

=head1 SEE ALSO

=over 4

=item * L<Spreadsheet::HTML>

The interface for this functionality.

=item * L<Spreadsheet::Engine>

The engine that provides this functionality.

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jeff Anderson.

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

1;
