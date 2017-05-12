package TestSimulator::Base;

use strict;
use warnings;

use IO::File;
use Benchmark qw( :all );
use Time::HiRes qw( time );
use TestApplication;

use base      qw( Pangloss::Object );
use accessors qw( app number log_file );

use constant ROLE => 'base';

#------------------------------------------------------------------------------
# Methods

sub simulate {
    my $self = shift;
    my $time = shift;
    $self->emit( "($$) simulating " . $self->ROLE . " for at least $time CPU seconds...\n" );
    require Carp;
    local $SIG{__DIE__} = \&Carp::confess;
    $self->timed_prepare->action_loop( $time )->timed_finish->summary;
}

sub timed_prepare {
    my $self = shift;

    my %t;
    $t{name}   = 'prepare';
    $t{start}  = time;
    $t{think}  = $self->zero_time;
    $t{action} = $self->time_this( sub { $self->prepare } );

    $self->open_log_file->log_timing_header->log_timing( %t );

    return $self;
}

sub prepare {
    my $self = shift;
    $self->{actions} = 0;
    $self->load_test_app;
    return $self;
}

sub timed_finish {
    my $self = shift;

    my %t;
    $t{name}   = 'finish';
    $t{start}  = time;
    $t{think}  = $self->zero_time;
    $t{action} = $self->time_this( sub { $self->finish } );

    $self->log_timing( %t )->close_log_file;

    return $self;
}

sub finish {
    my $self = shift;
    $self->unload_test_app;
}

sub summary {
    my $self = shift;

    print "($$) Simulation summary for " . $self->ROLE,
          $self->number ? " #" . $self->number . ' ' : (),
          "($self->{actions} actions in $self->{t_total} wallclock seconds):\n",
	  $self->summarize;

    return $self;
}

sub load_test_app {
    my $self = shift;

    $self->emit( "($$) loading test application...\n" );

    $self->app( TestApplication->new || die "error loading test application!" );

    return $self;
}

sub unload_test_app {
    my $self = shift;

    $self->emit( "($$) unloading test application...\n" );
    $self->app->store( undef );
    $self->app( undef );

    TestStore->reset_store;

    return $self;
}

sub action_loop {
    my $self = shift;
    my $time = shift;

    $self->emit( "($$) running action loop...\n" );

    $self->{t_start} = time;
    $self->{t}->{total} =
      countit( -$time,
	       sub { $self->perform_next_action },
	       $self->ROLE );
    $self->{t_finish} = time;
    $self->{t_total}  = $self->{t_finish} - $self->{t_start};

    return $self;
}

sub perform_next_action {
    my $self = shift;

    $self->{actions}++;

    my ($action, %t);
    $t{start}  = time;
    $t{think}  = $self->time_this( sub { $action = $self->choose_next_action } );
    $t{init}   = time;
    my $method = "action_$action";
    $t{action} = $self->time_this( sub { $self->$method } );
    $t{finish} = time;
    $t{name}   = $action;

    $self->{t}->{"think_$action"} =
      timesum( $self->{t}->{"think_$action"} || $self->{t_zero},
	       $t{think} );
    $self->{t}->{$action} =
      timesum( $self->{t}->{$action} || $self->{t_zero},
	       $t{action} );

    $self->log_timing( %t );

    return $self;
}

sub summarize {
    my $self = shift;
    my $str  = sprintf( "\t%-10s %-9s %-9s %-9s %-9s\n",
			qw( action real user system iters ) );

    while (my ($name, $benchmark) = each %{ $self->{t} }) {
	no warnings;
	next if ($name =~ /init|final|total/i);
	$str .= sprintf( "\t%-10s %-9s %-9s %-9s %-9s\n",
			 "$name:", map( {$_ ? sprintf('%5.3f,', $_) : "0,"}
					@{$benchmark}[0..2] ),
			 ${$benchmark}[-1] );
    }

    return $str;
}

sub log {
    my $self = shift;
    $self->{fh}->print( @_ );
}

#------------------------------------------------------------------------------
# CSV Logging Methods

sub open_log_file {
    my $self = shift;
    my $file = $self->log_file;
    $self->emit( "($$) logging CSV stats to $file..." );
    $self->{fh} = IO::File->new( $file, 'w' )
      || die "error opening $file for writing: $!";
    $self->{fh}->autoflush(1);
    return $self;
}

sub close_log_file {
    my $self = shift;
    $self->emit( "($$) closing logfile..." );
    $self->{fh}->close;
    undef $self->{fh};
    return $self;
}

sub log_timing_header {
    my $self = shift;
    $self->{fh}->print(
		       join( ',', qw( action start
				      think_real think_user think_system
				      real user system ) ),
		       "\n"
		      );
    return $self;
}

sub log_timing {
    my $self = shift;
    my %t    = @_;
    $self->{fh}->print(
		       join( ',', $t{name}, $t{start},
			     @{ $t{think} }[0..2], @{ $t{action} }[0..2] ),
		       "\n"
		      );
    return $self;
}


#------------------------------------------------------------------------------
# I'm absolutely fed up with Benchmark.pm so:

sub zero_time { bless [0,0,0,0,0,0], 'Benchmark'; }

sub time_this {
    my $self = shift;
    my $code = shift;

    my @t_init = (time, times);
    $code->();
    my @t_finish = (time, times);

    # fake a Benchmark object:
    my $benchmark = bless [], 'Benchmark';
    $benchmark->[0] = $t_finish[0] - $t_init[0]; # real time
    $benchmark->[1] = $t_finish[1] - $t_init[1]; # user time
    $benchmark->[2] = $t_finish[2] - $t_init[2]; # sys time
    $benchmark->[3] = $t_finish[3] - $t_init[3]; # kid user
    $benchmark->[4] = $t_finish[4] - $t_init[4]; # kid sys
    $benchmark->[5] = 1; # iters

    return $benchmark;
}

#------------------------------------------------------------------------------
# Abstract Methods

sub choose_next_action {
    die shift->class . "->choose_next_action() not implemented!";
}

1;
