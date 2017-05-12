package Search::Query::Dialect::SQL;
use Moo;
extends 'Search::Query::Dialect';
use Carp;
use Data::Dump qw( dump );
use Search::Query::Field::SQL;

use namespace::autoclean;

has 'wildcard'     => ( is => 'rw', default => sub {'%'} );
has 'quote_fields' => ( is => 'rw', default => sub {''} );
has 'fuzzify'      => ( is => 'rw' );
has 'fuzzify2'     => ( is => 'rw' );
has 'like'         => ( is => 'rw', default => sub {'ILIKE'}, );
has 'quote_char'   => ( is => 'rw', default => sub {q/'/}, );
has 'fuzzy_space'  => ( is => 'rw', default => sub {' '}, );

our $VERSION = '0.307';

=head1 NAME

Search::Query::Dialect::SQL - SQL query dialect

=head1 SYNOPSIS

 my $query = Search::Query->parser( dialect => 'SQL' )->parse('foo');
 print $query;

=head1 DESCRIPTION

Search::Query::Dialect::SQL is a query dialect for Query
objects returned by a Search::Query::Parser instance.

The SQL dialect class stringifies queries to work as SQL WHERE
clauses. This behavior is similar to Search::QueryParser::SQL.

=head1 METHODS

This class is a subclass of Search::Query::Dialect. Only new or overridden
methods are documented here.

=cut

=head2 BUILD

Called by new(). The new() constructor can accept the following params, which
are also standard attribute accessors:

=over

=item wildcard

Default value is C<%>.

=item quote_fields

Default value is "". Set to (for example) C<`> to quote each field name
in stringify() as some SQL variants require that syntax (e.g. mysql).

=item default_field

Override the default field set in Search::Query::Parser.

=item fuzzify

Append wildcard() to all terms.

=item fuzzify2

Prepend and append wildcard() to all terms.

=item like

The SQL reserved word for wildcard comparison. Default value is C<ILIKE>.

=item quote_char

The string to use for quoting strings. Default is C<'>.

=item fuzzy_space

The string to use to pad fuzzified terms. Default is a single space C< >.

=back

=cut

sub BUILD {
    my $self = shift;

    #carp dump $self;
    if ( !defined $self->parser->fields ) {
        croak "You must set fields in the Search::Query::Parser";
    }
    $self->{default_field} ||= $self->parser->default_field
        || [ sort keys %{ $self->parser->fields } ];
    if ( $self->{default_field} and !ref( $self->{default_field} ) ) {
        $self->{default_field} = [ $self->{default_field} ];
    }
    return $self;
}

=head2 stringify

Returns the Query object as a normalized string.

=cut

my %op_map = (
    '+' => 'AND',
    ''  => 'OR',
    '-' => 'AND',    # operator is munged
);

sub stringify {
    my $self = shift;
    my $tree = shift || $self;

    my @q;
    foreach my $prefix ( '+', '', '-' ) {
        my @clauses;
        my $joiner = $op_map{$prefix};
        next unless exists $tree->{$prefix};
        for my $clause ( @{ $tree->{$prefix} } ) {
            push( @clauses, $self->stringify_clause( $clause, $prefix ) );
        }
        next if !@clauses;

        push @q, join( " $joiner ", grep { defined and length } @clauses );
    }

    return join " AND ", @q;
}

sub _doctor_value {
    my ( $self, $clause ) = @_;

    my $value = $clause->{value};

    return $value unless defined $value;

    if ( $self->fuzzify ) {
        $value .= '*' unless $value =~ m/[\*\%]/;
    }
    elsif ( $self->fuzzify2 ) {
        $value = "*$value*" unless $value =~ m/[\*\%]/;
    }

    # normalize wildcard
    my $wildcard = $self->wildcard;
    $value =~ s/\*/$wildcard/g;

    return $value;
}

=head2 stringify_clause( I<leaf>, I<prefix> )

Called by stringify() to handle each Clause in the Query tree.

=cut

sub stringify_clause {
    my $self   = shift;
    my $clause = shift;
    my $prefix = shift;

    if ( $clause->{op} eq '()' ) {
        if ( $clause->has_children and $clause->has_children == 1 ) {

            # muck about in the internals because SQL relies on the operator,
            # not the prefix, to indicate the "NOT"-ness of a clause.
            if ( $prefix eq '-' and exists $clause->{value}->{'+'} ) {
                $clause->{value}->{'-'} = delete $clause->{value}->{'+'};
            }
            return '(' . $self->stringify( $clause->{value} ) . ')';
        }
        else {
            return
                ( $prefix eq '-' ? 'NOT ' : '' ) . "("
                . $self->stringify( $clause->{value} ) . ")";
        }
    }

    # optional
    my $quote_fields = $self->quote_fields;
    my $fuzzy_space  = $self->fuzzy_space;

    # TODO proximity - anything special and SQL-specific?

    # make sure we have a field
    my @fields
        = $clause->{field}
        ? ( $clause->{field} )
        : ( @{ $self->get_default_field } );

    # what value
    my $value = $self->_doctor_value($clause);

    # normalize operator
    my $op = $clause->{op} || "=";
    if ( $op eq ':' ) {
        $op = '=';
    }
    if ( $prefix eq '-' ) {
        $op = '!' . $op;
    }
    if ( defined $value and $value =~ m/\%/ ) {
        $op = $prefix eq '-' ? '!~' : '~';
    }

    my @buf;
NAME: for my $name (@fields) {
        my $field = $self->get_field($name);
        $value =~ s/\%//g if $field->is_int;
        my $this_op;

        # whether we quote depends on the field (column) type
        my $quote = $field->is_int ? "" : $self->quote_char;

        #warn dump [ $prefix, $field, $value, $op, $quote ];

        # range
        if ( $op eq '..' ) {
            if ( ref $value ne 'ARRAY' or @$value != 2 ) {
                croak "range of values must be a 2-element ARRAY";
            }

            my @range = ( $value->[0] .. $value->[1] );
            push(
                @buf,
                join( '',
                    $quote_fields, $name, $quote_fields, ' IN ', '(',
                    join( ', ', map { $quote . $_ . $quote } @range ), ')' )
            );
            next NAME;

        }

        # invert range
        elsif ( $op eq '!..' ) {
            if ( ref $value ne 'ARRAY' or @$value != 2 ) {
                croak "range of values must be a 2-element ARRAY";
            }

            my @range = ( $value->[0] .. $value->[1] );
            push(
                @buf,
                join( '',
                    $quote_fields, $name, $quote_fields, ' NOT IN ', '( ',
                    join( ', ', map { $quote . $_ . $quote } @range ), ' )' )
            );
            next NAME;
        }

        # fuzzy
        elsif ( $op =~ m/\~/ ) {

            # negation
            if ( $op eq '!~' ) {
                if ( $field->is_int ) {
                    $this_op = $field->fuzzy_not_op;
                }
                else {
                    $this_op
                        = $fuzzy_space . $field->fuzzy_not_op . $fuzzy_space;
                }
            }

            # standard fuzzy
            else {
                if ( $field->is_int ) {
                    $this_op = $field->fuzzy_op;
                }
                else {
                    $this_op = $fuzzy_space . $field->fuzzy_op . $fuzzy_space;
                }
            }
        }

        # null
        elsif ( !defined $value ) {
            if ( $op eq '=' ) {
                $this_op = ' is ';
            }
            else {
                $this_op = ' is not ';
            }
            $value = 'NULL';
            $quote = '';
        }

        # default, pass through
        else {
            $this_op = $op;
        }

        if ( defined $field->callback ) {
            push( @buf, $field->callback->( $field, $this_op, $value ) );
            next NAME;
        }

        #warn dump [ $quote_fields, $name, $this_op, $quote, $value ];

        push(
            @buf,
            join( '',
                $quote_fields, $name,  $quote_fields, $this_op,
                $quote,        $value, $quote )
        );

    }
    my $joiner = $prefix eq '-' ? ' AND ' : ' OR ';
    return
          ( scalar(@buf) > 1 ? '(' : '' )
        . join( $joiner, @buf )
        . ( scalar(@buf) > 1 ? ')' : '' );
}

=head2 get_field

Overrides default to set fuzzy_op and fuzzy_not_op.

=cut

around get_field => sub {
    my $orig  = shift;
    my $self  = shift;
    my $field = $orig->( $self, @_ );

    # fix up the operator based on our like() setting
    if ( !$field->is_int and $self->like ) {
        $field->fuzzy_op( $self->like );
        $field->fuzzy_not_op( 'NOT ' . $self->like );
    }

    return $field;
};

=head2 field_class

Returns "Search::Query::Field::SQL".

=cut

sub field_class {'Search::Query::Field::SQL'}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-query at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Query>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Query


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Query>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Query>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Query>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Query/>

=back


=head1 ACKNOWLEDGEMENTS

This module started as a fork of Search::QueryParser by
Laurent Dami.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
