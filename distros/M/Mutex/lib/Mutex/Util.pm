###############################################################################
## ----------------------------------------------------------------------------
## Utility functions for Mutex.
##
###############################################################################

package Mutex::Util;

use strict;
use warnings;

no warnings qw( threads recursion uninitialized );

our $VERSION = '1.004';

## no critic (BuiltinFunctions::ProhibitStringyEval)

use Socket qw( PF_UNIX PF_UNSPEC SOCK_STREAM );

my $is_winenv;

BEGIN {
    $is_winenv = ( $^O =~ /mswin|mingw|msys|cygwin/i ) ? 1 : 0;
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

        pipe($obj->{$r_sock}[$i], $obj->{$w_sock}[$i])
            or die "pipe: $!\n";

        # IO::Handle->autoflush not available in older Perl.
        select(( select($obj->{$w_sock}[$i]), $| = 1 )[0]);
    }
    else {
        pipe($obj->{$r_sock}, $obj->{$w_sock})
            or die "pipe: $!\n";

        select(( select($obj->{$w_sock}), $| = 1 )[0]); # Ditto.
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
            PF_UNIX, SOCK_STREAM, PF_UNSPEC ) or die "socketpair: $!\n";

        # IO::Handle->autoflush not available in older Perl.
        select(( select($obj->{$w_sock}[$i]), $| = 1 )[0]);
        select(( select($obj->{$r_sock}[$i]), $| = 1 )[0]);
    }
    else {
        socketpair( $obj->{$r_sock}, $obj->{$w_sock},
            PF_UNIX, SOCK_STREAM, PF_UNSPEC ) or die "socketpair: $!\n";

        select(( select($obj->{$w_sock}), $| = 1 )[0]); # Ditto.
        select(( select($obj->{$r_sock}), $| = 1 )[0]);
    }

    return;
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

This document describes Mutex::Util version 1.004

=head1 SYNOPSIS

   # Mutex::Util functions are beneficial inside a class.

   package Foo::Bar;

   use strict;
   use warnings;

   our $VERSION = '0.001';

   use Mutex::Util;

   my $has_threads = $INC{'threads.pm'} ? 1 : 0;
   my $tid = $has_threads ? threads->tid() : 0;

   sub CLONE {
       $tid = threads->tid() if $has_threads;
   }

   sub new {
       my ($class, %obj) = @_;
       $obj{_init_pid} = $has_threads ? $$ .'.'. $tid : $$;

       ($^O eq 'MSWin32')
           ? Mutex::Util::pipe_pair(\%obj, qw(_r_sock _w_sock))
           : Mutex::Util::sock_pair(\%obj, qw(_r_sock _w_sock));

       ...

       return bless \%obj, $class;
   }

   sub DESTROY {
       my ($pid, $obj) = ($has_threads ? $$ .'.'. $tid : $$, @_);

       if ($obj->{_init_pid} eq $pid) {
           ($^O eq 'MSWin32')
               ? Mutex::Util::destroy_pipes($obj, qw(_w_sock _r_sock))
               : Mutex::Util::destroy_socks($obj, qw(_w_sock _r_sock));
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

