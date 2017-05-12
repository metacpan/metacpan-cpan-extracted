package POE::Component::Client::MogileFS;

use warnings;
use strict;

use Carp qw(carp croak);
use POE qw(Wheel::Run Filter::Reference);
use MogileFS::Client;

sub spawn {
    my ($class, %args) = @_;
    %args = (
        max_concurrent => 10,
        alias => __PACKAGE__,
        todo => [],
        %args
    );
    my $self = bless {}, $class;
    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => {
                _start => '_start',
                _stop => '_stop',
                add_tasks => 'handle_add_task',
                shutdown => 'shutdown',
                next_task => 'next_task',
                task_result => 'handle_task_result',
                task_done => 'handle_task_done',
                task_debug => 'handle_task_debug',
                killme => 'handle_killme',
            },
        ],
        heap => { args => \%args,
                  todo => $args{todo},
                },
    )->ID;

    return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub shutdown {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    if (@{$heap->{todo}}) {
        $kernel->delay('shutdown', 1);
        return;
    }
    else {
        $kernel->yield('_stop');
        return;
    }
    if (keys %{$heap->{task}}) {
        $kernel->delay('shutdown', 1);
        return;
    }
    else {
        $kernel->yield('_stop');
        return;
    }
}

sub handle_task_result {
    my ($kernel,$heap,$result) = @_[KERNEL,HEAP,ARG0];
    return unless defined $heap->{args}->{result};
    if (ref($heap->{args}->{result}) eq 'ARRAY') {
        $kernel->post($heap->{args}->{result}->[0], 
            $heap->{args}->{result}->[1], $result);
    }
}

sub handle_task_debug {
    my ($kernel,$heap,$result) = @_[KERNEL,HEAP,ARG0];
    return unless defined $heap->{args}->{debug};
    if (ref($heap->{args}->{debug}) eq 'ARRAY') {
        $kernel->post($heap->{args}->{debug}->[0],
            $heap->{args}->{debug}->[1], $result);
    }
}

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $kernel->alias_set($heap->{args}->{alias});
    $kernel->sig(CHLD => 'killme');
    $kernel->yield('next_task');
}

sub next_task {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    my $max_con = $heap->{args}->{max_concurrent};
    while ( scalar keys %{$heap->{task}} < $max_con ) {
        my $next_task = shift @{$heap->{todo}};
        if (defined $next_task) {
            my $filter = POE::Filter::Reference->new('Storable');
            my $task = POE::Wheel::Run->new(
                Program => sub { do_stuff($next_task) },
                StdoutFilter => $filter,
                StdoutEvent  => 'task_result',
                StderrEvent  => 'task_debug',
                CloseEvent   => 'task_done',
                CloseOnCall => 1,
            );
            $heap->{task}->{ $task->ID } = $task;
        }
        else {
            delete $heap->{todo};
            $kernel->delay('next_task', 1);
            last;
        }
    }
}

sub _stop {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $kernel->alias_remove($heap->{args}->{alias});
    delete $heap->{args};
    delete $heap->{todo};
    delete $heap->{task};
}

sub handle_add_task {
    my ($kernel, $heap, $tasks) = @_[KERNEL, HEAP, ARG0];
    push @{$heap->{todo}}, @{$tasks};
    $kernel->yield('next_task');
}

sub handle_task_done {
    my ( $kernel, $heap, $task_id ) = @_[ KERNEL, HEAP, ARG0 ];
    $heap->{task}->{$task_id}->kill(9);
    delete $heap->{task}->{$task_id};
    unless (scalar keys %{$heap->{task}}) {
        delete $heap->{task};
    }
    $kernel->yield("next_task");
}

sub handle_killme {
    my ($kernel, $pid, $child_error) = @_[KERNEL, ARG1, ARG2];
    #we could do something here or something
    $kernel->sig_handled;
}

#not a POE function
#it's run from separate process
#can only run single MogileFS::Client methods that are run on the
#$mogc object
#so no printing to a file handle, use store_content instead
#
sub do_stuff {
    binmode(STDOUT);    # Required for this to work on MSWin32
    my $task   = shift;
    my $filter = POE::Filter::Reference->new('Storable');
    croak 'no domain in todo' unless $task->{domain};
    croak 'no trackers in todo' unless @{$task->{trackers}};
    croak 'no MogileFS::Client method in todo' unless $task->{method};
    croak 'no taskname in todo' unless $task->{taskname};
    my ($success, $mogc, $mogmethod);
    carp "$@" unless eval {
        $mogc = MogileFS::Client->new(
            domain => $task->{domain},
            hosts => $task->{trackers},
        )
    };
    carp 'no MogileFS::Client object' unless defined $mogc;
    $mogmethod = $task->{method};
    $success = eval {
        $mogc->$mogmethod(@{$task->{args}});
    };
    carp "$@" unless $success;
    my %result = (
        status => $success,
        task => $task,
    );
    my $output = $filter->put( [ \%result ] );
    print @$output;
}

