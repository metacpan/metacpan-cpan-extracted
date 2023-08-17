###############################################################################
## ----------------------------------------------------------------------------
## Mutex::Channel - Mutex locking via a pipe or socket.
##
###############################################################################

package Mutex::Channel;

use strict;
use warnings;

no warnings qw( threads recursion uninitialized once );

our $VERSION = '1.009';

use if $^O eq 'MSWin32', 'threads';
use if $^O eq 'MSWin32', 'threads::shared';

use base 'Mutex';
use Mutex::Util;
use Scalar::Util 'looks_like_number';
use Time::HiRes 'alarm';

my $is_MSWin32 = ($^O eq 'MSWin32') ? 1 : 0;
my $use_pipe = ($^O !~ /mswin|mingw|msys|cygwin/i && $] gt '5.010000');
my $tid = $INC{'threads.pm'} ? threads->tid : 0;

sub CLONE {
    $tid = threads->tid if $INC{'threads.pm'};
}

sub DESTROY {
    my ($pid, $obj) = ($tid ? $$ .'.'. $tid : $$, @_);

    CORE::syswrite($obj->{_w_sock}, '0'), $obj->{ $pid } = 0 if $obj->{ $pid };

    if ( $obj->{_init_pid} eq $pid ) {
        $use_pipe
            ? Mutex::Util::destroy_pipes($obj, qw(_w_sock _r_sock))
            : Mutex::Util::destroy_socks($obj, qw(_w_sock _r_sock));
    }

    return;
}

###############################################################################
## ----------------------------------------------------------------------------
## Public methods.
##
###############################################################################

sub new {
    my ($class, %obj) = (@_, impl => 'Channel');
    $obj{_init_pid} = $tid ? $$ .'.'. $tid : $$;
    $obj{_t_lock} = threads::shared::share( my $t_lock ) if $is_MSWin32;

    $use_pipe
        ? Mutex::Util::pipe_pair(\%obj, qw(_r_sock _w_sock))
        : Mutex::Util::sock_pair(\%obj, qw(_r_sock _w_sock));

    CORE::syswrite($obj{_w_sock}, '0');

    return bless(\%obj, $class);
}

sub lock {
    my ($pid, $obj) = ($tid ? $$ .'.'. $tid : $$, shift);

    CORE::lock($obj->{_t_lock}), Mutex::Util::_sock_ready($obj->{_r_sock})
        if $is_MSWin32;
    Mutex::Util::_sysread($obj->{_r_sock}, my($b), 1), $obj->{ $pid } = 1
        unless $obj->{ $pid };

    return;
}

*lock_exclusive = \&lock;
*lock_shared    = \&lock;

sub unlock {
    my ($pid, $obj) = ($tid ? $$ .'.'. $tid : $$, shift);

    CORE::syswrite($obj->{_w_sock}, '0'), $obj->{ $pid } = 0
        if $obj->{ $pid };

    return;
}

sub synchronize {
    my ($pid, $obj, $code) = ($tid ? $$ .'.'. $tid : $$, shift, shift);
    my (@ret, $b);

    return unless ref($code) eq 'CODE';

    # lock, run, unlock - inlined for performance
    CORE::lock($obj->{_t_lock}), Mutex::Util::_sock_ready($obj->{_r_sock})
        if $is_MSWin32;
    Mutex::Util::_sysread($obj->{_r_sock}, $b, 1), $obj->{ $pid } = 1
        unless $obj->{ $pid };

    (defined wantarray)
        ? @ret = wantarray ? $code->(@_) : scalar $code->(@_)
        : $code->(@_);

    CORE::syswrite($obj->{_w_sock}, '0'), $obj->{ $pid } = 0;

    return wantarray ? @ret : $ret[-1];
}

*enter = \&synchronize;

sub timedwait {
    my ($obj, $timeout) = @_;

    $timeout = 1 unless defined $timeout;
    Carp::croak('Mutex::Channel: timedwait (timeout) is not valid')
        if (!looks_like_number($timeout) || $timeout < 0);

    $timeout = 0.0003 if $timeout < 0.0003;
    local $@; my $ret = '';

    eval {
        local $SIG{ALRM} = sub { alarm 0; die "alarm clock restart\n" };
        alarm $timeout unless $is_MSWin32;

        die "alarm clock restart\n"
            if $is_MSWin32 && Mutex::Util::_sock_ready($obj->{_r_sock}, $timeout);

        (!$is_MSWin32)
            ? ($obj->lock_exclusive, $ret = 1, alarm(0))
            : ($obj->lock_exclusive, $ret = 1);
    };

    alarm 0 unless $is_MSWin32;

    $ret;
}

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=head1 NAME

Mutex::Channel - Mutex locking via a pipe or socket

=head1 VERSION

This document describes Mutex::Channel version 1.009

=head1 DESCRIPTION

A pipe-socket implementation for C<Mutex>.

The API is described in L<Mutex>.

=over 3

=item new

=item lock

=item lock_exclusive

=item lock_shared

=item unlock

=item synchronize

=item enter

=item timedwait

=back

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut

