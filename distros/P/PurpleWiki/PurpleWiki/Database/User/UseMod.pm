# PurpleWiki::Database::User::UseMod.pm
# vi:sw=4:ts=4:ai:sm:et:tw=0
#
# $Id: UseMod.pm 463 2004-08-09 01:31:48Z cdent $
#
# Copyright (c) Blue Oxen Associates 2002-2004.  All rights reserved.
#
# This file is part of PurpleWiki.  PurpleWiki is derived from:
#
#   UseModWiki v0.92          (c) Clifford A. Adams 2000-2001
#   AtisWiki v0.3             (c) Markus Denker 1998
#   CVWiki CVS-patches        (c) Peter Merel 1997
#   The Original WikiWikiWeb  (c) Ward Cunningham
#
# PurpleWiki is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
#    Free Software Foundation, Inc.
#    59 Temple Place, Suite 330
#    Boston, MA 02111-1307 USA

package PurpleWiki::Database::User::UseMod;

use strict;
#use base 'PurpleWiki::Database::User::Base';
use DB_File;
use PurpleWiki::Config;
use PurpleWiki::Database;
use PurpleWiki::User;

our $VERSION;
$VERSION = sprintf("%d", q$Id: UseMod.pm 463 2004-08-09 01:31:48Z cdent $ =~ /\s(\d+)\s/);

my @DataFields = (
    'username', 'id', 'randkey', 'rev', 'createtime', 'createip',
    'email', 'password', 'notify', 'adminpw', 'linkrandom',
    'toplinkbar', 'rcdays', 'rcnewtop', 'rcall', 'rcchangehist',
    'editwide', 'norcdiff', 'diffrclink', 'alldiff', 'defaultdiff',
    'rcshowedit', 'tzoffset', 'editrows', 'editcols',
);

sub new {
    my $class = shift;
    my $self = {};
    $self->{config} = PurpleWiki::Config->instance();

    # create user directories
    my $userDir = $self->{config}->UserDir;
    if (!(-d "$userDir/0")) {
        PurpleWiki::Database::CreateDir($userDir);

        foreach my $n (0..9) {
            PurpleWiki::Database::CreateDir("$userDir/$n");
        }
    }

    bless ($self, $class);
}

sub createUser {
    my $self = shift;

    # generate new user ID
    my $id = 1001;
    while (-f $self->_userFile($id+1000)) {
        $id += 1000;
    }
    while (-f $self->_userFile($id+100)) {
        $id += 100;
    }
    while (-f $self->_userFile($id+10)) {
        $id += 10;
    }

    &PurpleWiki::Database::RequestLock() or die('Could not get user ID lock');
    while (-f $self->_userFile($id)) {
        $id++;
    }
    # reserve the user ID
    &PurpleWiki::Database::WriteStringToFile($self->_userFile($id), "lock");
    &PurpleWiki::Database::ReleaseLock();

    return PurpleWiki::User->new($id);
}

sub loadUser {
    my $self = shift;
    my $userId = shift;
    my $user = PurpleWiki::User->new;

    if ($userId && -f $self->_userFile($userId)) {
        my $data = PurpleWiki::Database::ReadFileOrDie($self->_userFile($userId));
        if ($data !~ /^lock/) {
            my $regexp = $self->{config}->FS1;
            my %tempHash = split (/$regexp/, $data, -1);
            foreach my $key (keys(%tempHash)) {
                $user->setField($key, $tempHash{$key});
            }
            return $user;
        }
        else {
            return undef;
        }
    }
    else {
        return undef;
    }
}

sub saveUser {
    my $self = shift;
    my $user = shift;

    # serialize data
    my $separator = $self->{config}->FS1;
    my $string;
    foreach my $field (@DataFields) {
        $string .= $field . $separator . $user->getField($field);
        if ($field ne $DataFields[$#DataFields]) {
            $string .= $separator;
        }
    }

    # write user data
    PurpleWiki::Database::WriteStringToFile($self->_userFile($user->id), $string);

    # update username->id map
    my %users;
    my $userDir = $self->{config}->UserDir;
    &PurpleWiki::Database::RequestLock or die('Could not get usernames.db lock');
    tie %users, "DB_File", "$userDir/usernames.db",
        O_RDWR|O_CREAT, 0666, $DB_HASH;
    $users{$user->username} = $user->id;
    untie %users;
    &PurpleWiki::Database::ReleaseLock;
}

sub deleteUser {
    my $self = shift;
    my $userFile = $self->_userFile(shift);

    &PurpleWiki::Database::RequestLock() or die('Could not get user-ID lock');
    if (-f $userFile) {
        unlink $userFile;
    }
    &PurpleWiki::Database::ReleaseLock();
}

sub idFromUsername {
    my $self = shift;
    my $userName = shift;
    my %users;

    my $userDir = $self->{config}->UserDir;
    tie %users, "DB_File", "$userDir/usernames.db",
        O_RDONLY, 0444, $DB_HASH;
    my $id = $users{$userName};
    untie %users;
    return $id;
}

### private methods

sub _userFile {
    my $self = shift;
    my $userId = shift;

    return if ($userId < 0);
    return $self->{config}->UserDir . "/" . ($userId % 10) . "/$userId.db";
}

1;
__END__

=head1 NAME

PurpleWiki::Database::User::UseMod - UseMod backend for user database.

=head1 SYNOPSIS

  use PurpleWiki::Database::User::UseMod;

=head1 DESCRIPTION

Accesses UseMod user database (along with corresponding username
index, created by this class or by createUsernameIndex.pl).

=head1 METHODS

=head2 new

Constructor.  Creates user directory and subdirectories if it doesn't
already exist.

=head2 createUser

Creates a new user and reserves the user ID.  Returns a
PurpleWiki::User object.

=head2 loadUser($userId)

Loads user with $userId and returns PurpleWiki::User object.

=head2 saveUser($user)

Saves a PurpleWiki::User object and updates the index.

=head2 deleteUser($userId);

Deletes user with $userId from database.

=head2 idFromUsername($userName)

Returns user ID corresponding to $userName.

=head1 AUTHORS

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::Database::User::Base>

=cut
