#!/usr/bin/perl -w

use Test::More tests => 37;
use strict;
BEGIN { require "t/utils.pl"; }
use RT;
use RTx::RightsMatrix;
use RTx::RightsMatrix::Util;

# Load the config file
RT::LoadConfig();

#Connect to the database and get RT::SystemUser and RT::Nobody loaded
RT::Init();

unless ($RT::DatabaseName eq 'rt3regression') {
    diag("Must test against rt3regression\n");
    exit 255;
}

#Get the current user all loaded
my $CurrentUser = $RT::SystemUser;

my $group = RT::Group->new($CurrentUser);
$group->LoadUserDefinedGroup('security_all');
ok($group->id, "Group loaded");

my $lol = RTx::RightsMatrix::Util::build_group_lists($RT::System);
ok(!$lol, "Not fooled by bogus group");

$lol = RTx::RightsMatrix::Util::build_group_lists($group);
is(@$lol, 4 , "Number of lists OK");
ok(@{$lol->[0]} > 1, "List length OK");
ok(@{$lol->[1]} > 1, "List length OK");
ok(@{$lol->[2]} > 1, "List length OK");
ok(@{$lol->[3]} > 1, "List length OK");
ok(@{$lol->[0]} < 5, "List length OK");
ok(@{$lol->[1]} < 5, "List length OK");
ok(@{$lol->[2]} < 5, "List length OK");
ok(@{$lol->[3]} < 5, "List length OK");
is(@{$lol->[0]}+@{$lol->[1]}+@{$lol->[2]}+@{$lol->[3]}, 13, "Number of nodes OK");
#print RTx::RightsMatrix::Util::showme($lol);

$group->LoadUserDefinedGroup('security_consultants');
ok($group->id, "Group loaded");
$lol = RTx::RightsMatrix::Util::build_group_lists($group);
is(@$lol, 1 , "Number of lists OK");
ok(@{$lol->[0]} == 1, "List length OK");
is(@{$lol->[0]}, 1, "Number of nodes OK");

$group->LoadUserDefinedGroup('god_group');
ok($group->id, "Group loaded");
$lol = RTx::RightsMatrix::Util::build_group_lists($group);
is(@$lol, 1 , "Number of lists OK");
ok(@{$lol->[0]} == 1, "List length OK");
is(@{$lol->[0]}, 1, "Number of nodes OK");

$group->LoadUserDefinedGroup('security_admins');
ok($group->id, "Group loaded");
$lol = RTx::RightsMatrix::Util::build_group_lists($group);
is(@$lol, 3 , "Number of lists OK");
ok(@{$lol->[0]} >= 1, "List length OK");
ok(@{$lol->[1]} >= 1, "List length OK");
ok(@{$lol->[2]} >= 1, "List length OK");
ok(@{$lol->[0]} <= 3, "List length OK");
ok(@{$lol->[1]} <= 3, "List length OK");
ok(@{$lol->[2]} <= 3, "List length OK");
is(@{$lol->[0]}+@{$lol->[1]}+@{$lol->[2]}, 8, "Number of nodes OK");

$group->LoadUserDefinedGroup('security_admins_subgroup1');
ok($group->id, "Group loaded");
$lol = RTx::RightsMatrix::Util::build_group_lists($group);
is(@$lol, 2 , "Number of lists OK");
ok(@{$lol->[0]} == 2, "List length OK");
ok(@{$lol->[1]} == 2, "List length OK");
is(@{$lol->[0]}+@{$lol->[1]}, 4, "Number of nodes OK");

$group->LoadUserDefinedGroup('super_security');
ok($group->id, "Group loaded");
$lol = RTx::RightsMatrix::Util::build_group_lists($group);
# put some tests here!

my $queue = RT::Queue->new($CurrentUser);
$queue->Load('Request');
ok($queue->id, "Queue loaded");
$group->LoadSystemRoleGroup('AdminCc');
ok($group->id, "Group loaded");
$lol = RTx::RightsMatrix::Util::build_group_lists($group, 'RT::Queue', $queue->id);
#print RTx::RightsMatrix::Util::showme($lol);
