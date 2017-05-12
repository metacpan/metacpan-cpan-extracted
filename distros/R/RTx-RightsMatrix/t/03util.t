#!/usr/bin/perl -w

use Test::More tests => 41;
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

my %groups = map { $_ => 1 } qw( security_all security_admins security_consultants 
                                 god_group dept_x security_admins_subgroup1 
                                 security_admins_subgroup2 random_group random_group2 );

foreach my $group ( keys %groups ) {
    $groups{$group} = load_group($group);
}

my %users = map { $_ => 1 } qw( sec_admin1 sec_admin2 sec_consult power_user
                                user_a user_b user_c );

foreach my $user ( keys %users ) {
    $users{$user} = load_user($user);
}

### testing list_has_member ###

*list_has_member = \&RTx::RightsMatrix::Util::list_has_member;

ok( !list_has_member( [], undef ), "Empty list");

ok(  list_has_member( [ $groups{god_group   } ], $users{power_user}->PrincipalObj ) );
ok( !list_has_member( [ $groups{random_group} ], $users{power_user}->PrincipalObj ) );
ok(  list_has_member( [ @groups{qw(random_group god_group)} ], $users{power_user}->PrincipalObj ) );
ok(  list_has_member( [ @groups{qw(god_group random_group)} ], $users{power_user}->PrincipalObj ) );

ok(  list_has_member( [ @groups{qw(security_all)} ], $groups{security_admins}->PrincipalObj ) );
ok(  list_has_member( [ @groups{qw(security_all)} ], $groups{security_all}->PrincipalObj ) );
ok(  list_has_member( [ @groups{qw(security_all security_admins)} ], $groups{security_admins}->PrincipalObj ) );
ok( !list_has_member( [ @groups{qw(god_group random_group)} ], $groups{security_admins}->PrincipalObj ) );

### testing same ###

*same = \&RTx::RightsMatrix::Util::same;

ok(  same( [ @groups{qw()} ], [ @groups{qw()} ] ), "lists same");
ok(  same( [ values %groups ], [ values %groups ] ), "lists same");
ok(  same( [ @groups{qw(random_group)} ], [ @groups{qw(random_group)} ] ), "lists same");
ok(  same( [ @groups{qw(random_group god_group)} ], [ @groups{qw(random_group god_group)} ] ), "lists same");
ok( !same( [ @groups{qw(god_group random_group)} ], [ @groups{qw(random_group god_group)} ] ), "lists different");
ok( !same( [ @groups{qw(god_group)} ], [ @groups{qw(random_group)} ] ), "lists different");
ok( !same( [ @groups{qw()} ], [ @groups{qw(random_group)} ] ), "lists different");
ok( !same( [ @groups{qw(random_group)} ], [ @groups{qw()} ] ), "lists different");

### testing reduce_list ### ( I hope 'same' was tested will becuase we are going top use it to test reduce )

*reduce = \&RTx::RightsMatrix::Util::reduce_list;

# principal is user
ok ( same( [ @groups{qw(god_group)} ],
           reduce( [ @groups{qw(god_group)} ], $users{power_user}->PrincipalObj )), "list reduced" );
ok ( same( [ @groups{qw(god_group)} ],
           reduce( [ @groups{qw(god_group dept_x)} ], $users{power_user}->PrincipalObj )), "list reduced" );
ok ( same( [ @groups{qw(dept_x god_group)} ],
           reduce( [ @groups{qw(dept_x god_group)} ], $users{power_user}->PrincipalObj )), "list reduced" );
ok ( same( [ @groups{qw(dept_x god_group)} ],
           reduce( [ @groups{qw(dept_x god_group dept_x)} ], $users{power_user}->PrincipalObj )), "list reduced" );

# principal is group
ok ( same( [ @groups{qw(security_all)} ], 
           reduce( [ @groups{qw(security_all)} ], $groups{security_all}->PrincipalObj )), "list reduced" );
ok ( same( [ @groups{qw(security_all)} ], 
           reduce( [ @groups{qw(security_all)} ], $groups{security_all}->PrincipalObj )), "list reduced" );
ok ( same( [ @groups{qw(security_all)} ], 
           reduce( [ @groups{qw(security_all security_admins)} ], $groups{security_all}->PrincipalObj )), "list reduced" );
ok ( same( [ @groups{qw(security_admins security_all)} ], 
           reduce( [ @groups{qw(security_admins security_all)} ], $groups{security_all}->PrincipalObj )), "list reduced" );

# first group in list is a system role.
# need to check if principal is a member of any queue roles
my $system_role_group = RT::Group->new($CurrentUser);
$system_role_group->LoadSystemRoleGroup('AdminCc');
$system_role_group->PrincipalObj->GrantRight(Right => 'AdminQueue', Object => $RT::System);
my $queue = RT::Queue->new($CurrentUser);
$queue->Load('Task');

#ok ( same( [ $system_role_group ], 
#           reduce( [ $system_role_group ], $groups{security_all}->PrincipalObj ), $queue ), "list reduced" );


######### helper funcs #########
sub load_user {
    my $user = RT::User->new($CurrentUser);
    $user->Load($_[0]);
    ok($user->id, "User $_[0] loaded");
    return $user;
}
sub load_group {
    my $group = RT::Group->new($CurrentUser);
    $group->LoadUserDefinedGroup($_[0]);
    ok($group->id, "Group $_[0] loaded");
    return $group;
}
