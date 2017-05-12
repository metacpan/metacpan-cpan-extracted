#!/usr/bin/perl -w

use Test::More tests => 178;
use strict;
BEGIN { require "t/utils.pl"; }
use RT;

# Load the config file
RT::LoadConfig();

#Connect to the database and get RT::SystemUser and RT::Nobody loaded
RT::Init();

unless ($RT::DatabaseName eq 'rt3regression') {
    diag("Must test against rt3regression!\n");
    exit 255;
}

#Get the current user all loaded
my $CurrentUser = $RT::SystemUser;

# group to user mapping
my %groups = ( security_all => [],
               security_admins => [ 'sec_admin1', 'sec_admin2', ],
               security_consultants => ['sec_consult'],
               god_group => ['power_user',],
               dept_x => ['user_a', 'user_b', 'user_c',],
               security_admins_subgroup1 => [],
               security_admins_subgroup2 => ['power_user'],
               random_group => [],
               random_group2 => [],
               super_security => [],
             );

# nested group mapping
my %sub_groups = (
               security_all => [ 'security_admins', 'security_consultants' ],
               security_admins => [ 'security_admins_subgroup1', 'random_group', ],
               security_admins_subgroup1 => [ 'security_admins_subgroup2', 'random_group2' ],
               super_security => [ 'security_all', 'security_admins' ],
);



#### Set up users and groups ####
foreach ( map { @$_ } values %groups ) {
    my $user = RT::User->new($CurrentUser);
    my ($rv, $msg) = $user->Load($_);
    if (!$rv) {
        ($rv, $msg) = $user->Create(Name => $_, EmailAddress => "$_\@example.com", Privileged => 1);
    }
    else {
        my $group = RT::Group->new($CurrentUser);
        $group->LoadByCols( Type => 'UserEquiv', Instance => $user->id );
        my $acl = RT::ACL->new($CurrentUser);
        $acl->Limit( FIELD => 'PrincipalType', VALUE => 'Group' );
        $acl->Limit( FIELD => 'PrincipalId', VALUE => $group->id );
        while (my $ace = $acl->Next) {
            ($rv, $msg) = $ace->Delete;
            ok($rv, "Existing ACE deleted");
        }
    }
    ok($user->id, "User $_ loaded: $msg");
    is($user->Name, $_, "User name");
}

foreach ( keys %groups ) {
    my $group = RT::Group->new($CurrentUser);
    my ($rv, $msg) = $group->LoadUserDefinedGroup($_);
    if (! $rv) {
        ($rv, $msg) = $group->CreateUserDefinedGroup(Name => $_);
    }
    else {
        my $acl = RT::ACL->new($CurrentUser);
        $acl->Limit( FIELD => 'PrincipalType', VALUE => 'Group' );
        $acl->Limit( FIELD => 'PrincipalId', VALUE => $group->id );
        while (my $ace = $acl->Next) {
            ($rv, $msg) = $ace->Delete;
            ok($rv, "Existing ACE deleted");
        }
    }
    ok($group->id, "Group loaded");
    is($group->Name, $_, "Group name");
    
    foreach my $u (@{$groups{$_}}) {
        my $user = RT::User->new($CurrentUser);
        my ($rv, $msg) = $user->Load($u);
        ok($user->id, "User $u loaded: $msg");
        unless ($group->HasMember($user->PrincipalObj)) {
            $group->AddMember($user->PrincipalId);
        }
        ok($group->HasMember($user->PrincipalObj), "$u is member of ".$group->Name);
    }
}

foreach ( keys %sub_groups ) {
    my $group = RT::Group->new($CurrentUser);
    my ($rv, $msg) = $group->LoadUserDefinedGroup($_);
    ok($group->id, "Group loaded");

    foreach my $subgroup (@{$sub_groups{$_}}) {
        my $GroupObj = RT::Group->new($CurrentUser);
        my ($rv, $msg) = $GroupObj->LoadUserDefinedGroup($subgroup);
        ok($GroupObj->id, "Group $subgroup loaded: $msg");
        unless ($group->HasMember($GroupObj->PrincipalObj)) {
            $group->AddMember($GroupObj->PrincipalId);
        }
        ok($group->HasMember($GroupObj->PrincipalObj), "$subgroup is member of ".$group->Name);
    }
}

