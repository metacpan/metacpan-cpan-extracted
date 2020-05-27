package myEngine::Modules::Selector;

use 5.010;
use strict;
use warnings;
use File::Slurp;
use Carp;
use Data::Dumper;

use Service::Engine;

our $Config;
our $Log;
our $Data;
our $EngineName;

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
    $Data = $Service::Engine::Data;
    $EngineName = $Service::Engine::EngineName;

    $Log->log({msg=>"loading $EngineName" . "::Modules::Selector",level=>2});

    my $self = bless $attributes, $class;
    
    return $self;

}

sub get {
    
    my ($self) = @_;
    
    # YOUR CODE GOES HERE
    
    # === some tests
    my $dbh = $Data->prod_mysql();
    my ($value) = $dbh->selectrow_array("SELECT NOW()");
    say($value);
    # === end tests
    
    # return an array reference of items to process in the worker module
    return [$value];
    
}

1;