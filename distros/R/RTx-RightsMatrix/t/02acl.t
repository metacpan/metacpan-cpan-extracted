#!/usr/bin/perl -w

use Test::More tests => 28;
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
$group->LoadUserDefinedGroup('security_admins');
ok($group->id, "Group loaded");

# The number of ACEs expected is the number assigned in 00setup.t plus 1 for each role the user
# has system wide

# the user is an AdminCC of both queues so
my $RoleRights = role_rights(Right => 'SeeQueue', Queue => 'Task', Principal => $group->PrincipalObj);
is(check_acl_length('SeeQueue' ,  'RT::Queue', 'Task', $group->PrincipalObj), 1 + $RoleRights, "Number of ACEs OK");
$RoleRights = role_rights(Right => 'SeeQueue', Queue => 'Request', Principal => $group->PrincipalObj);
is(check_acl_length('SeeQueue' ,  'RT::Queue', 'Request', $group->PrincipalObj), 1 + $RoleRights, "Number of ACEs OK");

$RoleRights = role_rights(Right => 'ModifyTemplate', Queue => 'Task', Principal => $group->PrincipalObj);
is(check_acl_length('ModifyTemplate' ,  'RT::Queue', 'Task', $group->PrincipalObj), 0 + $RoleRights, "Number of ACEs OK");
$RoleRights = role_rights(Right => 'ModifyTemplate', Queue => 'Request', Principal => $group->PrincipalObj);
is(check_acl_length('ModifyTemplate' ,  'RT::Queue', 'Request', $group->PrincipalObj), 1 + $RoleRights, "Number of ACEs OK");

###

$group->LoadUserDefinedGroup('security_all');
ok($group->id, "Group loaded");

# The number of ACEs expected is the number assigned in 00setup.t plus 1 for each role the user
# has system wide

# the user is an AdminCC of both queues so
$RoleRights = role_rights(Right => 'SeeQueue', Queue => 'Task', Principal => $group->PrincipalObj);
is(check_acl_length('SeeQueue' ,  'RT::Queue', 'Task', $group->PrincipalObj), 0 + $RoleRights, "Number of ACEs OK");
$RoleRights = role_rights(Right => 'SeeQueue', Queue => 'Request', Principal => $group->PrincipalObj);
is(check_acl_length('SeeQueue' ,  'RT::Queue', 'Request', $group->PrincipalObj), 0 + $RoleRights, "Number of ACEs OK");

$RoleRights = role_rights(Right => 'ModifyTemplate', Queue => 'Task', Principal => $group->PrincipalObj);
is(check_acl_length('ModifyTemplate' ,  'RT::Queue', 'Task', $group->PrincipalObj), 0 + $RoleRights, "Number of ACEs OK");
$RoleRights = role_rights(Right => 'ModifyTemplate', Queue => 'Request', Principal => $group->PrincipalObj);
is(check_acl_length('ModifyTemplate' ,  'RT::Queue', 'Request', $group->PrincipalObj), 0 + $RoleRights, "Number of ACEs OK");

###

my $user = RT::User->new($CurrentUser);
$user->Load('power_user');
my $Principal = $user->PrincipalObj;

is(check_acl_length('SuperUser', 'RT::System', 'Task', $Principal), 2, "Number of ACEs OK");
# direct, member of god_group, member of security_admins(recursively)
is(check_acl_length('SeeQueue' ,  'RT::Queue', 'Task', $Principal), 3, "Number of ACEs OK");

$group->LoadUserDefinedGroup('god_group');
is(check_acl_length('SeeQueue' ,  'RT::Queue', 'Task', $group->PrincipalObj), 1, "Number of ACEs OK");
is(check_acl_length('SuperUser' ,  'RT::Queue', 'Task', $group->PrincipalObj), 0, "Number of ACEs OK");
is(check_acl_length('SuperUser' ,  'RT::System', undef, $group->PrincipalObj), 1, "Number of ACEs OK");

sub check_acl_length {

    my $object = $_[1]->new($CurrentUser);
    if ($_[2] ne 'RT::System') {
        $object->Load($_[2]);
    }
    ok($object->id, "object loaded");
    return RTx::RightsMatrix::Util::acl_for_object_right_and_principal(
        Principal => $_[3],
	RightName => $_[0],
	ObjectType => $_[1],
        ObjectId => $object->id,
    );

}
sub print_acl {

    my $object = $_[1]->new($CurrentUser);
    if ($_[2] ne 'RT::System') {
        $object->Load($_[2]);
    }
    ok($object->id, "object loaded");
    my @acl =  RTx::RightsMatrix::Util::acl_for_object_right_and_principal(
        Principal => $_[3],
	RightName => $_[0],
	ObjectType => $_[1],
        ObjectId => $object->id,
    );
    print $_->id, ' ' for @acl;

}

sub role_rights {

    my %args = @_;
    my $RoleRights = 0;

    my $Right = $args{Right};
    my $Principal = $args{Principal};

    my $SystemAdminCc = RT::Group->new($CurrentUser);
    $SystemAdminCc->LoadSystemRoleGroup('AdminCc');

    my $SystemCc = RT::Group->new($CurrentUser);
    $SystemCc->LoadSystemRoleGroup('Cc');

    my $Queue = RT::Queue->new($CurrentUser);
    $args{Queue} eq 'RT::System' ? $Queue = $RT::System : $Queue->Load($args{Queue});

    my $AdminCc = RT::Group->new($CurrentUser);
    $AdminCc->LoadQueueRoleGroup(Queue => $Queue->id, Type => 'AdminCc');

    my $Cc = RT::Group->new($CurrentUser);
    $Cc->LoadQueueRoleGroup( Queue => $Queue->id, Type => 'Cc');

    $RoleRights++ if $AdminCc->HasMemberRecursively($Principal)
                   and ( $SystemAdminCc->PrincipalObj->HasRight( Right => $Right,  Object => $RT::System )
                   or $SystemAdminCc->PrincipalObj->HasRight( Right => 'SuperUser', Object => $RT::System ) );
    $RoleRights++ if $Cc->HasMemberRecursively($Principal)
                   and ( $SystemCc->PrincipalObj->HasRight( Right => $Right,  Object => $RT::System )
                   or $SystemCc->PrincipalObj->HasRight( Right => 'SuperUser', Object => $RT::System ) );

    return $RoleRights;
}