### setup queues
my %queues = (
    CERT    => {
                AdminCc => {
                    Users => [],
                    Groups => ['security_consultants',],
                },
                Cc      => {
                    Users => [],
                    Groups => [],
                },
    },
    Request => {
                AdminCc => {
                    Users => [],
                    Groups => ['security_all', 'security_admins',],
                },
                Cc      => {
                    Users => [],
                    Groups => [],
                },
    },
    Task     => {
                AdminCc => {
                    Users => [],
                    Groups => ['security_all', 'security_admins',],
                },
                Cc      => {
                    Users => [],
                    Groups => [],
                },
    },
    General  => {
                AdminCc => {
                    Users => [],
                    Groups => [],
                },
                Cc      => {
                    Users => [],
                    Groups => ['dept_x',],
                },
    },
);

foreach ( keys %queues ) {

    my $queue = RT::Queue->new($CurrentUser);
    my ($rv, $msg) = $queue->Load($_);
    unless ($rv) {
        ($rv, $msg) = $queue->Create(Name => $_);
    }
    ok($queue->id, "Queue $_ loaded");

    foreach my $role (keys %{$queues{$_}}) {
        foreach my $user ( @{$queues{$_}{$role}{Users}} ) {
            my $UserObj = RT::User->new($CurrentUser);
            $UserObj->Load($user);
            ok($UserObj->id);
            my ($rv, $msg) = $queue->AddWatcher(Type => $role, PrincipalId => $UserObj->PrincipalId);
            $rv = $queue->IsWatcher(Type => $role, PrincipalId => $UserObj->PrincipalId);
            ok($rv, "User $user is role $role for queue $_: $msg");
        }
        foreach my $group ( @{$queues{$_}{$role}{Groups}} ) {
            my $GroupObj = RT::Group->new($CurrentUser);
            $GroupObj->LoadUserDefinedGroup($group);
            ok($GroupObj->id);
            my ($rv, $msg) = $queue->AddWatcher(Type => $role, PrincipalId => $GroupObj->PrincipalId);
            $rv = $queue->IsWatcher(Type => $role, PrincipalId => $GroupObj->PrincipalId);
            ok($rv, "Group $group is role $role for queue $_: $msg");
        }
    }
    
}

### set up rights
my @rights = (
    { Type => 'RT::User',
      Name => 'power_user',
      Rights => ['SuperUser'],
      ObjectType => 'RT::System',
      ObjectName => undef, },
    { Type => 'RT::Group',
      Name => 'god_group',
      Rights => ['SuperUser'],
      ObjectType => 'RT::System',
      ObjectName => undef, },
    { Type => 'RT::Group',
      Name => 'security_admins',
      Rights => [ qw( AdminQueue CommentOnTicket CreateTicket DeleteTicket ModifyQueueWatchers ModifyTicket
                      OwnTicket ReplyToTicket SeeQueue ShowACL ShowOutgoingEmail ShowScrips ShowTemplate
                      ShowTicket ShowTicketComments StealTicket TakeTicket Watch WatchAsAdminCc )],
      ObjectType => 'RT::Queue',
      ObjectName => 'Task', },
    { Type => 'RT::Group',
      Name => 'security_admins',
      Rights => [ qw( AdminQueue CommentOnTicket CreateTicket DeleteTicket ModifyQueueWatchers ModifyTicket ModifyTemplate
                      OwnTicket ReplyToTicket SeeQueue ShowACL ShowOutgoingEmail ShowScrips ShowTemplate
                      ShowTicket ShowTicketComments StealTicket TakeTicket Watch WatchAsAdminCc )],
      ObjectType => 'RT::Queue',
      ObjectName => 'Request', },
);

foreach my $right (@rights) {

    assign_right(%$right);

}

sub assign_right {

    my %args = @_;
    my $type = $args{Type}->new($CurrentUser);
    if ($args{Type} =~ /Group/) {
        my ($rv, $msg) = $type->LoadUserDefinedGroup($args{Name});
        ok($type->id, "$args{Type} $args{Name} loaded");
        return 0 unless $rv;
    }
    else {
        my ($rv, $msg) = $type->Load($args{Name});
        ok($type->id, "$args{Type} $args{Name} loaded");
        return 0 unless $rv;
    }
    my $Object = $args{ObjectType}->new($CurrentUser); 
    $Object->Load($args{ObjectName}) if $args{ObjectName} ne 'RT::System';
    ok($Object->id, "Object $args{ObjectType} $args{ObjectName} loaded");
    foreach my $right ( @{$args{Rights}} ) {
        $type->PrincipalObj->GrantRight(Right => $right, Object => $Object);
        ok($type->PrincipalObj->HasRight(Right => $right, Object => $Object), $type->Name . " has right $right on object");
    }
}
