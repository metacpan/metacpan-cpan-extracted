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
    
    my @to_process = ();
    
    my $dbh = $Data->prod_mysql();
    
    my $post_sql = "SELECT id, content FROM posts";
    my $post_sth = $dbh->prepare($post_sql);
    $post_sth->execute();
    
    while (my ($id, $content) = $post_sth->fetchrow_array()) {
        push @to_process, {id=>$id, content=>$content};
    }
    
    return \@to_process;
}

1;