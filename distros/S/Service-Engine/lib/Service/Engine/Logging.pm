package Service::Engine::Logging;

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use JSON;

use Service::Engine;

our $Config;
our $Log;
our $Data;

our $Log_to_file = '';
our $Log_to_console = 1;
our $Log_to_data = {};
our $EngineName;
our $EngineInstance;
our $JSON = JSON->new->utf8->allow_nonref;

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

    my ($level,$data,$msg,$pkg);
    if (ref($log) eq 'HASH') {
        $level = $log->{level};
        if (ref($log->{data}) eq 'HASH') {
            $data = _convert_references($log->{data});
        } else {
            $msg = $log->{msg};
        }
    }

    if (ref($log) eq '') {
        $msg = $log;
        $level = 0;
    }

    ($pkg) = caller;
    $level ||= 0;

    my $text = $EngineName . ':' . $EngineInstance;
    $text .= ":$pkg" unless !$pkg;
    $text .= ' ' . time() . " --> $msg" if ($msg);
    $text .= ' ' . time() . " --> " . Dumper($data) if ($data);
    say STDERR ($text) unless int($level) > int($Config->get_config('logging')->{'log_level'}) || !$msg;
}

sub to_file {
    my ($self,$log) = @_;

    my ($level,$data,$msg,$pkg);
    if (ref($log) eq 'HASH') {
        $level = $log->{level};
        if (ref($log->{data}) eq 'HASH') {
            $data = _convert_references($log->{data});
        } else {
            $msg = $log->{msg};
        }
    }

    if (ref($log) eq '') {
        $msg = $log;
        $level = 0;
    }

    ($pkg) = caller;
    $level ||= 0;

    my $text = $EngineName . ':' . $EngineInstance;
    $text .= ":$pkg" unless !$pkg;
    $text .= ' ' . time() . " --> $msg" if ($msg);
    $text .= ' ' . time() . " --> " . Dumper($data) if ($data);
    LOG($text) unless int($level) > int($Config->get_config('logging')->{'log_level'}) || !$msg || !$Log_to_file;
}

sub to_data {
    my ($self,$log) = @_;

    my ($level,$msg,$data,$pkg);
    if (ref($log) eq 'HASH') {
        $level = $log->{level};

        if ($log->{data} && ref($log->{data}) eq 'HASH') {
            $data = $log->{data};
        }
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

    if (ref($data) eq 'HASH') {
        LOG_DATA($data) unless int($level) > $log_level;
    }
}

sub LOG {

    my ($text) = @_;

    open(F, ">>$Log_to_file") || carp("can not open log file $Log_to_file");
    print F ($EngineName . ':' . $EngineInstance . ' ' . time() . ": $text\n");
    close(F);

    return '';

}

sub LOG_DATA {
    my ($log_data) = @_;

    return unless (ref($log_data) eq 'HASH');

    $log_data = _convert_references($log_data);
    my $handle = $Log_to_data->{'handle'};
    my $table = $Config->get_config('data')->{'Crate'}->{$handle}->{'table'};
    my $dbname = $Config->get_config('data')->{'Crate'}->{$handle}->{'dbname'};

    return unless $table;

    return unless $handle;

    return unless $dbname;

    if (!defined $Data) {
        $Data = Service::Engine::Data->new();
    }

    return unless $Data;

    # check to see we have a valid handle by checking the handle type
    # we won't right away, so we should skip it if we don't
    my $status = $Data->get_status($handle);

    return unless $status->{status};

    # Query Building
    my $param_fields = join(',', keys %$log_data);
    my @param_values = values %$log_data;

    my $count_param = scalar @param_values;
    my @binds       = ('?') x $count_param;
    my $joined_binds = join(',', @binds);

    my $dbh = $Data->$handle();

    my $sql = "INSERT INTO $dbname.$table ($param_fields) VALUES ($joined_binds)";

    my $log_sth = $dbh->prepare($sql);
    $log_sth->execute(@param_values);
}

sub _convert_references {
    my $data = shift;

    for my $key (keys %$data) {
        my $value = $data->{$key};
        if (ref($value) eq 'HASH' || ref($value) eq 'ARRAY') {
            $data->{$key} = $JSON->encode($value);
        } elsif (ref($value) eq 'SCALAR') {
            $data->{$key} = $$value;
        }
    }

    return $data;
}

1;