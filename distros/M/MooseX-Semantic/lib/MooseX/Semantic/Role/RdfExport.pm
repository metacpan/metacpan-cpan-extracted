package MooseX::Semantic::Role::RdfExport;
use Moose::Role;
use RDF::Trine::Serializer::SparqlUpdate;
use RDF::Trine qw(iri);
use RDF::Trine::Namespace qw(rdf);
use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request;
use Scalar::Util qw(blessed);
use MooseX::Semantic::Types qw(TrineLiteral);
use Data::Dumper;

with (
    'MooseX::Semantic::Role::Resource',
    'MooseX::Semantic::Util::TypeConstraintWalker',
);

=head1 NAME

MooseX::Semantic::Role::RdfExport - Role for exporting Moose objects to RDF

=head1 SYNOPSIS

    package My::Model::Person;
    use Moose;
    with qw(MooseX::Semantic::Role::RdfExport);
    has name => (
        traits => ['Semantic'],
        is => 'rw',
        isa => 'Str',
        uri => 'http://xmlns.com/foaf/0.1/name',
        uri_writer => ['http://myont.org/onto#name'],
    );
    package main;
    my $p = My::Model::Person->new(
        rdf_about => 'http://myont.org/data/John',
        name      => 'John'
    );
    print $p->export_to_string(format=>'turtle');
    # <http://myont.org/data/John> <http://myont.org/onto#name>     "John"^^<http://www.w3.org/2001/XMLSchema#string> ;
    #                              <http://xmlns.com/foaf/0.1/name> "John"^^<http://www.w3.org/2001/XMLSchema#string> .

=cut

has _user_agent => (
    is   => 'rw',
    isa  => 'LWP::UserAgent',
    lazy => 1,
    builder => '_build_user_agent',
);

sub _build_user_agent {
    my $self  = shift;
    my $agent = sprintf('%s/%s %s/%s ',
        ref $self, ($self->VERSION||'undef'),
        __PACKAGE__, (__PACKAGE__->VERSION||'undef'),
        );
    LWP::UserAgent->new(
        agent           => $agent,
        parse_head      => 0,
        max_redirect    => 2,
    );
}

=head1 METHODS

=cut

=head2 export_to_model

C<export_to_model($model, %opts)>

Exports the object to RDF in model C<$model>. 

For C<%opts> see L<EXPORT OPTIONS> below.

=cut

sub export_to_model {
    my $self = shift;
    my ($model, %opts) = @_;
    unless ($model) {
        # warn "No model supplied, create temporary model";
        $model = RDF::Trine::Model->temporary_model;
    }

    # BUG investigate TODO
    $opts{context} = $self->rdf_about if ($self->does('MooseX::Semantic::Role::Graph')) ;

    # TODO should be moved to MooseX::Semantic::Role::WithRdfType
    # rdf:type
    if ($self->does('MooseX::Semantic::Role::WithRdfType')){
        for my $this_type (@{ $self->rdf_type }) {
            $model->add_statement(RDF::Trine::Statement->new(
                $self->rdf_about,
                $rdf->type,
                $this_type,
            ),
            $opts{context},
            );
        }
    }
    $self->_walk_attributes({
            before => sub {
                my ($attr, $stash) = @_;
                push (@{$stash->{uris}}, @{$attr->uri_writer}) if $attr->has_uri_writer;
                return not $stash->{attr_val};
            },
            model => sub {
                my ($attr, $stash) = @_;
                my $iter = $stash->{attr_val}->as_stream;
                while (my $stmt = $iter->next) {
                    # warn Dumper $stmt;
                    if ($self->does('MooseX::Semantic::Role::Graph')) {
                        $stmt->[3] = $self->rdf_about;
                    }
                    $model->add_statement($stmt);
                }
            },
            literal => sub {
                my ($attr, $stash) = @_;
                my $val = $stash->{attr_val};
                if ($attr->has_rdf_formatter) {
                    $val = $attr->rdf_formatter->( $val );
                }
                $self->_export_one_scalar( $model, $val, $_, $attr->rdf_lang, $attr->rdf_datatype, $opts{context})
                    for (@{ $stash->{uris} });
            },
            resource => sub {
                my ($attr, $stash) = @_;
                $self->_export_one_object($model, $stash->{attr_val}, $_, $opts{context})
                    for (@{ $stash->{uris} });
            },
            literal_in_array => sub {
                my ($attr, $stash) = @_;
                for my $subval ( @{$stash->{attr_val}} ) {
                    if ($attr->has_rdf_formatter) {
                        $subval = $attr->rdf_formatter->( $subval );
                    }
                    $self->_export_one_scalar($model, $subval, $_, $attr->rdf_lang, $attr->rdf_datatype, $opts{context} )
                        for (@{ $stash->{uris} });
                }
            },
            resource_in_array => sub {
                my ($attr, $stash) = @_;
                for my $subval ( @{$stash->{attr_val}} ) {
                    $self->_export_one_object($model, $subval, $_, $opts{context})
                    for (@{ $stash->{uris} });
                }
            },
    });
    return $model;
}

