package Mojolicious::Plugin::Cron;
use Mojo::Base 'Mojolicious::Plugin';
use File::Spec;
use Fcntl ':flock';
use Mojo::File 'path';
use Mojo::IOLoop;
use Algorithm::Cron;

use Carp 'croak';

our $VERSION = "0.029";
use constant CRON_DIR => 'mojo_cron_';
my $crondir;

sub register {
  my ($self, $app, $cronhashes) = @_;
  croak "No schedules found" unless ref $cronhashes eq 'HASH';

# for *nix systems, getpwuid takes precedence
# for win systems or wherever getpwuid is not implemented,
# eval returns undef so getlogin takes precedence
  $crondir
    = path($app->config->{cron}{dir} // File::Spec->tmpdir)
    ->child(CRON_DIR . (eval { scalar getpwuid($<) } || getlogin || 'nobody'),
    $app->mode);
  Mojo::IOLoop->next_tick(sub {
    if (ref((values %$cronhashes)[0]) eq 'CODE') {

      # special case, plugin => 'mm hh dd ...' => sub {}
      $self->_cron($app->moniker,
        {crontab => (keys %$cronhashes)[0], code => (values %$cronhashes)[0]});
    }
    else {
      $self->_cron($_, $cronhashes->{$_}) for keys %$cronhashes;
    }
  });
}

sub _cron {
  my ($self, $sckey, $cronhash) = @_;
  my $code     = delete $cronhash->{code};
  my $all_proc = delete $cronhash->{all_proc} // '';
  my $test_key
    = delete $cronhash->{__test_key};    # __test_key is for test case only
  $sckey = $test_key // $sckey;

  $cronhash->{base} //= 'local';

  ref $cronhash->{crontab} eq ''
    or croak "crontab parameter for schedule $sckey not a string";
  ref $code eq 'CODE' or croak "code parameter for schedule $sckey is not CODE";

  my $cron = Algorithm::Cron->new(%$cronhash);
  my $time = time;

  # $all_proc, $code, $cron, $sckey and $time will be part of the $task clojure
  my $task;
  $task = sub {
    $time = $cron->next_time($time);
    if (!$all_proc) {
    }
    Mojo::IOLoop->timer(
      ($time - time) => sub {
        my $fire;
        if ($all_proc) {
          $fire = 1;
        }
        else {
          my $dat = $crondir->child("$sckey.time");
          my $sem = $crondir->child("$sckey.time.lock");
          $crondir->make_path;    # ensure path exists
          my $handle_sem = $sem->open('>')
            or croak "Cannot open semaphore file $!";
          flock($handle_sem, LOCK_EX);
          my $rtime = $1
            if (-e $dat && $dat->slurp // '') =~ /(\d+)/;   # do some untainting
          $rtime //= '0';
          if ($rtime != $time) {
            $dat->spurt($time);
            $fire = 1;
          }
          undef $dat;
          undef $sem;                                       # unlock
        }
        $code->() if $fire;
        $task->();
      }
    );
  };
  $task->();
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Cron - a Cron-like helper for Mojolicious and Mojolicious::Lite projects

=head1 SYNOPSIS

  # Execute some job every 5 minutes, from 9 to 5

  # Mojolicious::Lite

  plugin Cron => ( '*/5 9-17 * * *' => sub {
      # do someting non-blocking but useful
  });

  # Mojolicious

  $self->plugin(Cron => '*/5 9-17 * * *' => sub {
      # same here
  });

# More than one schedule, or more options requires extended syntax

  plugin Cron => (
  sched1 => {
    base    => 'utc', # not needed for local time
    crontab => '*/10 15 * * *', # at every 10th minute past hour 15
    code    => sub {
      # job 1 here
    }
  },
  sched2 => {
    crontab => '*/15 15 * * *', # at every 15th minute past hour 15
    code    => sub {
      # job 2 here
    }
  });

=head1 DESCRIPTION

L<Mojolicious::Plugin::Cron> is a L<Mojolicious> plugin that allows to schedule tasks
 directly from inside a Mojolicious application.

The plugin mimics *nix "crontab" format to schedule tasks (see L<cron|https://en.wikipedia.org/wiki/Cron>) .

As an extension to regular cron, seconds are supported in the form of a sixth space
separated field (For more information on cron syntax please see L<Algorithm::Cron>).

The plugin can help in development and testing phases, as it is very easy to configure and
doesn't require a schedule utility with proper permissions at operating system level.

For testing, it may be helpful to use Test::Mock::Time ability to "fast-forward"
time calling all the timers in the interval. This way, you can actually test events programmed
far away in the future.

For deployment phase, it will help avoiding the installation steps normally asociated with
scheduling periodic tasks.

=head1 BASICS

When using preforked servers (as applications running with hypnotoad), some coordination
is needed so jobs are not executed several times.

L<Mojolicious::Plugin::Cron> uses standard Fcntl functions for that coordination, to assure
a platform-independent behavior.

Please take a look in the examples section, for a simple Mojo Application that you can
run on hypnotoad, try hot restarts, adding / removing workers, etc, and
check that scheduled jobs execute without interruptions or duplications.

=head1 EXTENDEND SYNTAX HASH

When using extended syntax, you can define more than one crontab line, and have access
to more options

  plugin Cron => {key1 => {crontab line 1}, key2 => {crontab line 2}, ...};

=head2 Keys

Keys are the names that identify each crontab line. They are used to form a locking 
semaphore file to avoid multiple processes starting the same job. 

You can use the same name in different Mojolicious applications that will run
at the same time. This will ensure that not more that one instance of the cron job
will take place at a specific scheduled time. 

=head2 Crontab lines

Each crontab line consists of a hash with the following keys:

=over 8
 
=item base => STRING
 
Gives the time base used for scheduling. Either C<utc> or C<local> (default C<local>).
 
=item crontab => STRING
 
Gives the crontab schedule in 5 or 6 space-separated fields.
 
=item sec => STRING, min => STRING, ... mon => STRING
 
Optional. Gives the schedule in a set of individual fields, if the C<crontab>
field is not specified.

For more information on base, crontab and other time related keys,
 please refer to L<Algorithm::Cron> Constructor Attributes. 

=item code => sub {...}

Mandatory. Is the code that will be executed whenever the crontab rule fires.
Note that this code *MUST* be non-blocking. For tasks that are naturally
blocking, the recommended solution would be to enqueue tasks in a job 
queue (like the L<Minion> queue, that will play nicelly with any Mojo project).

=back

=head1 METHODS

L<Mojolicious::Plugin::Cron> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new, {Cron => '* * * * *' => sub {}});

Register plugin in L<Mojolicious> application.

=head1 WINDOWS INSTALLATION

To install in windows environments, you need to force-install module
Test::Mock::Time, or installation tests will fail.

=head1 AUTHOR

Daniel Mantovani, C<dmanto@cpan.org>

=head1 COPYRIGHT AND LICENCE

Copyright 2018, Daniel Mantovani.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<Mojolicious::Plugins>, L<Algorithm::Cron>

=cut
