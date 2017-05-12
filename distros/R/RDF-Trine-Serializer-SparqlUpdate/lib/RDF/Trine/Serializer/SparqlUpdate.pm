# RDF::Trine::Serializer::SparqlUpdate
# -----------------------------------------------------------------------------

=head1 NAME

RDF::Trine::Serializer::SparqlUpdate - SPARQL/U serialization of triples

=head1 SYNOPSIS

    my $sparqlu = RDF::Trine::Serializer::SparqlUpdate->new;
    $query = $sparqlu->serialize_to_string( $stmt, delete => $model );
    $query = $sparqlu->serialize_to_string( undef, delete => $iter );

    my $sparqlu_quad = RDF::Trine::Serializer->new('sparqlu', quad_semantics => 1 );
    $fh = $sparqlu_quad->serialize_to_io( $model );
    while (<$fh>) {
        print $_;
    }

=head1 DESCRIPTION

TODO

=head1 METHODS

Beyond the methods documented below, this class inherits methods from the
L<RDF::Trine::Serializer> class.


=cut

package RDF::Trine::Serializer::SparqlUpdate;

use strict;
use warnings;
no warnings 'redefine', 'once';
use base qw(RDF::Trine::Serializer);

use URI;
use Carp;
use Data::Dumper;
use Scalar::Util qw(blessed);
use IO::Handle::Iterator;
use SUPER;

use RDF::Trine::Node;
use RDF::Trine::Statement;
use RDF::Trine::Error qw(:try);
use RDF::Trine::Serializer::NTriples;

######################################################################

our ($VERSION);

BEGIN {
    $VERSION                                                  = '0.002';
    $RDF::Trine::Serializer::serializer_names{'sparqlu'}      = __PACKAGE__;
    $RDF::Trine::Serializer::serializer_names{'sparqlupdate'} = __PACKAGE__;
    $RDF::Trine::Serializer::format_uris{'http://www.w3.org/Submission/SPARQL-Update/'}
        = __PACKAGE__;
    foreach my $type (qw(application/sparql-update)) {
        $RDF::Trine::Serializer::media_types{$type} = __PACKAGE__;
    }
}

######################################################################

=head2 C<< new( [quad_semantics => (0|1)], [atomic => (0|1)] ) >>

Returns a new SPARQL/Update serializer object.

If C< quad_semantics > is set, contexts/graphs will be considered for INSERT
and DELETE clauses. Otherwise, the serializer works on the union graph of the
model.

If C< atomic > is set, every statement is wrapped in it's own INSERT/DELETE
clause.

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    $args{quad_semantics} //= undef;
    $args{serializer} = RDF::Trine::Serializer::NTriples->new(%args);

    my $self = bless( {%args}, $class );
    return $self;
}

=head2 C<< serialize_to_string ( $data, %opts ) >>

Coerces both $data and $opts{delete} to a model and calls C<<
serialize_model_to_string >> with those.

=cut

sub serialize_to_string {
    my $self = shift;
    if ($self->{atomic}) {
        return join "", do {
            my $fh = $self->_serialize_atomic( @_ );
            local $/; 
            <$fh>
        };
    }
    else {
        return $self->_serialize_non_atomic( @_ );
    }
}

=head2 C<< serialize_to_file ( $fh, $data, %opts ) >>

Coerces both $data and $opts{delete} to a model and calls C<<
serialize_model_to_string >> with those and writes the resulting
string to filehandle $fh.

=cut

sub serialize_to_file {
    my $self = shift;
    my $file = shift;
    print {$file} $self->serialize_to_string(@_);
}

=head2 C<< serialize_to_io( $data, %opts ) >>

Returns an IO::Handle with the C<$data> and $opts{delete} serialized to atomic SPARQL/U clauses

=cut
sub serialize_to_io {
    my $self =shift;
    return $self->_serialize_atomic( @_ );
}

=head2 C<< serialize_model_to_string ( $model ) >>

Serializes the C<$model> to SPARQL/Update, returning the result as a string.

