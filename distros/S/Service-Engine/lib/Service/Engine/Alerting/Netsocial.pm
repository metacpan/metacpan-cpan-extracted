package Service::Engine::Alerting::Netsocial;

use 5.010;
use strict;
use warnings;
use Data::Dumper;

use Service::Engine;

our $Config;
our $Log;

###>>>TO DO - this is just a stub for alerting methods for NetSocial

sub new {
    
    my ($class,$options) = @_;
        
    # set some defaults
    my $attributes = {'method'=>''};
    
    # load options
    if (ref($options) eq 'HASH') {
        foreach my $option (keys %{$options}) {
            $attributes->{$option} = $options->{$option};
        }
    }
    
    # pull in some Service::Engine globals
    $Config = $Service::Engine::Config;
    $Log = $Service::Engine::Log;
    
    # set some defaults
    
    my $self = bless $attributes, $class;
    
    return $self;

}

sub method {
    my ($self) = @_;    
    return $self->{'method'};
}

1;