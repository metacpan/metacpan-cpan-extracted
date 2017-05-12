package Passwd::Solaris;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
@EXPORT_OK = qw(
		modpwinfo
		setpwinfo
		rmpwnam
		mgetpwnam
		);

$VERSION = '1.2';

bootstrap Passwd::Solaris $VERSION;

our $have_lock = 0;

sub _lock_and_read ($) {
    my $hold_lock = shift;
    my @pass;
    my @shad;
    my %entries;
    my $lock;

    my $save_separator = $/; # just in case calling program change the separator
    $/ = "\n";

    if ($hold_lock != 0) {
        $lock = xs_getlock();
        if ($lock != 0) {
            croak "Couldn't get lock on password files (are you root?)";
        }
        $have_lock = 1;
    }

    open(FILE, "</etc/passwd") or do {
        if ($hold_lock != 0) {
            $lock = xs_releaselock();
            if ($lock != 0) {
                croak "Couldn't release lock after /etc/passwd read failure";
            } else {
                croak "Read of /etc/passwd failed";
            }
        }
    };
    chomp(@pass = <FILE>);

    close(FILE);

    if (open(FILE, "</etc/shadow")) {
        @shad = <FILE>;
        close(FILE);
    } else {
        if ($hold_lock != 0) {
            $lock = xs_releaselock();
            if ($lock != 0) {
                croak "Couldn't release lock after /etc/shadow read failure";
            } else {
                croak "Read of /etc/shadow failed";
            }
        } else { # non-shadow permission read
            for (my $j = 0; $j <= $#pass; $j++) {
                $shad[$j] = "unknown:x\n";
            }
        }
    };

    if ($#pass != $#shad) {
        croak "Mismatch in number of entries between /etc/passwd and /etc/shadow";
    }
    
    my $info = [];
    for (my $i=0; $i <= $#pass; $i++) {
        my @pentry = split(/:/, $pass[$i]);
        my @sentry = split(/:/, $shad[$i]);
        my $entry = [];
        chomp(@sentry);
        $pentry[1] = $sentry[1];
        push @{$entry}, @pentry, @sentry[2..$#sentry];
        push @{$info}, $pentry[0]; #preserve the order
        $entries{$pentry[0]} = $entry;
        my @test = @{$entry};
        #print "added $pentry[0] - @{$entry}\n";
    }
    $entries{':ORDER:'} = $info;
    $/ = $save_separator; # restore original input separator
    return %entries;
}

sub _write_and_release (%) {
    my %entries = @_;
    my $info;
    my $err;
    my $err2;
    
    # verify we have the lock?
    if ($have_lock == 0) {
        croak "_write_and_release called and we didn't have the lock, how did that happen?"
    }
    
    if (exists($entries{':ORDER:'})) {
        $info = $entries{':ORDER:'};
    } else {
        xs_releaselock();
        croak "_write_and_release called with no entry order info";
    }
    
    rename "/etc/passwd", "/etc/opasswd" or do {
        xs_releaselock();
        croak "Couldn't rename /etc/passwd";
    };
    
    rename "/etc/shadow", "/etc/oshadow" or do {
        $err = rename "/etc/opasswd", "/etc/passwd";
        xs_releaselock();
        if ($err == 0) {
            croak "/etc/passwd may not exist, /etc/opasswd contains the correct entries";
        }
        croak "Couldn't rename /etc/shadow";
    };
    
    open(PASS, ">/etc/passwd") or do {
        $err = rename "/etc/opasswd", "/etc/passwd";
        $err2 = rename "/etc/oshadow", "/etc/shadow";
        xs_releaselock();
        if (($err == 0) || ($err2 == 0)) {
            croak "/etc/passwd or /etc/shadow may not exist, /etc/opasswd and /etc/oshadow contain the correct entries";
        }
        croak "Couldn't open /etc/passwd for writing";
    };
    chmod 0644, "/etc/passwd";

    open(SHAD, ">/etc/shadow") or do {
        $err = rename "/etc/opasswd", "/etc/passwd";
        $err2 = rename "/etc/oshadow", "/etc/shadow";
        xs_releaselock();
        if (($err == 0) || ($err2 == 0)) {
            croak "/etc/passwd or /etc/shadow may not exist, /etc/opasswd and /etc/oshadow contain the correct entries";
        }
        croak "Couldn't open /etc/passwd for writing";
    };

    # if a shadow group exists give it read permissions
    my @sgrp = getgrnam("shadow");
    if (@sgrp > 1) {
        chown 0, $sgrp[2], "/etc/shadow";
        chmod 0640, "/etc/shadow";
    } else {
        chmod 0600, "/etc/shadow";
    }

    my $save_separator = $/; # just in case the program using this has changed it
    $/ = "\n";
    foreach my $user (@{$info}) {
        if (exists($entries{$user})) {
            my @data = @{$entries{$user}};
            my $pentry = join(":", $data[0], "x", @data[2..6]);
            my $sentry = join(":", @data[0..1], @data[7..$#data]);
            print PASS "$pentry\n";
            chomp $sentry;
            print SHAD "$sentry\n";
        } # else skip, its a deleted entry
    }
    $/ = $save_separator;

    close(SHAD);
    close(PASS);
    
    my $lock = xs_releaselock();
    if ($lock != 0) {
        croak "Couldn't release lock on password files";
    }
    $have_lock = 0;
    return 0;
}

sub _set_user ($$) {
    my %entries = %{$_[0]};
    my @info = @{$_[1]};
    my $days = int(time()/86400);
    my @data;

    $info[7] = $days;
    if (exists($entries{$info[0]})) {
        @data = @{$entries{$info[0]}};
    } else {
        push @{$entries{":ORDER:"}}, $info[0];
    }
    for (my $i = 0; $i <= $#info; $i++) {
        $data[$i] = $info[$i];
    }
    $entries{$info[0]} = \@data;

    if (eval { _write_and_release(%entries); } ) {
        print $@;
        return 1;
    }
    return 0;
}

sub modpwinfo {
    my @info = @_;
    my @user;

    if (($#info < 1) || ($#info > 13)) {
        croak "modpwinfo: (name, crypted_pass, [uid, gid, gecos, home, shell, stuff from shadow file] )";
    }
    my %entries = _lock_and_read(1);
    if (exists($entries{$info[0]})) {
        @user = @{$entries{$info[0]}};
        for (my $i = 0; $i <= $#info; $i++) {
            $user[$i] = $info[$i];
        }
    } else {
        xs_releaselock();
        $have_lock = 0;
        return 2;
    }
    return _set_user(\%entries, \@user);
}

sub setpwinfo {
    my @info = @_;
    my @user;

    if (($#info < 1) || ($#info > 13)) {
        print "setpwinfo croaking\n";
        croak "setpwinfo: (name, crypted_pass, uid, gid, gecos, home, shell, [(man shadow for the rest of the fields)] )";
    }
    my %entries = _lock_and_read(1);
    if (exists($entries{$info[0]})) {
        @user = @{$entries{$info[0]}};
    } else {
        $user[8] = 0;
        $user[9] = 99999;
        $user[10] = 7;
        $user[13] = "\n"; # fill in the rest as empty
    }
    for (my $i = 0; $i <= $#info; $i++) {
        $user[$i] = $info[$i];
    }        
    return _set_user(\%entries, \@user);
}

sub mgetpwnam {
    my ($login) = @_;
    
    my %entries = _lock_and_read(0);
    if (exists($entries{$login})) {
        my @info = @{$entries{$login}};
        return @info;
    }
    
    return;
}

sub rmpwnam {
    my %entries = _lock_and_read(1);
    foreach my $login (@_) {
        if (exists($entries{$login})) {
            my @data = @{$entries{$login}};
            if ($data[2] != 0) { # don't delete uid 0 accounts 
                delete $entries{$login};
            } else {
                return 1;
            } 
        }
    }
    _write_and_release(%entries);
    return 0;
}

1;
__END__

=head1 NAME

Passwd::Solaris - Perl module for manipulating the passwd and shadow files

=head1 SYNOPSIS

  use Passwd::Solaris qw(modpwinfo setpwinfo rmpwnam mgetpwnam);

  $err = modpwinfo(@info);
  $err = setpwinfo(@info);
  $err = rmpwnam(@logins);
  $err = rmpwnam($login);
  @info = mgetpwnam($name);

=head1 DESCRIPTION

Passwd::Solaris provides additional password routines.  It augments the getpw* functions with setpwinfo, modpwinfo, rmpwnam, mgetpwnam.  You need to run the functions as root or as someone who has permission to read/modify the shadow file.

setpwinfo and modpwinfo are called with arrays containing (in order):
 name, crypted_password, uid, gid, gecos, home_directory, shell, [ days_since_epoch_password_last_change, days_before_password_may_be_changed, days_after_which_password_must_be_changed, days_before_expire_user_is_warned, days_after_expire_password_is_disabled, days_since_epoch_account_is_disabled ]
 The optional fields are filled in as <days since the epoch>, 0, 99999, 7, <empty>, <empty>, when not given a value.
 Read the shadow manpage for additional details of the optional fields from the shadow file

rmpwnam is called with a list of names to remove

mgetpwnam returns the same array that getpwnam returns without the 'unused' age or comment fields it also returns the crypted password and the other shadow file fields if run with root permissions. 

setpwinfo does a create/modify of the user.
modpwinfo only does a modify, it will return an error if the user doesn't exist.

rmpwnam removes the users with the given logins from both the password and shadow files.

You must be running as root in order to use this module. If it successfully completes an operation and you are not root then you have a huge security problem on your box.

This module as distributed does not allow operations to occur on uid 0 files

Return values:
  < 0	system error occurred, error value should be in $!
    0   no error
    1   operation attempt on uid 0
    2   user does not exist

=head1 Exported functions on the OK basis

  modpwinfo
  setpwinfo
  rmpwnam
  mgetpwnam

=head1 AUTHOR

Eric Estabrooks,  eric@urbanrage.com

=head1 SEE ALSO

perl(1).

=cut
