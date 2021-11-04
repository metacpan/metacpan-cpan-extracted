#+##############################################################################
#                                                                              #
# File: No/Worries/Stat.pm                                                     #
#                                                                              #
# Description: stat() handling without worries                                 #
#                                                                              #
#-##############################################################################

#
# module definition
#

package No::Worries::Stat;
use strict;
use warnings;
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Fcntl qw(:mode);
use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use Params::Validate qw(validate :types);

#
# constants
#

use constant ST_DEV     =>  0;     # ID of device containing file
use constant ST_INO     =>  1;     # inode number
use constant ST_MODE    =>  2;     # protection
use constant ST_NLINK   =>  3;     # number of hard links
use constant ST_UID     =>  4;     # user ID of owner
use constant ST_GID     =>  5;     # group ID of owner
use constant ST_RDEV    =>  6;     # device ID (if special file)
use constant ST_SIZE    =>  7;     # total size, in bytes
use constant ST_ATIME   =>  8;     # time of last access
use constant ST_MTIME   =>  9;     # time of last modification
use constant ST_CTIME   => 10;     # time of last status change
use constant ST_BLKSIZE => 11;     # blocksize for filesystem I/O
use constant ST_BLOCKS  => 12;     # number of 512B blocks allocated

use constant _IMODE => oct(7777);  # all mode bits
use constant _IBITS => 12;         # number of mode bits

#
# global variables
#

our(
    @_Mode2Type,  # mode (shifted) to file type
    %_CachedUid,  # cached uid from getpwnam()
    %_CachedGid,  # cached gid from getgrnam()
);

#
# check user option and set uid and message accordingly
#

sub _check_user ($$) {
    my($option, $message) = @_;
    my($user);

    $user = $option->{user};
    return unless defined($user);
    if ($user =~ /^\d+$/) {
        $option->{uid} = $user;
    } else {
        unless (exists($_CachedUid{$user})) {
            $_CachedUid{$user} = getpwnam($user);
            dief("unknown user: %s", $user)
                unless defined($_CachedUid{$user});
        }
        $option->{uid} = $_CachedUid{$user};
    }
    $message->{user} = "user($user)";
}

#
# check group option and set gid and message accordingly
#

sub _check_group ($$) {
    my($option, $message) = @_;
    my($group);

    $group = $option->{group};
    return unless defined($group);
    if ($group =~ /^\d+$/) {
        $option->{gid} = $group;
    } else {
        unless (exists($_CachedGid{$group})) {
            $_CachedGid{$group} = getgrnam($group);
            dief("unknown group: %s", $group)
                unless defined($_CachedGid{$group});
        }
        $option->{gid} = $_CachedGid{$group};
    }
    $message->{group} = "group($group)";
}

#
# check the mode option and set mode_set, mode_clear and message accordingly
#

sub _check_mode ($$) {
    my($option, $message) = @_;
    my($mode, $action, $number);

    $mode = $option->{mode};
    return unless defined($mode);
    if ($mode =~ /^([\+\-])?(\d+)$/) {
        $action = $1 || "";
        $number = substr($2, 0, 1) eq "0" ? oct($2) : ($2+0);
        # use the canonical form for the message
        $mode = sprintf("%s%05o", $action, $number);
        if ($action eq "+") {
            # check that at least these bits are set
            $option->{mode_set} = $number;
            $option->{mode_clear} = 0;
        } elsif ($action eq "-") {
            # check that at least these bits are cleared
            $option->{mode_set} = 0;
            $option->{mode_clear} = $number;
        } else {
            # check that these bits are exactly the ones set
            $option->{mode_set} = $number;
            $option->{mode_clear} = _IMODE;
        }
    } else {
        dief("invalid mode: %s", $mode);
    }
    $message->{mode} = "mode($mode)";
}

#
# check the mtime option and set message accordingly
#

sub _check_mtime ($$) {
    my($option, $message) = @_;
    my($mtime);

    $mtime = $option->{mtime};
    return unless defined($mtime);
    $message->{mtime} = "mtime($mtime)";
}

#
# ensure proper ownership
#

