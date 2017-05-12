package RDF::Helper::RDFTrine;
use Moose;
use MooseX::Aliases;

use RDF::Trine;
use Cwd;
use RDF::Helper::Statement;
use Data::Dumper;

has query_interface => (
    isa     => 'Str',
    is      => 'ro',
    alias   => ['QueryInterface'],
    default => 'RDF::Helper::RDFQuery'
);

has Model => (
    isa      => 'RDF::Trine::Model',
    accessor => 'model',
    lazy     => 1,
    builder  => '_build_model'
);

sub _build_model {
    RDF::Trine::Model->new( RDF::Trine::Store::Memory->new() );
}

has namespaces => (
    isa     => 'HashRef',
    is      => 'ro',
    alias   => ['Namespaces'],
    builder => '_build_namespaces'
);

sub _build_namespaces {
    { rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#', };
}

has _NS => ( isa => 'HashRef', is => 'ro', );

has ExpandQNames => ( isa => 'Bool', is => 'ro' );

with (qw(RDF::Helper::API  RDF::Helper::PerlConvenience));

has base_uri => (
    isa     => 'Str',
    is      => 'ro',
    alias   => ['BaseURI'],
    default => sub {
        'file:' . getcwd();
    }
);

sub BUILD {
    my ( $self, $args ) = @_;
    unless ( defined( $self->namespaces->{'#default'} ) ) {
        $self->namespaces->{'#default'} = $self->BaseURI;
    }

    my %foo = reverse %{ $self->namespaces };
    $self->{_NS} = \%foo;
}

sub new_native_resource {
    my $self = shift;
    my $val  = shift;
    return RDF::Trine::Node::Resource->new($val);
}

sub new_native_literal {
    my $self = shift;
    my ( $val, $lang, $type ) = @_;
    return RDF::Trine::Node::Literal->new( $val, $lang, $type );
}

sub new_native_bnode {
    my $self = shift;
    my $id   = shift;
    return RDF::Trine::Node::Blank->new($id);
}

sub assert_literal {
    my $self = shift;
    my ( $s, $p, $o ) = @_;

    my ( $subj, $pred, $obj ) =
      $self->normalize_triple_pattern( $s, $p, undef );
    my @nodes = map { $self->helper2native($_) } ( $subj, $pred );

    $obj =
        ref($o)
      ? $o->does('RDF::Helper::Node::API') 
          ? $self->helper2native($o) 
          : $o
      : $self->new_native_literal("$o");
    push @nodes, $obj;
    $self->model->add_statement( RDF::Trine::Statement->new(@nodes) );
}

sub assert_resource {
    my $self = shift;
    my ( $s, $p, $o ) = @_;

    my ( $subj, $pred, $obj ) =
      $self->normalize_triple_pattern( $s, $p, undef );
    my @nodes = map { $self->helper2native($_) } ( $subj, $pred );

    $obj =
        ref($o)
      ? $o->does('RDF::Helper::Node::API') 
          ? $self->helper2native($o) 
          : $o
      : $self->new_native_resource(
        $self->ExpandQNames ? $self->qname2resolved($o) : $o );

    push @nodes, $obj;
    $self->model->add_statement( RDF::Trine::Statement->new(@nodes) );
}

sub add_statement {
    my $self      = shift;
    my $statement = shift;

    my @nodes = ();
    foreach my $type (qw( subject predicate object ) ){
        push @nodes, $self->helper2native( $statement->$type );
    }
    $self->model->add_statement( RDF::Trine::Statement->new(@nodes) );
}

sub remove_statements {
    my $self = shift;

    my $del_count = 0;

    my $e = $self->get_enumerator(@_);
    while ( my $s = $e->next ) {
        my @nodes = ();
        foreach my $type (qw( subject predicate object )) {
            push @nodes, $self->helper2native( $s->$type );
        }

        $self->model->remove_statement( RDF::Trine::Statement->new(@nodes) );
        $del_count++;
    }

    return $del_count;
}

sub update_node {
    my $self = shift;
    my ( $s, $p, $o, $new ) = @_;

    my $update_method = undef;

    # first, try to grok the type form the incoming node

    if ( ref($new) and $new->does('RDF::Trine::Node::API') ) {
        if ( $new->is_literal ) {
            $update_method = 'update_literal';
        }
        elsif ( $new->is_resource or $new->is_blank ) {
            $update_method = 'update_resource';
        }
    }

    unless ($update_method) {
        foreach my $stmnt ( $self->get_statements( $s, $p, $o ) ) {
            my $obj = $stmnt->object;
            if ( $obj->is_literal ) {
                $update_method = 'update_literal';
            }
            elsif ( $obj->is_resource or $obj->is_blank ) {
                $update_method = 'update_resource';
            }
            else {
                warn "updating unknown node type, falling back to literal.";
                $update_method = 'update_literal';
            }
        }
    }
    return $self->$update_method( $s, $p, $o, $new );
}

sub get_enumerator {
    my $self = shift;
    my ( $s, $p, $o ) = @_;

    my ( $subj, $pred, $obj ) = $self->normalize_triple_pattern( $s, $p, $o );

    my @nodes = map { $self->helper2native($_) } ( $subj, $pred, $obj );

    return RDF::Helper::RDFTrine::Enumerator->new(
        statement => RDF::Trine::Statement->new(@nodes),
        model     => $self->model,
    );
}

#---------------------------------------------------------------------
# Batch inclusions
#---------------------------------------------------------------------

sub include_rdfxml {
    my $self = shift;
    my %args = @_;
    my $p    = RDF::Trine::Parser->new('rdfxml');

    my $base_uri = $self->BaseURI;

    if ( defined( $args{filename} ) ) {
        $p->parse_file_into_model( $base_uri, $args{filename}, $self->model() );
    }
    elsif ( defined( $args{xml} ) ) {
        $p->parse_into_model( $base_uri, $args{xml}, $self->model() );
    }
    else {
        die
          "Missing argument. Yous must pass in an 'xml' or 'filename' argument";
    }
    return 1;
}

#---------------------------------------------------------------------
# Sub-object Accessors
#---------------------------------------------------------------------

sub serialize {
    my $self = shift;
    my %args = @_;

    $args{format} ||= 'rdfxml';

    my %namespaces = %{$self->namespaces};
    delete $namespaces{'#default'};
    my $serializer = RDF::Trine::Serializer->new( $args{format},
						  namespaces => \%namespaces,
						  base_uri => $self->base_uri );

    if ( $args{filename} ) {
        return $serializer->serialize_model_to_file( $args{filename},
            $self->model );
    }
    else {
        return $serializer->serialize_model_to_string( $self->model );
    }
}

1;

#---------------------------------------------------------------------
# RDF::Trine-specific enumerator
#---------------------------------------------------------------------

package RDF::Helper::RDFTrine::Enumerator;
use Moose; 
use RDF::Trine::Statement;
use RDF::Helper::Statement;

sub new {
    my $proto = shift;
    my %args  = @_;
    my $class = ref($proto) || $proto;
    die "Not enough args" unless $args{model};
    my $statement = delete $args{statement}
      || RDF::Trine::Statement->new( undef, undef, undef );
    my $self = bless \%args, $class;
    $self->{stream} = $self->{model}->get_statements( $statement->nodes );
    return $self;
}

sub next {
    my $self = shift;
    my $in   = undef;
    if ( defined $self->{stream} && !$self->{stream}->end ) {
        $in = $self->{stream}->current;
        $self->{stream}->next;
    }

    unless ($in) {
        ;
        delete $self->{stream};
        return undef;
    }

    my $s     = undef;
    my @nodes = ();
    foreach my $type (qw( subject predicate object )) {
        push @nodes, process_node( $in->$type );
    }
    return RDF::Helper::Statement->new(@nodes);
}

sub process_node {
    my $in = shift;

    my $out = undef;
    if ( $in->is_resource ) {
        $out = RDF::Helper::Node::Resource->new( uri => $in->uri_value );
    }
    elsif ( $in->is_blank ) {
        $out =
          RDF::Helper::Node::Blank->new( identifier => $in->blank_identifier );
    }
    else {
        my $type_uri = undef;
        if ( my $uri = $in->literal_datatype ) {
            
            $type_uri = blessed($uri)
              ? $uri->can('as_string')
                  ? $uri->as_string
                  : confess "$uri is not something we can coerce"
              : $uri;

        }
        $out = RDF::Helper::Node::Literal->new(
            value    => $in->literal_value,
            language => $in->literal_value_language,
            datatype => $type_uri
        );
    }
    return $out;
}
1;

__END__

=head1 NAME

RDF::Helper::RDFReland - RDF::Helper bridge for RDF::Trine

=head1 SYNOPSIS

  my $model = RDF::Trine::Model->new( 
      RDF::Trine::Storage->new( %storage_options )
  );

  my $rdf = RDF::Helper->new(
    Namespaces => \%namespaces,
    BaseURI => 'http://domain/NS/2004/09/03-url#'
  );

=head1 DESCRIPTION

RDF::Helper::RDFTrine is the bridge class that connects RDF::Helper's facilites to RDF::Trine and should not be used directly. 

See L<RDF::Helper> for method documentation

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

=head1 COPYRIGHT

Copyright (c) 2004 Kip Hampton.  
=head1 LICENSE

This module is free sofrware; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<RDF::Helper> L<RDF::Trine>.

=cut

