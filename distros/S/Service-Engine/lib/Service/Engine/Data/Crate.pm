package Service::Engine::Data::Crate;

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

    my $attributes = {'handle'=>''};
    
    if (ref($options) eq 'HASH') {
        foreach my $option (keys %{$options}) {
            $attributes->{$option} = $options->{$option};
        }
    }
    
    $Config = $Service::Engine::Config;
    $Log = $Service::Engine::Log;
    
    $attributes->{'raise_error'} ||= 0;
    
    if (!$attributes->{'hostname'} || !$attributes->{'username'} || !$attributes->{'password'} || !$attributes->{'dbname'} || !$attributes->{'port'}) {
        # Please note when logging in data handlers. Please do not log to data.
        # So please use the msg parameter for error handling as this will log both to file and and console when enabled on settings (like the example below).
        $Log->log({msg=>"cratedb requires a hostname, username and password",level=>1});
    } else {
        my $datasource = 'DBI:Pg:dbname=' . $attributes->{'dbname'} . ';host=' . $attributes->{'hostname'} . ';port=' . $attributes->{'port'};
        my $db = DBI->connect($datasource, $attributes->{'username'}, $attributes->{'password'},{ RaiseError => $attributes->{'raise_error'}, utf8 => 1, PrintError => 1, AutoCommit => 1 });
        $attributes->{'handle'} = $db;
        # Please note when logging in data handlers. Please do not log to data.
        # So please use the msg parameter for error handling as this will log both to file and and console when enabled on settings (like the example below).
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
    my $datasource = 'DBI:Pg:dbname=' . $self->{'dbname'} . ';host=' . $self->{'hostname'} . ';port=' . $self->{'port'};
    my $db = DBI->connect($datasource, $self->{'username'}, $self->{'password'},{ RaiseError => $self->{'raise_error'}, utf8 => 1, PrintError => 1, AutoCommit => 1 });
    # Please note when logging in data handlers. Please do not log to data.
    # So please use the msg parameter for error handling as this will log both to file and and console when enabled on settings (like the example below).
    $Log->log({msg=>"re-connecting to $datasource",level=>3});
    $self->{'handle'} = $db;  
    return $self->{'handle'};
}

1;