package Service::Engine::Logging;

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Carp;

use Service::Engine;

our $Config;
our $Log;
our $Data;

our $Log_to_file = '';
our $Log_to_console = 1;
our $Log_to_data = {};
our $EngineName;
our $EngineInstance;

# load desired classes 
# Service::Engine::Data:*

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
    $EngineName = $Service::Engine::EngineName;
    $EngineInstance = $Service::Engine::EngineInstance;
    
    $Config->{'logging'}->{'log_level'} ||= 0;
    if ($Config->get_config('logging')->{'types'}->{'to_file'}) {
        $Log_to_file = $Config->get_config('logging')->{'types'}->{'to_file'};
    }
    if ($Config->get_config('logging')->{'types'}->{'to_console'}) {
        $Log_to_console = $Config->get_config('logging')->{'types'}->{'to_console'};
    }
    if ($Config->get_config('logging')->{'types'}->{'to_data'}) {
        $Log_to_data = $Config->get_config('logging')->{'types'}->{'to_data'};
        if (ref($Log_to_data) ne 'HASH') {
            carp("log to data config must be a HASH reference");
            $Log_to_data = {};
        }
    }

    my $self = bless $attributes, $class;
    
    return $self;

}

sub log {

    my ($self,$log) = @_;
    
    if ($Log_to_console) {
        $self->to_console($log);
    }
    
    if ($Log_to_file) {
        $self->to_file($log);
    }
    
    if ($Log_to_data->{'handle'}) {
        $self->to_data($log);
    }

}

sub to_console {
    my ($self,$log) = @_;
    
    my ($level,$msg,$pkg);
    if (ref($log) eq 'HASH') {
        $level = $log->{level};
        $msg = $log->{msg};
    }
    
    if (ref($log) eq '') {
        $msg = $log;
        $level = 0;
    }
    
    ($pkg) = caller;
    $level ||= 0;
    
    my $text = $EngineName . ':' . $EngineInstance;
    $text .= ":$pkg" unless !$pkg;
    $text .= ' ' . time() . " --> $msg";
    say STDERR ($text) unless int($level) > int($Config->get_config('logging')->{'log_level'}) || !$msg;
}

sub to_file {
    my ($self,$log) = @_;
    
    my ($level,$msg,$pkg);
    if (ref($log) eq 'HASH') {
        $level = $log->{level};
        $msg = $log->{msg};
    }
    
    if (ref($log) eq '') {
        $msg = $log;
        $level = 0;
    }
    
    ($pkg) = caller;
    $level ||= 0;
    
    my $text = $EngineName . ':' . $EngineInstance;
    $text .= ":$pkg" unless !$pkg;
    $text .= ' ' . time() . " --> $msg";
    LOG($text) unless int($level) > int($Config->get_config('logging')->{'log_level'}) || !$msg || !$Log_to_file;
}

sub to_data {
    my ($self,$log) = @_;
    
    my ($level,$msg,$pkg);
    if (ref($log) eq 'HASH') {
        $level = $log->{level};
        $msg = $log->{msg};
    }
    
    if (ref($log) eq '') {
        $msg = $log;
        $level = 0;
    }
    
    ($pkg) = caller;
    $level ||= 0;
    
    my $log_level = int($Config->get_config('logging')->{'log_level'});
    if (defined($Log_to_data->{'data_log_level'})) {
        $log_level = int($Log_to_data->{'data_log_level'});
    }
    LOG_DATA($msg) unless int($level) > $log_level || !$msg;
}

sub LOG {

	my ($text) = @_;
        
    open(F, ">>$Log_to_file") || carp("can not open log file $Log_to_file");
    print F ($EngineName . ':' . $EngineInstance . ' ' . time() . ": $text\n");
    close(F);
    
    return '';

}

sub LOG_DATA {
    
    my $handle = $Log_to_data->{'handle'};
    
    return unless $handle;
    
    if (!defined $Data) {
        $Data = $Service::Engine::Data;
    }
    
    return unless $Data;
    
    # check to see we have a valid handle by checking the handle type
    # we won't right away, so we should skip it if we don't
    my $status = $Data->get_status($handle);
    
    return unless $status->{status};
        
###>>>TO DO - set log format

    #     my $log_sth = $dbh->prepare("INSERT INTO ATS_FEED_LOG (ATS_FEED_LOG_CLIENT_ID, ATS_FEED_LOG_FILE_NAME, ATS_FEED_LOG_FILE_SIZE, ATS_FEED_LOG_IS_ERROR, ATS_FEED_LOG_STATUS_MSG, ATS_FEED_LOG_RUNNER_ID, ATS_FEED_LOG_FILE_TIME)
    # 									VALUES (?,?,?,?,?,?,NOW())");
    # 
    #     $log_sth->execute(
    #         $client_id,
    #         'jbfeedservice.log',
    #         $file_size,
    #         $error,
    #         $message,
    #         $jbfs_runner_id
    #     );

}

1;