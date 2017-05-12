package Siebel::Srvrmgr::ListParser::Output::ToString;

use warnings;
use strict;
use Moose::Role 2.1604;
use Carp;

our $VERSION = '0.29'; # VERSION

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::ToString - Moose role to "stringfy" objects

=head1 SYNOPSIS

    with 'Siebel::Srvrmgr::ListParser::Output::ToString';

=head1 DESCRIPTION

This role will use some introspection to enable a object to return all it's attributes as a string.

=head1 METHODS

=head2 to_string_header

Returns a string with all attributes values, ordered alphabetically by their respective attribute names, concatenated with a single character.

Expects as parameter a single character to be used as field separator.

=cut

sub to_string_header {
    my ( $self, $separator ) = @_;
    confess 'separator must be a single character'
      unless ( ( defined($separator) ) and ( $separator =~ /^.$/ ) );
    my $meta              = $self->meta;
    my $attribs_names_ref = $self->_to_string;
    return join( $separator, @{$attribs_names_ref} );
}

=head2 to_string

Returns a string with all attributes values, ordered alphabetically by their respective attribute names, concatenated with a single character.

Expects as parameter a single character to be used as field separator.

=cut

sub to_string {
    my ( $self, $separator ) = @_;
    confess 'separator must be a single character'
      unless ( ( defined($separator) ) and ( $separator =~ /^.$/ ) );
    my $meta              = $self->meta;
    my $attribs_names_ref = $self->_to_string;
    my @values;

    foreach my $name ( @{$attribs_names_ref} ) {
        my $attrib = $meta->get_attribute($name);
        my $reader = $attrib->get_read_method;
        push( @values, ( defined( $self->$reader ) ? $self->$reader : '' ) );
    }

    return join( $separator, @values );
}

sub _to_string {
    my $self = shift;
    my $meta = $self->meta;
    my @attribs = sort( $meta->get_attribute_list );
    return \@attribs;
}

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

1;
