###############################################################################
## ----------------------------------------------------------------------------
## Utility functions for Mutex.
##
###############################################################################

package Mutex::Util;

use strict;
use warnings;

no warnings qw( threads recursion uninitialized );

our $VERSION = '1.007';

## no critic (BuiltinFunctions::ProhibitStringyEval)

use IO::Handle ();
use Socket qw( AF_UNIX );
use Errno ();

my ($is_winenv, $zero_bytes, %sock_ready);

BEGIN {
    $is_winenv = ( $^O =~ /mswin|mingw|msys|cygwin/i ) ? 1 : 0;
    $zero_bytes = "\x00\x00\x00\x00";
}

sub CLONE {
    %sock_ready = ();
}

###############################################################################
## ----------------------------------------------------------------------------
## Public functions.
##
###############################################################################

sub destroy_pipes {
    my ($obj, @params) = @_;
    local ($!,$?); local $SIG{__DIE__};

    for my $p (@params) {
        next unless (defined $obj->{$p});

        if (ref $obj->{$p} eq 'ARRAY') {
            for my $i (0 .. @{ $obj->{$p} } - 1) {
                next unless (defined $obj->{$p}[$i]);
                close $obj->{$p}[$i] if (fileno $obj->{$p}[$i]);
                undef $obj->{$p}[$i];
            }
        }
        else {
            close $obj->{$p} if (fileno $obj->{$p});
            undef $obj->{$p};
        }
    }

    return;
}

sub destroy_socks {
    my ($obj, @params) = @_;
    local ($!,$?,$@); local $SIG{__DIE__};

    for my $p (@params) {
        next unless (defined $obj->{$p});

        if (ref $obj->{$p} eq 'ARRAY') {
            for my $i (0 .. @{ $obj->{$p} } - 1) {
                next unless (defined $obj->{$p}[$i]);
                if (fileno $obj->{$p}[$i]) {
                    syswrite($obj->{$p}[$i], '0') if $is_winenv;
                    eval q{ CORE::shutdown($obj->{$p}[$i], 2) };
                    close $obj->{$p}[$i];
                }
                undef $obj->{$p}[$i];
            }
        }
        else {
            if (fileno $obj->{$p}) {
                syswrite($obj->{$p}, '0') if $is_winenv;
                eval q{ CORE::shutdown($obj->{$p}, 2) };
                close $obj->{$p};
            }
            undef $obj->{$p};
        }
    }

    return;
}

sub pipe_pair {
    my ($obj, $r_sock, $w_sock, $i) = @_;
    local $!;

    if (defined $i) {
        # remove tainted'ness
        ($i) = $i =~ /(.*)/;
        pipe($obj->{$r_sock}[$i], $obj->{$w_sock}[$i]) or die "pipe: $!\n";
        $obj->{$w_sock}[$i]->autoflush(1);
    }
    else {
        pipe($obj->{$r_sock}, $obj->{$w_sock}) or die "pipe: $!\n";
        $obj->{$w_sock}->autoflush(1);
    }

    return;
}

sub sock_pair {
    my ($obj, $r_sock, $w_sock, $i) = @_;
    local $!;

    if (defined $i) {
        # remove tainted'ness
        ($i) = $i =~ /(.*)/;
        socketpair( $obj->{$r_sock}[$i], $obj->{$w_sock}[$i],
            AF_UNIX, Socket::SOCK_STREAM(), 0 ) or die "socketpair: $!\n";
        $obj->{$r_sock}[$i]->autoflush(1);
        $obj->{$w_sock}[$i]->autoflush(1);
    }
    else {
        socketpair( $obj->{$r_sock}, $obj->{$w_sock},
            AF_UNIX, Socket::SOCK_STREAM(), 0 ) or die "socketpair: $!\n";
        $obj->{$r_sock}->autoflush(1);
        $obj->{$w_sock}->autoflush(1);
    }

    return;
}

