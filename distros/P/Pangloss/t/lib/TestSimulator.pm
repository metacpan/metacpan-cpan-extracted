package TestSimulator;

use strict;
use warnings;

use POSIX qw( :sys_wait_h );
use File::Spec;
use TestApplication;

use base qw( Pangloss::Object );

our $SINGLETON;
our $SIM_DIR    = File::Spec->catfile(qw( t tmp sim ));
our %ROLE_CLASS = ( translator  => 'TestSimulator::Translator',
		    proofreader => 'TestSimulator::Proofreader',
		    admin       => 'TestSimulator::Admin',
		    user        => 'TestSimulator::User', );

sub new {
    my $class = shift->class;
    return $SINGLETON if $SINGLETON;
    $SINGLETON = bless {}, $class;
    $SINGLETON->init(@_) || return;
    return $SINGLETON;
}

sub simulate {
    my $self = shift;
    my $time = $self->{time};

    unless (-d $SIM_DIR) {
	require File::Path;
	import File::Path;
	mkpath( $SIM_DIR );
    }

    print "Simulating $self->{users} concurrent users for at least $time CPU seconds each.\n";

    sub reap {
	no warnings;
	$self->reaper;
	$SIG{CHLD} = \&reap;
    }

    local $SIG{CHLD} = \&reap;

    $self->start_children
         ->wait_for_children;

    $self->emit( 'done' );

    print "Detailed results are in $SIM_DIR.\n";

    return $self;
}

sub start_children {
    my $self = shift;
    my $time = $self->{time};

    for my $i (1 .. $self->{users}) {
	my $role = $self->choose_role;

	my $pid  = fork;

	if ($pid) {
	    # parent
	    $self->emit( "setting kid $pid: user $i, role $role" );
	    $self->{kids}->{$pid} = { user => $i, role => $role };
	} elsif (not defined $pid) {
	    warn "couldn't fork child $i - $!";
	    exit 1;
	} else {
	    sleep 1; # HACK: give parent some time to populate $self->{kids} !
	    $self->emit( "($$) simulating $role (user #$i)" );
	    $SIG{CHLD} = 'IGNORE';
	    my $class  = $ROLE_CLASS{$role};
	    eval "require $class" || die $@;
	    $class->new
	      ->log_file( File::Spec->catfile($SIM_DIR, "$role-$i.csv") )
	      ->number( $i )
	      ->simulate( $time );
	    undef $_;
	    $self->emit( "($$) exiting $role (user #$i)" );
	    exit 0;
	}
    }

    return $self;
}

sub wait_for_children {
    my $self      = shift;
    my $i         = 0;
    my @indicator = qw( - \ | / );

    while (keys %{ $self->{kids} }) {
	print STDERR ' ' . $indicator[$i = ++$i % @indicator] . "\r";
	sleep 1;
    }

    return $self;
}

sub reaper {
    my $self  = shift;
    while (my $pid = waitpid( -1, WNOHANG )) {
	$self->emit( "reaped $pid" );
	return unless $pid > 0;
	my $kid = delete $self->{kids}->{$pid} || next;
	$self->emit( "($$) user $kid->{user} exited w/status=$? ($kid->{role})" );
    }
}

sub choose_role {
    my $self = shift;

    if ($self->{translators} > 0) {
	$self->{translators}--;
	return 'translator';
    } elsif ($self->{proofreaders} > 0) {
	$self->{proofreaders}--;
	return 'proofreader';
    } elsif ($self->{admins} > 0) {
	$self->{admins}--;
	return 'admin';
    }

    return 'user';
}

sub simulate_role {
    my $self = shift;
    my $role = shift;


    return $self;
}


1;
