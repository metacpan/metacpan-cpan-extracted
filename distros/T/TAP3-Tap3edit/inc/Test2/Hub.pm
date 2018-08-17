#line 1
package Test2::Hub;
use strict;
use warnings;

our $VERSION = '1.302073';


use Carp qw/carp croak confess/;
use Test2::Util qw/get_tid ipc_separator/;

use Scalar::Util qw/weaken/;

use Test2::Util::ExternalMeta qw/meta get_meta set_meta delete_meta/;
use Test2::Util::HashBase qw{
    pid tid hid ipc
    no_ending
    _filters
    _pre_filters
    _listeners
    _follow_ups
    _formatter
    _context_acquire
    _context_init
    _context_release

    active
    count
    failed
    ended
    bailed_out
    _passing
    _plan
    skip_reason
};

my $ID_POSTFIX = 1;
sub init {
    my $self = shift;

    $self->{+PID} = $$;
    $self->{+TID} = get_tid();
    $self->{+HID} = join ipc_separator, $self->{+PID}, $self->{+TID}, $ID_POSTFIX++;

    $self->{+COUNT}    = 0;
    $self->{+FAILED}   = 0;
    $self->{+_PASSING} = 1;

    if (my $formatter = delete $self->{formatter}) {
        $self->format($formatter);
    }

    if (my $ipc = $self->{+IPC}) {
        $ipc->add_hub($self->{+HID});
    }
}

sub is_subtest { 0 }

sub reset_state {
    my $self = shift;

    $self->{+COUNT} = 0;
    $self->{+FAILED} = 0;
    $self->{+_PASSING} = 1;

    delete $self->{+_PLAN};
    delete $self->{+ENDED};
    delete $self->{+BAILED_OUT};
    delete $self->{+SKIP_REASON};
}

sub inherit {
    my $self = shift;
    my ($from, %params) = @_;

    $self->{+_FORMATTER} = $from->{+_FORMATTER}
        unless $self->{+_FORMATTER} || exists($params{formatter});

    if ($from->{+IPC} && !$self->{+IPC} && !exists($params{ipc})) {
        my $ipc = $from->{+IPC};
        $self->{+IPC} = $ipc;
        $ipc->add_hub($self->{+HID});
    }

    if (my $ls = $from->{+_LISTENERS}) {
        push @{$self->{+_LISTENERS}} => grep { $_->{inherit} } @$ls;
    }

    if (my $pfs = $from->{+_PRE_FILTERS}) {
        push @{$self->{+_PRE_FILTERS}} => grep { $_->{inherit} } @$pfs;
    }

    if (my $fs = $from->{+_FILTERS}) {
        push @{$self->{+_FILTERS}} => grep { $_->{inherit} } @$fs;
    }
}

sub format {
    my $self = shift;

    my $old = $self->{+_FORMATTER};
    ($self->{+_FORMATTER}) = @_ if @_;

    return $old;
}

sub is_local {
    my $self = shift;
    return $$ == $self->{+PID}
        && get_tid() == $self->{+TID};
}

sub listen {
    my $self = shift;
    my ($sub, %params) = @_;

    carp "Useless addition of a listener in a child process or thread!"
        if $$ != $self->{+PID} || get_tid() != $self->{+TID};

    croak "listen only takes coderefs for arguments, got '$sub'"
        unless ref $sub && ref $sub eq 'CODE';

    push @{$self->{+_LISTENERS}} => { %params, code => $sub };

    $sub; # Intentional return.
}

sub unlisten {
    my $self = shift;

    carp "Useless removal of a listener in a child process or thread!"
        if $$ != $self->{+PID} || get_tid() != $self->{+TID};

    my %subs = map {$_ => $_} @_;

    @{$self->{+_LISTENERS}} = grep { !$subs{$_->{code}} } @{$self->{+_LISTENERS}};
}

sub filter {
    my $self = shift;
    my ($sub, %params) = @_;

    carp "Useless addition of a filter in a child process or thread!"
        if $$ != $self->{+PID} || get_tid() != $self->{+TID};

    croak "filter only takes coderefs for arguments, got '$sub'"
        unless ref $sub && ref $sub eq 'CODE';

    push @{$self->{+_FILTERS}} => { %params, code => $sub };

    $sub; # Intentional Return
}

sub unfilter {
    my $self = shift;
    carp "Useless removal of a filter in a child process or thread!"
        if $$ != $self->{+PID} || get_tid() != $self->{+TID};
    my %subs = map {$_ => $_} @_;
    @{$self->{+_FILTERS}} = grep { !$subs{$_->{code}} } @{$self->{+_FILTERS}};
}

