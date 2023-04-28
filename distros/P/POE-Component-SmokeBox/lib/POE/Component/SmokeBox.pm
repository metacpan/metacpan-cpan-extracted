package POE::Component::SmokeBox;
$POE::Component::SmokeBox::VERSION = '0.56';
#ABSTRACT: POE enabled CPAN smoke testing with added value.

use strict;
use warnings;
use POE qw(Component::SmokeBox::Backend Component::SmokeBox::JobQueue);
use POE::Component::SmokeBox::Smoker;
use POE::Component::SmokeBox::Job;
use POE::Component::SmokeBox::Result;

sub spawn {
  my $package = shift;
  my %params = @_;
  $params{lc $_} = delete $params{$_} for keys %params;
  my $options = delete $params{'options'};
  $params{'delay'} = 0 unless exists $params{'delay'};
  my $self = bless \%params, $package;
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => {
		shutdown      => '_shutdown',
		add_smoker    => '_add_smoker',
		del_smoker    => '_del_smoker',
		submit        => '_submit',
		register_ui   => '_reg_ui',
		unregister_ui => '_unreg_ui',
	   },
	   $self => [qw(_start)],
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
}

sub multiplicity {
  return $_[0]->{multiplicity};
}

sub delay {
  if ( defined $_[1] ) {
    # verify it's an int
    if ( $_[1] !~ /^\d+$/ ) {
      return;
    } else {
      $_[0]->{delay} = $_[1];
      return $_[1];
    }
  } else {
    return $_[0]->{delay};
  }
}

sub queues {
  return map { $_->{queue} } @{ $_[0]->{queues} };
}

sub shutdown {
  my $self = shift;
  $poe_kernel->call( $self->session_id() => 'shutdown' => @_ );
}

sub _start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $self->{alias} ) {
    $kernel->alias_set( $self->{alias} );
  }
  else {
    $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
  }
  $self->{queues} = [ ];
  my $smokers = delete $self->{smokers};
  return unless $smokers and ref $smokers eq 'ARRAY' and scalar @{ $smokers };
  $self->add_smoker( $_ ) for @{ $smokers };
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  if ( $self->{alias} ) {
	$kernel->alias_remove($_) for $kernel->alias_list();
  }
  else {
	$kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ );
  }
  $_->{queue}->shutdown() for @{ $self->{queues} };
  return;
}

sub add_smoker {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, 'add_smoker', @_ );
}

sub del_smoker {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, 'del_smoker', @_ );
}

sub _add_smoker {
  my ($kernel,$self,$state,$sender,$smoker) = @_[KERNEL,OBJECT,STATE,SENDER,ARG0];
  unless ( $smoker and $smoker->isa('POE::Component::SmokeBox::Smoker') ) {
     warn "ARG0 must be a 'POE::Component::SmokeBox::Smoker' object\n";
     return;
  }
  # If no jobqueues start a job queue.
  # If multiplicity start a job queue for each smoker object.
  if ( $self->{multiplicity} or scalar @{ $self->{queues} } == 0 ) {
    my $queue = { };
    $queue->{queue} = POE::Component::SmokeBox::JobQueue->spawn(
      'delay' => $self->{delay},
    );
    push @{ $queue->{smokers} }, $smoker;
    push @{ $self->{queues} }, $queue;
    return;
  }
  # Otherwise we just add the smoker to our existing queue
  push @{ $self->{queues}->[0]->{smokers} }, $smoker;
  return;
}

sub _del_smoker {
  my ($kernel,$self,$state,$sender,$smoker) = @_[KERNEL,OBJECT,STATE,SENDER,ARG0];
  unless ( $smoker and $smoker->isa('POE::Component::SmokeBox::Smoker') ) {
     warn "ARG0 must be a 'POE::Component::SmokeBox::Smoker' object\n";
     return;
  }
  my $x = 0;
  foreach my $queue ( @{ $self->{queues} } ) {
     my $i = 0;
     for ( @{ $queue->{smokers} } ) {
        splice(@{ $queue->{smokers} }, $i, 1) if $_ == $smoker;
        ++$i;
     }
     unless ( scalar @{ $queue->{smokers} } ) {
        splice(@{ $self->{queues} }, $x, 1);
	$queue->{queue}->shutdown();
     }
     ++$x;
  }
  return;
}

