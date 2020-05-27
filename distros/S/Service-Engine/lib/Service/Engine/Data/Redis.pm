package Service::Engine::Data::Redis;

use 5.010;
use strict;
use warnings;
use Data::Dumper;

use Service::Engine;
use RedisDB;

our $Config;
our $Log;

sub new {
    
    my ($class,$options) = @_;
        
    # set some defaults
    my $attributes = {'handle'=>''};
    
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
    $attributes->{'raise_error'} ||= 0;
    $attributes->{'port'} ||= 3306;
    $attributes->{'timeout'} ||= 2;
    
    if (!$attributes->{'hostname'}) {
        $Log->log({msg=>"redis requires a hostname",level=>1});
    } else {
        my $handle = eval{RedisDB->new(host => $attributes->{'hostname'}, port => $attributes->{'port'}, password=> $attributes->{'password'}, raise_error => $attributes->{'raise_error'}, timeout => $attributes->{'timeout'});};
        if ($@) {
            $Log->log({msg=>"error connecting to Redis: $@",level=>1});
        } else {
            $attributes->{'handle'} = $handle;
        }
    }

    my $self = bless $attributes, $class;
    
    return $self;

}

sub handle {
    my ($self) = @_;    
    return $self->{'handle'};
}

sub reconnect {
    my ($self) = @_;  
    my $handle = eval{RedisDB->new(host => $self->{'hostname'}, port => $self->{'port'}, password=> $self->{'password'}, raise_error => $self->{'raise_error'}, timeout => $self->{'timeout'});};
    if ($@) {
        $Log->log({msg=>"error connecting to Redis: $@",level=>1});
    } else {
        $self->{'handle'} = $handle;
    } 
    return $self->{'handle'};
}

1;