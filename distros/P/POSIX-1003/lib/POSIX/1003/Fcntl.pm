# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Fcntl;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

use POSIX::1003::FdIO   qw/SEEK_SET O_CLOEXEC/;
use POSIX::1003::Errno  qw/ENOSYS/;

my @constants;
my @functions = qw/fcntl
fcntl_dup
getfd_control
setfd_control
getfd_flags
setfd_flags
setfd_lock
getfd_islocked
getfd_owner
setfd_owner
setfd_signal
getfd_signal
setfd_lease
getfd_lease
setfd_notify
setfd_pipe_size
getfd_pipe_size

flock
flockfd

lockf
/;

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 , flock     => [ qw/flock flockfd LOCK_SH LOCK_EX LOCK_UN LOCK_NB/ ] 
 , lockf     => [ qw/lockf F_LOCK F_TLOCK F_ULOCK F_TEST/ ]
 , tables    => [ qw/%fcntl/ ]
 );

our @IN_CORE  = qw/fcntl flock/;

my $fcntl;

# We need to address all of our own constants via this HASH, because
# they will not be available at compile-time of this file.
our %fcntl;

BEGIN {
    $fcntl = fcntl_table;
    push @constants, keys %$fcntl;
    tie %fcntl,  'POSIX::1003::ReadOnlyTable', $fcntl;
}

# required parameter which does not get used by the OS.
use constant UNUSED => 0;


sub flockfd($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _flock($fd, $flags);
}


sub lockf($$;$)
{   my ($file, $flags, $len) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _lockf($fd, $flags, $len//0);
}

#---------------


sub fcntl_dup($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    my $func = $args{close_on_exec} ? $fcntl->{F_DUPFD_CLOEXEC} : $fcntl->{F_DUPFD};

    return _fcntl $fd, $fcntl->{F_DUPFD}, UNUSED
        if !$args{close_on_exec};

    return _fcntl $fd, $fcntl->{F_DUPFD_CLOEXEC}, UNUSED
        if defined $fcntl->{F_DUPFD_CLOEXEC};

    _fcntl $fd, $fcntl->{F_DUPFD}, UNUSED;
    setfd_control $fd, O_CLOEXEC;
}


sub getfd_control($)
{   my ($file) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_GETFD}, UNUSED;
}



sub setfd_control($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_SETFD}, $flags;
}



sub getfd_flags($)
{   my ($file) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_GETFL}, UNUSED;
}


sub setfd_flags($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_SETFL}, $flags;
}



sub setfd_lock($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;

    my $func;
    $func   = $args{wait} ? $fcntl->{F_SETLKP} : $fcntl->{F_SETLKWP}
        if $args{private};

    $func //= $args{wait} ? $fcntl->{F_SETLK}  : $fcntl->{F_SETLKW};

    $args{type}   //= $fcntl->{F_RDLCK};
    $args{whence} //= SEEK_SET;
    $args{start}  //= 0;
    $args{len}    //= 0;
    _lock $fd, $func, \%args;
}



sub getfd_islocked($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    $args{type}   //= $fcntl->{F_RDLCK};
    $args{whence} //= SEEK_SET;
    $args{start}  //= 0;
    $args{len}    //= 0;

    my $func = $args{private} ? ($fcntl->{F_GETLKW}//$fcntl->{F_GETLK}) : $fcntl->{F_GETLK};
    my $lock = _lock $fd, $func, \%args
       or return undef;

    #XXX MO: how to represent "ENOSYS"?
    $lock->{type}==$fcntl->{F_UNLCK} ? undef : $lock;
}



sub getfd_owner($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;

    my ($type, $pid) = _own_ex $fd, $fcntl->{F_GETOWN_EX}, UNUSED, UNUSED;
    unless(defined $type && $!==ENOSYS)
    {   $pid = _fcntl $fd, $fcntl->{F_GETOWN}, UNUSED;
        if($pid < 0)
        {   $pid  = -$pid;
            $type = $fcntl->{F_OWNER_PGRP} // 2;
        }
        else
        {   $type = $fcntl->{F_OWNER_PID}  // 1;
        }
    }

    wantarray ? ($type, $pid) : $pid;
}



sub setfd_owner($$%)
{   my ($file, $pid, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;

    my $type = $args{type}
       || ($pid < 0 ? ($fcntl->{F_OWNER_PGRP}//2) : ($fcntl->{F_OWNER_PID}//1));

    $pid     = -$pid if $pid < 0;

    my ($t, $p) = _own_ex $fd, $fcntl->{F_SETOWN_EX}, $pid, $type;
    unless($t && $!==ENOSYS)
    {   my $sig_pid = $type==($fcntl->{F_OWNER_PGRP}//2) ? -$pid : $pid;
        ($t, $p) = _fcntl $fd, $fcntl->{F_SETOWN}, $pid;
    }

    defined $t;
}


sub setfd_signal($$)
{   my ($file, $signal) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_SETSIG}, $signal;
}



sub getfd_signal($)
{   my $file = shift;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_SETSIG}, UNUSED;
}



sub setfd_lease($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_SETLEASE}, $flags;
}



sub getfd_lease($)
{   my $file = shift;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_GETLEASE}, UNUSED;
}



sub setfd_notify($$)
{   my ($dir, $flags) = @_;
    my $fd   = ref $dir ? fileno($dir) : $dir;
    _fcntl $fd, $fcntl->{F_NOTIFY}, $flags;
}



sub setfd_pipe_size($$)
{   my ($file, $size) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_SETPIPE_SZ}, $size;
}



sub getfd_pipe_size($)
{   my $file = shift;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_GETPIPE_SZ}, UNUSED;
}

#-----------------


sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $fcntl->{$name};
    sub() {$val};
}

1;