sub pre_filter {
    my $self = shift;
    my ($sub, %params) = @_;

    croak "pre_filter only takes coderefs for arguments, got '$sub'"
        unless ref $sub && ref $sub eq 'CODE';

    push @{$self->{+_PRE_FILTERS}} => { %params, code => $sub };

    $sub; # Intentional Return
}

sub pre_unfilter {
    my $self = shift;
    my %subs = map {$_ => $_} @_;
    @{$self->{+_PRE_FILTERS}} = grep { !$subs{$_->{code}} } @{$self->{+_PRE_FILTERS}};
}

sub follow_up {
    my $self = shift;
    my ($sub) = @_;

    carp "Useless addition of a follow-up in a child process or thread!"
        if $$ != $self->{+PID} || get_tid() != $self->{+TID};

    croak "follow_up only takes coderefs for arguments, got '$sub'"
        unless ref $sub && ref $sub eq 'CODE';

    push @{$self->{+_FOLLOW_UPS}} => $sub;
}

*add_context_aquire = \&add_context_acquire;
sub add_context_acquire {
    my $self = shift;
    my ($sub) = @_;

    croak "add_context_acquire only takes coderefs for arguments, got '$sub'"
        unless ref $sub && ref $sub eq 'CODE';

    push @{$self->{+_CONTEXT_ACQUIRE}} => $sub;

    $sub; # Intentional return.
}

*remove_context_aquire = \&remove_context_acquire;
sub remove_context_acquire {
    my $self = shift;
    my %subs = map {$_ => $_} @_;
    @{$self->{+_CONTEXT_ACQUIRE}} = grep { !$subs{$_} == $_ } @{$self->{+_CONTEXT_ACQUIRE}};
}

sub add_context_init {
    my $self = shift;
    my ($sub) = @_;

    croak "add_context_init only takes coderefs for arguments, got '$sub'"
        unless ref $sub && ref $sub eq 'CODE';

    push @{$self->{+_CONTEXT_INIT}} => $sub;

    $sub; # Intentional return.
}

sub remove_context_init {
    my $self = shift;
    my %subs = map {$_ => $_} @_;
    @{$self->{+_CONTEXT_INIT}} = grep { !$subs{$_} == $_ } @{$self->{+_CONTEXT_INIT}};
}

sub add_context_release {
    my $self = shift;
    my ($sub) = @_;

    croak "add_context_release only takes coderefs for arguments, got '$sub'"
        unless ref $sub && ref $sub eq 'CODE';

    push @{$self->{+_CONTEXT_RELEASE}} => $sub;

    $sub; # Intentional return.
}

sub remove_context_release {
    my $self = shift;
    my %subs = map {$_ => $_} @_;
    @{$self->{+_CONTEXT_RELEASE}} = grep { !$subs{$_} == $_ } @{$self->{+_CONTEXT_RELEASE}};
}

sub send {
    my $self = shift;
    my ($e) = @_;

    if ($self->{+_PRE_FILTERS}) {
        for (@{$self->{+_PRE_FILTERS}}) {
            $e = $_->{code}->($self, $e);
            return unless $e;
        }
    }

    my $ipc = $self->{+IPC} || return $self->process($e);

    if($e->global) {
        $ipc->send($self->{+HID}, $e, 'GLOBAL');
        return $self->process($e);
    }

    return $ipc->send($self->{+HID}, $e)
        if $$ != $self->{+PID} || get_tid() != $self->{+TID};

    $self->process($e);
}

sub process {
    my $self = shift;
    my ($e) = @_;

    if ($self->{+_FILTERS}) {
        for (@{$self->{+_FILTERS}}) {
            $e = $_->{code}->($self, $e);
            return unless $e;
        }
    }

    my $type = ref($e);
    my $is_ok = $type eq 'Test2::Event::Ok';
    my $no_fail = $type eq 'Test2::Event::Diag' || $type eq 'Test2::Event::Note';
    my $causes_fail = $is_ok ? !$e->{effective_pass} : $no_fail ? 0 : $e->causes_fail;
    my $counted = $is_ok || (!$no_fail && $e->increments_count);

    $self->{+COUNT}++      if $counted;
    $self->{+FAILED}++     if $causes_fail && $counted;
    $self->{+_PASSING} = 0 if $causes_fail;

    my $callback = $e->callback($self) unless $is_ok || $no_fail;

    my $count = $self->{+COUNT};

    $self->{+_FORMATTER}->write($e, $count) if $self->{+_FORMATTER};

    if ($self->{+_LISTENERS}) {
        $_->{code}->($self, $e, $count) for @{$self->{+_LISTENERS}};
    }

    return $e if $is_ok || $no_fail;

    my $code = $e->terminate;
    if (defined $code) {
        $self->{+_FORMATTER}->terminate($e) if $self->{+_FORMATTER};
        $self->terminate($code, $e);
    }

    return $e;
}

