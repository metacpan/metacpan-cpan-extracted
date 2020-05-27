package Service::Engine::Alerting::Log;

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Service::Engine;

our $Config;
our $Log;
our $Alert;

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
    
    my $self = bless $attributes, $class;
    
    return $self;

}


sub to_console {

    my ($self, $args) = @_;  
    
    my $msg = $args->{'msg'};
    
    my $log = {'msg'=>"ALERT: " . $msg,'level'=>2};
    
    $Log->to_console($log);
    
    return 1;
    
}

sub to_file {

    my ($self, $args) = @_;  
    
    my $msg = $args->{'msg'};
    
    my $log = {'msg'=>"ALERT: " . $msg,'level'=>2};
    
    $Log->to_file($log);
    
    return 1;
    
}

sub to_data {

    my ($self, $args) = @_;  
    
    my $msg = $args->{'msg'};
    
    my $log = {'msg'=>"ALERT: " . $msg,'level'=>2};
    
    $Log->to_data($log);
    
    return 1;
    
}


1;