sub submit {
  my $self = shift;
  $poe_kernel->call( $self->{session_id}, 'submit', @_ );
}

sub _submit {
  my ($kernel,$self,$state,$sender) = @_[KERNEL,OBJECT,STATE,SENDER];
  return if $self->{_shutdown};
  my $args;
  if ( ref( $_[ARG0] ) eq 'HASH' ) {
     $args = { %{ $_[ARG0] } };
  }
  else {
     $args = { @_[ARG0..$#_] };
  }

  $args->{lc $_} = delete $args->{$_} for grep { $_ !~ /^_/ } keys %{ $args };

  unless ( $args->{event} ) {
     warn "No 'event' specified for $state\n";
     return;
  }

  unless ( $args->{job} and $args->{job}->isa('POE::Component::SmokeBox::Job') ) {
     warn "No 'job' specified for $state or it was not a valid 'POE::Component::SmokeBox::Job' object\n";
     return;
  }

  if ( $args->{session} and my $ref = $kernel->alias_resolve( $args->{session} ) ) {
     $args->{session} = $ref->ID();
  }
  else {
     $args->{session} = $sender->ID();
  }

  warn "No smokers have been defined yet!!!!!\n" unless scalar @{ $self->{queues} };

  foreach my $q ( @{ $self->{queues} } ) {
     $args->{smokers} = [ @{ $q->{smokers} } ];
     $q->{queue}->submit( $args );
  }

  return;
}

sub _reg_ui {
}

sub _unreg_ui {
}

"We've Got a Fuzzbox and We're Gonna Use It";

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox - POE enabled CPAN smoke testing with added value.

=head1 VERSION

version 0.56

=head1 SYNOPSIS

  # A simple smoker that takes modules to smoke from @ARGV

  use strict;
  use warnings;
  use POE;
  use POE::Component::SmokeBox;
  use POE::Component::SmokeBox::Smoker;
  use POE::Component::SmokeBox::Job;
  use Getopt::Long;

  $|=1;

  my $perl;

  GetOptions( 'perl=s' => \$perl, );

  die "No 'perl' specified\n" unless $perl;

  die "No modules specified to smoke\n" unless scalar @ARGV;

  my $smokebox = POE::Component::SmokeBox->spawn();

  POE::Session->create(
        package_states => [
           'main' => [ qw(_start _stop _results) ],
        ],
        heap => { perl => $perl, pending => [ @ARGV ] },
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $smoker = POE::Component::SmokeBox::Smoker->new( perl => $perl, );

    $smokebox->add_smoker( $smoker );

    $smokebox->submit( event => '_results',
		 job => POE::Component::SmokeBox::Job->new( command => 'smoke', module => $_ ) )
       			for @{ $heap->{pending} };
    undef;
  }

  sub _stop {
    $smokebox->shutdown();
    undef;
  }

  sub _results {
    my $results = $_[ARG0];
    print $_, "\n" for map { @{ $_->{log} } } $results->{result}->results();
    undef;
  }

=head1 DESCRIPTION

POE::Component::SmokeBox is a flexible CPAN Smoke testing framework which provides an
extensible method for testing CPAN distributions against various different smoker backends.

A smoker backend is defined using a L<POE::Component::SmokeBox::Smoker> object and is basically
the path to a C<perl> executable that is configured for CPAN Testing and its associated environment settings.

The C<perl> executable must be configured appropriately to support CPAN testing with any of the currently
supported backends, L<CPANPLUS::YACSmoke>, L<CPAN::YACSmoke> or L<CPAN::Reporter>. Additional backends may be
supported by inheriting and extending the backend base class L<POE::Component::SmokeBox::Backend::Base>.

By default, the component will test submitted jobs against each configured smoker in turn. Setting C<multiplicity>
to true will enable each job to be run against configured smokers in parallel.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Creates a new session and returns an object. Takes a number of parameters:

  'alias', set an alias that you can use to address the component later;
  'options', a hashref of POE session options;
  'multiplicity', set to a true value to enable multiplicity, default is false;
  'smokers', an arrayref of POE::Component::SmokeBox::Smoker objects;
  'delay', the time in seconds to wait between job runs, default is 0;

=back

=head1 METHODS

=over

=item C<session_id>

Returns the L<POE::Session> ID of the smokebox component.

=item C<multiplicity>

Returns true or false depending on whether multiplicity is enabled or not.

NOTE: If you enable multiplicity, you cannot use "delay" as an argument to SmokeBox::Job->new!

=item C<queues>

Returns a list of L<POE::Component::SmokeBox::JobQueue> objects that are currently active in the smokebox.

=item C<add_smoker>

Takes one mandatory argument, a L<POE::Component::SmokeBox::Smoker> object to add to the smokebox.

=item C<del_smoker>

Takes one mandatory argument, a L<POE::Component::SmokeBox::Smoker> object to remove from the smokebox.

=item C<delay>

Sets the delay in seconds between job runs. Useful to "throttle" your smoker :) If called with no arguments, returns
the current delay. This option will work even if multiplicity is enabled.

=item C<submit>

Submits a job to the smokebox. Takes a number of parameters.

  'event', the event name where results should be sent, mandatory;
  'job', a POE::Component::SmokeBox::Job object to submit, mandatory;
  'session', optionally specify a different session to send the result event to;

=item C<shutdown>

Terminates the smokebox component.

=back

=head1 INPUT EVENTS

=over

=item C<add_smoker>

Takes one mandatory argument, a L<POE::Component::SmokeBox::Smoker> object to add to the smokebox.

=item C<del_smoker>

Takes one mandatory argument, a L<POE::Component::SmokeBox::Smoker> object to remove from the smokebox.

=item C<submit>

Submits a job to the smokebox. Takes a number of parameters.

  'event', the event name where results should be sent, mandatory;
  'job', a POE::Component::SmokeBox::Job object to submit, mandatory;
  'session', optionally specify a different session to send the result event to;

=item C<shutdown>

Terminates the smokebox component.

=back

=head1 OUTPUT EVENTS

An event will be sent on process completion with a hashref as C<ARG0>:

  'job', the POE::Component::SmokeBox::Job object of the job;
  'result', a POE::Component::SmokeBox::Result object containing the results;
  'submitted', the epoch time in seconds when the job was submitted;
  'event', the event that will be sent with the results;
  'session', the session ID the above event will be sent to;

The results will be same as returned by L<POE::Component::SmokeBox::Backend>. They may be obtained by querying the
L<POE::Component::SmokeBox::Result> object:

  $_[ARG0]->{result}->results() # produces a list

Each result is a hashref:

  'log', an arrayref of STDOUT and STDERR produced by the job;
  'PID', the process ID of the POE::Wheel::Run;
  'status', the $? of the process;
  'start_time', the time in epoch seconds when the job started running;
  'end_time', the time in epoch seconds when the job finished;
  'idle_kill', only present if the job was killed because of excessive idle;
  'excess_kill', only present if the job was killed due to excessive runtime;
  'term_kill', only present if the job was killed due to a poco shutdown event;
  'cb_kill', only present if the job was killed due to the callback returning false;

=head1 SEE ALSO

L<POE::Component::SmokeBox::Smoker>

L<POE::Component::SmokeBox::Job>

L<POE::Component::SmokeBox::JobQueue>

L<POE::Component::SmokeBox::Backend>

L<POE::Component::SmokeBox::Result>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
