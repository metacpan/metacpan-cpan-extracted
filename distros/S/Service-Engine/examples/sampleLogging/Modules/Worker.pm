package sampleLogging::Modules::Worker;

use 5.010;
use strict;
use warnings;
use File::Slurp;
use Carp;
use Data::Dumper;
use Time::HiRes qw( gettimeofday tv_interval );

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

    $Log->log({'msg'=>"loading $EngineName" . "::Modules::Worker",'level'=>2});
    
    my $self = bless $attributes, $class;
    
    return $self;

}

sub process {
    
    my ($self, $queue_item) = @_;

    my $start_time = [gettimeofday];

    my $log_params = {
        "log_server" => "sample",
        "log_method" => $EngineName,
        "log_application" => "platform",
        "log_remote_ip" => '127.0.0.1',
    };
    
    if (ref($queue_item) ne 'HASH') {
        $log_params->{'log_duration'} = tv_interval($start_time, [gettimeofday]);
        $log_params->{'log_type'} = 'error';
        $log_params->{'log_error'} = {
            'severity' => 'Error',
            'message' => "ERROR: $queue_item must be an object: " . Dumper($queue_item),
        };

        $Log->log({data => $log_params,level => 1});
        return '';
    }
    
    # you get a HASH with a reference to your data handles, 
    # the item in the queque, and the id of the thread processing the request
    
    # each thread needs its own data handles; they are set automatically in Threads.pm
    my $Data = $queue_item->{data};
    my $item = $queue_item->{item};
    my $thread_id = $queue_item->{id};
    $Log->log({msg=>"processing: thread $thread_id",level=>3});
    
    # process $item
    if (ref($item) ne 'HASH') {
        $log_params->{'log_duration'} = tv_interval($start_time, [gettimeofday]);
        $log_params->{'log_error'} = {
            'severity' => 'Error',
            'message' => "Data from getter must be an object",
            'data' => $item
        };

        $Log->log({data => $log_params, level => 1});
        return '';
    }

    my $dbh = $Data->prod_mysql();
    if ($item->{'status'} == '2') {
        $log_params->{'log_duration'} = tv_interval($start_time, [gettimeofday]);
        $log_params->{'log_type'} = 'error';
        $log_params->{'log_error'} = {
            'severity' => 'Warning',
            'message' => "Sample Error",
            'data' => $item
        };

        $Log->log({data => $log_params,level => 1});
    } elsif ($item->{'status'} == '3') {
        $log_params->{'log_duration'} = tv_interval($start_time, [gettimeofday]);
        $log_params->{'log_type'} = 'error';
        $log_params->{'log_error'} = {
            'severity' => 'Error',
            'message' => "SQLError",
            'data' => $item
        };

        $Log->log({data => $log_params,level => 0});
    } elsif ($item->{'status'} == '0') {
        my $sth = $dbh->prepare("UPDATE posts SET status=1 WHERE id=?");
        unless ($sth->execute($item->{'id'})) {
            $log_params->{'log_duration'} = tv_interval($start_time, [gettimeofday]);
            $log_params->{'log_type'} = 'error';
            $log_params->{'log_error'} = {
                'severity' => 'Error',
                'message' => "SQLError: " . $sth->errstr,
            };

            $Log->log({data => $log_params,level => 1});
        } else {
            $log_params->{'log_duration'} = tv_interval($start_time, [gettimeofday]);
            $log_params->{'log_type'} = 'transaction';
            $log_params->{'log_affected_data'} = {
                'object' => 'posts',
                'id' => $item->{id},
                'data' => {
                    'status' => 1,
                }
            };
            $Log->log({data => $log_params, level => 2});
        }
    }

    

    return '';
}

1;