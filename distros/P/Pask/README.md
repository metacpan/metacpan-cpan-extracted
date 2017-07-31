# NAME

Pask - A Micro Task Framewor

# SYNOPSIS

    # create a new application
    $> script/pask.pl Demo

    # show all task
    $> perl Demo/pask 

    # run task
    perl Demo/pask TaskName --Parameter Arguments

# TASK

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
