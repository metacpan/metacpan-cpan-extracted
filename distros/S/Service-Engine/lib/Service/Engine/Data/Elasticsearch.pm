package Service::Engine::Data::Elasticsearch;

use 5.010;
use strict;
use warnings;
use Data::Dumper;

use Service::Engine;
use Search::Elasticsearch;

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

    $attributes->{'cxn_pool'} ||= 'Static';
    $attributes->{'trace_to'} ||= undef;
    
    if (!$attributes->{'nodes'}) {
        $Log->log({msg=>"Elasticsearch requires nodes",level=>1});
    } else {
        my $handle = eval{Search::Elasticsearch->new('nodes'=>$attributes->{'nodes'}, 'cxn_pool'=>$attributes->{'cxn_pool'}, 'trace_to' => $attributes->{'trace_to'} );};
        
        if ($@) {
            $Log->log({msg=>"error connecting to Elasticsearch: $@",level=>1});
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
    my $handle = eval{Search::Elasticsearch->new('nodes'=>$self->{'nodes'}, 'cxn_pool'=>$self->{'cxn_pool'}, 'trace_to' => $self->{'trace_to'} );};
    if ($@) {
        $Log->log({msg=>"error re-connecting to Elasticsearch: $@",level=>1});
    } else {
        $self->{'handle'} = $handle;
    } 
    return $self->{'handle'};
}

1;