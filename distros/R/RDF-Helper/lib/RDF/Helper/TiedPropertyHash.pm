package RDF::Helper::TiedPropertyHash;
use strict;
use warnings;
require Tie::Hash;
use Data::Dumper;
use vars qw( @ISA );
@ISA = qw( Tie::ExtraHash );
use overload
    '""' => \&overload_uri,
    'eq' => \&overload_uri_equals,
    '==' => \&overload_uri_equals;

sub new {
    my $proto = shift;
    my %args = @_;
    my %data;
    
    unless ( $args{Helper} ) {
        eval "require RDF::Helper";
        $args{Helper} = RDF::Helper->new( BaseInterface => 'RDF::Redland' );
    }
    
    tie %data, 
        'RDF::Helper::TiedPropertyHash', 
        $args{Helper}, 
        $args{ResourceURI},
        $args{Options};
    return \%data;
}

#----------------------------------------
# here, $self is an array ref with the following indices
# 0 -- a ref to the hash we're operation on
# 1 -- a ref to the RDF::Helper object that suppies the backend
# 2 -- The subject URI associated with this set of properties.
#----------------------------------------

sub TIEHASH {
    my $class = shift;
    my ( $helper, $lookup_uri, $options ) = @_;
    $options ||= {
        Deep => 0
    };
    my $data = {};
    
    unless ( defined $helper ) {
        eval "require RDF::Helper";
        $helper = RDF::Helper->new( BaseInterface => 'RDF::Redland' );
    }
    if ( defined $lookup_uri ) {
        foreach my $stmnt ( $helper->get_statements( $lookup_uri, undef, undef ) ) {
            my $predicate = $stmnt->predicate->uri->as_string;
            my $prop_key = $helper->resolved2prefixed( $predicate );
            push @{$data->{$prop_key}}, $stmnt->object;
        }
    }
    else {
        $lookup_uri = $helper->new_bnode;
    }
    bless [$data, $helper, $lookup_uri, $options], $class;
}

sub DELETE {
    my $self = shift;
    my $key = shift;
    my $prop_uri = $self->[1]->prefixed2resolved( $key );
    $self->[1]->remove_statements( $self->[2], $prop_uri );
    my @results = map { $self->_node_value($_) } @{$self->[0]->{$key}};
    delete $self->[0]->{$key};
    if ($#results > 0) {
        return \@results;
    } else {
        return $results[0];
    }
}

sub CLEAR {
    #warn "clear called!!!!";
    my $self = shift;
    my $key = shift;
    $self->[1]->remove_statements( $self->[2] );
    %{$self->[0]} = ();
}

sub FETCH {
    my $self = shift;
    my $key = shift;

    # Return the resource URI of this hash if requested
    if ($key eq 'resource_uri') {
        return $self->[2];
    }

    # Otherwise, return the property value
    if (defined($self->[0]->{$key}) and ref($self->[0]->{$key}) eq 'ARRAY' and scalar(@{$self->[0]->{$key}}) > 0) {
        my @results = ();
        foreach my $obj (@{$self->[0]->{$key}}) {

            # Find the node's value
            my $val = $self->_node_value($obj);

            # If it's a resource, make it an object
            if ($self->[3]->{Deep} and ($obj->is_resource or $obj->is_blank)) {
                $val = $self->[1]->tied_property_hash( $val );
            }
            push @results, $val;
        }
        if ($#results > 0) {
            return \@results;
        } else {
            return $results[0];
        }
    }
    return undef;
}

sub STORE {
    my $self = shift;
    my ($key, $value) = @_;
    
    my $val_type = $self->[1]->get_perl_type( $value );    
    my $prop_uri = $self->[1]->prefixed2resolved( $key );
    my $old_val = $self->[0]->{$key};

    if ( defined $old_val and ref($old_val) eq 'ARRAY' and scalar(@$old_val) > 0) {
        $self->[1]->remove_statements( $self->[2], $prop_uri );
    }
    
    if ( $val_type eq 'literal' ) {
        $self->[1]->assert_literal( $self->[2], $prop_uri, $value )
    }
    elsif ( $val_type eq 'resource' or $val_type eq 'SCALAR') {
        $self->[1]->assert_resource( $self->[2], $prop_uri, $value )
    }
    elsif ( $val_type eq 'ARRAY' ) {
        foreach my $v ( @{$value} ) {
            # this is dubious
            my $type = $self->[1]->get_perl_type( $v );

            if ( $type eq 'resource' ) {
                $self->[1]->assert_resource( $self->[2], $prop_uri, $v );
            }
            else {
                $self->[1]->assert_literal( $self->[2], $prop_uri, $v );
            }
        }
    }
    # get smarter here
    else {
       die "I do not know how to store value of reference type '$val_type' as RDF, please contact the module author";
    }
    
    $self->[0]->{$key} = [ map { $_->object } $self->[1]->get_statements( $self->[2], $prop_uri, undef ) ];
}

sub _node_value {
    my $self = shift;
    my $obj = shift;
    return $obj unless (ref($obj));

    if ($obj->is_literal) {
        return $obj->literal_value;
    } elsif ($obj->is_resource) {
        return $obj->uri->as_string;
    } else {
        return $obj->as_string;
    }
}

sub overload_uri {
    my $self = shift;
    return $self->[2];
}

sub overload_uri_equals {
    my $self = shift;
    my $value = shift;
    return $self->[2] eq $value;
}

1;
