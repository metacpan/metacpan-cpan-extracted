package RDF::Helper::Object;
use strict;
use warnings;
use Data::Dumper;
use Data::UUID;
use RDF::Helper::TiedPropertyHash;
use vars qw( $AUTOLOAD );
use overload
    '""' => \&object_uri,
    'eq' => \&object_uri_equals,
    '==' => \&object_uri_equals;

# TODO:
# - Handle namespaces properly

=head1 NAME

RDF::Helper::Object - Perl extension to use RDF property names as methods

=head1 SYNOPSIS

  use RDF::Helper;
  my $rdf = RDF::Helper->new(
      BaseInterface => 'RDF::Trine',
      namespaces => { 
        dc => 'http://purl.org/dc/terms/',
        rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        '#default' => "http://xmlns.com/foaf/0.1/"
     }
  );
  my $obj = $rdf->get_object('http://dahut.pm.org/dahut_group.rdf#bender');
  $obj->rdf_type('http://xmlns.com/foaf/0.1/Person');
  $obj->name("Bender");
  $obj->dc_description("A description of Bender");
  print $rdf->serialize(format => 'rdfxml')

=head1 DESCRIPTION

An object of this class is returned by the L<RDF::Helper>
C<get_object> method, which takes a B<subject> URI as the first
argument, and optionally a hash or hashref of options as the second
argument.

On this object, you may then call methods that correspond to property
names of the properties you want to get or set.

For properties in the default namespace, you may use them without any
regard to prefixes, whereas with properties in other namespaces, you
need to use the prefix and an underscore before the property name.

This class does not make any attempt to verify whether the methods are
actually valid properties within the used schema, it just blindly does
what you tell it to. It is suitable for creating relatively simple RDF.

To set more than one object, use an arrayref as argument, e.g.

  $obj->rdfs_label(['Foo', 'Bar'])

will result in two triples, one for each C<rdfs:label>.

=cut

sub new {
    my $proto = shift;
    my %args;
    if ($#_ % 2) {
        %args = @_;
    } else {
        my $ResourceURI = shift;
        %args = @_;
        $args{ResourceURI} = $ResourceURI;
    }
    my $class = ref( $proto ) || $proto;

    my $self = {};
    $self->{_datastore_} = $args{RDFHelper};
    my $ug    = new Data::UUID;
    my $uuid = $ug->create();

    $self->{_uri_} = $args{ResourceURI} || "urn:" . $ug->to_string( $uuid );

    $self->{_rdftype_} = $args{RDFType};
    $self->{_defaultns_} = $args{DefaultNS} || $self->{_datastore_}->namespaces->{'#default'} || '';
        
    if ( defined( $args{NoTie} ) and $args{NoTie} == 1 ) {
        $self->{_data_} = $self->{_datastore_}->property_hash(
                            $self->{_uri_}
                          );
        $self->{_tied_} = 0;
    }
    else {
        unless (defined( $args{TiedHashOptions} )) {
            $args{TiedHashOptions}->{Deep} = 1;
        }
        $self->{_data_} = $self->{_datastore_}->tied_property_hash(
                            $self->{_uri_},
                            $args{TiedHashOptions}
                          );
        $self->{_tied_} = 1;
    }
    
    #warn "inired with data" . Dumper( $self->{_data_} );
    
    my $obj = bless $self, $class;
    
    # init for new objects
    $obj->object_init_internal;

    return $obj;
}

sub object_default_namespace {
    my $self = shift;
    if ( @_ ) {
        $self->{_defaultns_} = shift;
    }
    return $self->{_defaultns_};
}

sub object_init_internal {
    my $self = shift;
    unless ( defined( $self->{_data_}->{'rdf:type'} ) ) {
        my $type = $self->object_rdfclasstype;
        $self->{_data_}->{'rdf:type'} = $type if ($type);
    }    
}

sub object_is_tied {
    my $self = shift;
    return $self->{_tied_};
}

sub object_uri {
    my $self = shift;
    return $self->{_uri_};
}

sub object_uri_equals {
    my $self = shift;
    my $value = shift;
    return $self->object_uri eq $value;
}

sub object_datastore {
    my $self = shift;
    return $self->{_datastore_};
}

sub object_rdfclasstype {
    my $self = shift;
    if ( $#_ > -1 and $_[0] ) {
        $self->{_rdftype_} = shift;
    }
    if ($self->{_rdftype_}) {
       return $self->{_rdftype_};
    } else {
       return $self->{_data_}->{'rdf:type'};
   }
}

sub object_data {
    my $self = shift;
    my $new = shift;
    if ( $new ) {
        # this is a little different since its a tied hash
        %{$self->{_data_}} = ();
        foreach my $key ( keys( %{$new} ) ) {
            $self->{_data_}->{$key} = $new->{$key};
        }
        $self->object_init_internal;
        return 1;
    }
    # don'[t cough up the tied data, give a copy
    # and add the internal properties
    my $clone = {};
    foreach my $k ( keys( %{$self->{_data_}} ) ) {
        $clone->{$k} = $self->{_data_}->{$k};
    }
    $clone->{object_uri} = $self->object_uri;
    
    #warn "returning clone" . Dumper( $clone );
    return $clone;
}

sub AUTOLOAD {
    # don't DESTROY 
    return if $AUTOLOAD =~ /::DESTROY/;
    die "Unknown method" if $AUTOLOAD =~ /::object_.*$/;

    my $self = $_[0];
    
    # fetch the attribute name
    $AUTOLOAD =~ /.*::([a-zA-Z0-9_]+)/;
    my $ns = $self->object_default_namespace;
    my $attr = $1;
    my $attr_uri = $ns . $attr;
    if ($attr =~ /^([^_]+)_(.+)$/) {
        my $nsprefix = $1;
        my $nsattr = $2;
        if ($self->{_datastore_}->namespaces->{$nsprefix}) {
            $ns = $self->{_datastore_}->namespaces->{$nsprefix};
            $attr = $nsprefix . ':' . $nsattr;
            $attr_uri = $ns . $nsattr;
        }
    }

    
    if ( $attr  ) {
        no strict 'refs';
        # create the method
        *{$AUTOLOAD} = sub {
            #warn "accessor called: $attr";
            my $self = shift;
            if ( @_ ) {
                my $val = shift;
                unless( defined( $val ) ) {
                    delete $self->{_data_}->{$attr};
                    return 1;
                }
                $self->{_data_}->{$attr} = $val;
                return 1;
            }
            if (defined $self->{_data_}->{$attr}) {
                my $result = $self->{_data_}->{$attr};
                my @results = ref($result) eq 'ARRAY' ? @$result : $result;
                @results = map {ref($_) eq 'HASH' ? $self->{_datastore_}->get_object($_->{resource_uri}) : $_ } @results;
                if ($#results > 0) {
                    return wantarray ? @results : \@results;
                } else {
                    return $results[0];
                }
            }
            return undef;
        };
        # now do it
        goto &{$AUTOLOAD};
    }
}

1;
