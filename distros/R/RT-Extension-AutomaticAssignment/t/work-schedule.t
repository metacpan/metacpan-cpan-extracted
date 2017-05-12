use strict;
use warnings;

use RT::Extension::AutomaticAssignment::Test tests => undef;
use Test::MockTime 'set_fixed_time';

my $queue = RT::Queue->new(RT->SystemUser);
$queue->Load('General');
ok($queue->Id, 'loaded General queue');

my $cf = RT::CustomField->new(RT->SystemUser);
my ($ok, $msg) = $cf->Create(
    Name       => 'Work Schedule',
    LookupType => RT::User->CustomFieldLookupType,
    Type       => 'SelectSingle',
    MaxValues  => 1,
);
ok($ok, "created Work Schedule CF");

($ok, $msg) = $cf->AddToObject(RT::User->new(RT->SystemUser));
ok($ok, "made Work Schedule global");

($ok, $msg) = $cf->AddValue(Name => 'Morning');
ok($ok, 'added Morning shift');
($ok, $msg) = $cf->AddValue(Name => 'Afternoon');
ok($ok, 'added Afternoon shift');
($ok, $msg) = $cf->AddValue(Name => 'Weekend');
ok($ok, 'added Weekend shift');

my $assignees = RT::Group->new(RT->SystemUser);
$assignees->CreateUserDefinedGroup(Name => 'Assignees');
$assignees->PrincipalObj->GrantRight(Right => 'OwnTicket', Object => $queue);

($ok, $msg) = RT::Extension::AutomaticAssignment->_SetConfigForQueue(
    $queue,
    [
        { ClassName => 'WorkSchedule', user_cf => $cf->Id },
        { ClassName => 'MemberOfGroup', group => $assignees->Id },
    ],
    { ClassName => 'Random' },
);
ok($ok, "set AutomaticAssignment config");

sub add_user {
    my $name = shift;
    my $work_schedule = shift;

    my $user = RT::User->new(RT->SystemUser);
    my ($ok, $msg) = $user->Create(
        Name => $name,
    );
    ok($ok, "created user $name");

    ($ok, $msg) = $assignees->AddMember($user->Id);
    ok($ok, "added user $name to Assignees group");

    if ($work_schedule) {
        ($ok, $msg) = $user->AddCustomFieldValue(
            Field => $cf->Id,
            Value => $work_schedule,
        );
        ok($ok, "added Work Schedule $work_schedule: $msg");
    }

    return $user;
}

sub eligible_ownerlist_is {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $input_time = shift;
    my $expected = shift;
    my $msg = shift;

    my $epoch = do {
        my $date = RT::Date->new(RT->SystemUser);
        $date->Set(Format => 'unknown', Value => $input_time);
        $date->Unix;
    };

    set_fixed_time($epoch);

    my $ticket = RT::Ticket->new(RT->SystemUser);
    $ticket->Create(Queue => $queue->Id);
    ok($ticket->Id, 'created ticket');

    my $got = RT::Extension::AutomaticAssignment->_EligibleOwnersForTicket(
        $ticket,
        undef,
        { time => $epoch },
    );

    is_deeply(
        [ sort map { $_->Name } @$got ],
        [ sort @$expected ],
        $msg,
    );
}

# 4th=Sunday, 5th=Monday(holiday), 6th=Tuesday ..., 9th=Friday, 10th=Saturday

