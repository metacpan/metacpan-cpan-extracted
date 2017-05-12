package Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef - subclass to parse component definitions

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;

extends 'Siebel::Srvrmgr::ListParser::Output::Tabular';
our $VERSION = '0.29'; # VERSION

=pod

=head1 SYNOPSIS

	use Siebel::Srvrmgr::ListParser::Output::ListCompDef;

	my $comp_defs = Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef->new({});

=head1 DESCRIPTION

This subclass of L<SiebeL::Srvrmgr::ListParser::Output::Tabular> parses the output of the command C<list comp def COMPONENT_NAME>.

The order of the fields and their configuration must follow the pattern defined below:

	srvrmgr> configure list comp def
		CC_NAME (76):  Component name
		CT_NAME (76):  Component type name
		CC_RUNMODE (31):  Component run mode (enum)
		CC_ALIAS (31):  Component alias
		CC_DISP_ENABLE_ST (61):   Display enablement state (translatable)
		CC_DESC_TEXT (115):   Component description
		CG_NAME (76):  Component group
		CG_ALIAS (31):  Component Group Alias
		CC_INCARN_NO (23):  Incarnation Number

=head1 ATTRIBUTES

All attributes of L<SiebeL::Srvrmgr::ListParser::Output::Tabular>.

=head1 METHODS

All methods of L<SiebeL::Srvrmgr::ListParser::Output::Tabular> plus the ones explaned below.

=head2 get_comp_defs

Returns the content of C<comp_params> attribute.

=head2 set_comp_defs

Set the content of the C<comp_defs> attribute. Expects an array reference as parameter.

=head2 parse

Parses the content of C<raw_data> attribute, setting the result on C<parsed_data> attribute.

The contents of C<raw_data> is changed to an empty array reference at the end of the process.

It raises an exception when the parser is not able to define the C<fields_pattern> attribute.

=cut

sub _build_expected {

    my $self = shift;

    $self->_set_expected_fields(
        [
            'CC_NAME',           'CT_NAME',
            'CC_RUNMODE',        'CC_ALIAS',
            'CC_DISP_ENABLE_ST', 'CC_DESC_TEXT',
            'CG_NAME',           'CG_ALIAS',
            'CC_INCARN_NO'
        ]
    );

}

sub _consume_data {

    my $self       = shift;
    my $fields_ref = shift;
    my $parsed_ref = shift;

    my $cc_name = $fields_ref->[0];

    my $list_len = scalar( @{$fields_ref} );

    my $columns_ref = $self->get_expected_fields();

    die "Cannot continue without defining fields names"
      unless ( defined($columns_ref) );

    if ( @{$fields_ref} ) {

        for ( my $i = 0 ; $i < $list_len ; $i++ ) {

            $parsed_ref->{$cc_name}->{ $columns_ref->[$i] } =
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

__PACKAGE__->meta->make_immutable;

1;