sub _ensure_owner ($$$$) {
    my($path, $stat, $option, $message) = @_;
    my(@todo);

    @todo = ();
    if ($message->{user} and $stat->[ST_UID] != $option->{uid}) {
        $stat->[ST_UID] = $option->{uid};
        push(@todo, $message->{user});
    }
    if ($message->{group} and $stat->[ST_GID] != $option->{gid}) {
        $stat->[ST_GID] = $option->{gid};
        push(@todo, $message->{group});
    }
    return(0) unless @todo and $option->{callback}->($path, "@todo");
    chown($stat->[ST_UID], $stat->[ST_GID], $path)
        or dief("cannot chown(%d, %d, %s): %s",
                $stat->[ST_UID], $stat->[ST_GID], $path, $!);
    return(1)
}

#
# ensure proper permissions
#

sub _ensure_mode ($$$$) {
    my($path, $stat, $option, $message) = @_;
    my($mode);

    $mode = $stat->[ST_MODE] & _IMODE;
    $mode &= ~$option->{mode_clear};
    $mode |=  $option->{mode_set};
    return(0) if ($stat->[ST_MODE] & _IMODE) == $mode;
    return(0) unless $option->{callback}->($path, $message->{mode});
    chmod($mode, $path)
        or dief("cannot chmod(%05o, %s): %s", $mode, $path, $!);
    return(1)
}

#
# ensure proper modification time
#

sub _ensure_mtime ($$$$) {
    my($path, $stat, $option, $message) = @_;

    return(0) if $stat->[ST_MTIME] == $option->{mtime};
    return(0) unless $option->{callback}->($path, $message->{mtime});
    utime($stat->[ST_ATIME], $option->{mtime}, $path)
        or dief("cannot utime(%d, %d, %s): %s",
                $stat->[ST_ATIME], $option->{mtime}, $path, $!);
    return(1);
}

#
# make sure the the file status is what is expected
#

my %stat_ensure_options = (
    user     => { optional => 1, type => SCALAR, regex => qr/^[\w\-]+$/ },
    group    => { optional => 1, type => SCALAR, regex => qr/^[\w\-]+$/ },
    mode     => { optional => 1, type => SCALAR, regex => qr/^[\+\-]?\d+$/ },
    mtime    => { optional => 1, type => SCALAR, regex => qr/^\d+$/ },
    follow   => { optional => 1, type => BOOLEAN },
    callback => { optional => 1, type => CODEREF },
);

sub stat_ensure ($@) {
    my($path, %option, %message, @stat, $changed);

    $path = shift(@_);
    %option = validate(@_, \%stat_ensure_options) if @_;
    _check_user(\%option, \%message);
    _check_group(\%option, \%message);
    _check_mode(\%option, \%message);
    _check_mtime(\%option, \%message);
    $option{callback} ||= sub { return(1) };
    dief("no options given") unless keys(%message);
    if ($option{follow}) {
        @stat = stat($path);
        dief("cannot stat(%s): %s", $path, $!) unless @stat;
    } else {
        @stat = lstat($path);
        dief("cannot lstat(%s): %s", $path, $!) unless @stat;
        # we do not try to change symbolic links
        return(undef) if -l _;
    }
    $changed = 0;
    # first ensure owner
    $changed += _ensure_owner($path, \@stat, \%option, \%message)
        if $message{user} or $message{group};
    # then ensure mode
    $changed += _ensure_mode($path, \@stat, \%option, \%message)
        if $message{mode};
    # finally ensure mtime
    $changed += _ensure_mtime($path, \@stat, \%option, \%message)
        if $message{mtime};
    return($changed);
}

#
# return the file type as a string from stat[ST_MODE]
#

sub stat_type ($) {
    my($mode) = @_;

    unless (@_Mode2Type) {
        eval { $_Mode2Type[S_IFREG()  >> _IBITS] = "plain file" };
        eval { $_Mode2Type[S_IFDIR()  >> _IBITS] = "directory" };
        eval { $_Mode2Type[S_IFIFO()  >> _IBITS] = "pipe" };
        eval { $_Mode2Type[S_IFSOCK() >> _IBITS] = "socket" };
        eval { $_Mode2Type[S_IFBLK()  >> _IBITS] = "block device" };
        eval { $_Mode2Type[S_IFCHR()  >> _IBITS] = "character device" };
        eval { $_Mode2Type[S_IFLNK()  >> _IBITS] = "symlink" };
        eval { $_Mode2Type[S_IFDOOR() >> _IBITS] = "door" };
        eval { $_Mode2Type[S_IFPORT() >> _IBITS] = "event port" };
        eval { $_Mode2Type[S_IFNWK()  >> _IBITS] = "network file" };
        eval { $_Mode2Type[S_IFWHT()  >> _IBITS] = "whiteout" };
    }
    $mode &= S_IFMT;
    $mode >>= _IBITS;
    return($_Mode2Type[$mode] || "unknown");
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, grep(/^ST?_[A-Z]+$/, keys(%No::Worries::Stat::)));
    grep($exported{$_}++, qw(stat_ensure stat_type));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__DATA__

