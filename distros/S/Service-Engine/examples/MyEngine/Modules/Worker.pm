package myEngine::Modules::Worker;

use 5.010;
use strict;
use warnings;
use File::Slurp;
use Carp;
use Data::Dumper;

use Service::Engine;

our $Config;
our $Log;
our $EngineName;
our $Alert;
our $Throughput;

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
    $Log = $Service::Engine::Log;
    $Alert = $Service::Engine::Alert;
    $Throughput = $Service::Engine::Throughput;
    $EngineName = $Service::Engine::EngineName;

    $Log->log({msg=>"loading $EngineName" . "::Modules::Worker",level=>2});
    
    my $self = bless $attributes, $class;
    
    return $self;

}

sub process {
    
    my ($self, $queue_item) = @_;
    
    if (ref($queue_item) ne 'HASH') {
        $Log->log({msg=>"ERROR: $queue_item must be an object: " , Dumper($queue_item),level=>1});
        return '';
    }
    
    # you get a HASH with a reference to your data handles, 
    # the item in the queque, and the id of the thread processing the request
    
    # each thread needs its own data handles; they are set automatically in Threads.pm
    my $Data = $queue_item->{data};
    my $item = $queue_item->{item};
    my $thread_id = $queue_item->{id};
    $Log->log({msg=>"processing: thread $thread_id",level=>3});
    
    # YOUR CODE GOES HERE
    # process $item
    
    # === some tests
    my $memd = $Data->prod_mc();
    $memd->set('testkey','testval');
    say($memd->get('testkey'));
    
    my $dbh = $Data->prod_mysql();
    my ($value) = $dbh->selectrow_array("SELECT NOW()");
    say($value);
    # === end tests
    
    return '';
    
}

1;