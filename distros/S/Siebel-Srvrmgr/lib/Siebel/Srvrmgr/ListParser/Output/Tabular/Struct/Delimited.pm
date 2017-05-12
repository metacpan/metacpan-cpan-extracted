package Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Delimited;

use Moose 2.0401;
use Carp;
use namespace::autoclean 0.13;

extends 'Siebel::Srvrmgr::ListParser::Output::Tabular::Struct';
our $VERSION = '0.29'; # VERSION

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Delimited - subclasses to parse delimited output from srvrmgr

=head1 DESCRIPTION

This class is a subclass of L<Siebel::Srvrmgr::ListParser::Output::Tabular::Struct> to parse output from C<srvrmgr> that
is created with a field delimiter character.

=head1 ATTRIBUTES

=head2 trimmer

A code reference to remove additional spaces from the fields attributes data.

It is created automatically by a L<Moose> builder.

=cut

has trimmer => (
    is      => 'ro',
    isa     => 'CodeRef',
    reader  => 'get_trimmer',
    builder => '_build_trimmer'
);

 # :WORKAROUND:01-01-2014 18:42:35:: could not user super() because
 # it was using a "default" value after calling _set_header_regex
override '_build_header_regex' => sub {

    my $self = shift;

    my $new_sep = '(\s+)?' . $self->get_col_sep();

    $self->_set_header_regex( join( $new_sep, @{ $self->get_header_cols() } ) );

};

# :WORKAROUND:01-01-2014 17:43:39:: used closure to compile the regex only once
sub _build_trimmer {

    my $r_spaces = qr/\s+$/;

    return sub {

        my $values_ref = shift;

        for ( my $i = 0 ; $i <= $#{$values_ref} ; $i++ ) {

            $values_ref->[$i] =~ s/$r_spaces//;

        }

        return 1;

      }

}

=pod

=head2 get_fields

Overrided method from parent class.

Expects a string as parameter and returns a array reference with the fields values extracted.

=cut

override 'get_fields' => sub {

    my $self = shift;
    my $line = shift;

    my $fields_ref = $self->split_fields($line);

    $self->get_trimmer()->($fields_ref);

    return $fields_ref;

};

=pod

=head2 BUILD

This L<Moose> BUILD implementation does some additional validations during object creation
and also escapes the field delimiter character to be used in regular expressions.

=cut

sub BUILD {

    my $self = shift;
    my $args = shift;

    confess 'col_sep is a required attribute for ' . __PACKAGE__ . ' instances'
      unless ( defined( $args->{col_sep} ) );

    my $sep = $self->get_col_sep();

    #escape the char to be used in a regex
    $self->_set_col_sep( '\\' . $sep );

}

=pod

=head2 define_fields_pattern

Method overrided from the superclass.

Since this classes doesn't use the concept of "fields pattern" for parsing, 
it simply returns C<true>, making this class compatible with parent class interface.

=cut

sub define_fields_pattern {

    return 1;

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