=cut

*serialize_model_to_string = *serialize_to_string;

=head2 C<< serialize_model_to_file ( $fh, $model ) >>

Serializes the C<$model> to SPARQL/Update, printing the results to the supplied
filehandle C<<$fh>>.

Alias for L</serialize_to_file>.

=cut

*serialize_model_to_file = *serialize_to_file;


=head2 C<< serialize_iterator_to_file ( $file, $iter ) >>

Serializes the iterator to SPARQL/Update, printing the results to the supplied
filehandle C<<$fh>>.

Alias for L</serialize_to_file>.

=cut

*serialize_iterator_to_file = *serialize_to_file;

=head2 C<< serialize_iterator_to_string ( $iter ) >>

Serializes the iterator to SPARQL/Update, returning the result as a string.

Alias for L</serialize_to_string>.

=cut

*serialize_iterator_to_string = *serialize_to_string;

=head2 C<< statement_as_string ( $st ) >>

Serializes a statement to a SPARQL/Update INSERT DATA clause.

Alias for L</serialize_to_string>.

=cut

*statement_as_string = *serialize_to_string;

=head2 C<< serialize_model_to_io( $model ) >>

TODO Returns an IO::Handle with the C<$model> serialized to atomic SPARQL/U clauses

=cut

# sub serialize_model_to_io {
#     my $self = shift;
#     my $model = shift;



=head2 C<< _serialize_data_to_ntriples( $data ) >>

Turns $data into a string of N-Triples.

=cut


sub _serialize_data_to_ntriples {
    my $self = shift;
    my $data = shift;
    return "" unless blessed $data;
    my %class_to_serializer_function = (
        'RDF::Trine::Statement' => 'statement_as_string',
        'RDF::Trine::Model'     => 'serialize_model_to_string',
        'RDF::Trine::Iterator'  => 'serialize_iterator_to_string',
    );
    while ( my ( $isa, $sub ) = each %class_to_serializer_function ) {
        return $self->{serializer}->$sub($data) if $data->isa($isa);
    }
}

=head2 C<< _to_model( $data ) >>

Turns $data into a L<RDF::Trine::Model>.

=cut

sub _to_model {
    my $self           = shift;
    my $data           = shift;
    return undef unless $data;
    my %class_to_model = (
        'RDF::Trine::Statement' => sub {
            my $model = RDF::Trine::Model->temporary_model;
            $model->add_statement( shift() );
            return $model;
        },
        'RDF::Trine::Iterator' => sub {
            my $iter  = shift;
            my $model = RDF::Trine::Model->temporary_model;
            while ( my $stmt = $iter->next ) {
                $model->add_statement($stmt);
            }
            return $model;
        },
        'RDF::Trine::Model' => sub { shift; },
    );
    while ( my ( $isa, $sub ) = each %class_to_model ) {
        return $sub->($data) if $data->isa($isa);
    }
}

sub _to_iter {
    my $self =shift;
    my $data = shift;
    return undef unless $data;
    my %class_to_iter = (
        'RDF::Trine::Statement' => sub { [RDF::Trine::Iterator->new( [ shift() ], 'graph' )] },
        'RDF::Trine::Iterator' => sub { [shift] },
        'RDF::Trine::Model' => sub {
            my $model = shift;
            my @iters;
            if ( $self->{quad_semantics} ) {
                my @contexts = $model->get_contexts->get_all ;
                push @contexts, RDF::Trine::Node::Nil->new;
                push @iters, $model->get_statements( undef, undef, undef, $_ ) for @contexts;
                return \@iters;
            }
            else {
                return [ $model->as_stream ];
            }

        }
    );
    while ( my ( $isa, $sub ) = each %class_to_iter ) {
        return $sub->($data) if $data->isa($isa);
    }
}

=head2 C<< _create_clause( $type, $data, [$graph] ) >>

Creates a SPARQL/U 'INSERT' or 'DELETE' clause, depending on L<$type>. 

