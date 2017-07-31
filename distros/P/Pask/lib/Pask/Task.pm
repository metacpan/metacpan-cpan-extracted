package Pask::Task;

use File::Find::Rule;

use Carp;

use Pask::Container;

sub add {
    my ($name, $task_obj) = @_;
    Carp::confess "task name can not be null!" unless $name;
    my $task = Pask::Container::set_task $name;
    if ($task_obj) {
        Pask::Container::set_description($name, $task_obj->{"description"}) if $task_obj->{"description"};
        Pask::Parameter::add($name, $task_obj->{"parameter"}) if $task_obj->{"parameter"};
        Pask::Command::add($name, $task_obj->{"command"}) if $task_obj->{"command"};
    }
    # Pask::Container::get_task $name;
    $task;
}

sub register_all {
    require $_ foreach File::Find::Rule->file()->name("*.pl")->in(Pask::Container::get_task_path);
}

1;
