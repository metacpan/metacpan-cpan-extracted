use strict;
use warnings;

use RT::Extension::CommandByMail::Test tests => undef;
my $test = 'RT::Extension::CommandByMail::Test';

my $test_ticket_id;

diag("simple test of the mailgate") if $ENV{'TEST_VERBOSE'};
{
    my $text = <<END;
Subject: test
From: root\@localhost

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    $test_ticket_id = $id;
}

diag("test with umlaut in subject") if $ENV{'TEST_VERBOSE'};
{
    my $text = <<END;
Subject: test =?UTF-8?B?QnJvbnTDqw==?=
From: root\@localhost

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    is($obj->Subject, Encode::decode("UTF-8","test Brontë"), "got correct subject with umlauts");
}

# XXX: use statuses from config/libs
diag("set status on create") if $ENV{'TEST_VERBOSE'};
foreach my $status ( qw(new open resolved) ) {
    my $text = <<END;
Subject: test
From: root\@localhost

Status: $status

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    is($obj->Status, $status, 'set status' );
}

diag("set priority and final_priority on create") if $ENV{'TEST_VERBOSE'};
foreach my $priority ( 10, 20 ) { foreach my $final_priority ( 5, 15, 20 ) {
    my $text = <<END;
Subject: test
From: root\@localhost

Priority: $priority
FinalPriority: $final_priority

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    is($obj->Priority, $priority, 'set priority' );
    is($obj->FinalPriority, $final_priority, 'set final priority' );
} }

diag("ignore multiple leading newlines") if $ENV{'TEST_VERBOSE'};
{
my $priority = 10; 
my $final_priority = 15;
    my $text = <<END;
Subject: test
From: root\@localhost




Priority: $priority

FinalPriority: $final_priority

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    is($obj->Priority, $priority, 'found priority after multiple leading newlines' );
    isnt($obj->FinalPriority, $final_priority, 'did not set final priority' );
}

# XXX: these test are fail as 
diag("set date on create") if $ENV{'TEST_VERBOSE'};
foreach my $field ( qw(Due Starts Started) ) {
    my $value = '2005-12-01 12:34:00';
    my $date_obj = RT::Date->new( $RT::SystemUser );
    $date_obj->Set( Format => 'unknown', Value => $value );

    my $text = <<END;
Subject: test
From: root\@localhost

$field: $value

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    my $method = $field .'Obj';
    is($obj->$method->ISO, $date_obj->ISO, 'set date' );
}

diag("set time on create") if $ENV{'TEST_VERBOSE'};
foreach my $field ( qw(TimeWorked TimeEstimated TimeLeft) ) {
    my $value = int rand 10;
    my $text = <<END;
Subject: test
From: root\@localhost

$field: $value

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    is($obj->$field(), $value, 'set time' );
}


diag("handle multiple time worked statements") if $ENV{'TEST_VERBOSE'};
{
    my $text = <<END;
Subject: multiple TimeWorked test
From: root\@localhost

TimeWorked: 5
TimeWorked: 5

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    is($obj->TimeWorked, 10, 'set time' );
}


diag("set watchers on create") if $ENV{'TEST_VERBOSE'};
foreach my $field ( qw(Requestor Cc AdminCc) ) {
    my $value = 'test@localhost';
    my $text = <<END;
Subject: test
From: root\@localhost

$field: $value

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    my $method = $field .'Addresses';
    is($obj->$method(), $value, 'set '. $field );
}

diag("add requestor on create") if $ENV{'TEST_VERBOSE'};
{
    my $value = 'test@localhost';
    my $text = <<END;
Subject: test
From: root\@localhost

AddRequestor: $value

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    is($obj->RequestorAddresses, "root\@localhost, $value", 'add requestor' );
}

diag("del requestor on create") if $ENV{'TEST_VERBOSE'};
{
    my $text = <<END;
Subject: test
From: root\@localhost

DelRequestor: root\@localhost

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    is($obj->RequestorAddresses, '', 'del requestor' );
}

diag("set links on create") if $ENV{'TEST_VERBOSE'};
foreach my $field ( qw(DependsOn DependedOnBy RefersTo ReferredToBy Members MemberOf) ) {
    my $text = <<END;
Subject: test
From: root\@localhost

$field: $test_ticket_id

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");

    my $links = $obj->$field();
    ok($links, "ticket has links");
    is($links->Count, 1, "one link");

    my $typemap = keys %RT::Link::TYPEMAP ? \%RT::Link::TYPEMAP : $obj->LINKTYPEMAP;
    my $link_type = $typemap->{ $field }->{'Type'};
    my $link_mode = $typemap->{ $field }->{'Mode'};

    my $link = $links->First;
    is($link->Type, $link_type, "correct type");
    isa_ok($link, 'RT::Link');
    my $method = $link_mode .'Obj';
    is($link->$method()->Id, $test_ticket_id, 'set '. $field );
}

