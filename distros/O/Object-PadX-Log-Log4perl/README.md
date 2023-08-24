# DESCRIPTION

A logging role building a very lightweight wrapper to [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) for use
with your [Object::Pad](https://metacpan.org/pod/Object%3A%3APad) classes. The initialization of the Log4perl instance
must be performed prior to logging the first log message.  Otherwise the
default initialization will happen, probably not doing the things you expect.

The logger needs to be setup before using the logger, which could happen in the
main application:

    package main;
    use Log::Log4perl qw(:easy);
    use MyClass;

    BEGIN { Log::Log4perl->easy_init() }

    my $myclass = MyClass->new();
    $myclass->log->info("In my class");    # Access the log of the object
    $myclass->dummy;                       # Will log "Dummy log entry"

Using the logger within a class is as simple as consuming a role:

# SYNOPSIS

    package MyClass;
    use v5.26;
    use Object::Pad;

    class MyClass :does(Object::PadX::Log::Log4perl)

    method foo {
        $self->log->info("Foo called");
    }

# METHODS

## logger

The `logger` attribute holds the [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) object that implements all
logging methods for the defined log levels, such as `debug` or `error`.

## log

Basically the same as logger, but also allowing to change the log category for
this log message.

    if ($myapp->log->is_debug()) {
      $myapp->log->debug("Woot");            # category is class myapp
    }

    $myapp->log("FooBar")->info("Foobar");   # category FooBar
    $myapp->log->info("Yihaa");              # category class again myapp
    $myapp->log(".FooBar")->info("Foobar");  # category myapp.FooBar
    $myapp->log("::FooBar")->info("Foobar"); # category myapp.FooBar

# PRIOR ART

This code has been mostly ported/inspired from [MooseX::Log::Log4perl](https://metacpan.org/pod/MooseX%3A%3ALog%3A%3ALog4perl).
Copyright (c) 2008-2016, Roland Lammel <lammel@cpan.org>, http://www.quikit.at