sub _sock_ready {
   my ($socket, $timeout) = @_;
   return '' if !defined $timeout && $sock_ready{"$socket"} > 1;

   my ($delay, $val_bytes, $start) = (0, "\x00\x00\x00\x00", time);
   my $ptr_bytes = unpack('I', pack('P', $val_bytes));

   if (!defined $timeout) {
      $sock_ready{"$socket"}++;
   }
   else {
      $timeout = undef   if $timeout < 0;
      $timeout += $start if $timeout;
   }

   while (1) {
      # MSWin32 FIONREAD - from winsock2.h macro
      ioctl($socket, 0x4004667f, $ptr_bytes);

      return '' if $val_bytes ne $zero_bytes;
      return  1 if $timeout && time > $timeout;

      # delay after a while to not consume a CPU core
      sleep(0.015), next if $delay;
      $delay = 1 if time - $start > 0.015;
   }
}

sub _sysread {
    ( @_ == 3
        ? CORE::sysread($_[0], $_[1], $_[2])
        : CORE::sysread($_[0], $_[1], $_[2], $_[3])
    )
    or do {
        goto \&_sysread if ($! == Errno::EINTR());
    };
}

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=head1 NAME

Mutex::Util - Utility functions for Mutex

=head1 VERSION

This document describes Mutex::Util version 1.007

=head1 SYNOPSIS

   # Mutex::Util functions are beneficial inside a class.

   package Foo::Bar;

   use strict;
   use warnings;

   our $VERSION = '0.002';

   use Mutex::Util;

   my $has_threads = $INC{'threads.pm'} ? 1 : 0;
   my $tid = $has_threads ? threads->tid : 0;

   sub CLONE {
       $tid = threads->tid if $has_threads;
   }

   sub new {
       my ($class, %obj) = @_;
       $obj{init_pid} = $has_threads ? "$$.$tid" : $$;

       ($^O eq 'MSWin32')
           ? Mutex::Util::sock_pair(\%obj, qw(_r_sock _w_sock))
           : Mutex::Util::pipe_pair(\%obj, qw(_r_sock _w_sock));

       ...

       return bless \%obj, $class;
   }

   sub DESTROY {
       my ($pid, $obj) = ($has_threads ? "$$.$tid" : $$, @_);

       if ($obj->{init_pid} eq $pid) {
           ($^O eq 'MSWin32')
               ? Mutex::Util::destroy_socks($obj, qw(_w_sock _r_sock))
               : Mutex::Util::destroy_pipes($obj, qw(_w_sock _r_sock));
       }

       return;
   }

   1;

=head1 DESCRIPTION

Useful functions for managing pipe and socket handles stored in a hashref.

=head1 API DOCUMENTATION

=head2 destroy_pipes ( hashref, list )

Destroy pipes in the hash for given key names.

   Mutex::Util::destroy_pipes($hashref, qw(_w_sock _r_sock));

=head2 destroy_socks ( hashref, list )

Destroy sockets in the hash for given key names.

   Mutex::Util::destroy_socks($hashref, qw(_w_sock _r_sock));

=head2 pipe_pair ( hashref, r_name, w_name [, idx ] )

Creates a pair of connected pipes and stores the handles into the hash
with given key names representing the two read-write handles. Optionally,
pipes may be constructed into an array stored inside the hash.

   Mutex::Util::pipe_pair($hashref, qw(_r_sock _w_sock));

   $hashref->{_r_sock};
   $hashref->{_w_sock};

   Mutex::Util::pipe_pair($hashref, qw(_r_sock _w_sock), $_) for 0..3;

   $hashref->{_r_sock}[0];
   $hashref->{_w_sock}[0];

=head2 sock_pair ( hashref, r_name, w_name [, idx ] )

Creates an unnamed pair of sockets and stores the handles into the hash
with given key names representing the two read-write handles. Optionally,
sockets may be constructed into an array stored inside the hash.

   Mutex::Util::sock_pair($hashref, qw(_r_sock _w_sock));

   $hashref->{_r_sock};
   $hashref->{_w_sock};

   Mutex::Util::sock_pair($hashref, qw(_r_sock _w_sock), $_) for 0..3;

   $hashref->{_r_sock}[0];
   $hashref->{_w_sock}[0];

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut

