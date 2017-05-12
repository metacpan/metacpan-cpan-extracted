package RDF::Helper::RDFRedland;
use Moose;
use MooseX::Aliases;

use RDF::Redland;
use RDF::Helper::RDFRedland::Query;
use Cwd;
use RDF::Helper::Statement;


has query_interface => (
    isa     => 'Str',
    is      => 'ro',
    default => 'RDF::Helper::RDFRedland::Query'
);

has Model => (
    isa      => 'RDF::Redland::Model',
    accessor => 'model',
    lazy     => 1,
    builder  => '_build_model'
);

sub _build_model {
    RDF::Redland::Model->new(
        RDF::Redland::Storage->new(
            "hashes", "temp", "new='yes',hash-type='memory'"
        ),
        ""
    );
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

with qw(RDF::Helper::API  RDF::Helper::PerlConvenience );

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
    return RDF::Redland::Node->new( RDF::Redland::URI->new($val) );
}

sub new_native_literal {
    my $self = shift;
    my ( $val, $lang, $type ) = @_;
    if ( defined($type) and !ref($type) ) {
        $type = RDF::Redland::URI->new($type);
    }
    return RDF::Redland::Node->new_literal( "$val", $type, $lang );
}

sub new_native_bnode {
    my $self = shift;
    my $id   = shift;
    return RDF::Redland::Node->new_from_blank_identifier($id);
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
    $self->model->add_statement(@nodes);
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
    $self->model->add_statement(@nodes);
}

sub add_statement {
    my $self      = shift;
    my $statement = shift;

    my @nodes = ();
    foreach my $type qw( subject predicate object ) {
        push @nodes, $self->helper2native( $statement->$type );
    }

    $self->model->add_statement(@nodes);
}

sub remove_statements {
    my $self = shift;

    my $del_count = 0;

    my $e = $self->get_enumerator(@_);
    while ( my $s = $e->next ) {
        my @nodes = ();
        foreach my $type qw( subject predicate object ) {
            push @nodes, $self->helper2native( $s->$type );
        }

        $self->model->remove_statement( RDF::Redland::Statement->new(@nodes) );
        $del_count++;
    }

    return $del_count;
}

sub update_node {
    my $self = shift;
    my ( $s, $p, $o, $new ) = @_;

    my $update_method = undef;

    # first, try to grok the type form the incoming node

    if ( ref($new) and $new->does('RDF::Redland::Node::API') ) {
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

    return RDF::Helper::RDFRedland::Enumerator->new(
        statement => RDF::Redland::Statement->new(@nodes),
        model     => $self->model,
    );
}


#---------------------------------------------------------------------
# Batch inclusions
#---------------------------------------------------------------------


sub include_rdfxml {
    my $self = shift;
    my %args = @_;
    my $p    = RDF::Redland::Parser->new('rdfxml');

    my $base_uri = RDF::Redland::URI->new( $self->BaseURI );

    if ( defined( $args{filename} ) ) {
        my $file = $args{filename};
        if ( $file !~ /^file:/ ) {
            $file = 'file:' . $file;
        }
        my $source_uri = RDF::Redland::URI->new($file);
        $p->parse_into_model( $source_uri, $base_uri, $self->model() );
    }
    elsif ( defined( $args{xml} ) ) {
        $p->parse_string_into_model( $args{xml}, $base_uri, $self->model() );
    }
    else {
        confess
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

    $args{format} ||= 'rdfxml-abbrev';
    my $serializer = undef;

    # Trix is handled differently
    if ( $args{format} eq 'trix' ) {
        eval "require RDF::Trix::Serializer::Redland";
        $serializer =
          RDF::Trix::Serializer::Redland->new( Models => [ [ $self->model ] ] );

        # XXX: Cleanup on aisle 5...
        my $trix = $serializer->as_string();

        if ( $args{filename} ) {
            open( TRIX, $args{filename} )
              || die "could not open file '$args{filename}' for writing: $! \n";
            print TRIX $trix;
            close TRIX;
            return 1;
        }
        return $trix;
    }

    $serializer = RDF::Redland::Serializer->new( $args{format} );
    if ( $serializer->can("set_namespace") ) {
        while ( my ( $prefix, $uri ) = each %{ $self->namespaces } ) {
            next if ( $prefix eq 'rdf' or $prefix eq '#default' );
            $serializer->set_namespace( $prefix, RDF::Redland::URI->new($uri) );
        }
    }

    if ( $args{filename} ) {
        return $serializer->serialize_model_to_file( $args{filename},
            RDF::Redland::URI->new( $self->BaseURI ),
            $self->model );
    }
    else {
        return $serializer->serialize_model_to_string(
            RDF::Redland::URI->new( $self->BaseURI ),
            $self->model );
    }
}

#---------------------------------------------------------------------
# Redland-specific enumerator
#---------------------------------------------------------------------

package RDF::Helper::RDFRedland::Enumerator;
use strict;
use warnings;
use RDF::Redland::Statement;
use RDF::Helper::Statement;

sub new {
    my $proto = shift;
    my %args  = @_;
    my $class = ref($proto) || $proto;
    die "Not enough args" unless $args{model};
    my $statement = delete $args{statement}
      || RDF::Redland::Statement->new( undef, undef, undef );
    my $self = bless \%args, $class;
    $self->{stream} = $self->{model}->find_statements($statement);
    return $self;
}
##

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
    foreach my $type qw( subject predicate object ) {
        push @nodes, process_node( $in->$type );
    }
    return RDF::Helper::Statement->new(@nodes);
}

sub process_node {
    my $in = shift;

    my $out = undef;
    if ( $in->is_resource ) {
        $out = RDF::Helper::Node::Resource->new( uri => $in->uri->as_string );
    }
    elsif ( $in->is_blank ) {
        $out =
          RDF::Helper::Node::Blank->new( identifier => $in->blank_identifier );
    }
    else {
        my $type_uri = undef;
        if ( my $uri = $in->literal_datatype ) {
            $type_uri = $uri->as_string;
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

RDF::Helper::RDFReland - RDF::Helper bridge for RDF::Redland

=head1 SYNOPSIS

  my $model = RDF::Redland::Model->new( 
      RDF::Redland::Storage->new( %storage_options )
  );

  my $rdf = RDF::Helper->new(
    Namespaces => \%namespaces,
    BaseURI => 'http://domain/NS/2004/09/03-url#'
  );

=head1 DESCRIPTION

RDF::Helper::RDFRedland is the bridge class that connects RDF::Helper's facilites to RDF::Redland and should not be used directly. 

See L<RDF::Helper> for method documentation

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

=head1 COPYRIGHT

Copyright (c) 2004 Kip Hampton.  
=head1 LICENSE

This module is free sofrware; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<RDF::Helper> L<RDF::Redland>.

=cut
