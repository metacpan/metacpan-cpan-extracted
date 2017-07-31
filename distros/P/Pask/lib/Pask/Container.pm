package Pask::Container;

use POSIX qw (strftime);
use Carp;

my $base_path = ".";
my $app_prefix_path = "app";
my $env_file = ".env";
my $env_config;
my $tasks = {};
my $storage_prefix_path = "storage";
my $storages = {};
my $date = strftime("%Y-%m-%d", localtime);
my $log_handle;

sub set_base_path {
    my $argv = shift;
    Carp::confess "base_path name can not be null!" unless $argv;
    $base_path = $argv;
}

sub set_log_handle {
    $log_handle = shift;
}

sub get_log_handle {
    $log_handle;
}

sub get_base_path {
    $base_path;
}

sub get_app_path {
    $base_path . "/app";
}

sub get_task_path {
    $base_path . "/tasks";
}

sub set_env_file {
    my $argv = shift;
    Carp::confess "base_path name can not be null!" unless $argv;
    $env_file = $argv;
}

sub get_env_file {
    $base_path . "/" . $env_file;
}

sub set_env_config {
    $env_config = shift;
}

sub get_env_config {
    $env_config;
}

sub get_storage_path {
    $base_path . "/" . $storage_prefix_path;
}

sub get_log_file {
    get_storage_path . "/" . $date . ".log";
}

sub get_tasks {
    $tasks;
}

### instance ###

sub new {
    bless {};
}

sub set_storage {
    my ($type, $instance) = (shift, shift);
    $storages->{$type} = $instance;
}

sub get_storage {
    my $type = shift;
    Carp::confess "type name can not be null!" unless $type;
    $storages->{$type};
}

sub set_task {
    my $name = shift;
    my $instance;
    Carp::confess "task name has been existed!" if exists $tasks->{$name};
    $instance = new Pask::Container;
    $instance->{"name"} = $name;
    $instance->{"description"} = "No Description.";
    $tasks->{$name} = $instance;
}

sub get_task {
    my $name = shift;
    Carp::confess "task name can not be null!" unless $name;
    $tasks->{$name};
}

sub set_description {
    my ($this, $description) = @_;
    $this = Pask::Container::get_task $this unless ref $this;
    Carp::confess "can not call set_description method directly!" unless ref $this;
    Carp::confess "description can not be null!" unless $description;
    $this->{"description"} = $description;
    $this;
}

sub set_parameter {
    my ($this, $parameter) = @_;
    $this = Pask::Container::get_task $this unless ref $this;
    Carp::confess "can not call set_parameter method directly!" unless ref $this;
    Carp::confess "parameter can not be null!" unless $parameter;
    $this->{"parameter"} = $parameter;
    $this;    
}

sub set_command {
    my ($this, $command) = @_;
    $this = Pask::Container::get_task $this unless ref $this;
    Carp::confess "can not call set_command method directly!" unless ref $this;
    Carp::confess "need to pass a sub as it's argument!" unless $command;
    $this->{"command"} = $command;
    $this;
}

1;
