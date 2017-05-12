package Siebel::Srvrmgr::ListParser::Output::Tabular;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Tabular - base class for all command outputs that have a tabular form

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;
use Carp qw(cluck);
use Siebel::Srvrmgr::Regexes qw(ROWS_RETURNED);
use Siebel::Srvrmgr::Types;
use Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Fixed;
use Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Delimited;

extends 'Siebel::Srvrmgr::ListParser::Output';
with 'Siebel::Srvrmgr::ListParser::Output::ToString';
our $VERSION = '0.29'; # VERSION

=head1 SYNOPSIS

This is a base class, look for implementations of subclasses for examples.

=head1 DESCRIPTION

This class is a base class for all classes that parses output that have a tabular form (almost all of them).

All those outputs have a header with the columns names and the columns with the data. The "columns" are defined by a single character to separate them or by fixed width.

It have common attributes and methods for parsing different commands output.

This class extends L<Siebel::Srvrmgr::ListParser::Output> and applies the Moose Role L<Siebel::Srvrmgr::ListParser::Output::ToString>.

=head1 ATTRIBUTES

=head2 structure_type

Identifies which subtype of output a instance is. See L<Siebel::Srvrmgr::Types>, C<OutputTabularType> for details.

It is a read-only, required attribute during object creation.

=cut

has structure_type => (
    is       => 'ro',
    isa      => 'OutputTabularType',
    reader   => 'get_type',
    required => 1
);

=head2 col_sep

The column/field separator in the tabular output, if any. Used to parse the data into columns.

It is a single character (see L<Siebel::Srvrmgr::Types>, C<Chr>) and is a read-only, required attribute during object creation.

=cut

has col_sep => (
    is     => 'ro',
    isa    => 'Chr',
    reader => 'get_col_sep'
);

=head2 expected_fields

An array reference with the fields names expected by a subclass.

It is used for validation and parsing of the output. If the output doesn't have the same sequence of fields names, 
an exception will be raised.

It is a read-only, required attribute during object creation.

=cut

has expected_fields => (
    is      => 'ro',
    isa     => 'ArrayRef',
    reader  => 'get_expected_fields',
    writer  => '_set_expected_fields',
    builder => '_build_expected',
    lazy    => 1
);

=head2 known_types

The two known types of tabular output, by default:

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Fixed>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Delimited>

=back

Unless you're going to subclass this class you won't need to know more than that.

=cut

has known_types => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    reader  => 'get_known_types',
    default => sub {
        {
            fixed =>
              'Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Fixed',
            delimited =>
              'Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Delimited'
        };
    }
);

=head2 found_header

A boolean indicating if the header was located in the command output.

Returns true or false depending on it. By default is false.

=cut

has found_header => (
    is      => 'ro',
    isa     => 'Bool',
    reader  => 'found_header',
    writer  => '_set_found_header',
    default => 0
);

=head1 METHODS

=head2 get_type

Getter for C<structure_type> attribute.

=head2 get_col_sep

Getter for C<col_sep> attribute.

=head2 get_expected_fields

Getter for C<expected_fields> attribute.

=head2 found_header

Getter for C<found_header> attribute.

=cut

sub _build_expected {

    confess
'_build_expected must be overrided by subclasses of Siebel::Srvrmgr::Output::Tabular';

}

sub _consume_data {

    confess
'_consume_data must be overrided by subclasses of Siebel::Srvrmgr::ListParser::Output::Tabular';

}

=head2 parse

The method that parses the content of C<raw_data> attribute.

This method expects a header in the file, so all subclasses of this class.

=cut

override 'parse' => sub {

    my $self = shift;

    my $data_ref = $self->get_raw_data();

    confess 'Invalid data to parse'
      unless ( ( ( ref($data_ref) ) eq 'ARRAY' )
        and ( scalar( @{$data_ref} ) ) );

# cleaning up, state machine should not handle the end of response from a list command
    while (
        ( scalar( @{$data_ref} ) > 0 )
        and (  ( $data_ref->[ $#{$data_ref} ] eq '' )
            or ( $data_ref->[ $#{$data_ref} ] =~ ROWS_RETURNED ) )
      )
    {

        pop( @{$data_ref} );

    }

    confess 'Raw data became invalid after initial cleanup'
      unless ( @{$data_ref} );

    my $struct;

  SWITCH: {

        if ( ( $self->get_type eq 'delimited' ) and $self->get_col_sep() ) {

            $struct = $self->get_known_types()->{ $self->get_type() }->new(
                {
                    header_cols => $self->get_expected_fields(),
                    col_sep     => $self->get_col_sep()
                }
            );

            last SWITCH;

        }

        if ( $self->get_type() eq 'fixed' ) {

            $struct = $self->get_known_types()->{ $self->get_type() }
              ->new( { header_cols => $self->get_expected_fields() } );

        }
        else {

            confess "Don't know what to do with "
              . $self->get_type()
              . ' and column separator = '
              . $self->get_col_sep();

        }

    }

    my $header       = $struct->get_header_regex();
    my $header_regex = qr/$header/;
    my %parsed_lines;
    my $line_header_regex = qr/^\-+\s/;

    foreach my $line ( @{$data_ref} ) {

      SWITCH: {

            if ( $line eq '' ) {

                # do nothing
                last SWITCH;
            }

            if ( $line =~ $line_header_regex )
            {    # this is the '-------' below the header

                confess 'could not defined fields pattern'
                  unless ( $struct->define_fields_pattern($line) );
                last SWITCH;

            }

            # this is the header
            if ( $line =~ $header_regex ) {

                $self->_set_found_header(1);
                last SWITCH;

            }
            else {

                my $fields_ref = $struct->get_fields($line);

                confess "Cannot continue without having fields pattern defined"
                  unless ( ( defined($fields_ref) ) and ( @{$fields_ref} ) );

                unless ( $self->_consume_data( $fields_ref, \%parsed_lines ) ) {

                    confess 'Could not parse fields from line [' . $line . ']';

                }

            }

        }

    }

    confess 'failure detected while parsing: header not found'
      unless ( $self->found_header() );

    $self->set_data_parsed( \%parsed_lines );
    $self->set_raw_data( [] );

    return 1;

};

=head1 CAVEATS

All subclasses of Siebel::Srvrmgr::ListParser::Output::Tabular are expect to have both the header and trailer in the output of executed commands in C<srvrmgr> 
program. Removing one or both of them will result in parsing errors and probably exceptions.

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=item *

l<Siebel::Srvrmgr::ListParser::Output::ToString>

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

