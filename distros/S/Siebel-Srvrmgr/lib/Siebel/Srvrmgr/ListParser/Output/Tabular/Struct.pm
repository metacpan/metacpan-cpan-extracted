package Siebel::Srvrmgr::ListParser::Output::Tabular::Struct;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Tabular::Struct - base class for parsing srvrmgr tabular output

=cut

use Moose 2.0401;
use namespace::autoclean 0.13;
use Carp;
our $VERSION = '0.29'; # VERSION

=pod

=head1 DESCRIPTION

This is a base classes to parse C<srvrmgr> output in tabular form. That means that the output is expected to be
as a table, having a header and a clear definition of columns.

The subclasses of this class are expected to be used inside an output class like L<Siebel::Srvrmgr::ListParser::Output::Tabular>
since it will know the differences in parsing fixed width output from delimited one.

=head1 ATTRIBUTES

=head2 header_regex

This attribute is read-only.

The regular expression used to match the header of the list <command> output (the sequence of column names).

There is a L<Moose> C<builder> associated with it, so the definition of the regular expression is created automatically.

This attribute is also C<lazy>.

=cut

has 'header_regex' => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_header_regex',
    writer  => '_set_header_regex',
    reader  => 'get_header_regex',
    lazy    => 1
);

sub _build_header_regex {
    my $self = shift;
    $self->_set_header_regex(
        join( $self->get_col_sep(), @{ $self->get_header_cols() } ) );
}

=pod

=head2 col_sep

This attribute is read-only.

A regular expression string used to match the columns separator.

col_sep has a builder C<sub> that must be override by subclasses of this class or
an exception will be raised.

This attribute is also C<lazy>.

=cut

has 'col_sep' => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_col_sep',
    writer  => '_set_col_sep',
    reader  => 'get_col_sep',
    lazy    => 1
);

sub _build_col_sep {
    confess '_build_col_sep must be overrided by subclasses';
}

=head2 header_cols

This attribute is read-only and required during object instantiation.

An array reference with all the header columns names, in the exact sequence their appear in the output.

=cut

has 'header_cols' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    reader   => 'get_header_cols',
    writer   => '_set_header_cols',
    required => 1
);

=pod

=head1 METHODS

All the attributes, since read-only, have their associated getters.

=head2 get_col_sep

Returns the col_sep attribute value.

=head2 get_header_cols

Returns the header_cols attribute value.

=head2 split_fields

Split a output line into fields as defined by C<get_col_sep> method. It expects a string as parameter.

Returns an array reference.

If the separator could not be matched against the string, returns C<undef>.

=cut

sub split_fields {
    my ($self, $line) = @_;
    my $sep = $self->get_col_sep();
    my $comp_sep = qr/$sep/;

    if ( $line =~ $comp_sep ) {
        my @columns = split( $comp_sep, $line );
        return \@columns;
    }
    else {
        return;
    }
}

=pod

=head2 define_fields_pattern

This method must be overrided by subclasses of this classes or an exception will be raised.

It is responsible to define automatically the fields pattern to be used during parsing to retrieve
fields values.

=cut

sub define_fields_pattern {
    confess
'define_fields_pattern must be overrided by subclasses of Siebel::Srvrmgr::ListParser::Output::Tabular::Struct';
}

=pod

=head2 get_fields

This method must be overrided by subclasses of this classes or an exception will be raised.

This methods returns the fields data as an array reference. Expects as parameter the string of the line of
C<srvrmgr> output.

=cut

sub get_fields {
    confess
'get_fields must be overrided by subclasses of Siebel::Srvrmgr::ListParser::Output::Tabular::Struct';
}

=pod

=head1 CAVEATS

All subclasses of Siebel::Srvrmgr::ListParser::Output::Tabular::Struct expect to have both the header and trailer of 
executed commands in C<srvrmgr> program. Removing one or both of them will result in parsing errors and 
probably exceptions.

=head1 SEE ALSO

=over

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular>

=item *

L<Moose>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Fixed>

=item *

L<Siebel::Srvrmgr::ListParser::Output::Tabular::Struct::Delimited>

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
