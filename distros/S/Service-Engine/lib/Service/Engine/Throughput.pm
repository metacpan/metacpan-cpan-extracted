package Service::Engine::Throughput;

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Service::Engine;

use threads;
use threads::shared;

our $Config;
our $Log;
our $Data;
our $EngineName;
our $AddCounter = {};
our $FinishCounter = {};

share($AddCounter);
share($FinishCounter);

sub new {
    
    my ($class,$options) = @_;
    
    # set some defaults
    my $attributes = {};
    
    # load options
    if (ref($options) eq 'HASH') {
        foreach my $option (keys %{$options}) {
            $attributes->{$option} = $options->{$option};
        }
    }
    
    # pull in some Service::Engine globals
    $Config = $Service::Engine::Config;
    $Data = $Service::Engine::Data;
    $Log = $Service::Engine::Log;
    $EngineName = $Service::Engine::EngineName;
        
    $AddCounter->{'350'} = shared_clone([]);
    $AddCounter->{'5'} = shared_clone([]);
    $AddCounter->{'10'} = shared_clone([]);
    $AddCounter->{'60'} = shared_clone([]);
    
    $FinishCounter->{'350'} = shared_clone([]);
    $FinishCounter->{'5'} = shared_clone([]);
    $FinishCounter->{'10'} = shared_clone([]);
    $FinishCounter->{'60'} = shared_clone([]);
    
    $Log->log({msg=>"loading Throughput",level=>2});

    my $self = bless $attributes, $class;
    
    return $self;

}

sub add {
    
    my ($self,$count) = @_;
    
    my $now = time();
    
    my @queue_numbers = ('5','10','60','350');
    
    foreach my $number (@queue_numbers) {
    	# first remove old items from queues
    	my @valid_items = ();
    	my $old = $now - $number;
        foreach my $item (@{$AddCounter->{$number}}) {
            if ($item > $old) {
                push @valid_items, $item;
            }        	
        }
        # pop on new items
        my $i = 0;
        while ($i < $count) {
            push @valid_items,$now;
            $i++;
        }
        $AddCounter->{$number} = shared_clone(\@valid_items);
    }
    
    $Log->log({msg=>"added $count items",level=>3});
    return;
    
}

sub finish {
    
    my ($self) = @_;
    
    
    my $now = time();
    
    my @queue_numbers = ('5','10','60','350');
    
    foreach my $number (@queue_numbers) {
    	# first remove old items from queues
    	my @valid_items = ();
    	my $old = $now - $number;
        foreach my $item (@{$FinishCounter->{$number}}) {
            if ($item > $old) {
                push @valid_items, $item;
            }
        }
        # pop on new item
        push @valid_items,$now;
        $FinishCounter->{$number} = shared_clone(\@valid_items);
    }
    
    $Log->log({msg=>"finishing item",level=>3});
    return;
    
}

sub throughput {
    
    my ($self) = @_;
    
    my $now = time();
    
    my @queue_numbers = ('5','10','60','350');
    
    my $stats = {};
        
    foreach my $number (@queue_numbers) {
       
        my $in = scalar(@{$AddCounter->{"$number"}});
        my $out = scalar(@{$FinishCounter->{"$number"}});
        my $duration = $number;
        my $ratio = 0;
        if ($out) {
            $ratio = sprintf('%.2f', $in / $out);
        }
        my $throughput = sprintf('%.2f',$out / $duration);
        
        $stats->{"$number"} = {'in'=>$in,'out'=>$out,'ratio'=>$ratio,'throughput'=>$throughput};
                
    };
    
    return $stats;
    
}


1;