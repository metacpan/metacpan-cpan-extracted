package Net::Marathon::Group;

use strict;
use warnings;
use parent 'Net::Marathon::Remote';
use JSON::XS;

sub new {
    my ($class, $conf, $parent) = @_;
    my $self = bless {};
    $conf = {} unless $conf && ref $conf eq 'HASH';
    $self->{data} = $conf;
    $self->{parent} = $parent;
    $self->{children} = {
        apps => {},
        groups => {},
    };
    if ( $conf->{apps} ) {
        foreach ( @{$conf->{apps}} ) {
            $self->add( Net::Marathon::App->new( $_, $parent ) ); 
        }
    }
    if ( $conf->{groups} ) {
        foreach ( @{$conf->{groups}} ) {
            $self->add( Net::Marathon::Group->new( $_, $parent ) ); 
        }
    }
    return $self;
}

sub list {
    my $self = shift;
    
}

sub get {
    my ($self, $id, $parent) = @_;
    my $api_response_obj = $parent->_get_obj('/v2/groups/' . $id);
    return undef unless $api_response_obj;
    return $self->new( $api_response_obj, $parent );
}

sub create {
    my $self = shift;
    $self->_bail unless defined $self->{parent};
    my $response = $self->{parent}->_post('/v2/groups', $self->get_updateable_values);
    if ( $response ) {
        $self->version( decode_json($response)->{version} );
        return $self;
    } 
    return undef;
}

sub update {
    my ($self, $args) = @_;
    $self->_bail unless defined $self->{parent};
    my $payload = $self->get_updateable_values;
    delete $payload->{id};
    my $response = $self->{parent}->_put('/v2/groups/' . $self->id . $self->_uri_args($args), $payload);
    if ( $response ) {
        $self->version( decode_json($response)->{version} );
        return $self;
    } 
    return undef;
}

sub delete {
    my ($self, $args) = @_;
    $self->_bail unless defined $self->{parent};
    return $self->{parent}->_delete('/v2/groups/' . $self->id . $self->_uri_args($args));
}

sub _uri_args {
    my ($self, $args) = @_;
    my $retval = '';
    foreach ( keys %{$args} ) {
        $retval .= $_ .'=' . $args->{$_};
    }
    return $retval ? '?' . $retval : $retval;
}

sub add {
    my ($self, $child) = @_;
    if ( $child->isa('Net::Marathon::App') ) {
        if ( exists $self->{children}->{apps}->{$child->id} ) {
            print STDERR "You cannot add the same App twice.\n" if $Net::Marathon::verbose;
            return 0;
        }
        $self->{children}->{apps}->{$child->id} = $child;
    } elsif ( $child->isa('Net::Marathon::Group') ) {
        if ( $self->is_or_has($child) ) {
            print STDERR "You cannot add a group to itself.\n" if $Net::Marathon::verbose;
            return 0;
        }
        $self->{children}->{groups}->{$child->id} = $child;
    } else {
        print STDERR "You cannot add something else than an App or a Group to a Group.\n" if $Net::Marathon::verbose;
        return 0;
    }
    return 1;
}

sub is_or_has {
    my ($self, $other) = @_;
    if ( $self->id eq $other->id ) {
        return 1;
    }    
    foreach my $group ( values %{$self->{children}->{groups}} ) {
        return $group->is_or_has($other);
    }
    return 0;
}

sub apps {
    my $self = shift;
    my @apps = values %{$self->{children}->{apps}};
    return scalar @apps ? wantarray ? @apps : \@apps : undef;
}

sub groups {
    my $self = shift;
    my @groups = values %{$self->{children}->{groups}};
    return scalar @groups ? wantarray ? @groups : \@groups : undef;
}

sub get_updateable_values {
    my $self = shift;
    my $struct = {
        id => $self->id,
    };
    if ( $self->dependencies ) {
        $struct->{dependencies} = $self->dependencies;
    }
    if ( $self->apps ) {
        $struct->{apps} = [];
        foreach my $app ( $self->apps ) {
            push @{$struct->{apps}}, $app->get_updateable_values
        }
    }
    if ( $self->groups ) {
        $struct->{groups} = [];
        foreach my $group ( $self->groups ) {
            push @{$struct->{groups}}, $group->get_updateable_values
        }
    }
    return $struct;
}

1;
