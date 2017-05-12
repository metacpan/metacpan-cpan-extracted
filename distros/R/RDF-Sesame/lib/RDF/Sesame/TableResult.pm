package RDF::Sesame::TableResult;

use strict;
use warnings;

use base qw( Data::Table );

use Carp;

our $VERSION = '0.17';

#
# The $response parameter is an RDF::Sesame::Response object.
#
# This method is only intended to be called from RDF::Sesame::Repository
#
sub new {
    my ($class, $r, %opts) = @_;

    # set our 'strip_' values
    my $strip_literals = 0;
    my $strip_uris     = 0;
    $strip_literals = $opts{strip} =~ /^literals|all$/;
    $strip_uris     = $opts{strip} =~ /^urirefs|all$/;

    my ( $content, $parser )
        = $r->is_xml()            ? ( $r->parsed_xml(), \&_parse_xml )
        : $r->is_binary_results() ? ( $r->content(),    \&_parse_bin )
        :                           croak "TableResults: Bad response format"
        ;
    my ($column_names, $tuples) = $parser->(
        $content,
        $strip_literals,
        $strip_uris,
    );

    my $self = $class->SUPER::new($tuples, $column_names, 0);
    $self->{coming} = 0;  # the number of the next row for each()

    # rebless ourselves and return
    return bless $self, $class;
}

# Converts the binary RDF table results format from Sesame into an array of
# arrays with column names.  The binary results format is described at
# http://www.openrdf.org/doc/sesame/api/org/openrdf/sesame/query/BinaryTableResultConstants.html
sub _parse_bin {
    my ($bin, $strip_literals, $strip_uris) = @_;

    # validate the header
    my ( $magic, $version, $column_count ) = unpack( 'A4 N N', $bin );
    die "Not an Binary RDF Table Result" if $magic ne 'BRTR';
    die "Version $version is higher than 1" if $version > 1;
    substr( $bin, 0, 12, q{} );

    # collect the column names
    my @column_names;
    for ( 1 .. $column_count ) {
        my ( $byte_count, $column_name ) = unpack( 'n X2 n/A*', $bin );
        substr( $bin, 0, 2 + $byte_count, q{} );
        push @column_names, $column_name;
    }

    # parse the results table from the binary representation
    my @row;
    my @rows;
    my $prev_row;
    my @namespaces;
    ROW:
    while (1) {
        my $column_value;
        my $column_i = 0;
        @row = ();

        COLUMN:
        while ( $column_i < $column_count ) {
            my ($record_type) = unpack( 'c', $bin );
            substr( $bin, 0, 1, q{} );

            if ( $record_type == 0 ) {       # NULL
                $column_value = undef;
            }
            elsif ( $record_type == 1 ) {    # REPEAT
                $column_value = $prev_row->[$column_i];
            }
            elsif ( $record_type == 2 ) {    # NAMESPACE
                my ( $ns_id, $ns_len, $ns ) = unpack( 'N n X2 n/A*', $bin );
                substr( $bin, 0, 6 + $ns_len, q{} );
                $namespaces[$ns_id] = $ns;
                redo COLUMN;
            }
            elsif ( $record_type == 3 ) {    # QNAME
                my ( $ns_id, $local_len, $local )
                    = unpack( 'N n X2 n/A*', $bin );
                substr( $bin, 0, 6 + $local_len, q{} );
                my $ns = $namespaces[$ns_id];
                $column_value = $strip_uris ? "$ns$local" : "<$ns$local>";
            }
            elsif ( $record_type == 4 ) {    # URI
                my ( $uri_len, $uri ) = unpack( 'n X2 n/A*', $bin );
                substr( $bin, 0, 2 + $uri_len, q{} );
                $column_value = $strip_uris ? $uri : "<$uri>";
            }
            elsif ( $record_type == 5 ) {    # BNODE
                my ( $bnode_len, $bnode ) = unpack( 'n X2 n/A*', $bin );
                substr( $bin, 0, 2 + $bnode_len, q{} );
                $column_value = "_:$bnode";
            }
            elsif ( $record_type == 6 ) {    # PLAIN LITERAL
                my ( $lit_len, $lit ) = unpack( 'n X2 n/A*', $bin );
                substr( $bin, 0, 2 + $lit_len, q{} );
                $column_value = $strip_literals ? $lit : qq{"$lit"};
            }
            elsif ( $record_type == 7 ) {    # LANG LITERAL
                my ( $lit_len, $lit, $lang_len, $lang )
                    = unpack( 'n X2 n/A* n X2 n/A*', $bin );
                substr( $bin, 0, 4 + $lit_len + $lang_len, q{} );
                $column_value = $strip_literals ? $lit : qq{"$lit"\@$lang};
            }
            elsif ( $record_type == 8 ) {    # DATATYPE LITERAL
                my ( $lit_len, $lit, $record_type )
                    = unpack( 'n X2 n/A* c', $bin );
                substr( $bin, 0, 3 + $lit_len, q{} );

                my $datatype;
                if ( $record_type == 3 ) {    # embedded QNAME
                    my ( $ns_id, $local_len, $local )
                        = unpack( 'N n X2 n/A*', $bin );
                    substr( $bin, 0, 6 + $local_len, q{} );
                    my $ns = $namespaces[$ns_id];
                    $datatype = $ns . $local;
                }
                elsif ( $record_type == 4 ) {    # embedded URI
                    my ( $uri_len, $uri ) = unpack( 'n X2 n/A*', $bin );
                    substr( $bin, 0, 2 + $uri_len, q{} );
                    $datatype = $uri;
                }
                else {
                    die "Bad record type $record_type after typed literal";
                }

                $column_value = $strip_literals ? $lit : qq{"$lit"^^<$datatype>};
            }
            elsif ( $record_type == 126 ) {   # ERROR
                my ( $error_type, $error_len, $error )
                    = unpack( 'c n X2 n/A*', $bin );
                substr( $bin, 0, 3 + $error_len, q{} );
                die "$error_type: $error";
            }
            elsif ( $record_type == 127 ) {   # END OF RESULTS
                last ROW;
            }
            else {
                die "Unknown record type: $record_type";
            }
        }
        continue {
            push @row, $column_value;
            $column_i++;
        }

    }
    continue {
        my $row_copy = [ @row ];
        push @rows, $row_copy;
        $prev_row = $row_copy;
    }

    push @rows, \@row if @row;

    return ( \@column_names, \@rows );
}

