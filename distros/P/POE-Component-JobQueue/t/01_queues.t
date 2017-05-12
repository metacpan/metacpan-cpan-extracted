#!/usr/bin/perl -w
# $Id: 01_queues.t 18 2003-11-29 23:18:56Z rcaputo $

use strict;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE;
use POE::Component::JobQueue;

sub DEBUG () { 0 };

$| = 1;
print "1..3\n";

#------------------------------------------------------------------------------
# A list of tasks to run.

my @active_tasks  = qw( 5 4 3 2 1 5 4 3 2 1 );
my @passive_tasks = @active_tasks;
my @tests_done;

my $active_test              = 1;
my $passive_test             = $active_test + scalar @passive_tasks;
my $active_simultaneous      = 0;
my $passive_simultaneous     = 0;
my $active_max_simultaneous  = 0;
my $passive_max_simultaneous = 0;
my $target_done_count        = @active_tasks + @passive_tasks;

#------------------------------------------------------------------------------

sub worker_start {
  my ($kernel, $heap, $postback, $test, $task, $a_or_p) =
    @_[KERNEL, HEAP, ARG0..ARG3];

  $heap->{test} = $test;
  $heap->{task} = $task;
  $heap->{aorp} = $a_or_p;
  $heap->{postback} = $postback;

  $kernel->delay( done => $task );

  DEBUG and warn "$a_or_p test $test started ($task)\n";

  if ($a_or_p eq 'active') {
    $active_simultaneous++;
    $active_max_simultaneous = $active_simultaneous
      if $active_simultaneous > $active_max_simultaneous;
  }
  else {
    $passive_simultaneous++;
    $passive_max_simultaneous = $passive_simultaneous
      if $passive_simultaneous > $passive_max_simultaneous;
  }
}

sub worker_done {
  my $heap = $_[HEAP];

  DEBUG and
    warn "$heap->{aorp} test $heap->{test} finished ($heap->{task})\n";

  push @tests_done, $heap->{test};
  if ($heap->{aorp} eq 'active') {
    $active_simultaneous--;
  }
  else {
    $passive_simultaneous--;
  }

  my $postback = delete $heap->{postback};
  if (ref $postback eq 'ARRAY') {
    my $session = $_[KERNEL]->alias_resolve($postback->[0]);
    if (defined $session) {
      $postback = $session->postback( $postback->[1], $heap->{task} );
    }
    else {
      $postback = sub { 1 };
    }
  }

  # Causes some evil recursion somewhere. :(
  # $postback->( $heap->{test}, $heap->{task} );
}

#------------------------------------------------------------------------------

sub spawn_worker {
  my ($outer_postback, $outer_test, $outer_task, $active_or_passive) = @_;

  POE::Session->create
    ( inline_states =>
      { _start => \&worker_start,
        done   => \&worker_done,
        _stop => sub {},
      },
      args => [ $outer_postback, $outer_test, $outer_task, $active_or_passive ]
    );
}

#------------------------------------------------------------------------------

sub passive_respondee_start {
  my $kernel = $_[KERNEL];
  $kernel->yield( 'flood_queue' );
}

sub passive_respondee_flood_queue {
  my $kernel = $_[KERNEL];
  foreach (@passive_tasks) {
    $kernel->post( passive => enqueue => response => $_ );
  }
  $kernel->yield( 'dummy' );
}

sub passive_respondee_response {
  my ($request, $response) = @_[ARG0, ARG1];
  my (@req_job) = @$request;
  my (@resp_answer) = @$response;
  DEBUG and warn "passive respondee got: (@req_job) = (@resp_answer)";
}

POE::Session->create
  ( inline_states =>
    { _start      => \&passive_respondee_start,
      flood_queue => \&passive_respondee_flood_queue,
      response    => \&passive_respondee_response,

      # quiets ASSERT_DEFAULT
      _stop       => sub {},
      dummy       => sub {},
    }
  );

#------------------------------------------------------------------------------

sub active_respondee_start {
  my $kernel = $_[KERNEL];
  $kernel->alias_set( 'respondee' );
}

sub active_respondee_response {
  my ($request, $response) = @_[ARG0, ARG1];
  my (@req_job) = @$request;
  my (@resp_answer) = @$response;
  DEBUG and warn "active respondee got: (@req_job) = (@resp_answer)";
}

POE::Session->create
  ( inline_states =>
    { _start   => \&active_respondee_start,
      response => \&active_respondee_response,

      # quiets ASSERT_DEFAULT
      _stop    => sub {},
    }
  );

#------------------------------------------------------------------------------

POE::Component::JobQueue->spawn
  ( Alias        => 'active',
    WorkerLimit  => 5,
    Worker       =>
    sub {
      my $metapostback = shift;
      my $task = shift @active_tasks;
      my $test = $active_test++;
      if (defined $task) {
        my $postback = $metapostback->($task);
        &spawn_worker( $postback, $test, $task, 'active' );
      }
    },

    Active =>
    { AckAlias => 'respondee',
      AckState => 'response',
    },
  );

POE::Component::JobQueue->spawn
  ( Alias       => 'passive',
    WorkerLimit => 5,
    Worker      =>
    sub {
      my ($postback, $task) = @_;
      my $test = $passive_test++;
      &spawn_worker($postback, $test, $task, 'passive') if defined $task;
    },

    Passive => { },
  );

# Run it all until done.
$poe_kernel->run();

# Figure out whether the tests worked.

print 'not ' unless $active_max_simultaneous == 5;
print "ok 1\n";

print 'not ' unless $passive_max_simultaneous == 5;
print "ok 2\n";

print 'not ' unless scalar(@tests_done) == $target_done_count;
print "ok 3\n";

exit;
