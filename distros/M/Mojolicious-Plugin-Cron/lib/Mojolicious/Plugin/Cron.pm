package Mojolicious::Plugin::Cron;
use Mojo::Base 'Mojolicious::Plugin';
use File::Spec;
use Fcntl ':flock';
use Mojo::File 'path';
use Mojo::IOLoop;
use Algorithm::Cron;

use Carp 'croak';

our $VERSION = "0.023";
use constant CRON_DIR => 'mojo_cron_dir';
my $crondir;

sub register {
  my ($self, $app, $cronhashes) = @_;
  croak "No schedules found" unless ref $cronhashes eq 'HASH';
  $crondir = path($app->config->{cron}{dir} // File::Spec->tmpdir)
    ->child(CRON_DIR, $app->mode);
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

  plugin Cron( '*/5 9-17 * * *' => sub {
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

=head1 DESCRIPTION

L<Mojolicious::Plugin::Cron> is a L<Mojolicious> plugin that allows to schedule tasks
 directly from inside a Mojolicious application.
You should not consider it as a *nix cron replacement, but as a method to make a proof of
concept of a project.

=head1 BASICS

When using preforked servers (as applications running with hypnotoad), some coordination
is needed so jobs are not executed several times.
L<Mojolicious::Plugin::Cron> uses standard Fcntl functions for that coordination, to assure
a platform-independent behavior.

=head1 EXTENDEND SYNTAX HASH

When using extended syntax, you can define more than one crontab line, and have access
to more options

  plugin Cron => {key1 => {crontab line 1}, key2 => {crontab line 2}, ...};

=head2 Keys

Keys are the names that identify each crontab line. They are used to form the locking semaphore
to avoid multiple processes starting the same job. You can use the same name in different Mojolicious
applications, and this will ensure that not more that one instance of the cron job will take place at
a specific scheduled time.

=head2 Crontab lines

Each crontab line consists of a hash with the following keys:

=over 8
 
=item base => STRING
 
Gives the time base used for scheduling. Either C<utc> or C<local> (default C<local>.
 
=item crontab => STRING
 
Gives the crontab schedule in 5 or 6 space-separated fields.
 
=item sec => STRING, min => STRING, ... mon => STRING
 
Optional. Gives the schedule in a set of individual fields, if the C<crontab>
field is not specified.

For more information on base, crontab and other time related keys,
 please refer to L<Algorithm::Cron> Contstructor Attributes. 

=item code => sub {}

Mandatory. Is the code that will be executed whenever the crontab rule fires.
Note that this code *MUST* be non-blocking.

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
