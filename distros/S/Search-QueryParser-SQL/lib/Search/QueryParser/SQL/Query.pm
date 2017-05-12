package Search::QueryParser::SQL::Query;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );

use overload '""' => 'stringify', 'fallback' => 1;

our $VERSION = '0.010';

my $debug = $ENV{PERL_DEBUG} || 0;

=head1 NAME

Search::QueryParser::SQL::Query - query object

=head1 SYNOPSIS

 # see Search::QueryParser::SQL

=head1 DESCRIPTION

This class is primarily for unparsing Search::QueryParser
data structures into valid SQL.
 
=head1 METHODS

Only new or overridden method are documented here.

=cut

=head2 stringify

Returns Query as a string suitable for plugging into a WHERE
clause.

=cut

sub stringify {
    my $self = shift;
    return $self->_unwind;
}

my %op_map = (
    '+' => 'AND',
    ''  => 'OR',
    '-' => 'AND',    # operator is munged
);

=head2 dbi

Like stringify(), but returns array ref of two items:
the SQL string and an array ref of values. The SQL string
uses the C<?> placeholder as expected by the DBI API.

=cut

sub dbi {
    my $self = shift;

    # set flag temporarily
    $self->{opts}->{delims} = 1;

    my $sql = $self->_unwind;
    my @values;
    my $start   = chr(2);
    my $end     = chr(3);
    my $opstart = chr(5);
    my $opend   = chr(6);

    # do not need op delims at all
    $sql =~ s/($opstart|$opend)//go;

    while ( $sql =~ s/$start(.+?)$end/\?/o ) {
        push( @values, $1 );
    }

    delete $self->{opts}->{delims};

    return [ $sql, \@values ];
}

=head2 pairs

Returns array ref of array refs of column/op/value pairs.
Note that the logical AND/OR connectors will not be present.

=cut

sub pairs {
    my $self = shift;

    my @pairs;
    my $vstart  = chr(2);
    my $vend    = chr(3);
    my $opstart = chr(5);
    my $opend   = chr(6);

    # set flag temporarily
    $self->{opts}->{delims} = 1;
    my $sql = $self->_unwind;

    while ( $sql =~ m/([\.\w]+)\ ?$opstart(.+?)$opend\ ?$vstart(.+?)$vend/go )
    {
        push( @pairs, [ $1, $2, $3 ] );
    }

    delete $self->{opts}->{delims};

    return \@pairs;
}

=head2 rdbo

Returns array ref ready for passing to Rose::DB::Object::Querybuilder
build_select() method as the C<query> argument.

=cut

sub rdbo {
    my $self = shift;

    $debug and warn '=' x 80 . "\n";
    $debug and warn "STRING: $self->{_string}\n";
    $debug and warn "PARSER: " . dump( $self->{_parser} ) . "\n";

    my $q = $self->_orm;

    $debug and warn "rdbo q: " . dump $q;

    my $joiner = $self->{_implicit_AND} ? 'AND' : 'OR';
    if ( defined $self->{'-'} ) {

        # no implicit OR with NOT queries
        $joiner = 'AND';
    }

    if ( scalar @$q > 2 ) {
        $debug and warn "rdbo \$q > 2, joiner=$joiner";
        return [ $joiner => $q ];
    }
    else {
        return $q;
    }
}

=head2 dbic

Returns array ref ready for passing to DBIx::Class as search query.
This is the SQL::Abstract format.

=cut

sub dbic {
    my $self = shift;

    $debug and warn '=' x 80 . "\n";
    $debug and warn "STRING: $self->{_string}\n";
    $debug and warn "PARSER: " . dump( $self->{_parser} ) . "\n";

    $self->{opts}->{dbic} = 1;

    my $q = $self->_orm;

    $debug and warn "dbic q: " . dump $q;

    delete $self->{opts}->{dbic};

    my $joiner = $self->{_implicit_AND} ? '-and' : '-or';
    if ( defined $self->{'-'} ) {

        # no implicit OR with NOT queries
        $joiner = '-and';
    }

    if ( scalar @$q > 2 ) {
        $debug and warn "dbic \$q > 2, joiner=$joiner";
        return [ $joiner => $q ];
    }
    else {
        return $q;
    }
}