sub _export_one_object {
    my $self = shift;
    my ($model,  $single_val, $rel, $context) = @_;
    if (blessed $single_val) {
        # warn Dumper ref $single_val;
        if (ref $single_val eq 'RDF::Trine::Node::Resource' ) {
            $model->add_statement(RDF::Trine::Statement->new(
                    $self->rdf_about,
                    $rel,
                    $single_val,
                ),
                $context,
            );
        }
        elsif ($single_val->does('MooseX::Semantic::Role::RdfExport')) {
            #
            # Here's the recursion
            #
            $single_val->export_to_model($model);
            $model->add_statement(RDF::Trine::Statement->new(
                    $self->rdf_about,
                    $rel,
                    $single_val->rdf_about
                ),
                $context,
            );
        } else {
            warn "Can't export this object since it doesn't MooseX::Semantic::Role::RdfExport";
        }
    }
    else {
        confess "Trying to export unblessed reference like an object: $single_val";
    }
}
sub _export_one_scalar {
    my $self = shift;
    my ($model,  $val, $rel, $lang, $datatype, $context) = @_;
    # warn Dumper \@_;
    my $lit;
    if ($lang) {
        $lit = RDF::Trine::Node::Literal->new($val, $lang);
    } elsif ($datatype) {
        $lit = RDF::Trine::Node::Literal->new($val, undef, $datatype);
    } else {
        $lit = TrineLiteral->coerce($val);
    }
    $model->add_statement(RDF::Trine::Statement->new(
        $self->rdf_about,
        $rel,
        $lit,
    ),
    $context,
    );
}

sub _get_serializer{
    my $self = shift;
    my (%opts) = @_;
    # warn Dumper keys %opts;
    my $format =  $opts{format} || 'nquads';
    my $options = $opts{serializer_opts} || {};
    my $serializer = RDF::Trine::Serializer->new($format, %{$options} );
    return $serializer;
}

=head2 export_to_string

C<export_to_string( %opts )>

For C<%opts>, see L<EXPORT OPTIONS> below.

=cut

sub export_to_string {
    my ($self, %opts) = @_;
    # HACK HACK HACK
    my $context = $opts{context} || 0;
    my $model = $self->export_to_model($opts{model}, context => $opts{context});
    # my $iter = $model->get_statements;
    # while ($_ = $iter->next) {
    #     warn Dumper [
    #         $_->subject->uri,
    #         $_->predicate->uri,
    #         $_->object->as_string,
    #     ];
    # }
    my $serializer = $self->_get_serializer(%opts)->serialize_model_to_string($model); 
}

=head2 export_to_file

TODO

=cut

sub export_to_file {
    my ($self, $fh, %opts) = @_;
    if (! ref $fh) {
        open $fh, ">", $fh;
    } elsif (ref $fh ne 'GLOB') {
        warn "can't open file for ref type " . ref $fh;
        return;
    }
    my $model = $self->export_to_model($opts{model}, context => $opts{context});
    # TODO prove that data was actually written out to $fh
    # and return undef otherwise
    $self->_get_serializer(%opts)->serialize_model_to_file($fh, $model); 
    return 1;
}

=head2 export_to_web

TODO

=cut