C<$data> can be anything that L</_serialize_data_to_ntriples> can coerce to N-Triples.

If C<$graph> is given, clauses take the form
    
    INSERT DATA { GRAPH <$graph> { ... } };

otherwise they act on the default graph, like so:

    INSERT DATA { ... };

=cut

sub _create_clause {
    my $self  = shift;
    my $type  = uc shift;
    my $data  = shift;
    my %opts = @_;
    my $graph = $opts{graph};
    my $data_ser;

    return unless $data;

    if ( ref $data ) {
        $data_ser = $self->_serialize_data_to_ntriples($data);
        return unless $data_ser;
        if (! $graph && $self->{quad_semantics}) {
            if ($data->isa('RDF::Trine::Statement::Quad')) {
                $graph = [$data->nodes]->[3];
            }
        }
    }
    else {
        $data_ser = $data;
    }
    if ($graph && $graph->is_resource) {
        my $graph_uri;
        # if ($graph->is_resource) {
            $graph_uri = $graph->uri_value;
        # }
        # elsif ($graph->is_blank) {
        #     $graph_uri = $graph->sse;
        # }
        return sprintf( "%s DATA { GRAPH <%s> {\n%s}};\n", $type, $graph_uri, $data_ser );
    }
    else {
        return sprintf( "%s DATA { \n%s};\n", $type, $data_ser );
    }
}

sub _serialize_non_atomic {
    my $self         = shift;
    my $insert_model = shift;
    my %opts         = @_;
    my %model        = (
        INSERT => $self->_to_model($insert_model),
        DELETE => $self->_to_model( $opts{delete} ),
    );
    my @clauses;
    for ( keys %model ) {
        next unless $model{$_};
        if ( $self->{quad_semantics} ) {
            my $iter_context = $model{$_}->get_contexts;

            # create clauses for every context'd statement
            while ( my $cur_context = $iter_context->next ) {
                push @clauses,
                    $self->_create_clause( $_,
                    $model{$_}->get_statements( undef, undef, undef, $cur_context ),
                    graph => $cur_context );
            }

            # also those statements not in any context
            push @clauses,
                $self->_create_clause( $_,
                $model{$_}->get_statements( undef, undef, undef, RDF::Trine::Node::Nil->new ),
                graph => RDF::Trine::Node::Nil->new
                );
        }
        else {
            push @clauses, $self->_create_clause( $_, $model{$_} );
        }
    }
    return join "", sort { $a cmp $b } map {$_} @clauses;
}

sub _serialize_atomic {
    my $self =shift;
    my $insert_data = shift;
    my %opts = @_;
    my %iters = (
        DELETE => $self->_to_iter($opts{delete}),
        INSERT => $self->_to_iter($insert_data),
    );
    my @iters_in_order;
    for (qw(DELETE INSERT)) {
        if ( $iters{$_} && scalar @{ $iters{$_} } ) {
            push @iters_in_order, $_ => @{$iters{$_}};
        }
    }
    return sub {1} unless @iters_in_order;

    # warn Dumper  \@iters_in_order;


    my $current_type = shift @iters_in_order;
    my $current_iter = shift @iters_in_order;
    my $sub = sub {
        my $st = $current_iter->next;
        if ($current_iter->finished) {
            my $iter_or_type = shift @iters_in_order;
            return unless $iter_or_type;
            if ( ! ref $iter_or_type ) {
                $current_type = $iter_or_type;
                $current_iter = shift @iters_in_order;
            }
            else {
                $current_iter = $iter_or_type;
            }
            $st = $current_iter->next;
        }
        return unless blessed($st);
        return $self->_create_clause( $current_type, $st, @_ );
    };
    return IO::Handle::Iterator->new( $sub );
}


1;

__END__

=head1 SEE ALSO

L<http://www.w3.org/TR/rdf-testcases/#ntriples>

L<http://www.w3.org/TR/sparql11-update/#deleteInsert>

=head1 AUTHOR

Konstantin Baierer <kba@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2011 Konstantin Baierer. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
1;
