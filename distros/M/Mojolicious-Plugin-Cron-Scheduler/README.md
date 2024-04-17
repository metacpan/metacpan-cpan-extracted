# NAME

Mojolicious::Plugin::Cron::Scheduler - easily configure [Mojolicious::Plugin::Cron](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ACron)

# SYNOPSIS

    # For a full Mojo app
    $self->plugin('Cron::Scheduler' => {
      schdules => {
        do_a_thing => [
          { 
            schedule => {
              minute => 0,
              hour => '*',
              day => '*',
              month => '*',
              weekday => '*'
            }
          }
        }
      ],
      tasks => {
        do_a_thing => sub { ... }
      }
    });

    # or, tasks can be imported from a namespace, keeping your code well-organized
    package MyApp::Cron::DoAThing;

    sub register($self, $app, $args) {
      $app->crontask(do_a_thing => sub { ... })
    }

    package MyApp;
    ...
    $self->plugin('Cron::Scheduler' => {
      schedules  => { do_a_thing => { ... } },
      namespaces => ['MyApp::Cron']
    });

# DESCRIPTION

[Mojolicious::Plugin::Cron](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ACron) is great, but is best used when the tasks are fairly
static. This module was created to wrap its functionality and add the ability
to easily pull in an external configuration of when and how tasks should be run,
cleanly separated from the implementation of those tasks themselves.

# METHODS

[Mojolicious::Plugin::Cron::Scheduler](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ACron%3A%3AScheduler) inherits all methods from [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin) and implements the following
new ones

## register( ..., $parameters )

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application. Accepts a HashRef of parameters
with three supported, optional keys:

#### schedules

Optional (though if omitted, no scheduling will be performed)

A HashRef whose keys are `crontask` names. The values of this hash are ArrayRefs,
each item of which is a HashRef with `schedule` and `parameters` keys.

scheduleA HashRef whose keys are `minute`, `hour`, `day`, `month`, `weekday`, 
corresponding to the [crontab](https://linuxhandbook.com/crontab/) columns. If
any of these keys are omitted, they are assumed to be `*` elements.

parametersAn ArrayRef of values to be passed to the task when it is run from this schedule

#### tasks

Optional
HashRef\[CodeRef\]

A HashRef whose keys are `crontask` names. The values of this hash are CodeRefs
 - the code to be run when the scheduled task is executed. The parameters passed
to the code are only those present in the ["parameters"](#parameters) array.

#### namespaces

Optional
ArrayRef\[Str\]

An ArrayRef of package namespaces to load. The premise is that such packages would
call ["crontask"](#crontask) to register schedulable tasks for this module to schedule. Any
packages in this namespace will be loaded and registered as [Mojolicious](https://metacpan.org/pod/Mojolicious) 
[plugins](https://metacpan.org/pod/Mojolicious%3A%3APlugin), whether or not they register `crontask`s.

## crontask( name => $coderef )

Registers a coderef/anonymous subroutine by name as a schedulable task. This
registration is an alternative to passing these code blocks in at the time of
plugin loading. Often this will be called from small, specialized plugins 
loadable by [namespace](#namespaces)

# AUTHOR

Mark Tyrrell `<mark@tyrrminal.dev>`

# LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