sub export_to_web {
    my ($self, $method, $uri, %opts) = @_;
    confess "Method must be PUT or POST" unless $method =~ /^(PUT|POST)$/;
    
    ### XXX: It would be handy if there were an application/sparql-update
    ###      serializer for Trine.
    ### kb Tue Nov 29 03:55:55 CET 2011
    #   started sparqlu_insert serializer
    my $ser = $self->_get_serializer(%opts);
    my ($type) = $ser->media_types;
    
    my $req = HTTP::Request->new(POST => $uri);
    $req->header(Content_Type => $type);
    my $model = $self->export_to_model($opts{model}, %opts);
    $req->content( $ser->serialize_model_to_string($model) );
    
    my $res = $self->_user_agent->request($req);
    $res->is_success or
        confess("<%s> HTTP %d Error: %s", $uri, $res->code, $res->message);
    return $res;
}

=head2 export_to_hash

TODO

=cut

sub export_to_hash {
    # warn Dumper [@_];<>;
    my ($self, %opts) = @_;
    my $self_hash = {};
    $opts{max_recursion} //= 0;
    $opts{hash_key} //= 'Moose';
    $self_hash->{rdf_about} = $self->rdf_about->uri;
    $self->_walk_attributes({
        # skip empty attributes;
        before => sub {
            my ($attr, $stash) = @_;
            push (@{$stash->{uris}}, @{$attr->uri_writer}) if $attr->has_uri_writer;
            return not $stash->{attr_val};
        },
        literal => sub {
            my ($attr, $stash) = @_;
            $self->_attr_to_hash( $self_hash, $attr, $stash->{attr_val}, %opts);
        },
        model => sub {
            my ($attr, $stash) = @_;
            $self_hash->{$attr->name} = $self->{$attr->name}->as_hashref;
        },
        resource => sub {
            my ($attr, $stash) = @_;
            my $self_hash_value = $self->export_to_hash( $stash->{attr_val}, %opts );
            $self_hash_value = [ map {$_->export_to_hash(%opts)} @{ $stash->{attr_val} } ];
        }
        ,
        literal_in_array => sub {
            my ($attr, $stash) = @_;
            $self->_attr_to_hash( $self_hash, $attr, $stash->{attr_val}, %opts);
        },
        resource_in_array => sub {
            my ($attr, $stash) = @_;
            my $self_hash_value;
            if ($opts{max_recursion}-- > 0) {
                $self_hash_value = [ map {$_->export_to_hash(%opts)} @{ $stash->{attr_val} } ];
            }
            else {
                $self_hash_value = [ map {{rdf_about => $_->rdf_about->uri_value}} @{ $stash->{attr_val} } ];
            }
            $self->_attr_to_hash( $self_hash, $attr, $self_hash_value, %opts);
        },
    });
    # # TODO
    #     if ($opts{hash_key} && $opts{hash_key} eq 'rdf_about') {
    #     }
    return $self_hash;
}

=head2 rdf_serialize

TODO

=cut

sub rdf_serialize {
    my $self = shift;
    my $content_type = shift;
    my %opts = @_;
    my $temp_model = RDF::Trine::Model->temporary_model;
    my $content_type_mapping = {
        'application/json' => sub {$self->export_to_hash(%opts)},
        'application/rdf+xml' => sub {$self->export_to_string(%opts, model => $temp_model, format=>'rdfxml')},
    };
    if (my $coderef = $content_type_mapping->{$content_type}) {
        return $coderef->();
    }
    else {
        warn "Unknown content type '$content_type'";
    }
    return;
}

=head1 EXPORT OPTIONS

=over 4

=item format

Format string to be passed to L<RDF::Trine::Parser>, e.g. C<turtle> or C<rdfxml>. Defaults to C<nquads>.

=item serializer_opts

Additional options for the L<RDF::Trine::Serializer> to be used.

=item context


Optional URI of the named graph this export should be exported into.


=back

=cut


1;
=head1 AUTHOR

Konstantin Baierer (<kba@cpan.org>)

=head1 SEE ALSO

=over 4

=item L<MooseX::Semantic|MooseX::Semantic>

=back

=cut

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perldoc perlartistic.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

