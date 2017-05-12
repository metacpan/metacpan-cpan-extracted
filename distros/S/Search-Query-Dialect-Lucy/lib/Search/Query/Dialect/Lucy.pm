package Search::Query::Dialect::Lucy;
use Moo;
extends 'Search::Query::Dialect::Native';
use Carp;
use Data::Dump qw( dump );
use Scalar::Util qw( blessed );
use Search::Query::Field::Lucy;
use Lucy::Search::ANDQuery;
use Lucy::Search::NoMatchQuery;
use Lucy::Search::NOTQuery;
use Lucy::Search::ORQuery;
use Lucy::Search::PhraseQuery;
use Lucy::Search::RangeQuery;
use Lucy::Search::TermQuery;
use LucyX::Search::ProximityQuery;
use LucyX::Search::NOTWildcardQuery;
use LucyX::Search::WildcardQuery;
use LucyX::Search::NullTermQuery;
use LucyX::Search::AnyTermQuery;

use namespace::autoclean;

our $VERSION = '0.202';

has 'wildcard'                  => ( is => 'rw', default => sub {'*'} );
has 'fuzzify'                   => ( is => 'rw', default => sub {0} );
has 'ignore_order_in_proximity' => ( is => 'rw', default => sub {0} );
has 'allow_single_wildcards'    => ( is => 'rw', default => sub {0} );

=head1 NAME

Search::Query::Dialect::Lucy - Lucy query dialect

=head1 SYNOPSIS

 use Lucy;
 use Search::Query;
 
 my ($idx, $query) = get_index_name_and_query();
 
 my $searcher = Lucy::Search::IndexSearcher->new( index => $idx );
 my $schema   = $searcher->get_schema();
 
 # build field mapping
 my %fields;
 for my $field_name ( @{ $schema->all_fields() } ) { 
     $fields{$field_name} = { 
         type     => $schema->fetch_type($field_name),
         analyzer => $schema->fetch_analyzer($field_name),
     };  
 }
 
 my $query_parser = Search::Query->parser(
     dialect        => 'Lucy',
     croak_on_error => 1,
     default_field  => 'foo',  # applied to "bare" terms with no field
     fields         => \%fields
 );
 
 my $parsed_query = $query_parser->parse($query);
 my $lucy_query   = $parsed_query->as_lucy_query();
 my $hits         = $searcher->hits( query => $lucy_query );

=head1 DESCRIPTION

Search::Query::Dialect::Lucy extends the Lucy::QueryParser syntax
to support wildcards, proximity and ranges, in addition to the standard
Search::Query features.

=head1 METHODS

This class is a subclass of Search::Query::Dialect. Only new or overridden
methods are documented here.

=cut

=head2 BUILD

Sets Lucy-appropriate defaults.
Can take the following params, also available as standard attribute
methods.

=over

=item wildcard

Default is '*'.

=item allow_single_wildcards

If true, terms like '*' and '?' are allowed as valid. If false,
the Parser will croak if any term consists solely of a wildcard.

The default is false.

=item fuzzify

If true, a wildcard is automatically appended to each query term.

=item ignore_order_in_proximity

If true, the terms in a proximity query will be evaluated for
matches regardless of the order in which they appear. For example,
given a document excerpt like:

 foo bar bing

and a query like:

 "bing foo"~5

if ignore_order_in_proximity is true, the document would match.
If ignore_order_in_proximity is false (the default), the document would
not match.

=back

=cut

sub BUILD {
    my $self = shift;

    if ( $self->{default_field} and !ref( $self->{default_field} ) ) {
        $self->{default_field} = [ $self->{default_field} ];
    }

    return $self;
}

=head2 stringify

Returns the Query object as a normalized string.

=cut

my %op_map = (
    '+' => ' AND ',
    ''  => ' OR ',
    '-' => ' ',
);

sub _get_clause_joiner {
    my $self = shift;
    if ( $self->parser->default_boolop eq '+' ) {
        return 'AND';
    }
    else {
        return 'OR';
    }
}

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

        push @q, join( $joiner, grep { defined and length } @clauses );
    }
    my $clause_joiner = $self->_get_clause_joiner;
    return join " $clause_joiner ", @q;
}

sub _doctor_value {
    my ( $self, $clause ) = @_;

    my $value = $clause->{value};

    if ( defined $value and $self->fuzzify ) {
        $value .= '*' unless $value =~ m/[\*]/;
    }

    return $value;
}