=head1 NAME

POE::Component::Client::MogileFS - an async MogileFS client for POE

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use POE qw(Component::Client::MogileFS);

  my $num = 500;
  my @tasks;
  foreach (1..$num) {
      my $key = $_ .'x'. int(rand($num)) . time();
      my $data = $key x 1000;
      push @tasks, {
          method => 'store_content',
          domain => 'testdomain',
          trackers => [qw/192.168.0.31:6001/],
          args => [$key, 'testclass', $data],
          taskname => $key.':testclass:testdomain',
      };
  }

  POE::Session->create(
      inline_states => {
          _start => \&start_session,
          storesomestuff => \&storesomestuff,
          debugging => \&debugging,
      }
  );

  sub start_session {
      my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
      POE::Component::Client::MogileFS->spawn(
          alias => 'mog',
          max_concurrent => 50,
          result => [$session, 'storesomestuff'],
          debug => [$session, 'debugging'],
      );
      $kernel->post('mog', 'add_tasks', \@tasks);
  }

  my $count = 0;
  sub storesomestuff {
      my ($kernel,$result) = @_[KERNEL,ARG0];
      if ($result->{status}) {
          $count++;
          print "$count RESULT ".$result->{task}->{taskname};
          print " SUCCESS ".$result->{status}."\n";
      }
      else {
          print "$count RESULT ".$result->{task}->{taskname};
          print " FAILED\n";
          $kernel->post('mog', 'add_tasks', [$result->{task}]);
      }
      $kernel->post('mog', 'shutdown') if $count == $num;
  }

  sub debugging {
      my $result = $_[ARG0];
      print "DEBUG $result\n";
  }

  $poe_kernel->run();

=head1 DESCRIPTION

  POE::Component::Client::MogileFS is a POE component that uses Wheel::Run
  to fork off child processes which will execute MogileFS::Client methods
  with your provided data asyncronously.  By default it will not allow more
  than 10 concurrent connections, but you can adjust that as needed.

  This is my first go at a POE::Component so the api may change in future,
  and I'm really open to suggestions for improvement/features.

=head1 FUNCTIONS

=head2 spawn

  Can take the following arguments:

    alias => 'alias of mogilefs session or __PACKAGE__ by default',
    max_concurrent => 'max number of concurrent children - default 10',
    result => ['session alias or id', 'eventname'],
    debug => ['session alias or id', 'eventname'],
    todo => ['list of hashes of jobs todo']

=head2 session_id

  Returns the session id

=head2 add_tasks

  $kernel->post('session', 'add_tasks', \@tasks);

  Takes an arraref of hashes, each hash represents one MogileFS::Client method
  to call and should have the following keys:

  {method => 'MogileFS::Client method name',
   domain => 'domain to use',
   trackers => [array ref of trackers],
   args => [arrayref, of, args, for, method],
   taskname => 'name of this task',
  }

=head2 shutdown

  $kernel->post('session', 'shutdown');

  Kills the MogileFS session and cleans up.

=head2 result

  If result is set in spawn, then your event will get a hashref in ARG0.

  $_[ARG0]->{status} is whatever is returned from the MogileFS method you
  called, typically undef means it failed.

  $_[ARG0]->{task} is the task you originally gave add_task.

  This should allow you to retry if something fails and it's appropriate to
  do so (the synopsis contains an example of doing so, using store_content).

=head2 debug

  Returns back all the warnings and errors MogileFS::Client will spew in
  ARG0.  Mostly just useful for debugging.

=head1 STUFF

  This module is kinda simplistic in what MogileFS::Client methods you can
  use.  Essentially all it does is create a new MogileFS::Client object in
  each child, call the method you provide on that object with the arguments
  you specified and return the result.  Obviously this won't work for any
  methods that want more than one operation on the same object.  For example
  my $fh = $mogc->newfile( ... ); print $fh 'foobar'; close $fh; isn't going
  to work.  Instead use store_content;

  The session won't go away until you shutdown.  This is to allow you to do
  things like this:

  $kernel->post('session', 'add_tasks', \@tasks);
  $kernel->post('session', 'add_tasks', \@moretasks);

  and to re-add your tasks from result if they failed.

=head1 AUTHOR

mock, C<< <mock at obscurity.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-poe-component-client-mogilefs at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-Client-MogileFS>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::Client::MogileFS

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-Client-MogileFS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-Client-MogileFS>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Client-MogileFS>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-Client-MogileFS>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 RJ Research, Inc, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of POE::Component::Client::MogileFS
