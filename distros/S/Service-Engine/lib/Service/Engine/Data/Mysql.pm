package Service::Engine::Data::Mysql;

use 5.010;
use strict;
use warnings;
use Data::Dumper;

use Service::Engine;
use DBI;

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
    $attributes->{'port'} ||= '3306';
    
    if (!$attributes->{'database'} || !$attributes->{'hostname'} || !$attributes->{'username'} || !$attributes->{'password'}) {
        $Log->log({msg=>"mysql requires a database, hostname, username and password",level=>1});
    } else {
        my $datasource = 'DBI:mysql:' . $attributes->{'database'} . ':' . $attributes->{'hostname'} . ':' . $attributes->{'port'};
        my $db = DBI->connect($datasource, $attributes->{'username'}, $attributes->{'password'},{ RaiseError => $attributes->{'raise_error'}, mysql_enable_utf8 => 1, mysql_auto_reconnect => 1 });
        $attributes->{'handle'} = $db;
        $Log->log({msg=>"creating connection to $datasource",level=>3});
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
    my $datasource = 'DBI:mysql:' . $self->{'database'} . ':' . $self->{'hostname'} . ':' . $self->{'port'};
    my $db = DBI->connect($datasource, $self->{'username'}, $self->{'password'},{ RaiseError => $self->{'raise_error'}, mysql_enable_utf8 => 1, mysql_auto_reconnect => 1 });
    $Log->log({msg=>"re-connecting to $datasource",level=>3});
    $self->{'handle'} = $db;  
    return $self->{'handle'};
}

1;