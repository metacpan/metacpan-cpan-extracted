#!/usr/bin/perl
#
# createUsernameIndex.pl
#
# $Id$
#
# Cleans out locked and duplicate user IDs and renumbers users.
# Generates a username -> userID lookup table from wikidb/user
# directory

use strict;
use DB_File;
use File::Copy;
use File::Find;
use PurpleWiki::Config;
use PurpleWiki::Database::User::UseMod;

my $CONFIG;
if (scalar @ARGV) {
    $CONFIG = shift;
}
else {
    print "Usage: $0 wikidb\n";
    exit;
}

my $config = new PurpleWiki::Config($CONFIG);
my $userDir = $config->UserDir;

my %users;  # $users{name} = id
my %ids;    # $ids{id} = name
my @userIds;
find(sub {-f && /^(\d+)\.db/ && push @userIds, $1}, ( $userDir ) );

my @toDelete;

my $userDb = new PurpleWiki::Database::User::UseMod;
foreach my $userId (sort @userIds) {
    my $user = $userDb->loadUser($userId);
    if ($user) {
        if (my $userName = $user->username) {
            if ($users{$userName}) { # duplicate
                push @toDelete, $users{$userName};
                delete $ids{$users{$userName}};
            }
            $users{$userName} = $userId;
            $ids{$userId} = $userName;
        }
    }
    else {
        push @toDelete, $userId;
    }
}

print "Deleting " . scalar @toDelete . " lock files....\n";
foreach my $userId (sort @toDelete) {
    unlink &fullPath($userId);
}

my $currentId = 1001;
my %persistentUsers;
tie %persistentUsers, "DB_File", "$userDir/usernames.db",
    O_RDWR|O_CREAT, 0666, $DB_HASH;
foreach my $oldUserId (sort keys %ids) {
    print "Mapping $oldUserId to $currentId (";
    if ($oldUserId > $currentId) {
        move(&fullPath($oldUserId), &fullPath($currentId));
        my $user = $userDb->loadUser($currentId);
        $user->id($currentId);
        print $user->username . ")\n";
        $userDb->saveUser($user);
    }
    else {
        print $ids{$oldUserId} . ")\n";
    }
    $persistentUsers{$ids{$oldUserId}} = $currentId;
    $currentId++;
}
untie %persistentUsers;

# fini

sub fullPath {
    my $id = shift;
    $config->UserDir . '/' . ($id % 10) . "/$id.db";
}


=head1 NAME

createUsernameIndex.pl - Cleans and indexes UseMod username database

=head1 SYNOPSIS

  createUsernameIndex.pl /path/to/wikidb

=head1 DESCRIPTION

UseModWiki has two problems with its user database (wikidb/user).
First, it uses it as both a user database and also a session
management database.  As a result, the database becomes unnecessarily
enormous with spurious "users" that do nothing but lock a user ID.
Second, it does not keep a mapping of usernames to user IDs.  As a
result, users have to remember their user IDs in order to log in.

This script cleans up the user database and creates an index.  You
must run this script in order to convert UseModWiki or PurpleWiki (<
0.93) installations.

=head1 AUTHORS

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=cut
