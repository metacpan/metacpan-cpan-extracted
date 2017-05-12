#!/usr/bin/perl

# $Id: fetch_all.pl,v 3.1 2004/01/10 02:49:58 lachoy Exp $

# Fetch all objects in the database

use strict;
use Log::Log4perl;
Log::Log4perl::init( 'log4perl.conf' );

require My::Security;
require My::User;
require My::Group;
require My::Doodad;

my $users    = My::User->fetch_group({ skip_security => 1 });
my $groups   = My::Group->fetch_group({ skip_security => 1 });
my $security = My::Security->fetch_group({ skip_security => 1 });
my $doodads  = My::Doodad->fetch_group({ skip_security => 1 });

foreach my $user ( @{ $users } ) {
    print "User ", $user->id, ": $user->{login_name}\n";
}

print "\n";

foreach my $group ( @{ $groups } ) {
    print "Group ", $group->id, ": $group->{name}\n";
}

print "\n";

my $ug_sql = qq/
    SELECT group_id, user_id
      FROM spops_group_user
  ORDER BY group_id, user_id
/;
my $sth = My::User->global_datasource_handle->prepare( $ug_sql );
$sth->execute;
while ( my ( $gid, $uid ) = $sth->fetchrow_array ) {
    print "Group [$gid] User [$uid]\n";
}

print "\n";

foreach my $sec ( @{ $security } ) {
    print "Security ", $sec->id, " [$sec->{class}] [$sec->{object_id}] ",
          "[$sec->{scope}] [$sec->{scope_id}] [$sec->{security_level}]\n";
}


print "\n";

foreach my $d ( @{ $doodads } ) {
    print "Doodad ", $d->id, ": $d->{name}\n";
}
