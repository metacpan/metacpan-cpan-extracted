package POE::Component::SmokeBox::JobQueue;
$POE::Component::SmokeBox::JobQueue::VERSION = '0.54';
#ABSTRACT: An array based queue for SmokeBox

use strict;
use warnings;
use POE qw(Component::SmokeBox::Backend Component::SmokeBox::Job Component::SmokeBox::Smoker Component::SmokeBox::Result);
use Params::Check qw(check);

# Stolen from POE::Wheel. This is static data, shared by all
my $current_id = 0;
my %active_identifiers;

sub spawn {
  my $package = shift;
  my %params = @_;
  $params{lc $_} = delete $params{$_} for keys %params;
  $params{'delay'} = 0 unless exists $params{'delay'};
  my $options = delete $params{'options'};
  my $self = bless \%params, $package;
  $self->{session_id} = POE::Session->create(
        object_states => [
           $self => {
                'shutdown' => '_shutdown',
		submit     => '_submit',
		cancel     => '_cancel',
           },
           $self => [qw(_start _process_queue _backend_done _process_queue_delayed)],
        ],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub session_id {
  return $_[0]->{session_id};
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
  $self->{_queue} = [ ];
  return;
}

sub _shutdown {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  $self->{_shutdown} = 1;
  if ( $self->{alias} ) {
        $kernel->alias_remove($_) for $kernel->alias_list();
  }
  else {
        $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ );
  }
  # shutdown currently running backend
  $self->{_current}->{backend}->shutdown() if $self->{_current}->{backend};
  # remove queued jobs.
#  $kernel->refcount_decrement( $_->{session}, __PACKAGE__ ) for @{ $self->{_queue} };
  $kernel->refcount_decrement( $_, __PACKAGE__ ) for keys %{ $self->{_refcounts} };
  delete $self->{_queue};

  # remove delay for jobs if we set one
  $kernel->alarm_remove( delete $self->{_delay} ) if exists $self->{_delay};

  return;
}

sub _process_queue_delayed {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{_delay} if exists $self->{_delay};
  $kernel->yield( '_process_queue', 'DELAYDONE' );
  return;
}

sub _process_queue {
  my ($kernel,$self,$delaydone) = @_[KERNEL,OBJECT,ARG0];
  return if $self->{_shutdown};
  return if exists $self->{_delay};
  return if exists $self->{paused} and $self->{paused} == 2;
  my ($job, $smoker );
  if ( $self->{_current} ) {
     return if $self->{_current}->{backend};
     $job = $self->{_current};

     # do we have a delay between smokers?
     if ( $job->{job}->delay > 0 and ! defined $delaydone and scalar @{ $job->{smokers} } > 0 ) {
	# fire off an alarm for the next iteration
	#warn "Setting delay(" . $job->{job}->delay . ") for smoker" if $ENV{PERL5_SMOKEBOX_DEBUG};
	$self->{_delay} = $kernel->delay_set( '_process_queue_delayed' => $job->{job}->delay );
	return;
     }

     $smoker = shift @{ $job->{smokers} };
     unless ( $smoker ) {
	# Reached the end send an event back to the original requestor
	delete $self->{_current};
	delete $job->{smokers};
	my $session = delete $job->{session};
	$kernel->post( $session, delete $job->{event}, $job );
	$self->{_refcounts}->{ $session }--;
	if ( $self->{_refcounts}->{ $session } <= 0 ) {
	   $kernel->refcount_decrement( $session, __PACKAGE__ );
	   delete $self->{_refcounts}->{ $session };
	}

	# did we enable delay between jobs?
	# don't check the queue, we force a delay all the time so if we add a job, we're already delaying for it...
	if ( $self->{delay} > 0 ) {
	   # fire off an alarm for the next iteration
	   #warn "Setting delay($self->{delay}) for job" if $ENV{PERL5_SMOKEBOX_DEBUG};
	   $self->{_delay} = $kernel->delay_set( '_process_queue_delayed' => $self->{delay} );
	} else {
  	   $kernel->yield( '_process_queue' );
	}
	return;
     }
  }
  else {
     $job = $self->_shift();
     return unless $job;
     $smoker = shift @{ $job->{smokers} };
     $job->{result} = POE::Component::SmokeBox::Result->new();
     $self->{_current} = $job;
  }
  $job->{backend} = POE::Component::SmokeBox::Backend->spawn( event => '_backend_done', $job->{job}->dump_data(), $smoker->dump_data(), );
  return;
}

sub _backend_done {
  my ($kernel,$self,$result) = @_[KERNEL,OBJECT,ARG0];
  delete $self->{_current}->{backend};
  $self->{_current}->{result}->add_result( $result );
  $kernel->yield( '_process_queue' );
  return;
}

sub submit {
  my $self = shift;
  return $poe_kernel->call( $self->{session_id}, 'submit', @_ );
}

sub cancel {
  my $self = shift;
  return $poe_kernel->call( $self->{session_id}, 'cancel', @_ );
}

sub _submit {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  return if $self->{_shutdown};
  my $args;
  if ( ref( $_[ARG0] ) eq 'HASH' ) {
     $args = { %{ $_[ARG0] } };
  }
  else {
     $args = { @_[ARG0..$#_] };
  }

  my $tmpl = {
     event   => { required => 1, defined => 1, },
     session => { defined => 1, allow => [ sub { return 1 if $poe_kernel->alias_resolve( $_[0] ); }, ], },
     type    => { defined => 1, allow => [qw(push unshift)], default => 'push', },
     job     => { required => 1, defined => 1,
		  allow => [ sub { return 1 if ref $_[0] and $_[0]->isa('POE::Component::SmokeBox::Job'); }, ], },
     smokers => { required => 1, defined => 1, allow => [
                sub {
                        return 1 if ref $_[0] eq 'ARRAY'
                                and scalar @{ $_[0] }
                                and ( grep { $_->isa('POE::Component::SmokeBox::Smoker') } @{ $_[0] } ) == @{ $_[0] };
                    }, ],
		},

  };

  my $checked = check( $tmpl, $args, 1 ) or return;
  $checked->{session} = $kernel->alias_resolve( $checked->{session} )->ID() if $checked->{session};
  $checked->{session} = $sender->ID() unless $checked->{session};
  my $type = delete $checked->{type};
  my $id = $self->_add_job( $checked, $type );
  return unless $id;
  unless ( defined $self->{_refcounts}->{ $checked->{session} } ) {
    $kernel->refcount_increment( $checked->{session}, __PACKAGE__ );
  }
  $self->{_refcounts}->{ $checked->{session} }++;
  $checked->{submitted} = time();
  #$checked->{job}->id( $id );
  return $id;
}

sub _cancel {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  return if $self->{_shutdown};
  my $args;
  if ( ref( $_[ARG0] ) eq 'HASH' ) {
     $args = { %{ $_[ARG0] } };
  }
  else {
     $args = { @_[ARG0..$#_] };
  }

  my $tmpl = {
     job     => { required => 1, defined => 1, },
  };

  my $checked = check( $tmpl, $args, 1 ) or return;
  return $self->_remove_job( $checked->{job} );
}

sub _push {
  my ($self,$job) = @_;
  return unless ref $job eq 'HASH';
  my $id = _allocate_identifier();
  $job->{id} = $id;
  CORE::push @{ $self->{_queue} }, $job;
  $self->{_jobs}->{ $id } = $job;
  $poe_kernel->post( $self->session_id(), '_process_queue' );
  return $id;
}

sub _unshift {
  my ($self,$job) = @_;
  return unless ref $job eq 'HASH';
  my $id = _allocate_identifier();
  $job->{id} = $id;
  CORE::unshift @{ $self->{_queue} }, $job;
  $self->{_jobs}->{ $id } = $job;
  $poe_kernel->post( $self->session_id(), '_process_queue' );
  return $id;
}

sub _shift {
  my $self = CORE::shift;
  return if $self->{paused};
  my $job = CORE::shift @{ $self->{_queue} };
  return unless $job;
  delete $self->{_jobs}->{ $job->{id} };
  _free_identifier( $job->{id} );
  delete $job->{id};
  return $job;
}

sub _pop {
  my $self = CORE::shift;
  return if $self->{paused};
  my $job = CORE::pop @{ $self->{_queue} };
  return unless $job;
  delete $self->{_jobs}->{ $job->{id} };
  _free_identifier( $job->{id} );
  delete $job->{id};
  return $job;
}

sub _add_job {
  my ($self,$job,$type) = @_;
  $type = lc $type if $type;
  if ( $type and grep { /^\Q$type\E$/ } qw(push unshift) ) {
     $type = '_' . $type;
     return $self->$type( $job );
  }
  return $self->_push( $job );
}

sub _remove_job {
  my ($self,$type) = @_;
  return if $self->{paused};
  $type = lc $type if $type;
  if ( $type and grep { /^\Q$type\E$/ } qw(pop shift) ) {
     $type = '_' . $type;
     return $self->$type();
  }
  elsif ( $type and defined $self->{_jobs}->{ $type } ) {
     my $job = delete $self->{_jobs}->{ $type };
     my $i = 0;
     for ( @{ $self->{_queue} } ) {
	splice(@{ $self->{_queue} }, $i, 1) if $_->{id} eq $type;
	++$i;
     }
     delete $job->{id};
  }
  return $self->_shift();
}

sub pending_jobs {
  my $self = CORE::shift;
  return @{ $self->{_queue} };
}

sub pause_queue {
  my $self = CORE::shift;
  $self->{paused} = 1;
}

sub pause_queue_now {
  my $self = CORE::shift;
  $self->{paused} = 2;
}

sub resume_queue {
  my $self = CORE::shift;
  delete $self->{paused};
  $poe_kernel->post( $self->{session_id}, '_process_queue' );
}

sub queue_paused {
  if ( exists $_[0]->{paused} ) {
    return 1;
  } else {
    return 0;
  }
}

sub current_job {
  my $self = CORE::shift;
  return $self->{_current};
}

sub _allocate_identifier {
  while (1) {
    last unless exists $active_identifiers{ ++$current_id };
  }
  return $active_identifiers{$current_id} = $current_id;
}

sub _free_identifier {
  my $id = CORE::shift;
  delete $active_identifiers{$id};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::JobQueue - An array based queue for SmokeBox

=head1 VERSION

version 0.54

=head1 SYNOPSIS

  use strict;
  use warnings;
  use data::Dumper;
  use POE qw(Component::SmokeBox::JobQueue Component::SmokeBox::Job Component::SmokeBox::Smoker);

  my $perl = 'home/cpan/rel/perl-5.8.8/bin/perl';

  my $q = POE::Component::SmokeBox::JobQueue->spawn();

  POE::Session->create(
     package_states => [
        'main' => [qw(_start _result)],
     ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    my $smoker = POE::Component::SmokeBox::Smoker->new( perl => $perl );
    my $job = POE::Component::SmokeBox::Job->new(
	type => 'CPANPLUS::YACSmoke',
	command => 'smoke',
	module => 'B/BI/BINGOS/POE-Component-IRC-5.88.tar.gz',
    );

    my $id = $q->submit( event => '_result', job => $job, smokers => [ $smoker ] );
    print "Job ID $id submitted\n";

    return;
  }

  sub _result {
    my ($kernel,$results) = @_[KERNEL,ARG0];

    print "Submitted = ", $results->{submitted}, "\n";
    print Dumper( $_ ) for $results->{result}->results();

    $q->shutdown();
    return;
  }

=head1 DESCRIPTION

POE::Component::SmokeBox::JobQueue is an array based job queue for L<POE::Component::SmokeBox>.

Smoke jobs are submitted to the queue and processed with L<POE::Component::SmokeBox::Backend>.

A smoke job is encapsulated in a L<POE::Component::SmokeBox::Job> object.

The results of the smoke are returned encapsulated in a L<POE::Component::SmokeBox::Result> object.

=head1 CONSTRUCTOR

=over

=item C<spawn>

Creates a new POE::Component::SmokeBox::JobQueue object. Takes a number of optional parameters:

  'alias', specify a POE::Kernel alias for the component;
  'options', a hashref of POE::Session options to pass to the poco's POE::Session;
  'delay', the time in seconds to wait between job runs, default is 0;

=back

=head1 METHODS

=over

=item C<session_id>

Returns the L<POE::Session> ID of the component's session.

=item C<shutdown>

Terminates the jobqueue and kills any currently processing job.

=item C<submit>

Submits a job to the jobqueue for processing. Takes a number of parameters:

  'job', a POE::Component::SmokeBox::Job object, mandatory;
  'event', the event to send results to, mandatory;
  'smokers', an arrayref of POE::Component::SmokeBox::Smoker objects, mandatory;
  'session', the session to send results to, default is the sender;
  'type', specify the job priority, 'push' or 'unshift', defaults to 'push';

Jobs are by default pushed onto the end of the queue. You may specify C<unshift> to put submitted items to the front
of the queue.

Returns a unique job ID number.

=item C<cancel>

Given a previously returned job ID number, removes that job from the queue.

  'job', a job ID number, mandatory;

Returns a hashref defining the cancelled job on success, undef otherwise.

=item C<pending_jobs>

Returns a list of pending jobs in the queue. Each job is represented as a hashref, defined as following:

  'id', the unique job ID number of the job;
  'job', the POE::Component::SmokeBox::Job object of the job;
  'submitted', the epoch time in seconds when the job was submitted;
  'event', the event that will be sent with the results;
  'session', the session ID the above event will be sent to;

=item C<current_job>

Returns a hashref to the currently processing job, if there is one, undef otherwise. The hashref will have the following keys:

  'job', the POE::Component::SmokeBox::Job object of the job;
  'submitted', the epoch time in seconds when the job was submitted;
  'event', the event that will be sent with the results;
  'session', the session ID the above event will be sent to;
  'smokers', an arrayref of POE::Component::SmokeBox::Smoker objects that are waiting to be processed;
  'backend', the POE::Component::SmokeBox::Backend object of the current job;
  'result', a POE::Component::SmokeBox::Result object containing the results so far;

=item C<pause_queue>

Pauses the jobqueue. Any currently processing jobs will be completed, but nothing else will be processed until the
queue is resumed.

=item C<pause_queue_now>

Same as C<pause_queue> but also halts any currently processing job.

=item C<resume_queue>

Resumes the processing of a previously paused jobqueue.

=item C<queue_paused>

Returns true if the jobqueue is paused, false otherwise.

=back

=head1 OUTPUT EVENT

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

L<POE::Component::SmokeBox::Backend>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
