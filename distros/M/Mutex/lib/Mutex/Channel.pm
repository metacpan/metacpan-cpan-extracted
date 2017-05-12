###############################################################################
## ----------------------------------------------------------------------------
## Mutex::Channel - Mutex locking via a pipe or socket.
##
###############################################################################

package Mutex::Channel;

use strict;
use warnings;

no warnings qw( threads recursion uninitialized once );

our $VERSION = '1.004';

use base 'Mutex';
use Mutex::Util ();

my $has_threads = $INC{'threads.pm'} ? 1 : 0;
my $tid = $has_threads ? threads->tid()  : 0;

sub CLONE {
    $tid = threads->tid() if $has_threads;
}

sub DESTROY {
    my ($pid, $obj) = ($has_threads ? $$ .'.'. $tid : $$, @_);

    syswrite($obj->{_w_sock}, '0'), $obj->{ $pid } = 0 if $obj->{ $pid };

    if ($obj->{'_init_pid'} eq $pid) {
        ($^O eq 'MSWin32')
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
    $obj{'_init_pid'} = $has_threads ? $$ .'.'. $tid : $$;

    ($^O eq 'MSWin32')
        ? Mutex::Util::pipe_pair(\%obj, qw(_r_sock _w_sock))
        : Mutex::Util::sock_pair(\%obj, qw(_r_sock _w_sock));

    1 until syswrite($obj{_w_sock}, '0') || ($! && !$!{'EINTR'});

    return bless(\%obj, $class);
}

sub lock {
    my ($pid, $obj) = ($has_threads ? $$ .'.'. $tid : $$, @_);

    sysread($obj->{_r_sock}, my($b), 1), $obj->{ $pid } = 1
        unless $obj->{ $pid };

    return;
}

*lock_exclusive = \&lock;
*lock_shared    = \&lock;

sub unlock {
    my ($pid, $obj) = ($has_threads ? $$ .'.'. $tid : $$, @_);

    syswrite($obj->{_w_sock}, '0'), $obj->{ $pid } = 0
        if $obj->{ $pid };

    return;
}

sub synchronize {
    my ($pid, $obj, $code, @ret) = (
        $has_threads ? $$ .'.'. $tid : $$, shift, shift
    );
    return unless ref($code) eq 'CODE';

    # lock, run, unlock - inlined for performance
    sysread($obj->{_r_sock}, my($b), 1), $obj->{ $pid } = 1
        unless $obj->{ $pid };

    (defined wantarray) ? @ret = $code->(@_) : $code->(@_);
    syswrite($obj->{_w_sock}, '0'), $obj->{ $pid } = 0;

    return wantarray ? @ret : $ret[-1];
}

*enter = \&synchronize;

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

This document describes Mutex::Channel version 1.004

=head1 DESCRIPTION

A pipe-socket implementation for L<Mutex>. See documentation there.

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut

