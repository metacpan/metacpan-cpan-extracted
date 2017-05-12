#!/usr/bin/perl
#

##################################################################
package Service;
use strict;

sub new {
    my ($class)  = shift;
    my (%params) = @_;
    bless { "_ports" => undef }, $class;
}

sub get_port {
    my $self = shift;
    my ($port_name) = @_;
    return $self->{'_ports'}->{$port_name};
}

sub get_port_binding {
    my $self = shift;
    my ($port_name) = @_;
    return $self->get_port($port_name)->binding();
}

sub add_port {
    my $self = shift;
    my $port = Service::Port->new(@_);
    $self->{'_ports'}->{ $port->name() } = $port;
}

##################################################################
package Service::Port;
use strict;

sub BEGIN {
    no strict 'refs';
    for my $method (qw(name bindingName binding)) {
        my $field = '_' . $method;
        *$method = sub {
            my $self = shift;
            @_
              ? ( $self->{$field} = shift, return $self )
              : return $self->{$field};
          }
    }
}

sub address {
    my $self = shift;
    return $self->binding->{'address'};
}

sub new {
    my ($class)  = shift;
    my (%params) = @_;

    bless {
        "_name"        => $params{"name"},
        "_binding"     => $params{"binding"},
        "_bindingName" => $params{"bindingName"}
    }, $class;
}

##################################################################
1;