# Converts the XML parse tree from RDF::Sesame::Response into
# an array of arrays with column names
sub _parse_xml {
    my ( $parsed_xml, $strip_literals, $strip_uris ) = @_;

    # make a copy of the header info for ourselves
    my @head = @{ $parsed_xml->{header}{columnName} };

    # convert the tuples into our internal representation
    my @tuples;
    foreach my $t ( @{ $parsed_xml->{tuple} } ) {
        my @row = ();
        foreach my $a ( @{ $t->{attribute} } ) {
            my $content = $a->{content};

            # encode each type according to N-Triples syntax
            if( $a->{type} eq 'bNode' ) {
                push(@row, "_:$content");
            } elsif( $a->{type} eq 'uri' ) {
                if( $strip_uris ) {
                    push(@row, $content);
                } else {
                    push(@row, "<$content>");
                }
            } elsif( $a->{type} eq 'literal' ) {
                if( $strip_literals ) {
                    push(@row, $content);
                } elsif( $a->{'xml:lang'} ) {
                    push(@row, "\"$content\"\@" . $a->{'xml:lang'} );
                } elsif( $a->{datatype} ) {
                    push(@row, "\"$content\"^^<" . $a->{datatype} . ">" );
                } else {
                    push(@row, "\"$content\"" );
                }
            } else {
                # type must be 'null'
                push(@row, undef);
            }
        }

        push(@tuples, \@row);
    }

    return ( \@head, \@tuples );
}

sub has_rows {
    my $self = shift;

    return $self->nofRow > 0;
}

sub sort {
    my ($self, @ps) = @_;

    my $i = 1;
    while( $i < $#_ ) {

        # munge the type parameter
        if( defined $ps[$i] ) {
            if( $ps[$i] eq 'numeric' ) {
                $ps[$i] = 0;
            } elsif( $ps[$i] eq 'non-numeric' ) {
                $ps[$i] = 1;
            }
        }

        $i++;

        # munge the order parameter
        if( defined $ps[$i] ) {
            if( $ps[$i] eq 'asc' ) {
                $ps[$i] = 0;
            } elsif( $ps[$i] eq 'desc' ) {
                $ps[$i] = 1;
            }
        }

        $i += 2;  # skip the next colID parameter
    }

    $self->SUPER::sort(@ps);
}

sub each {
    my ($self) = @_;

    # have we passed the last row?
    if( $self->{coming} >= $self->nofRow ) {
        $self->{coming} = 0;
        return ();
    }

    # nope, so return the current row and increment our pointer
    return @{ $self->rowRef($self->{coming}++) };
}

sub reset {
    $_[0]->{coming} = 0;
}


1;

__END__

=head1 NAME

RDF::Sesame::TableResult - Results from a select query

=head1 DESCRIPTION

The RDF::Sesame::Repository::select method returns a TableResult object
after completing a successful query.  This object is a subclass of
L<Data::Table> so many table manipulation methods are available.  Additional
methods specific to RDF::Sesame::TableResult are documented below.

The values returned by a query are represented in N-Triples syntax.  NULL
values are represented with C<undef>.

=head1 METHODS

=head2 has_rows

Returns a true value if the table result has any rows, otherwise it returns
a false value.  This method is a small wrapper around Data::Table::nofRow
to provide some syntactic sugar.

=head2 sort

This method overrides the method provided by Data::Table.  The method
performs the same, but it allows for more pleasing parameter values.
For $type, one may pass the strings 'numeric' and 'non-numeric' instead of
0 and 1 respectively.  For $order, one may pass 'asc' and 'desc' instead
of 0 and 1 respectively.  The name parameters are case sensitive.

For further documentation, see L<Data::Table>.

=head2 each

A method for iterating through the result rows, similar in spirit to
Perl's built-in each() function for hashes.  Returns a list consisting of
the values for the next row.  When all rows have been read, an empty list
is returned.  The next call to each() after that will start iterating again.

If you want to restart the iteration before reaching the end, see 
reset() which is documented below.  Here is an example:

 my $r = $repo->select($serql);
 while( my @row = $r->each ) {
    print join("\t", @row), "\n";
 }

=head2 reset( )

Reset the counter used by each() for iterating through the results.  Following
a call to reset() the next call to each() will return the values from the
first row of results.

=head1 AUTHOR

Michael Hendricks  <michael@ndrix.org>

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2005-2006 Michael Hendricks (<michael@ndrix.org>). All rights
reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
