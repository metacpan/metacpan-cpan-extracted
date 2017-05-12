package Privileges::Drop;
use strict;
use warnings;
use English qw( -no_match_vars );
use Carp;

our $VERSION = '1.03';

=head1 NAME

Privileges::Drop - A module to make it simple to drop all privileges, even 
POSIX groups.

=head1 DESCRIPTION

This module tries to simplify the process of dropping privileges. This can be
useful when your Perl program needs to bind to privileged ports, etc. This
module is much like Proc::UID, except that it's implemented in pure Perl.
Special care has been taken to also drop saved uid on platforms that support
this, currently only test on on Linux.

=head1 SYNOPSIS
  
  use Privileges::Drop;

  # Do privileged stuff

  # Drops privileges and sets euid/uid to 1000 and egid/gid to 1000.
  drop_uidgid(1000, 1000);

  # Drop privileges to user nobody looking up gid and uid with getpwname
  # This also set the enviroment variables USER, LOGNAME, HOME and SHELL. 
  drop_privileges('nobody');

=head1 METHODS

=over

=cut

use base "Exporter";

our @EXPORT = qw(drop_privileges drop_uidgid);

=item drop_uidgid($uid, $gid, @groups)

Drops privileges and sets euid/uid to $uid and egid/gid to $gid.

Supplementary groups can be set in @groups.

=cut

sub drop_uidgid {
    my ($uid, $gid, @reqPosixGroups) = @_;
    
    # Sort the groups and make sure they are uniq
    my %groupHash = map { $_ => 1 } ($gid, @reqPosixGroups);
    my $newgid ="$gid ".join(" ", sort { $a <=> $b } (keys %groupHash));

    # Description from:
    # http://www.mail-archive.com/perl5-changes@perl.org/msg02683.html
    #
    # According to Stevens' APUE and various
    # (BSD, Solaris, HP-UX) man pages setting
    # the real uid first and effective uid second
    # is the way to go if one wants to drop privileges,
    # because if one changes into an effective uid of
    # non-zero, one cannot change the real uid any more.
    #
    # Actually, it gets even messier.  There is
    # a third uid, called the saved uid, and as
    # long as that is zero, one can get back to
    # uid of zero.  Setting the real-effective *twice*
    # helps in *most* systems (FreeBSD and Solaris)
    # but apparently in HP-UX even this doesn't help:
    # the saved uid stays zero (apparently the only way
    # in HP-UX to change saved uid is to call setuid()
    # when the effective uid is zero).

    # Drop privileges to $uid and $gid for both effective and saved uid/gid
    ($GID) = split /\s/, $newgid;
    $EGID = $newgid;
    $EUID = $UID = $uid;

    # To overwrite the saved UID on all platforms we need to do it twice
    ($GID) = split /\s/, $newgid;
    $EGID = $newgid;
    $EUID = $UID = $uid;

    # Sort the output so we can compare it
    my %GIDHash = map { $_ => 1 } ($gid, split(/\s/, $GID));
    my $cgid = int($GID)." ".join(" ", sort { $a <=> $b } (keys %GIDHash));
    my %EGIDHash = map { $_ => 1 } ($gid, split(/\s/, $EGID));
    my $cegid = int($EGID)." ".join(" ", sort { $a <=> $b } (keys %EGIDHash));
    
    # Check that we did actually drop the privileges
    if($UID ne $uid or $EUID ne $uid or $cgid ne $newgid or $cegid ne $newgid) {
        croak("Could not drop privileges to uid:$uid, gid:$newgid\n"
            ."Currently is: UID:$UID, EUID=$EUID, GID=$cgid, EGID=$cegid\n");
    }
}

=item drop_privileges($user)

Drops privileges to the $user, looking up gid and uid with getpwname and 
calling drop_uidgid() with these arguments.

The environment variables USER, LOGNAME, HOME and SHELL are also set to the
values returned by getpwname.

Returns the $uid and $gid on success and dies on error.

NOTE: If drop_privileges() is called when you don't have root privileges
it will just return undef;

=cut

sub drop_privileges {
    my ($user) = @_;
    
    croak "No user give" if !defined $user;

    # Check if we are root and stop if we are not.
    if($UID != 0 and $EUID != 0) {
        return;
    }
    
    # Find user in passwd file
    my ($uid, $gid, $home, $shell) = (getpwnam($user))[2,3,7,8];
    if(!defined $uid or !defined $gid) {
        croak("Could not find uid and gid user $user");
    }

    # Find all the groups the user is a member of
    my @groups;
    while (my ($name, $comment, $ggid, $mstr) = getgrent()) {
        my %membership = map { $_ => 1 } split(/\s/, $mstr);
        if(exists $membership{$user}) {
            push(@groups, $ggid) if $ggid ne 0;
        }
    }

    # Cleanup $ENV{}
    $ENV{USER} = $user;
    $ENV{LOGNAME} = $user;
    $ENV{HOME} = $home;
    $ENV{SHELL} = $shell;

    drop_uidgid($uid, $gid, @groups);

    return ($uid, $gid, @groups);
}

=back

=head1 NOTES

As this module only uses Perl's build in function, it relies on them to work
correctly. That means setting $GID and $EGID should also call setgroups(),
something that might not have been the case before Perl 5.004. So if you are 
running an older version, Proc::UID might be a better choice.

=head1 AUTHOR

Troels Liebe Bentsen <tlb@rapanden.dk> 

=head1 COPYRIGHT

Copyright(C) 2007-2009 Troels Liebe Bentsen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
