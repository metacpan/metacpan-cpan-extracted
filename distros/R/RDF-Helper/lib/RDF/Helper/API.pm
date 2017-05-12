package RDF::Helper::API;
use Class::Load;
use Moose::Role;
requires qw(
  arrayref2rdf
  assert_literal
  assert_resource
  deep_prophash
  exists
  get_perl_type
  hashlist_from_statement
  hashref2rdf
  include_model
  include_rdfxml
  model
  namespaces
  new_bnode
  prefixed2resolved
  property_hash
  query_interface
  remove_statements
  resolved2prefixed
  resourcelist
  serialize
  tied_property_hash
  update_node
);

sub normalize_triple_pattern {
    my $self = shift;
    my ( $s, $p, $o ) = @_;
    my ( $subj, $pred, $obj ) = ( undef, undef, undef );

    if ( defined($s) ) {
        $subj =
          ref($s)
          ? $s
          : $self->new_resource(
            $self->{ExpandQNames} ? $self->qname2resolved($s) : $s );
    }
    if ( defined($p) ) {
        $pred =
          ref($p)
          ? $p
          : $self->new_resource(
            $self->{ExpandQNames} ? $self->qname2resolved($p) : $p );
    }
    if ( defined($o) ) {
        if ( ref($o) ) {
            $obj = $o;
        }
        else {
            my $testval =
              $self->{ExpandQNames} ? $self->qname2resolved($o) : $o;
            my $type = $self->get_perl_type($testval);
            if ( $type eq 'resource' ) {
                $obj = $self->new_resource("$testval");
            }
            else {
                $obj = $self->new_literal("$testval");
            }
        }
    }
    return ( $subj, $pred, $obj );
}

sub new_resource {
    my $self = shift;
    my $uri  = shift;
    return RDF::Helper::Node::Resource->new( uri => $uri );
}

sub get_object {
    my $self     = shift;
    my $resource = shift;
    my %args     = ref( $_[0] ) eq 'HASH' ? %{ $_[0] } : @_;
    my $obj      = new RDF::Helper::Object(
        RDFHelper   => $self,
        ResourceURI => $resource,
        %args
    );
    return $obj;
}

sub new_query {
    my $self = shift;
    my ( $query_string, $query_lang ) = @_;

    my $class = $self->query_interface;
    Class::Load::load_class($class);
    return $class->new( $query_string, $query_lang, $self->model );
}

sub new_literal {
    my $self = shift;
    my ( $val, $lang, $type ) = @_;
    if (defined($type)) {
      $type = $self->{ExpandQNames} ? $self->qname2resolved($type) : $type;
    }
    return RDF::Helper::Node::Literal->new(
        value    => $val,
        language => $lang,
        datatype => $type
    );
}

sub new_bnode {
    my $self = shift;
    my $id   = shift;
    $id ||= time . 'r' . $self->{bnodecounter}++;
    return RDF::Helper::Node::Blank->new( identifier => $id );
}

sub get_statements {
    my $self      = shift;
    my @ret_array = ();

    my $e = $self->get_enumerator(@_);
    while ( my $s = $e->next ) {
        push @ret_array, $s;
    }

    return @ret_array;
}

sub get_triples {
    my $self      = shift;
    my @ret_array = ();

    foreach my $stmnt ( $self->get_statements(@_) ) {
        my $subj = $stmnt->subject;
        my $obj  = $stmnt->object;

        my $subj_value =
          $subj->is_blank ? $subj->blank_identifier : $subj->uri->as_string;
        my $obj_value;
        if ( $obj->is_literal ) {
            $obj_value = $obj->literal_value;
        }
        elsif ( $obj->is_resource ) {
            $obj_value = $obj->uri->as_string;
        }
        else {
            $obj_value = $obj->as_string;
        }

        push @ret_array,
          [ $subj_value, $stmnt->predicate->uri->as_string, $obj_value ];
    }

    return @ret_array;
}

sub exists {
    my $self = shift;
    if ( $self->count(@_) > 0 ) {
        return 1;
    }
    return 0;
}

sub update_literal {
    my $self = shift;
    my ( $s, $p, $o, $new ) = @_;

    my $count = $self->remove_statements( $s, $p, $o );
    warn "More than one resource removed.\n" if $count > 1;
    return $self->assert_literal( $s, $p, $new );
}

sub update_resource {
    my $self = shift;
    my ( $s, $p, $o, $new ) = @_;

    my $count = $self->remove_statements( $s, $p, $o );
    warn "More than one resource removed.\n" if $count > 1;
    return $self->assert_resource( $s, $p, $new );
}

sub helper2native {
    my $self = shift;
    my $in   = shift;

    my $out = undef;
    return undef unless $in;
    if ( $in->is_resource ) {
        $out = $self->new_native_resource( $in->uri->as_string );
    }
    elsif ( $in->is_blank ) {
        $out = $self->new_native_bnode( $in->blank_identifier );
    }
    else {
        my $type_uri = undef;
        if ( my $uri = $in->literal_datatype ) {
            $type_uri = $uri->as_string;
        }
        $out =
          $self->new_native_literal( $in->literal_value,
            $in->literal_value_language, $type_uri );
    }
    return $out;
}

sub count {
    my $self = shift;
    my ( $s, $p, $o ) = @_;

    my $retval = 0;

    # if no args are passed, just return the size of the model
    unless ( defined($s) or defined($p) or defined($o) ) {
        return $self->model->size;
    }

    my $stream = $self->get_enumerator( $s, $p, $o );

    my $e = $self->get_enumerator(@_);
    while ( my $s = $e->next ) {
        $retval++;
    }

    return $retval;

}

sub include_model {
    my $self  = shift;
    my $model = shift;

    my $stream = $model->as_stream;

    while ( $stream && !$stream->end ) {
        $self->model->add_statement( $stream->current );
        $stream->next;
    }

    return 1;
}

1;
__END__