diag("set custom fields on create") if $ENV{'TEST_VERBOSE'};
{
    require RT::CustomField;
    my $cf = RT::CustomField->new( $RT::SystemUser );
    my $cf_name = 'test'.rand $$;
    $cf->Create( Name => $cf_name, Queue => 0, Type => 'Freeform' );
    ok($cf->id, "created global CF");

    my $text = <<END;
Subject: test
From: root\@localhost

CustomField.{$cf_name}: foo

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    is($obj->FirstCustomFieldValue($cf_name), 'foo', 'correct cf value' );
}

diag("set custom fields with whitespace on create") if $ENV{'TEST_VERBOSE'};
{
    require RT::CustomField;
    my $cf = RT::CustomField->new( $RT::SystemUser );
    my $cf_name = 'te st'.rand $$;
    $cf->Create( Name => $cf_name, Queue => 0, Type => 'Freeform' );
    ok($cf->id, "created global CF");

    my $text = <<END;
Subject: test
From: root\@localhost

CustomField.{$cf_name}: foo

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    is($obj->FirstCustomFieldValue($cf_name), 'foo', 'correct cf value' );
}

diag("accept watcher as username and email address") if $ENV{'TEST_VERBOSE'};
{
    require RT::Queue;
    require RT::User;

    my $queue_name = "WatcherQueue$$";
    my $queue = RT::Queue->new($RT::SystemUser);
    my ($id, $msg) = $queue->Create( Name => $queue_name );
    ok($id, "Created queue '$queue_name'? $msg");

    require RT::CustomField;
    my $cf = RT::CustomField->new( $RT::SystemUser );
    my $cf_name = 'test'.rand $$;
    $cf->Create( Name => $cf_name, Queue => $queue->Id, Type => 'Freeform' );
    ok($cf->id, "created queue CF");

    my $user_name = "WatcherCommandTest$$";
    my $user_email = "watchercommand$$\@example.com";

    my $user = RT::User->new($RT::SystemUser);
    ($id, $msg) = $user->Create( Name => $user_name, 
                                     EmailAddress => $user_email );
    ok($id, "Created '$user_name'? $msg");
    ($id, $msg) = $user->SetPrivileged(1);
    ($id, $msg) = $user->PrincipalObj->GrantRight( Right => 'OwnTicket',
        Object => $queue );
    ok($id, "Granted 'OwnTicket' to '$user_name'? $msg");
    ($id, $msg) = $user->PrincipalObj->GrantRight( Right => 'Watch',
        Object => $queue );
    ok($id, "Granted 'Watch' to '$user_name'? $msg");

    foreach my $owner ( $user_name, $user_email ) {
        my $text = <<END;
Subject: owner test $$
From: root\@localhost

Queue: $queue_name
Owner: $owner
CF.{$cf_name}: fro'b

owner test
END
        (undef, $id) = $test->send_via_mailgate( $text );
        ok($id, "created ticket");
        my $ticket = RT::Ticket->new($RT::SystemUser);
        $ticket->Load( $id );
        is($ticket->id, $id, "loaded ticket");
        ok( $ticket->IsWatcher( Type => 'Owner', 
            PrincipalId => $user->PrincipalId ), "set '$owner' as Owner"
        );
        is($ticket->FirstCustomFieldValue($cf_name), "fro'b", 'correct cf value' );
    }

    foreach my $cc ( $user_name, $user_email ) {
        my $text = <<END;
Subject: cc test $$
From: root\@localhost

Queue: $queue_name
Cc: $cc

cc test
END
        (undef, $id) = $test->send_via_mailgate( $text );
        ok($id, "created ticket");
        my $ticket = RT::Ticket->new($RT::SystemUser);
        $ticket->Load( $id );
        is($ticket->id, $id, "loaded");
        ok( $ticket->IsWatcher( Type => 'Cc',
            PrincipalId => $user->PrincipalId ), "set '$cc' as Cc" 
        );
    }

}

RT::Config->Set('ParseNewMessageForTicketCcs', 1);
diag("test with ParseNewMessageForTicketCcs set") if $ENV{'TEST_VERBOSE'};
{
    my $text = <<END;
Subject: test
From: root\@localhost

test
END
    my (undef, $id) = $test->send_via_mailgate( $text );
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket");
    $test_ticket_id = $id;
}

done_testing();
