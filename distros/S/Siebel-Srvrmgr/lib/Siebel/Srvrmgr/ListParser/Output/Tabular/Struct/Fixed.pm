package Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Fixed;
use Moose 2.0401;
use namespace::autoclean 0.13;
extends 'Siebel::Srvrmgr::ListParser::Output::Tabular::Struct';
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Fixed - subclass to parse fixed width output from srvrmgr

=head1 DESCRIPTION

This class is a subclass of L<Siebel::Srvrmgr::ListParser::Output::Tabular::Struct> to parse fixed width output from C<srvrmgr>.

=head1 ATTRIBUTES

=head2 fields_pattern

This is a read-only attribute which is defined internally by invoking the C<define_fields_pattern> method during parsing execution.

It is a string representing the pattern of the fields to be used with C<unpack> function.

=cut

has fields_pattern => (
    is     => 'ro',
    isa    => 'Str',
    reader => 'get_fields_pattern',
    writer => '_set_fields_pattern'
);

sub _build_col_sep {
    my $self = shift;
    $self->_set_col_sep('\s{2,}');
}

=pod

=head1 METHODS

=head2 define_fields_pattern

Overrided from the parent class.

Based on the first two rows of a C<srvrmgr> output with fixed width format, it will define
the fields pattern to be used with C<unpack> to retrieve the fields values.

Expects the "------------" line under the header with the fields names.

=cut

sub define_fields_pattern {
    my ( $self, $line ) = @_;
    my $separator = $self->get_col_sep();
    my $comp_sep  = qr/$separator/;

    # :TODO:30-12-2013:: some logging would ne nice here
    if ( $line =~ $comp_sep ) {
        my @columns = split( /$separator/, $line );
        my $pattern;

        foreach my $column (@columns) {
# :WARNING   :09/05/2013 12:19:37:: + 2 because of the spaces after the "---" that will be trimmed
            $pattern .= 'A' . ( length($column) + 2 );
        }

        $self->_set_fields_pattern($pattern);
        return 1;

    }
    else {
        return 0;
    }
}

=pod

=head2 get_fields

Overrided from parent class.

Returns the fields values as an array reference.

Expects a string with fields values to be parsed.

=cut

sub get_fields {
    my ( $self, $line ) = @_;

    if ( defined( $self->get_fields_pattern() ) ) {
        my @fields = unpack( $self->get_fields_pattern(), $line );
        return \@fields;
    }
    else {
        confess
'cannot procede without being able to define the fields pattern for parsing: check if command output configuration is as expected by the parsing class';
    }
}

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular>

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular::Struct>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see L<http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;
