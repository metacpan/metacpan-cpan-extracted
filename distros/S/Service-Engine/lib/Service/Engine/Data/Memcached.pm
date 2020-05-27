package Service::Engine::Data::Memcached;

use 5.010;
use strict;
use warnings;
use Data::Dumper;

use Service::Engine;
use Cache::Memcached::Fast;

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
    
    if (!$attributes->{ip} || !$attributes->{port}) {
        $Log->log({msg=>"memcached requires a port and ip",level=>1});
    } else {
        my $thismemd =
        new Cache::Memcached::Fast {
                    'servers' => [ $attributes->{ip}.':'.$attributes->{port} ],
                    'compress_threshold' => 10_000,
                };
        $thismemd->enable_compress(1) if $thismemd;
        $attributes->{'handle'} = $thismemd; 
    }
    
    my $self = bless $attributes, $class;
    
    return $self;

}

sub handle {
    my ($self) = @_;
    $Log->log({msg=>'memcache_ip: ' . $self->{'ip'} . ' port: ' . $self->{'port'},level=>3}); 
    return $self->{'handle'};
}

1;