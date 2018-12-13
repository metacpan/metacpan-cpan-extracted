[![Build Status](https://travis-ci.org/dmanto/Mojolicious-Plugin-Cron.svg?branch=master)](https://travis-ci.org/dmanto/Mojolicious-Plugin-Cron) [![Build Status](https://img.shields.io/appveyor/ci/dmanto/Mojolicious-Plugin-Cron/master.svg?logo=appveyor)](https://ci.appveyor.com/project/dmanto/Mojolicious-Plugin-Cron/branch/master)
# NAME

Mojolicious::Plugin::Cron - a Cron-like helper for Mojolicious and Mojolicious::Lite projects

# SYNOPSIS

    # Execute some job every 5 minutes, from 9 to 5

    # Mojolicious::Lite

    plugin Cron => ( '*/5 9-17 * * *' => sub {
        # do someting non-blocking but useful
    });

    # Mojolicious

    $self->plugin(Cron => '*/5 9-17 * * *' => sub {
        # same here
    });

\# More than one schedule, or more options requires extended syntax

    plugin Cron => (
    sched1 => {
      base    => 'utc', # not needed for local time
      crontab => '*/10 15 * * *', # every 10 minutes starting at minute 15, every hour
      code    => sub {
        # job 1 here
      }
    },
    sched2 => {
      crontab => '*/15 15 * * *', # every 15 minutes starting at minute 15, every hour
      code    => sub {
        # job 2 here
      }
    });

# DESCRIPTION

[Mojolicious::Plugin::Cron](https://metacpan.org/pod/Mojolicious::Plugin::Cron) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin that allows to schedule tasks
 directly from inside a Mojolicious application.

You should not consider it as a \*nix cron replacement, but as a method to make a proof of
concept of a project. It helps also in the deployment phase because in the end it
could mean less and simpler installation/removing tasks.

As an extension to regular cron, seconds are supported in the form of a sixth space
separated field (For more information on cron syntax please see [Algorithm::Cron](https://metacpan.org/pod/Algorithm::Cron)).

# BASICS

When using preforked servers (as applications running with hypnotoad), some coordination
is needed so jobs are not executed several times.

[Mojolicious::Plugin::Cron](https://metacpan.org/pod/Mojolicious::Plugin::Cron) uses standard Fcntl functions for that coordination, to assure
a platform-independent behavior.

Please take a look in the examples section, for a simple Mojo Application that you can
run on hypnotoad, try hot restarts, adding / removing workers, etc, and
check that scheduled jobs execute without interruptions or duplications.

# EXTENDEND SYNTAX HASH

When using extended syntax, you can define more than one crontab line, and have access
to more options

    plugin Cron => {key1 => {crontab line 1}, key2 => {crontab line 2}, ...};

## Keys

Keys are the names that identify each crontab line. They are used to form a locking 
semaphore file to avoid multiple processes starting the same job. 

You can use the same name in different Mojolicious applications that will run
at the same time. This will ensure that not more that one instance of the cron job
will take place at a specific scheduled time. 

## Crontab lines

Each crontab line consists of a hash with the following keys:

- base => STRING

    Gives the time base used for scheduling. Either `utc` or `local` (default `local`).

- crontab => STRING

    Gives the crontab schedule in 5 or 6 space-separated fields.

- sec => STRING, min => STRING, ... mon => STRING

    Optional. Gives the schedule in a set of individual fields, if the `crontab`
    field is not specified.

    For more information on base, crontab and other time related keys,
     please refer to [Algorithm::Cron](https://metacpan.org/pod/Algorithm::Cron) Contstructor Attributes. 

- code => sub {...}

    Mandatory. Is the code that will be executed whenever the crontab rule fires.
    Note that this code \*MUST\* be non-blocking.

# METHODS

[Mojolicious::Plugin::Cron](https://metacpan.org/pod/Mojolicious::Plugin::Cron) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    $plugin->register(Mojolicious->new, {Cron => '* * * * *' => sub {}});

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# WINDOWS INSTALLATION

To install in windows environments, you need to force-install module
Test::Mock::Time, or installation tests will fail.

# AUTHOR

Daniel Mantovani, `dmanto@cpan.org`

# COPYRIGHT AND LICENCE

Copyright 2018, Daniel Mantovani.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [Mojolicious::Plugins](https://metacpan.org/pod/Mojolicious::Plugins), [Algorithm::Cron](https://metacpan.org/pod/Algorithm::Cron)