=head2 parser

Returns the original parser object that generated the query.

=cut

sub parser {
    shift->{_parser};
}

sub _orm {
    my $self = shift;
    my $q = shift || $self;
    my $query;
    my $OR  = $self->{opts}->{dbic} ? '-or'  : 'OR';
    my $AND = $self->{opts}->{dbic} ? '-and' : 'AND';
    for my $prefix ( '+', '', '-' ) {
        next unless ( defined $q->{$prefix} and @{ $q->{$prefix} } );

        my $joiner = $op_map{$prefix};

        $joiner = '-' . lc($joiner) if $self->{opts}->{dbic};

        $debug and warn "prefix '$prefix' ($joiner): " . dump $q->{$prefix};

        my @op_subq;

        for my $subq ( @{ $q->{$prefix} } ) {
            my $q = $self->_orm_subq( $subq, $prefix );
            my $items = scalar(@$q);

            $debug and warn "items $items $joiner : " . dump $q;
            my $sub_joiner = $prefix eq '-' ? $AND : $OR;
            push( @op_subq, ( $items > 2 ) ? ( $sub_joiner => $q ) : @$q );
        }

        $debug and warn sprintf( "n subq == %d, joiner=%s, dump: %s\n",
            scalar(@op_subq), $joiner, dump \@op_subq );

        if ( $self->{_parser}->{lower}
            and grep { ref($_) eq 'ARRAY' } @op_subq )
        {
            # when 'lower' is on, items in the subq are arrayrefs, so count
            # of items is different
            push @$query, $joiner => \@op_subq;
        }
        else {

            push( @$query,
                  ( scalar(@op_subq) > 2 )
                ? ( $joiner => \@op_subq )
                : @op_subq );
        }

    }
    return $query;
}

sub _orm_subq {
    my $self   = shift;
    my $subQ   = shift;
    my $prefix = shift;
    my $opts   = $self->{opts} || {};

    return $self->_orm( $subQ->{value} )
        if $subQ->{op} eq '()';

    # make sure we have a column
    my @columns
        = $subQ->{field}
        ? ( $subQ->{field} )
        : ( @{ $self->{_parser}->{default_column} } );

    # what value
    my $value = $self->_doctor_value($subQ);

    # normalize operator
    my $op = $subQ->{op};
    if ( $op eq ':' ) {
        $op = '=';
    }
    if ( $prefix eq '-' ) {
        $op = '!' . $op;
    }
    if ( $value =~ m/\%/ ) {
        $op = $prefix eq '-' ? '!~' : '~';
    }

    my @buf;
    for my $colname (@columns) {
        my $column = $self->{_parser}->get_column($colname);

        $value =~ s/\%//g if $column->is_int;

        my @pair;

        if ( defined $column->orm_callback ) {
            @pair = $column->orm_callback->( $column, $op, $value );
        }

        # standard
        elsif ( $op eq '=' ) {
            @pair = ( $colname, $value );
        }

        # negation
        elsif ( $op eq '!=' ) {
            @pair = ( $colname, { $op => $value } );
        }

        # fuzzy
        elsif ( $op eq '~' ) {
            @pair = ( $colname, { $column->fuzzy_op => $value } );
        }

        # not fuzzy
        elsif ( $op eq '!~' ) {
            @pair = ( $colname, { $column->fuzzy_not_op => $value } );
        }
        else {
            croak
                "unknown operator logic for column '$colname' op '$op' value '$value'";
        }

        # if lower, then turn pair into a scalar ref literal
        if ( !$column->is_int and $self->{_parser}->{lower} ) {
            my $col     = $pair[0];
            my $val     = $pair[1];
            my $this_op = $op;
            if ( ref $val ) {
                ( $this_op, $val ) = each %$val;
            }
            @pair = ( [ \qq/lower($pair[0]) $this_op lower(?)/, $val ] );
        }

        push @buf, @pair;
    }

    #warn "buf: " . dump \@buf;

    return \@buf;

}

