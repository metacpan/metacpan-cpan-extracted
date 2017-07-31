package Pask;

use Carp;
use Time::HiRes qw(time);

use Pask::Config;
use Pask::Container;
use Pask::Storage;
use Pask::Command;
use Pask::Parameter;
use Pask::Task;

sub parameter {
    Pask::Parameter::add(@_);
}

sub command {
    Pask::Command::add(@_);
}

sub task {
    Pask::Task::add(@_);
}

sub say {
    Pask::Storage::say(@_);
}

# list all tasks
sub list {
    use Data::Dumper;
    my $tasks = Pask::Container::get_tasks;
    my $i = 0;
    foreach (sort keys %$tasks) {
        Pask::say {-title}, ++$i, ": ", $tasks->{$_}{"name"};
        Pask::say {-description}, $tasks->{$_}{"description"};
        print "\n";
    }
}

sub init {
    my $config = shift;
   
    Pask::Container::set_base_path($config->{"base_path"});
    Pask::Container::set_env_file($config->{"env_file"}) if $config->{"env_file"};
    Pask::Container::set_env_config(Pask::Config::parse_env_file(Pask::Container::get_env_file));

    Pask::Storage::init_log_handle;

    Pask::Storage::register_all;
    Pask::Task::register_all;
}

sub fire {
    if (@_) {
        my $file_handle = Pask::Container::get_log_handle;
        
        my $task = Pask::Container::get_task $_[0];
        Pask::Storage::error "Task name $_[0] is not exsit!" unless $task;        
        print $file_handle "--- Task [", $task->{"name"}, "] Begin ---\n";
        my $timing = time;

        $task->{"command"}(Pask::Parameter::parse $task->{"parameter"});

        print $file_handle "--- Timing: ", sprintf("%0.3f", time - $timing) , "s ---\n";
        print $file_handle "--- Task End ---\n\n";
    } else {
        list;        
    }
}

1;

=encoding utf8

=head1 NAME

Pask - A Micro Task Framework

=head1 SYNOPSIS

    # create a new application
    $> script/pask.pl Demo

    # show all task
    $> perl Demo/pask 

    # run task
    perl Demo/pask TaskName --Parameter Arguments

#=head1 TASK

    # look at demos in the examples directory
    # create a task
    my $pask = Pask::task "Foo";
    # or
    my $pask = Pask::task "Foo" => {
        description = "my description",
        parameter = {},
        command = sub {}
    };

    # set description
    $pask->set_description = "";

    # set parameter
    $pask->set_parameter({
        "bar" => [],
        "dep" => [{"dependency" => ["bar"]}]
    });

    # set command
    $pask->set_command(sub {
        say "hello world!"
    });
