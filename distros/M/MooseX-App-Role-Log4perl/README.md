# NAME

MooseX::App::Role::Log4perl - Add basic Log::Log4perl logging to a MooseX::App application as a role.

# SYNOPSIS

    use MooseX::App::Simple;

    with MooseX::App::Role::Log4perl
    
    sub run
    {
        my $self = shift;

        $self->log->debug("This is a DEBUG message");
        $self->log->info("This is an INFO message");
        $self->log->warn("This is a WARN message");
        $self->log->error("This is an ERROR message");
        $self->log->fatal("This is a FATAL message");

    }

# DESCRIPTION

The is a role built for CLI apps using the MooseX::App framework. It adds the following command line options:

    --logfile #write log4perl output to a file
    --debug   #include your debug log messages
    --quiet   #suppress output to the terminal (STDOUT)

By default this role will only log messages to STDOUT with INFO or higher priority.

# LICENSE

Copyright (C) John Dexter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

John Dexter 