sub _unwind {
    my $self = shift;
    my $q = shift || $self;
    my @subQ;
    for my $prefix ( '+', '', '-' ) {
        my @clause;
        my $joiner = $op_map{$prefix};
        for my $subq ( @{ $q->{$prefix} } ) {
            push @clause, $self->_unwind_subQ( $subq, $prefix );
        }
        next if !@clause;

        #warn "$joiner clause: " . dump \@clause;

        push( @subQ,
            join( " $joiner ", grep { defined && length } @clause ) );
    }
    return join( " AND ", @subQ );
}

sub _doctor_value {
    my ( $self, $subQ ) = @_;

    my $value = $subQ->{value};

    if ( $self->{_parser}->{fuzzify} ) {
        $value .= '*' unless $value =~ m/[\*\%]/;
    }
    elsif ( $self->{_parser}->{fuzzify2} ) {
        $value = "*$value*" unless $value =~ m/[\*\%]/;
    }

    # normalize wildcard to sql variety
    $value =~ s/\*/\%/g;

    return $value;
}

sub _unwind_subQ {
    my $self   = shift;
    my $subQ   = shift;
    my $prefix = shift;
    my $opts   = $self->{opts} || {};

    return "(" . $self->_unwind( $subQ->{value} ) . ")"
        if $subQ->{op} eq '()';

    # optional
    my $col_quote = $self->{_parser}->{quote_columns};
    my $use_lower = $self->{_parser}->{lower};

    # make sure we have a column
    my @columns
        = $subQ->{field}
        ? ( $subQ->{field} )
        : ( @{ $self->{_parser}->{default_column} } );

    # what value
    my $value = $self->_doctor_value($subQ);

    # normalize operator
    my $op = $subQ->{op};
    if ( $op eq ':' ) {
        $op = '=';
    }
    if ( $prefix eq '-' ) {
        $op = '!' . $op;
    }
    if ( $value =~ m/\%/ ) {
        $op = $prefix eq '-' ? '!~' : '~';
    }

    my @buf;
COLNAME: for my $colname (@columns) {
        my $column = $self->{_parser}->get_column($colname);
        $value =~ s/\%//g if $column->is_int;
        my $this_op;

        # whether we quote depends on the field (column) type
        my $quote = $column->is_int ? "" : "'";

        my $prefix = '';
        my $suffix = '';
        if ( !$column->is_int and $use_lower ) {
            $prefix = 'lower(';
            $suffix = ')';
        }

        # fuzzy
        if ( $op =~ m/\~/ ) {

            # negation
            if ( $op eq '!~' ) {
                if ( $column->is_int ) {
                    $this_op = $column->fuzzy_not_op;
                }
                else {
                    $this_op = ' ' . $column->fuzzy_not_op . ' ';
                }
            }

            # standard fuzzy
            else {
                if ( $column->is_int ) {
                    $this_op = $column->fuzzy_op;
                }
                else {
                    $this_op = ' ' . $column->fuzzy_op . ' ';
                }
            }
        }
        else {
            $this_op = $op;
        }

        if ( defined $column->callback ) {
            push( @buf, $column->callback->( $column, $this_op, $value ) );
            next COLNAME;
        }

        if ( $opts->{delims} ) {
            push(
                @buf,
                join( '',
                    $prefix, $col_quote, $colname, $col_quote, $suffix,
                    chr(5),  $this_op,   chr(6),   $prefix,    chr(2),
                    $value,  chr(3),     $suffix, )
            );
        }
        else {
            push(
                @buf,
                join( '',
                    $prefix, $col_quote, $colname, $col_quote,
                    $suffix, $this_op,   $prefix,  $quote,
                    $value,  $quote,     $suffix, )
            );
        }
    }
    my $joiner = $prefix eq '-' ? ' AND ' : ' OR ';
    return
          ( scalar(@buf) > 1 ? '(' : '' )
        . join( $joiner, @buf )
        . ( scalar(@buf) > 1 ? ')' : '' );

}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-search-queryparser-sql@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


