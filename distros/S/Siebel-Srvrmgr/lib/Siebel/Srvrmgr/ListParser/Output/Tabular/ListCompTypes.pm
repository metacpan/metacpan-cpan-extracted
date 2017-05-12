package Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompTypes;

use Moose 2.0401;
use namespace::autoclean 0.13;

extends 'Siebel::Srvrmgr::ListParser::Output::Tabular';
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompTypes - subclass to parse list comp types command

=cut


=pod

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output::Tabular> for examples.

=head1 DESCRIPTION

This subclass of L<Siebel::Srvrmgr::ListParser::Output::Tabular> parses the output of the command C<list comp types>.

This is the list configuration of the C<srvrmgr> expected by the module:

	srvrmgr> configure list comp type
		CT_NAME (76):  Component type name
		CT_RUNMODE (31):  Supported run mode
		CT_ALIAS (31):  Component type alias
		CT_DESC_TEXT (251):  Description of component type

If the configuration is not setup as this, the parsing will fail and the module may raise exceptions.

=head1 ATTRIBUTES

All from superclass.

=head1 METHODS

=head2 get_attribs

Returns the array reference stored in the C<types_attribs> attribute.

=head2 set_attribs

Sets the attribute C<types_attribs>. Expects an array reference as parameter.

=cut

sub _build_expected {

    my $self = shift;

    $self->_set_expected_fields(
        [ 'CT_NAME', 'CT_RUNMODE', 'CT_ALIAS', 'CT_DESC_TEXT' ] );

}

sub _consume_data {

    my $self       = shift;
    my $fields_ref = shift;
    my $parsed_ref = shift;

    my $ct_name = $fields_ref->[0];

    my $list_len = scalar( @{$fields_ref} );

    my $columns_ref = $self->get_expected_fields();

    confess "Could not retrieve the name of the fields"
      unless ( defined($columns_ref) );

    if ( @{$fields_ref} ) {

        for ( my $i = 0 ; $i < $list_len ; $i++ ) {

            $parsed_ref->{$ct_name}->{ $columns_ref->[$i] } =
              $fields_ref->[$i];

        }

        return 1;

    }
    else {

        return 0;

    }

}

=pod

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular>

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::ListParser::Output::ToString>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

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

no Moose;
__PACKAGE__->meta->make_immutable;
