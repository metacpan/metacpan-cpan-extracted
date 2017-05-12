# NAME

MooX::Log::Any - Role to add Log::Any

# VERSION

version 0.004004

# DESCRIPTION

A logging role building a very lightweight wrapper to [Log::Any](https://metacpan.org/pod/Log::Any) for use with your [Moo](https://metacpan.org/pod/Moo) or [Moose](https://metacpan.org/pod/Moose) classes.
Connecting a Log::Any::Adapter should be performed prior to logging the first log message, otherwise nothing will happen, just like with Log::Any

Using the logger within a class is as simple as consuming a role:

    package MyClass;
    use Moo;
    with 'MooX::Log::Any';
    
    sub dummy {
        my $self = shift;
        $self->log->info("Dummy log entry");
    }

The logger needs to be setup before using the logger, which could happen in the main application:

    package main;
    use Log::Any::Adapter;
    # Send all logs to Log::Log4perl
    Log::Any::Adapter->set('Log4perl')
    
    use MyClass;
    my $myclass = MyClass->new();
    $myclass->log->info("In my class"); # Access the log of the object
    $myclass->dummy;                    # Will log "Dummy log entry"

# SYNOPSIS;

    package MyApp;
    use Moo;
    
    with 'MooX::Log::Any';
    
    sub something {
        my ($self) = @_;
        $self->log->debug("started bar");    ### logs with default class catergory "MyApp"
        $self->log->error("started bar");    ### logs with default class catergory "MyApp"
    }

# ACCESSORS

## log

The `log` attribute holds the [Log::Any::Adapter](https://metacpan.org/pod/Log::Any::Adapter) object that implements all logging methods for the
defined log levels, such as `debug` or `error`. As this method is defined also in other logging
roles/systems like [MooseX::Log::LogDispatch](https://metacpan.org/pod/MooseX::Log::LogDispatch) this can be thought of as a common logging interface.

    package MyApp::View::JSON;

    extends 'MyApp::View';
    with 'MooseX:Log::Log4perl';

    sub bar {
      $self->logger->info("Everything fine so far");    # logs a info message
      $self->logger->debug("Something is fishy here");  # logs a debug message
    }

## logger(\[$category\])

This is an alias for log.

# SEE ALSO

[Log::Any](https://metacpan.org/pod/Log::Any), [Moose](https://metacpan.org/pod/Moose), [Moo](https://metacpan.org/pod/Moo)

## Inspired by

Inspired by the work by Chris Prather `<perigrin@cpan.org>` and Ash
Berlin `<ash@cpan.org>` on [MooseX::LogDispatch](https://metacpan.org/pod/MooseX::LogDispatch) and Roland Lammel `<lammel@cpan.org>`

# BUGS AND LIMITATIONS

Please report any bugs or feature requests through github 
[https://github.com/cazador481/MooX-Log-Any](https://github.com/cazador481/MooX-Log-Any).

# CONTRIBUTORS

In alphabetical order:

Jens Rehsack `rehsack@gmail.com>`

# AUTHOR

Edward Ash &lt;eddie+cpan@ashfamily.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Edward Ash.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