sub terminate {
    my $self = shift;
    my ($code) = @_;
    exit($code);
}

sub cull {
    my $self = shift;

    my $ipc = $self->{+IPC} || return;
    return if $self->{+PID} != $$ || $self->{+TID} != get_tid();

    # No need to do IPC checks on culled events
    $self->process($_) for $ipc->cull($self->{+HID});
}

sub finalize {
    my $self = shift;
    my ($trace, $do_plan) = @_;

    $self->cull();

    my $plan   = $self->{+_PLAN};
    my $count  = $self->{+COUNT};
    my $failed = $self->{+FAILED};
    my $active = $self->{+ACTIVE};

	# return if NOTHING was done.
	unless ($active || $do_plan || defined($plan) || $count || $failed) {
		$self->{+_FORMATTER}->finalize($plan, $count, $failed, 0, $self->is_subtest) if $self->{+_FORMATTER};
		return;
	}

    unless ($self->{+ENDED}) {
        if ($self->{+_FOLLOW_UPS}) {
            $_->($trace, $self) for reverse @{$self->{+_FOLLOW_UPS}};
        }

        # These need to be refreshed now
        $plan   = $self->{+_PLAN};
        $count  = $self->{+COUNT};
        $failed = $self->{+FAILED};

        if (($plan && $plan eq 'NO PLAN') || ($do_plan && !$plan)) {
            $self->send(
                Test2::Event::Plan->new(
                    trace => $trace,
                    max => $count,
                )
            );
        }
        $plan = $self->{+_PLAN};
    }

    my $frame = $trace->frame;
    if($self->{+ENDED}) {
        my (undef, $ffile, $fline) = @{$self->{+ENDED}};
        my (undef, $sfile, $sline) = @$frame;

        die <<"        EOT"
Test already ended!
First End:  $ffile line $fline
Second End: $sfile line $sline
        EOT
    }

    $self->{+ENDED} = $frame;
    my $pass = $self->is_passing(); # Generate the final boolean.

	$self->{+_FORMATTER}->finalize($plan, $count, $failed, $pass, $self->is_subtest) if $self->{+_FORMATTER};

    return $pass;
}

sub is_passing {
    my $self = shift;

    ($self->{+_PASSING}) = @_ if @_;

    # If we already failed just return 0.
    my $pass = $self->{+_PASSING} or return 0;
    return $self->{+_PASSING} = 0 if $self->{+FAILED};

    my $count = $self->{+COUNT};
    my $ended = $self->{+ENDED};
    my $plan = $self->{+_PLAN};

    return $pass if !$count && $plan && $plan =~ m/^SKIP$/;

    return $self->{+_PASSING} = 0
        if $ended && (!$count || !$plan);

    return $pass unless $plan && $plan =~ m/^\d+$/;

    if ($ended) {
        return $self->{+_PASSING} = 0 if $count != $plan;
    }
    else {
        return $self->{+_PASSING} = 0 if $count > $plan;
    }

    return $pass;
}

sub plan {
    my $self = shift;

    return $self->{+_PLAN} unless @_;

    my ($plan) = @_;

    confess "You cannot unset the plan"
        unless defined $plan;

    confess "You cannot change the plan"
        if $self->{+_PLAN} && $self->{+_PLAN} !~ m/^NO PLAN$/;

    confess "'$plan' is not a valid plan! Plan must be an integer greater than 0, 'NO PLAN', or 'SKIP'"
        unless $plan =~ m/^(\d+|NO PLAN|SKIP)$/;

    $self->{+_PLAN} = $plan;
}

sub check_plan {
    my $self = shift;

    return undef unless $self->{+ENDED};
    my $plan = $self->{+_PLAN} || return undef;

    return 1 if $plan !~ m/^\d+$/;

    return 1 if $plan == $self->{+COUNT};
    return 0;
}

sub DESTROY {
    my $self = shift;
    my $ipc = $self->{+IPC} || return;
    return unless $$ == $self->{+PID};
    return unless get_tid() == $self->{+TID};

    $ipc->drop_hub($self->{+HID});
}

1;

__END__

#line 829