=head2 stringify_clause( I<leaf>, I<prefix> )

Called by stringify() to handle each Clause in the Query tree.

=cut

sub stringify_clause {
    my $self   = shift;
    my $clause = shift;
    my $prefix = shift;

    #warn '=' x 80;
    #warn dump $clause;
    #warn "prefix = '$prefix'";

    if ( $clause->{op} eq '()' ) {
        my $str = $self->stringify( $clause->{value} );
        if ( $clause->has_children and $clause->has_children == 1 ) {
            if ( $prefix eq '-' ) {
                return "(NOT ($str))";
            }
            else {

                # try not to double up the () unnecessarily
                if ( $str =~ m/^\(/ ) {
                    return $str;
                }
                else {
                    return "($str)";
                }
            }
        }
        else {
            if ( $prefix eq '-' ) {
                if ( $str =~ m/^\(/ ) {
                    return "(NOT $str)";
                }
                else {
                    return "(NOT ($str))";
                }
            }
            else {
                return "($str)";
            }
        }
    }

    my $quote     = $clause->quote     || '';
    my $proximity = $clause->proximity || '';
    if ($proximity) {
        $proximity = '~' . $proximity;
    }

    # make sure we have a field
    my $default_field
        = $self->default_field
        || $self->parser->default_field
        || undef;    # not empty string or 0
    my @fields;
    if ( $clause->{field} ) {
        @fields = ( $clause->{field} );
    }
    elsif ( defined $default_field ) {
        if ( ref $default_field ) {
            @fields = @$default_field;
        }
        else {
            @fields = ($default_field);
        }
    }

    # what value
    my $value
        = ref $clause->{value}
        ? $clause->{value}
        : $self->_doctor_value($clause);

    # if we have no fields, then operator is ignored.
    if ( !@fields ) {
        $self->debug and warn "no fields for " . dump($clause);
        my $str = qq/$quote$value$quote$proximity/;
        return $prefix eq '-' ? ( 'NOT ' . $str ) : $str;
    }

    my $wildcard = $self->wildcard;

    # normalize operator
    my $op = $clause->{op} || ":";
    $op =~ s/=/:/g;
    if ( $prefix eq '-' ) {
        $op = '!' . $op unless $op =~ m/^!/;
    }
    if ( defined $value and $value =~ m/[\*\?]|\Q$wildcard/ ) {
        $op =~ s/:/~/g;
        if ( $value eq '*' or $value eq '?' ) {
            if ( !$self->allow_single_wildcards ) {
                croak "single wildcards are not allowed: $clause";
            }
        }
    }

    my @buf;
NAME: for my $name (@fields) {
        my $field = $self->get_field($name);

        if ( defined $field->callback ) {
            push( @buf, $field->callback->( $field, $op, $value ) );
            next NAME;
        }

        ( $self->debug > 1 )
            and warn "lucy string: "
            . dump [ $name, $op, $prefix, $quote, $value, ];

        if ( !defined $value ) {
            $value = 'NULL';
        }

        # invert fuzzy
        if ( $op eq '!~' ) {
            $value .= $wildcard unless $value =~ m/\Q$wildcard/;
            push(
                @buf,
                join( '',
                    '(NOT ', $name, ':', qq/$quote$value$quote$proximity/,
                    ')' )
            );
        }

        # fuzzy
        elsif ( $op eq '~' ) {
            $value .= $wildcard unless $value =~ m/\Q$wildcard/;
            push( @buf,
                join( '', $name, ':', qq/$quote$value$quote$proximity/ ) );
        }

        # invert
        elsif ( $op eq '!:' ) {

            # double negative
            if ( $prefix eq '-' and $clause->{op} eq '!:' ) {
                push @buf,
                    join( '', $name, ':', qq/$quote$value$quote$proximity/ );
            }
            else {
                push(
                    @buf,
                    join( '',
                        '(NOT ', $name, ':', qq/$quote$value$quote$proximity/,
                        ')' )
                );
            }
        }

        # range
        elsif ( $op eq '..' ) {
            if ( ref $value ne 'ARRAY' or @$value != 2 ) {
                croak "range of values must be a 2-element ARRAY";
            }

            push(
                @buf,
                join( '',
                    $name, ':', '(', $value->[0], '..', $value->[1], ')' )
            );

        }

        # invert range
        elsif ( $op eq '!..' ) {
            if ( ref $value ne 'ARRAY' or @$value != 2 ) {
                croak "range of values must be a 2-element ARRAY";
            }

            push(
                @buf,
                join( '',
                    $name, '!:', '(', $value->[0], '..', $value->[1], ')' )
            );
        }

        # standard
        else {
            push( @buf,
                join( '', $name, ':', qq/$quote$value$quote$proximity/ ) );
        }
    }
    my $joiner = $prefix eq '-' ? ' AND ' : ' OR ';
    return
          ( scalar(@buf) > 1 ? '(' : '' )
        . join( $joiner, @buf )
        . ( scalar(@buf) > 1 ? ')' : '' );
}

=head2 as_lucy_query

Returns the Dialect object as a Lucy::Search::Query-based object.
The Dialect object is walked and converted to a
Lucy::Searcher-compatible tree.

=cut

my %lucy_class_map = (
    '+' => 'AND',
    ''  => 'OR',
    '-' => 'NOT',
);

sub as_lucy_query {
    my $self = shift;
    my $tree = shift || $self;

    my @q;
    foreach my $prefix ( '+', '', '-' ) {
        my @clauses;
        my $joiner = $lucy_class_map{$prefix};
        next unless exists $tree->{$prefix};
        my $has_explicit_fields = 0;
        for my $clause ( @{ $tree->{$prefix} } ) {
            my @lucy_clauses = $self->_lucy_clause( $clause, $prefix );
            if ( !@lucy_clauses ) {

                #warn "No lucy_clauses for $clause";
                next;
            }
            push( @clauses, @lucy_clauses );
            if ( defined $clause->{field} ) {
                $has_explicit_fields++;
            }
        }
        next if !@clauses;

        my $lucy_class = 'Lucy::Search::' . $joiner . 'Query';
        my $lucy_param_name = $joiner eq 'NOT' ? 'negated_query' : 'children';
        @clauses = grep {defined} @clauses;
        if ( $prefix eq '-' and @clauses > 1 ) {
            $lucy_class      = 'Lucy::Search::ANDQuery';
            $lucy_param_name = 'children';
        }

        #warn "$lucy_class -> new( $lucy_param_name => " . dump \@clauses;
        #warn "has_explicit_fields=$has_explicit_fields";

        if ( @clauses == 1 ) {
            if (    $prefix eq '-'
                and $has_explicit_fields
                and !$clauses[0]->isa($lucy_class) )
            {
                push @q, $lucy_class->new( $lucy_param_name => $clauses[0] );
            }
            else {
                push @q, $clauses[0];
            }
        }
        elsif ( !$has_explicit_fields and $prefix eq '-' ) {

            warn "do not wrap \@clauses in a $lucy_class";
            push @q, @clauses;

        }
        else {
            push @q, $lucy_class->new( $lucy_param_name => \@clauses );
        }

    }

    # possible we end up with nothing if StopFilter applied
    if ( !@q ) {
        return ();
    }

    my $clause_joiner     = $self->_get_clause_joiner;
    my $lucy_class_joiner = 'Lucy::Search::' . $clause_joiner . 'Query';

    return @q == 1
        ? $q[0]
        : $lucy_class_joiner->new( children => \@q );
}

sub _lucy_clause {
    my $self   = shift;
    my $clause = shift;
    my $prefix = shift;

    #warn dump $clause;
    #warn "prefix = '$prefix'";

    if ( $clause->{op} eq '()' ) {
        return $self->as_lucy_query( $clause->{value} );
    }

    # make sure we have a field
    my $default_field = $self->default_field || $self->parser->default_field;
    my @fields;
    if ( $clause->{field} ) {
        @fields = ( $clause->{field} );
    }
    elsif ( defined $default_field ) {
        if ( ref $default_field ) {
            @fields = @$default_field;
        }
        else {
            @fields = ($default_field);
        }
    }

    # what value
    my $value
        = ref $clause->{value}
        ? $clause->{value}
        : $self->_doctor_value($clause);

    # if we have no fields, we can't proceed, because Lucy
    # requires a field for every term.
    if ( !@fields ) {
        croak
            "No field specified for term '$value' -- set a default_field in Parser or Dialect";
    }

    my $wildcard = $self->wildcard;

    # normalize operator
    my $op = $clause->{op} || ":";
    $op =~ s/=/:/g;
    if ( $prefix eq '-' ) {
        $op = '!' . $op unless $op =~ m/^!/;
    }
    if ( defined $value and $value =~ m/[\*\?]|\Q$wildcard/ ) {
        $op =~ s/:/~/;
        if ( $value eq '*' or $value eq '?' ) {
            if ( !$self->allow_single_wildcards ) {
                croak "single wildcards are not allowed: $clause";
            }
        }
    }

    my $quote = $clause->quote || '';
    my $is_phrase = $quote eq '"' ? 1 : 0;
    my $proximity = $clause->proximity || '';

    my @buf;
FIELD: for my $name (@fields) {
        my $field = $self->get_field($name);

        if ( defined $field->callback ) {
            push( @buf, $field->callback->( $field, $op, $value ) );
            next FIELD;
        }

        if ( $self->debug ) {
            warn "as_lucy_query:\n";
            warn dump(
                {   name      => $name,
                    op        => $op,
                    prefix    => $prefix,
                    quote     => $quote,
                    value     => $value,
                    clause_op => $clause->{op},
                }
            ) . "\n";
        }

        # NULL
        if ( !defined $value ) {
            if ( $op eq '!:' ) {
                if ( $prefix eq '-' ) {

                    # original op was inverted above by $prefix
                    if ( $clause->{op} eq ':' ) {

                        # appears to be a double negative, but necessary
                        # to get the logic and serialization correct.
                        # e.g. NOT foo:NULL
                        push @buf,
                            Lucy::Search::NOTQuery->new(
                            negated_query =>
                                $field->nullterm_query_class->new(
                                field => $name
                                )
                            );

                    }
                    else {
                        # true double negative
                        # e.g. NOT foo!:NULL  => foo:NULL
                        push @buf,
                            $field->nullterm_query_class->new(
                            field => $name );

                    }

                }
                else {
                    push @buf,
                        $field->anyterm_query_class->new( field => $name );
                }
            }
            else {
                push @buf,
                    $field->nullterm_query_class->new( field => $name );
            }
            next FIELD;
        }

        # range is un-analyzed
        if ( $op eq '..' ) {
            if ( ref $value ne 'ARRAY' or @$value != 2 ) {
                croak "range of values must be a 2-element ARRAY";
            }

            my $range_query = $field->range_query_class->new(
                field         => $name,
                lower_term    => $value->[0],
                upper_term    => $value->[1],
                include_lower => 1,
                include_upper => 1,
            );

            push( @buf, $range_query );
            next FIELD;

        }

        # invert range
        elsif ( $op eq '!..' ) {
            if ( ref $value ne 'ARRAY' or @$value != 2 ) {
                croak "range of values must be a 2-element ARRAY";
            }

            my $range_query = $field->range_query_class->new(
                field         => $name,
                lower_term    => $value->[0],
                upper_term    => $value->[1],
                include_lower => 1,
                include_upper => 1,
            );
            push( @buf,
                Lucy::Search::NOTQuery->new( negated_query => $range_query )
            );
            next FIELD;
        }

        #$self->debug and warn "value before:$value";
        my @values = ($value);

        # if the field has an analyzer, use it on $value
        if ( blessed( $field->analyzer ) && !ref $value ) {

            # preserve any wildcards
            if ( $value =~ m/[$wildcard\*\?]/ ) {

                # can't use full PolyAnalyzer since it will tokenize
                # and strip the wildcards off.

                # assume CaseFolder
                # TODO do not assume
                $value = lc($value);

                # split on whitespace, not token regex
                my @tok = split( m/\s+/, $value );

                # if stemmer, apply only to prefix if at all.
                my $stemmer;

                if ( $field->analyzer->isa('Lucy::Analysis::PolyAnalyzer') ) {
                    my $analyzers = $field->analyzer->get_analyzers();
                    for my $ana (@$analyzers) {
                        if ( $ana->isa('Lucy::Analysis::SnowballStemmer') ) {
                            $stemmer = $ana;
                            last;
                        }

                    }
                }
                elsif (
                    $field->analyzer->isa('Lucy::Analysis::SnowballStemmer') )
                {
                    $stemmer = $field->analyzer;
                }

                if ($stemmer) {
                    for my $tok (@tok) {
                        if ( $tok =~ s/^(\w+)\*$/$1/ ) {
                            my $stemmed = $stemmer->split($tok);

                            # re-append the wildcard
                            # TODO ever have multiple?
                            $tok = $stemmed->[0] . '*';
                        }
                    }
                }

                @values = @tok;

            }
            else {
                @values = grep { defined and length }
                    @{ $field->analyzer->split($value) };

                # if we have a StopFilter in our analyzer chain,
                # it's possible the @values ends up empty.
                # The Lucy QueryParser will handle that case
                # by trying twice with a NoMatchQuery.
                # TODO what should our behavior be?
                # a stopword will never match since the word
                # won't be in the index...
            }
        }

        #$self->debug and warn "value after :" . dump( \@values );

        # StopFilter or similar case
        if ( !@values ) {
            return ();
        }

        if ( $is_phrase or @values > 1 ) {
            if ($proximity) {

                if ( $self->ignore_order_in_proximity ) {
                    my $n_values = scalar @values;
                    my @permutations;
                    while ( $n_values-- > 0 ) {
                        push(
                            @permutations,
                            $field->proximity_query_class->new(
                                field  => $name,
                                terms  => [@values],    # new array
                                within => $proximity,
                            )
                        );
                        push( @values, shift(@values) );    # shuffle

                    }
                    $self->debug
                        and dump [ map { $_->get_terms } @permutations ];
                    push(
                        @buf,
                        Lucy::Search::ORQuery->new(
                            children => \@permutations,
                        )
                    );
                }
                else {
                    push(
                        @buf,
                        $field->proximity_query_class->new(
                            field  => $name,
                            terms  => \@values,
                            within => $proximity,
                        )
                    );
                }
            }
            else {
                # invert
                if ( $op eq '!:' ) {
                    push(
                        @buf,
                        Lucy::Search::NOTQuery->new(
                            negated_query => $field->phrase_query_class->new(
                                field => $name,
                                terms => \@values,
                            )
                        )
                    );
                }

                # standard
                else {

                    push(
                        @buf,
                        $field->phrase_query_class->new(
                            field => $name,
                            terms => \@values,
                        )
                    );
                }
            }
        }
        else {
            my $term = $values[0];

            # TODO why would this happen?
            if ( !defined $term or !length $term ) {
                warn "No term defined";
                next FIELD;
            }

            # invert fuzzy
            if ( $op eq '!~'
                || ( $op eq '!:' and $term =~ m/[$wildcard\*\?]/ ) )
            {
                $term .= $wildcard unless $term =~ m/\Q$wildcard/;

                # if the prefix is already NOT do not apply a double negative
                if ( $prefix eq '-' ) {
                    push(
                        @buf,
                        $field->wildcard_query_class->new(
                            field => $name,
                            term  => $term,
                        )
                    );
                }
                elsif ( $op =~ m/^\!/ ) {
                    push(
                        @buf,
                        Lucy::Search::NOTQuery->new(
                            negated_query =>
                                $field->wildcard_query_class->new(
                                field => $name,
                                term  => $term,
                                )
                        )
                    );
                }
                else {
                    push(
                        @buf,
                        $field->wildcard_query_class->new(
                            field => $name,
                            term  => $term,
                        )
                    );
                }
            }

            # fuzzy
            elsif ( $op eq '~'
                || ( $op eq ':' and $term =~ m/[$wildcard\*\?]/ ) )
            {
                $term .= $wildcard unless $term =~ m/\Q$wildcard/;

                push(
                    @buf,
                    $field->wildcard_query_class->new(
                        field => $name,
                        term  => $term,
                    )
                );
            }

            # invert
            elsif ( $op eq '!:' ) {
                push(
                    @buf,
                    Lucy::Search::NOTQuery->new(
                        negated_query => $field->term_query_class->new(
                            field => $name,
                            term  => $term,
                        )
                    )
                );
            }

            # standard
            else {
                push(
                    @buf,
                    $field->term_query_class->new(
                        field => $name,
                        term  => $term,
                    )
                );
            }

        }    # TERM
    }

    # possible that stop_filter results in nothing in buffer
    if ( !@buf ) {
        return ();
    }
    if ( @buf == 1 ) {
        return $buf[0];
    }
    my $joiner = $prefix eq '-' ? 'AND' : 'OR';
    my $lucy_class = 'Lucy::Search::' . $joiner . 'Query';
    return $lucy_class->new( children => \@buf );
}

=head2 field_class

Returns "Search::Query::Field::Lucy".

=cut

sub field_class {'Search::Query::Field::Lucy'}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-query-dialect-Lucy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Query-Dialect-Lucy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Query::Dialect::Lucy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Query-Dialect-Lucy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Query-Dialect-Lucy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Query-Dialect-Lucy>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Query-Dialect-Lucy/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