eligible_ownerlist_is '2016-09-08 10:00:00' => [qw//];
eligible_ownerlist_is '2016-09-08 13:00:00' => [qw//];
eligible_ownerlist_is '2016-09-08 16:00:00' => [qw//];
eligible_ownerlist_is '2016-09-10 14:00:00' => [qw//];
eligible_ownerlist_is '2016-09-05 13:00:00' => [qw//];

add_user 'Unscheduled1', undef;
eligible_ownerlist_is '2016-09-08 10:00:00' => [qw//];
eligible_ownerlist_is '2016-09-08 13:00:00' => [qw//];
eligible_ownerlist_is '2016-09-08 16:00:00' => [qw//];
eligible_ownerlist_is '2016-09-10 14:00:00' => [qw//];
eligible_ownerlist_is '2016-09-05 13:00:00' => [qw//];

add_user 'Morning1', 'Morning';
eligible_ownerlist_is '2016-09-08 10:00:00' => [qw/Morning1/];
eligible_ownerlist_is '2016-09-08 13:00:00' => [qw/Morning1/];
eligible_ownerlist_is '2016-09-08 16:00:00' => [qw//];
eligible_ownerlist_is '2016-09-10 14:00:00' => [qw//];
eligible_ownerlist_is '2016-09-05 13:00:00' => [qw//], 'holiday';

add_user 'Afternoon1', 'Afternoon';
eligible_ownerlist_is '2016-09-08 10:00:00' => [qw/Morning1/];
eligible_ownerlist_is '2016-09-08 13:00:00' => [qw/Morning1 Afternoon1/];
eligible_ownerlist_is '2016-09-08 16:00:00' => [qw/Afternoon1/];
eligible_ownerlist_is '2016-09-10 14:00:00' => [qw//];
eligible_ownerlist_is '2016-09-05 13:00:00' => [qw//], 'holiday';

add_user 'Weekend1', 'Weekend';
eligible_ownerlist_is '2016-09-08 10:00:00' => [qw/Morning1/];
eligible_ownerlist_is '2016-09-08 13:00:00' => [qw/Morning1 Afternoon1/];
eligible_ownerlist_is '2016-09-08 16:00:00' => [qw/Afternoon1/];
eligible_ownerlist_is '2016-09-10 14:00:00' => [qw/Weekend1/];
eligible_ownerlist_is '2016-09-05 13:00:00' => [qw//], 'holiday';

add_user 'Unscheduled2', undef;
add_user 'Morning2', 'Morning';
add_user 'Afternoon2', 'Afternoon';
add_user 'Weekend2', 'Weekend';
eligible_ownerlist_is '2016-09-08 10:00:00' => [qw/Morning1 Morning2/];
eligible_ownerlist_is '2016-09-08 13:00:00' => [qw/Morning1 Morning2 Afternoon1 Afternoon2/];
eligible_ownerlist_is '2016-09-08 16:00:00' => [qw/Afternoon1 Afternoon2/];
eligible_ownerlist_is '2016-09-10 14:00:00' => [qw/Weekend1 Weekend2/];
eligible_ownerlist_is '2016-09-05 13:00:00' => [qw//], 'holiday';

# test boundaries of the business hours
eligible_ownerlist_is '2016-09-08 07:59:59' => [qw//];
eligible_ownerlist_is '2016-09-08 08:00:00' => [qw/Morning1 Morning2/];
eligible_ownerlist_is '2016-09-08 08:00:01' => [qw/Morning1 Morning2/];
eligible_ownerlist_is '2016-09-08 12:59:59' => [qw/Morning1 Morning2/];
eligible_ownerlist_is '2016-09-08 13:00:00' => [qw/Morning1 Morning2 Afternoon1 Afternoon2/];
eligible_ownerlist_is '2016-09-08 13:00:01' => [qw/Morning1 Morning2 Afternoon1 Afternoon2/];
eligible_ownerlist_is '2016-09-08 13:29:59' => [qw/Morning1 Morning2 Afternoon1 Afternoon2/];
eligible_ownerlist_is '2016-09-08 13:30:00' => [qw/Afternoon1 Afternoon2/];
eligible_ownerlist_is '2016-09-08 13:30:01' => [qw/Afternoon1 Afternoon2/];
eligible_ownerlist_is '2016-09-08 17:59:59' => [qw/Afternoon1 Afternoon2/];
eligible_ownerlist_is '2016-09-08 18:00:00' => [qw//];
eligible_ownerlist_is '2016-09-08 18:00:01' => [qw//];

done_testing;