=head1 NAME

No::Worries::Stat - stat() handling without worries

=head1 SYNOPSIS

  use No::Worries::Stat qw(*);

  @stat = stat($path) or die;
  printf("type is %s\n", stat_type($stat[ST_MODE]));
  printf("size is %d\n", $stat[ST_SIZE]);
  printf("user can read\n") if $stat[ST_MODE] & S_IRUSR;

  # make sure "/bin/ls" is owned by root and has the right permissions
  stat_ensure("/bin/ls", user => "root", mode => 0755);
  # make sure "/var/log" is not group or world writable
  stat_ensure("/var/log", mode => "-022");
  # idem but using the S_* constants
  stat_ensure("/var/log", mode => "-" . (S_IWGRP|S_IWOTH));

=head1 DESCRIPTION

This module eases file status handling by providing convenient constants and
functions to get, set and manipulate file status information. All the
functions die() on error.

=head1 CONSTANTS

This module provides the following constants to ease access to stat() fields
(none of them being exported by default):

=over

=item C<ST_DEV>

ID of device containing file

=item C<ST_INO>

inode number

=item C<ST_MODE>

protection

=item C<ST_NLINK>

number of hard links

=item C<ST_UID>

user ID of owner

=item C<ST_GID>

group ID of owner

=item C<ST_RDEV>

device ID (if special file)

=item C<ST_SIZE>

total size, in bytes

=item C<ST_ATIME>

time of last access

=item C<ST_MTIME>

time of last modification

=item C<ST_CTIME>

time of last status change

=item C<ST_BLKSIZE>

blocksize for filesystem I/O

=item C<ST_BLOCKS>

number of 512B blocks allocated

=back

In addition, it also optionally exports all the ":mode" constants from L<Fcntl>.

This way, all the stat() related constants can be imported in a uniform way.

=head1 FUNCTIONS

This module provides the following functions (none of them being
exported by default):

=over

=item stat_type(MODE)

given the file mode (C<ST_MODE> field), return the file type as a string;
possible return values are: "block device", "character device", "directory",
"door", "event port", "network file", "pipe", "plain file", "socket",
"symlink", "unknown" and "whiteout".

=item stat_ensure(PATH[, OPTIONS])

make sure the given path has the expected file "status" (w.r.t. stat()) and
call chown(), chmod() or utime() if needed, returning the number of changes
performed; supported options:

=over

=item * C<user>: expected user name or uid

=item * C<group>: expected group name or gid

=item * C<mode>: expected mode specification (see below)

=item * C<mtime>: expected modification time

=item * C<follow>: follow symbolic links (default is to skip them)

=item * C<callback>: code to be executed before changing something (see below)

=back

=back

The C<mode> option of stat_ensure() can be given:

=over

=item I<NUMBER>

an absolute value like 0755, meaning that mode must be equal to it

=item +I<NUMBER>

a list of bits that must be set, e.g. "+0111" for "executable for all"

=item -I<NUMBER>

a list of bits that must be clear, e.g. "-022" for not writable by group or
other

=back

Note: the number after "+" or "-" will be interpreted as being octal only if
it starts with "0". You should therefore use "+0111" or "+".oct(111) to
enable the executable bits but not "+111" which is the same as "+0157".

The C<callback> option of stat_ensure() will receive the given path and a
string describing what is about to be changed. It must return true to tell
stat_ensure() to indeed perform the changes.

Here is for insatnce how a "noaction" option could be implemented:

  sub noaction ($$) {
      my($path, $change) = @_;
  
      printf("did not change %s of %s\n", $change, $path);
      return(0);
  }
  foreach my $path (@paths) {
      stat_ensure($path, user => "root", mode => 0755, callback => \&noaction);
  }

=head1 SEE ALSO

L<Fcntl>,
L<No::Worries>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2012-2019
