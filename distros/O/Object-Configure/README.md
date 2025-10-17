[![CPAN version](https://badge.fury.io/pl/Object-Configure.svg)](https://metacpan.org/pod/Object::Debug)
![Perl CI](https://github.com/nigelhorne/Object-Configure/actions/workflows/perl-ci.yml/badge.svg)

# NAME

Object::Configure - Runtime Configuration for an Object

# VERSION

0.16

# SYNOPSIS

The `Object::Configure` module is a lightweight utility designed to inject runtime parameters into other classes,
primarily by layering configuration and logging support,
when instatiating objects.

[Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) and [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction) are modules developed to solve a specific need,
runtime configurability without needing to rewrite or hardcode behaviours.
The goal is to allow individual modules to enable or disable features on the fly,
and to do it using whatever configuration system the user prefers.

Although the initial aim was general configurability,
the primary use case that's emerged has been fine-grained logging control,
more flexible and easier to manage than what you'd typically do with [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl).
For example,
you might want one module to log verbosely while another stays quiet,
and be able to toggle that dynamically - without making invasive changes to each module.

To tie it all together,
there is `Object::Configure`.
It sits on [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) and [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction),
and with just a couple of extra lines in a class constructor,
you can hook in this behaviour seamlessly.
The intent is to keep things modular and reusable,
especially across larger systems or in situations where you want user-selectable behaviour.

Add this to your constructor:

    package My::Module;

    use Object::Configure;
    use Params::Get;

    sub new {
         my $class = shift;
         my $params = Object::Configure::configure($class, @_ ? \@_ : undef);    # Reads in the runtime configuration settings
         # or my $params = Object::Configure::configure($class, { @_ });

         return bless $params, $class;
     }

Throughout your class, add code such as:

    sub method
    {
        my $self = shift;

        $self->{'logger'}->trace(ref($self), ': ', __LINE__, ' entering method');
    }

## CHANGING BEHAVIOUR AT RUN TIME

### USING A CONFIGURATION FILE

To control behavior at runtime, `Object::Configure` supports loading settings from a configuration file via [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction).

A minimal example of a config file (`~/.conf/local.conf`) might look like:

    [My__Module]
    logger.file = /var/log/mymodule.log

The `configure()` function will read this file,
overlay it onto your default parameters,
and initialize the logger accordingly.

If the file is not readable and no config\_dirs are provided,
the module will throw an error.

This mechanism allows dynamic tuning of logging behavior (or other parameters you expose) without modifying code.

More details to be written.

### USING ENVIRONMENT VARIABLES

`Object::Configure` also supports runtime configuration via environment variables,
without requiring a configuration file.

Environment variables are read automatically when you use the `configure()` function,
thanks to its integration with [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction).
These variables should be prefixed with your class name, followed by a double colon.

For example, to enable syslog logging for your `My::Module` class,
you could set:

    export My__Module__logger__file=/var/log/mymodule.log

This would be equivalent to passing the following in your constructor:

     My::Module->new(logger => Log::Abstraction->new({ file => '/var/log/mymodule.log' });

All environment variables are read and merged into the default parameters under the section named after your class.
This allows centralized and temporary control of settings (e.g., for production diagnostics or ad hoc testing) without modifying code or files.

Note that environment variable settings take effect regardless of whether a configuration file is used,
and are applied during the call to `configure()`.

More details to be written.

## HOT RELOAD

Hot reload is not supported on Windows.

### Basic Hot Reload Setup

    package My::App;
    use Object::Configure;

    sub new {
        my $class = shift;
        my $params = Object::Configure::configure($class, @_ ? \@_ : undef);
        my $self = bless $params, $class;

        # Register for hot reload
        Object::Configure::register_object($class, $self) if $params->{_config_file};

        return $self;
    }

    # Optional: Define a reload hook
    sub _on_config_reload {
        my ($self, $new_config) = @_;
        print "My::App config was reloaded!\n";
        # Custom reload logic here
    }

### Enable Hot Reload in Your Main Application

    # Enable hot reload with custom callback
    Object::Configure::enable_hot_reload(
        interval => 5,  # Check every 5 seconds
        callback => sub {
            print "Configuration files have been reloaded!\n";
        }
    );

    # Your application continues running...
    # Config changes will be automatically detected and applied

### Manual Reload

    # Manually trigger a reload
    my $count = Object::Configure::reload_config();
    print "Reloaded configuration for $count objects\n";

# SUBROUTINES/METHODS

## configure

Configure your class at runtime with hot reload support.

Takes arguments:

- `class`
- `params`

    A hashref containing default parameters to be used in the constructor.

- `carp_on_warn`

    If set to 1, call `Carp::carp` on `warn()`.
    This value is also read from the configuration file,
    which will take precedence.
    The default is 0.

- `croak_on_error`

    If set to 1, call `Carp::croak` on `error()`.
    This value is also read from the configuration file,
    which will take precedence.
    The default is 1.

- `logger`

    The logger to use.
    If none is given, an instatiation of [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) will be created, unless the logger is set to NULL.

- `schema`

    A [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) compatible schema to validate the configuration file against.

Returns a hash ref containing the new values for the constructor.

Now you can set up a configuration file and environment variables to configure your object.

## instantiate($class,...)

Create and configure an object of the given class.
This is a quick and dirty way of making third-party classes configurable at runtime.

# HOT RELOAD FEATURES

## enable\_hot\_reload

Enable hot reloading for configuration files.

    Object::Configure::enable_hot_reload(
        interval => 5,  # Check every 5 seconds (default: 10)
        callback => sub { print "Config reloaded!\n"; }  # Optional callback
    );

## disable\_hot\_reload

Disable hot reloading and stop the background watcher.

    Object::Configure::disable_hot_reload();

## reload\_config

Manually trigger a configuration reload for all registered objects.

    Object::Configure::reload_config();

## register\_object

Register an object for hot reload monitoring.

    Object::Configure::register_object($class, $obj);

This is automatically called by the configure() function when a config file is used,
but can also be called manually to register objects for hot reload.

## restore\_signal\_handlers

Restore original signal handlers and disable hot reload integration.
Useful when you want to cleanly shut down the hot reload system.

    Object::Configure::restore_signal_handlers();

## get\_signal\_handler\_info

Get information about the current signal handler setup.
Useful for debugging signal handler chains.

    my $info = Object::Configure::get_signal_handler_info();
    print "Original USR1 handler: ", $info->{original_usr1} || 'none', "\n";
    print "Hot reload active: ", $info->{hot_reload_active} ? 'yes' : 'no', "\n";

# SEE ALSO

- [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction)
- [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)
- Test coverage report: [https://nigelhorne.github.io/Object-Configure/coverage/](https://nigelhorne.github.io/Object-Configure/coverage/)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-object-configure at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Configure](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Configure).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Object::Configure

# LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
