package Term::ANSITable;

use 5.14.0;
use strict;
use warnings;
use Term::Size 'chars';

=head1 NAME

Term::ANSITable - Tool for drawing and redrawing tables on term!

=head1 VERSION

Version 0.010100

=cut

our $VERSION = '0.010100';

=head1 SUBROUTINES/METHODS

=head2 new

Constructor

=cut

sub new {
    my $class = shift;
    require Text::ANSITable;
    require Term::Cap;
    my $self = {
        _table    => Text::ANSITable->new(@_),
        _terminal => Tgetent Term::Cap { TERM => 'cygwin', OSPEED => 9600 },
    };
    $self->{_terminal}->Trequire("up");    # move cursor up
    $self->{_sig_up} = $self->{_terminal}->Tputs("up");
    $self->{_drawer} = Term::ANSITable::Draw->new;

    bless $self, $class;
    return $self;
}

=head2 table

Getter/Setter for internal hash key _table.

=cut

sub table {
    return $_[0]->{_table} unless $_[1];
    $_[0]->{_table} = $_[1];
    return $_[0]->{_table};
}

=head2 rows

Get or set rows from Text::ANSITable object.

=cut

sub rows {
    return $_[0]->table->{rows} unless $_[1];
    $_[0]->table->{rows} = $_[1];
    return $_[0]->table->{rows};
}

=head2 drawer

Get or set a custom drawer instead of print.

=cut

sub drawer {
    return $_[0]->{_drawer} unless $_[1];
    $_[0]->{_drawer} = $_[1];
    return $_[0]->{_drawer};
}

=head2 add_row

Add row to Text::ANSITable object.

=cut

sub add_row {
    my ( $self, $row ) = @_;
    $self->table->add_row($row);
    return $self;
}

=head2 draw($prepare2refresh)

Draw table on term and go back to first line of row for redrawing

=over 4

=item

prepare2refresh: if is set term will go back to the first line
and it will be overwritten on any print afer that.

=cut

sub draw {
    my ( $self, $prepare4refresh ) = @_;
    my @lines = split "\n", $self->table->draw;
    my $chars = chars * STDOUT { IO };
    foreach (@lines) {
        my $length = length($_);
        $self->drawer->print( $_, ( $chars > $length ) ? '' x ( $chars - $length ) : '', $/ );
    }
    return if ( !$prepare4refresh );
    $self->drawer->print( $self->{_sig_up} ) foreach ( 1 .. scalar @lines );
}

=back

=head2 refresh_table

Grep all empty rows from table.

=cut

sub refresh_table {
    my ($self) = @_;
    $self->rows( [ grep { @$_ } @{ $self->rows } ] );
    return $self;
}

=head2 Term::ANSITable::Draw

Internal drawing package

=cut

package Term::ANSITable::Draw;

=head2 new

Constructor

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 new

Simple print to stdout.

=cut

sub print {
    my $self = shift;
    print @_;
}

1;    # End of Term::ANSITable

__END__

=head1 SYNOPSIS

    require Term::ANSITable;
    my $at = Term::ANSITable->new( columns => [ 'Type', 'Value' ] );

    my $t      = 0;
    my $hour   = [ 'Hour', ( $t / 3600 ) ];
    my $minute = [ 'Minute', ( ( $t / 60 ) % 60 ) ];
    my $second = [ 'Second', ( $t % 60 ) ];
    $at->add_row($hour)->add_row($minute)->add_row($second);

    while (1) {
        $hour->[1]   = ( $t / 3600 );
        $minute->[1] = ( ( $t / 60 ) % 60 );
        $second->[1] = ( $t % 60 );
        $at->refresh_table->draw();
        sleep 2;
        $t += 2;
    }

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-term-ansitable at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Term-ANSITable>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::ANSITable


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Term-ANSITable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Term-ANSITable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Term-ANSITable>

=item * Search CPAN

L<http://search.cpan.org/dist/Term-ANSITable/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Mario Zieschang.

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
