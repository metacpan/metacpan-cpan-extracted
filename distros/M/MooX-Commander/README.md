[![Build Status](https://travis-ci.org/kablamo/MooX-Commander.svg?branch=master)](https://travis-ci.org/kablamo/MooX-Commander) [![Coverage Status](https://img.shields.io/coveralls/kablamo/MooX-Commander/master.svg)](https://coveralls.io/r/kablamo/MooX-Commander?branch=master)
# NAME

MooX::Commander - Build command line apps with subcommands and option parsing

# SYNOPSIS

    # EXAMPLE
    # MooX::Commander helps you build a command line app like this:
    $ bin/pie-factory --help
    usage: pie-factory [options]

    You have inherited a pie factory.  Use your powers wisely.
    
    COMMANDS
    pie-factory recipe list             List pie recipes
    pie-factory recipe show <recipe>    Display a recipe
    pie-factory recipe add <recipe>     Add a recipe
    pie-factory recipe delete <recipe>  Delete a recipe
    pie-factory bake <pie>              Bake a pie
    pie-factory eat <pie>               Eat a pie
    pie-factory throw <pie> <target>    Throw a pie at something
    pie-factory help <cmd>              Get help with a command

    OPTIONS
      -v, --version  Show version
      -h, --help     Show this message

    
    # HOW TO DISPATCH TO COMMAND CLASSES
    # inside bin/pie-factory:
    my $commander = MooX::Commander->new(
        base_class   => 'PieFactory',
        class_prefix => 'Cmd',  # optional, default value is 'Cmd'
        version      => 'v1.0', # optional. default lazy loads $PieFactory::VERSION
    );
    $commander->dispatch(argv => \@ARGV);

    # HOW TO BUILD A COMMAND CLASS
    # inside lib/PieFactory/Cmd/Throw.pm
    package PieFactory::Cmd::Throw;
    sub go {
        my ($self, $pie, $target) = @_;
        # throw $pie at the $target
    }

    # HOW TO ADD OPTION PARSING TO A COMMAND CLASS
    # See L<MooX::Command::HasOptions>

    # HOW TO BUILD A HELP SUBCOMMAND
    # See L<MooX::Command::IsaHelpCommand>

    # HOW TO BUILD A SUBSUBCOMMAND
    # See L<MooX::Command::HasSubcommands>

# DESCRIPTION

MooX::Commander makes it easy to add commands and option parsing to your
command line application a la git.  

This module instantiates the command class requested by the user and calls the
`go()` method on the object.  `@ARGV` is passed to the command class
and saved in the `argv` attribute.

If a user passes in no args or `--help` or `-h` the `help` command class is 
instantiated and the `usage()` method is called on that object.

# WHAT THIS MODULE DOES NOT DO

This module doesn't dynamically generate usage/help statements.  I wasn't
interested in solving that problem.  I think its not possible or very difficult
to do well and usually leads to a very complex and verbose user interface and a
one size fits all usage/help output that is inflexible and poorly formatted.  

I also suspect people who really care about the usability of their command line
applications want to tweak help output based on the situation and their
personal preferences.  Or maybe thats just me.

# LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Eric Johnson <eric.git@iijo.org>
