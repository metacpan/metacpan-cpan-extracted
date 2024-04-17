package Mojolicious::Plugin::Cron::Scheduler 0.01;
use v5.26;
use warnings;

# ABSTRACT: Mojolicious Plugin that wraps Mojolicious::Plugin::Cron for job configurability

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Cron::Scheduler - easily configure L<Mojolicious::Plugin::Cron>

=head1 SYNOPSIS

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

=head1 DESCRIPTION

L<Mojolicious::Plugin::Cron> is great, but is best used when the tasks are fairly
static. This module was created to wrap its functionality and add the ability
to easily pull in an external configuration of when and how tasks should be run,
cleanly separated from the implementation of those tasks themselves.

=head1 METHODS

L<Mojolicious::Plugin::Cron::Scheduler> inherits all methods from L<Mojolicious::Plugin> and implements the following
new ones

=head2 register( ..., $parameters )

Register plugin in L<Mojolicious> application. Accepts a HashRef of parameters
with three supported, optional keys:

=head4 schedules

Optional (though if omitted, no scheduling will be performed)

A HashRef whose keys are C<crontask> names. The values of this hash are ArrayRefs,
each item of which is a HashRef with C<schedule> and C<parameters> keys.

=head6 schedule

A HashRef whose keys are C<minute>, C<hour>, C<day>, C<month>, C<weekday>, 
corresponding to the L<crontab|https://linuxhandbook.com/crontab/> columns. If
any of these keys are omitted, they are assumed to be C<*> elements.

=head6 parameters

An ArrayRef of values to be passed to the task when it is run from this schedule

=head4 tasks

Optional
HashRef[CodeRef]

A HashRef whose keys are C<crontask> names. The values of this hash are CodeRefs
 - the code to be run when the scheduled task is executed. The parameters passed
to the code are only those present in the L</parameters> array.

=head4 namespaces

Optional
ArrayRef[Str]

An ArrayRef of package namespaces to load. The premise is that such packages would
call L</crontask> to register schedulable tasks for this module to schedule. Any
packages in this namespace will be loaded and registered as L<Mojolicious> 
L<plugins|Mojolicious::Plugin>, whether or not they register C<crontask>s.

=head2 crontask( name => $coderef )

Registers a coderef/anonymous subroutine by name as a schedulable task. This
registration is an alternative to passing these code blocks in at the time of
plugin loading. Often this will be called from small, specialized plugins 
loadable by L<namespace|/namespaces>

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Plugin::Cron;

use List::Util qw(min max);
use Module::Find;
use Syntax::Keyword::Try;
use Readonly;

use experimental qw(signatures);

Readonly::Scalar my $CRONTAB_WILDCARD => q{*};
Readonly::Array my @CRONTAB_FIELDS => qw(minute hour day month weekday);

my sub hashref_to_crontab_fmt($h = undef) {
  die("Invalid schedule") if (!defined($h) || ref($h) ne 'HASH');
  my %s = map {$_ => exists($h->{$_}) ? $h->{$_} : $CRONTAB_WILDCARD} @CRONTAB_FIELDS;
  return join(q{ }, @s{@CRONTAB_FIELDS});
}

my sub compile_crontab($app, $jobs, $schedules) {
  my %combined;
  $combined{$_}->{code}      = $jobs->{$_}      foreach (keys($jobs->%*));
  $combined{$_}->{schedules} = $schedules->{$_} foreach (keys($schedules->%*));

  my $cron = {};
  foreach my $name (keys(%combined)) {
    my $c = $combined{$name};
    $app->log->error("Cron job '$name' skipped: no implementation loaded") and next unless (defined($c->{code}));
    my $i = 1;
    foreach my $instance (($c->{schedules} // [])->@*) {
      try {
        my $schedule  = hashref_to_crontab_fmt($instance->{schedule});
        my $task_name = sprintf('%s-%d', $name, $i++);
        $app->log->info("Scheduling '$task_name' at {$schedule}");
        $cron->{$task_name} = {
          crontab => $schedule,
          code    => sub {
            $app->log->info("Running $name cronjob");
            $c->{code}->($instance->{parameters}->@*);
          },
        };
      } catch ($e) {
        $app->log->error("Cron job '$name' skipped: $e");
      }
    }
  }
  return $cron;
}

sub register ($self, $app, $args) {
  my @namespaces = ($args->{namespaces} // [])->@*;
  # %jobs = { jobname => CODEREF, ... }
  my %jobs = ($args->{tasks} // {})->%*;
  # %schedules = { jobname => [ { schedule => { hour => x, minute => y, ... }, parameters: { ... } }, ... ]}
  my %schedules = ($args->{schedules} // {})->%*;

  # crontask helper MUST be installed...
  $app->helper(crontask => sub ($self, $name, $code) {$jobs{$name} = $code;});
  # ...BEFORE loading cron plugins
  foreach (map {Module::Find::findallmod($_)} @namespaces) {
    $app->plugin($_);
    $app->log->debug("Cron loaded plugin: '$_'");
  }

  my $cron = compile_crontab($app, \%jobs, \%schedules);
  return $app->plugin(Cron => $cron);
}

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

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

=cut

1;

__END__
