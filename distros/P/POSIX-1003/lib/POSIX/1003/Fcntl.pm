# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package POSIX::1003::Fcntl;
use vars '$VERSION';
$VERSION = '0.98';

use base 'POSIX::1003::Module';

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

our @IN_CORE  = qw/
fcntl
flock/;

my $fcntl;
our %fcntl;

BEGIN {
    $fcntl = fcntl_table;
    push @constants, keys %$fcntl;
    tie %fcntl,  'POSIX::1003::ReadOnlyTable', $fcntl;
}

use constant UNUSED => 0;

# We need to have these values, but get into a chicked-egg problem with
# the normal import() procedure.
use constant
 { F_DUPFD      => $fcntl->{F_DUPFD}
 , F_DUPFD_CLOEXEC => $fcntl->{F_DUPFD_CLOEXEC}
 , F_GETFD      => $fcntl->{F_GETFD}
 , F_GETFL      => $fcntl->{F_GETFL}
 , F_GETLCK     => $fcntl->{F_GETLCK}
 , F_GETLEASE   => $fcntl->{F_GETLEASE}
 , F_GETLK      => $fcntl->{F_GETLK}
 , F_GETLKW     => $fcntl->{F_GETLKW}
 , F_GETOWN     => $fcntl->{F_GETOWN}
 , F_GETOWN_EX  => $fcntl->{F_GETOWN_EX}
 , F_GETPIPE_SZ => $fcntl->{F_GETPIPE_SZ}
 , F_GETSIG     => $fcntl->{F_GETSIG}
 , F_NOTIFY     => $fcntl->{F_NOTIFY}
 , F_OWNER_PGRP => $fcntl->{F_OWNER_PGRP}
 , F_OWNER_PID  => $fcntl->{F_OWNER_PID}
 , F_RDLCK      => $fcntl->{F_RDLCK}
 , F_SETFD      => $fcntl->{F_SETFD}
 , F_SETFL      => $fcntl->{F_SETFL}
 , F_SETLEASE   => $fcntl->{F_SETLEASE}
 , F_SETLK      => $fcntl->{F_SETLK}
 , F_SETLKW     => $fcntl->{F_SETLKW}
 , F_SETOWN     => $fcntl->{F_SETOWN}
 , F_SETOWN_EX  => $fcntl->{F_SETOWN_EX}
 , F_SETPIPE_SZ => $fcntl->{F_SETPIPE_SZ}
 , F_SETSIG     => $fcntl->{F_SETSIG}
 , F_UNLCK      => $fcntl->{F_UNLCK}
 , F_WRLCK      => $fcntl->{F_WRLCK}
 };


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


sub fcntl_dup($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    my $func = $args{close_on_exec} ? F_DUPFD_CLOEXEC : F_DUPFD;

    return _fcntl $fd, F_DUPFD, UNUSED
        if !$args{close_on_exec};

    return _fcntl $fd, F_DUPFD_CLOEXEC, UNUSED
        if defined F_DUPFD_CLOEXEC;

    _fcntl $fd, F_DUPFD, UNUSED;
    setfd_control $fd, O_CLOEXEC;
}


sub getfd_control($)
{   my ($file) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_GETFD, UNUSED;
}


sub setfd_control($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_SETFD, $flags;
}


sub getfd_flags($)
{   my ($file) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_GETFL, UNUSED;
}


sub setfd_flags($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_SETFL, $flags;
}


sub setfd_lock($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    my $func = $args{wait} ? F_SETLK : F_SETLKW;
    $args{type}   //= F_RDLCK;
    $args{whence} //= SEEK_SET;
    $args{start}  //= 0;
    $args{len}    //= 0;
    _lock $fd, $func, \%args;
}


sub getfd_islocked($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    $args{type}   //= F_RDLCK;
    $args{whence} //= SEEK_SET;
    $args{start}  //= 0;
    $args{len}    //= 0;
    my $lock = _lock $fd, F_GETLK, \%args
       or return undef;

    #XXX MO: how to represent "ENOSYS"?
    $lock->{type}==F_UNLCK ? undef : $lock;
}


sub getfd_owner($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;

    my ($type, $pid) = _own_ex $fd, F_GETOWN_EX, UNUSED, UNUSED;
    unless(defined $type && $!==ENOSYS)
    {   $pid = _fcntl $fd, F_GETOWN, UNUSED;
        if($pid < 0)
        {   $pid  = -$pid;
            $type = F_OWNER_PGRP // 2;
        }
        else
        {   $type = F_OWNER_PID  // 1;
        }
    }

    wantarray ? ($type, $pid) : $pid;
}


sub setfd_owner($$%)
{   my ($file, $pid, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;

    my $type = $args{type}
            || ($pid < 0 ? (F_OWNER_PGRP//2) : (F_OWNER_PID//1));

    $pid     = -$pid if $pid < 0;

    my ($t, $p) = _own_ex $fd, F_SETOWN_EX, $pid, $type;
    unless($t && $!==ENOSYS)
    {   my $sig_pid = $type==(F_OWNER_PGRP//2) ? -$pid : $pid;
        ($t, $p) = _fcntl $fd, F_SETOWN, $pid;
    }

    defined $t;
}


sub setfd_signal($$)
{   my ($file, $signal) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_SETSIG, $signal;
}


sub getfd_signal($)
{   my $file = shift;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_SETSIG, UNUSED;
}


sub setfd_lease($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_SETLEASE, $flags;
}


sub getfd_lease($)
{   my $file = shift;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_GETLEASE, UNUSED;
}



sub setfd_notify($$)
{   my ($dir, $flags) = @_;
    my $fd   = ref $dir ? fileno($dir) : $dir;
    _fcntl $fd, F_NOTIFY, $flags;
}


sub setfd_pipe_size($$)
{   my ($file, $size) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_SETPIPE_SZ, $size;
}


sub getfd_pipe_size($)
{   my $file = shift;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_GETPIPE_SZ, UNUSED;
}


sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $fcntl->{$name};
    sub() {$val};
}

1;
