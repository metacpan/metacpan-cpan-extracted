package Proc::LoadMonitor;
$Proc::LoadMonitor::VERSION = '1.000';
use Time::HiRes qw(tv_interval gettimeofday);
use Moo;
use strict;
use warnings;

has '__load_log' => ( is => 'ro', default => sub { [] } );

has '__start_busy' => ( is => 'rw' );

has '__start_idle' => ( is => 'rw' );

has '__start_time' => ( is => 'rw' );

has 'state' => ( is => 'rw' );

has 'jobs' => ( is => 'rw', default => 0 );

has 'loops' => ( is => 'rw', default => 0 );

sub BUILD {
    my ($self) = @_;
    my $timeofday = [gettimeofday];
    $self->__start_idle($timeofday);
    $self->__start_time($timeofday);
    $self->state('idle');
}

sub busy {
    my ($self) = @_;
    return if $self->state eq 'busy';
    $self->__start_busy( [gettimeofday] );
    $self->jobs( $self->jobs + 1 );
    $self->state('busy');
}

sub idle {
    my ($self) = @_;
    $self->loops( $self->loops + 1 );
    return if $self->state eq 'idle';
    $self->__start_idle( [gettimeofday] );
    my $elapsed   = tv_interval( $self->__start_busy );
    my $time_slot = __time_slot();
    my $load_log  = $self->__load_log;
    $load_log->[$time_slot] += $elapsed;
    $load_log->[ __time_slot( $time_slot, $_ ) ] = undef for 1 .. 15;
    $self->state('idle');
}

sub report {
    my ($self)    = @_;
    my $time_slot = __time_slot();
    my $load_log  = $self->__load_log;
    my $seconds   = (localtime)[0];
    my $sum_05    = $load_log->[$time_slot];
    $sum_05 += $load_log->[ __time_slot( $time_slot, -$_ ) ] // 0 for 1 .. 5;
    my $load_05 = $sum_05 / ( 300 + $seconds );
    my $sum_10 = $sum_05;
    $sum_10 += $load_log->[ __time_slot( $time_slot, -$_ ) ] // 0 for 6 .. 10;
    my $load_10 = $sum_10 / ( 600 + $seconds );
    my $sum_15 = $sum_10;
    $sum_15 += $load_log->[ __time_slot( $time_slot, -$_ ) ] // 0 for 11 .. 15;
    my $load_15 = $sum_15 / ( 900 + $seconds );
    return {
        load_05 => sprintf( '%.3f', $load_05 > 1 ? 1 : $load_05 ),
        load_10 => sprintf( '%.3f', $load_10 > 1 ? 1 : $load_10 ),
        load_15 => sprintf( '%.3f', $load_15 > 1 ? 1 : $load_15 ),
        total => tv_interval( $self->__start_time ),
        loops => $self->loops,
        jobs  => $self->jobs,
        state => $self->state,
    };
}

sub __time_slot {
    my ( $base, $offset ) = @_;
    $base   //= (localtime)[1];    # minutes
    $offset //= 0;
    return ( $base + $offset + 60 ) % 60;
}

1;                                 # track-id: 3a59124cfcc7ce26274174c962094a20

__END__

=pod

=encoding utf-8

=head1 NAME

Proc::LoadMonitor - Load monitoring for worker processes

=head1 SYNOPSIS
 
 use Proc::LoadMonitor;

  # get monitor, starts in 'idle' state
  my $lmon = Proc::LoadMonitor->new;

  # some job queue with timeout (e.g redis BLPOP) which
  # blocks until a new job is available, or times out.
  #  
  while ( my $job = $some_queue->get_next_job() ) {

    if ($job) {
        $lmon->busy; # set monitor to 'busy';
        $job->do_it();
    }
    
    $lmon->idle; # set monitor to 'idle', increment loop count

    my $report = $lmon->report;
    
    # $report = {
    #     loops   => 781,       # number of loops
    #     jobs    => 674,       # number of processed jobs 
    #     load_05 => 0.650,     #  5 min. load avg. 
    #     load_10 => 0.510,     # 10 min. load avg. 
    #     load_15 => 0.414,     # 15 min. load avg.
    #     state   => 'idle',    # 'busy'/'idle'
    #     total   => 110566.19  # total run time    
    # }

  }
  
=head1 DESCRIPTION

This module keeps track of idle and busy times in a worker process and calculates
5, 10 and 15 minutes load averages.

=head2 busy

Set C<state> to C<busy>.

=head2 idle

Set C<state> to C<idle> and increment the C<loop> counter.

=head2 state

Returns the C<state> which may be C<busy> or C<idle>.

=head2 loops

Returns the C<loop> count.

=head2 jobs

Returns the number of C<jobs> processed so far.

=head2 report

Returns a report (hash) containing C<loops>, C<jobs>, C<total> (total run time in sec.),
C<load_05> (5 min. load average), C<load_10> (10 min. load average) and C<load_15>
(15 min. load average).

=head1 AUTHOR

Michael Langner (cpan:MILA)

=head1 COPYRIGHT

Copyright (c) 2015 the Proc::LoadMonitor L</AUTHOR>.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut


