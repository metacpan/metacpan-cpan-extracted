#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 18;

use lib qw(./lib /opt/rt3/local/lib /opt/rt3/lib);

use RT;
RT::LoadConfig;
RT::Init;

my ($id, $msg);
my $RecordTransaction;
my $UpdateLastUpdated;


use_ok('RT::Action::LinearEscalate');
use RT::Action::LinearEscalate;

my $queue_name = "EscalationTest$$"; 
my $queue = RT::Queue->new($RT::SystemUser);
($id, $msg) = $queue->Create( Name => $queue_name );
ok( $id, "Created queue? $msg");

my $user_name = "suer$$";
my $user = RT::User->new($RT::SystemUser);
($id, $msg) = $user->Create( Name => $user_name );
ok( $id, "Created user? $msg");
($id, $msg) = $user->SetPrivileged(1);
ok( $id, "Made user privileged? $msg" );
$user->PrincipalObj->GrantRight( Right => 'SuperUser' );
ok( $id, "Made user a SuperUser? $msg" );
my $current_user = RT::CurrentUser->new($RT::SystemUser);
($id, $msg) = $current_user->Load($user->id);
ok( $id, "Got current user? $msg" );


#defaults
$RecordTransaction = 0;
$UpdateLastUpdated = 1;
my $ticket2 = create_ticket_as_ok($current_user);
escalate_ticket_ok($ticket2);
ok( $ticket2->LastUpdatedBy != $user->id, "Set LastUpdated" );
ok( $ticket2->Transactions->Last->Type =~ /Create/i, "Did not record a transaction" );

$RecordTransaction = 1;
$UpdateLastUpdated = 1;
my $ticket1 = create_ticket_as_ok($current_user);
escalate_ticket_ok($ticket1);
ok( $ticket1->LastUpdatedBy != $user->id, "Set LastUpdated" );
ok( $ticket1->Transactions->Last->Type !~ /Create/i, "Recorded a transaction" );

$RecordTransaction = 0;
$UpdateLastUpdated = 0;
my $ticket3 = create_ticket_as_ok($current_user);
escalate_ticket_ok($ticket3);
ok( $ticket3->LastUpdatedBy == $user->id, "Did not set LastUpdated" );
ok( $ticket3->Transactions->Last->Type =~ /Create/i, "Did not record a transaction" );

1;


sub create_ticket_as_ok {
    my $user = shift;

    my $created = RT::Date->new($RT::SystemUser);
    $created->Unix(time() - ( 7 * 24 * 60**2 ));
    my $due = RT::Date->new($RT::SystemUser);
    $due->Unix(time() + ( 7 * 24 * 60**2 ));

    my $ticket = RT::Ticket->new($user);
    ($id, $msg) = $ticket->Create( Queue => $queue_name,
                                   Subject => "Escalation test",
                                   Priority => 0,
                                   InitialPriority => 0,
                                   FinalPriority => 50,
                                 );
    ok($id, "Created ticket? ".$id);
    $ticket->__Set( Field => 'Created',
                    Value => $created->ISO,
                  );
    $ticket->__Set( Field => 'Due',
                    Value => $due->ISO,
                  );

    return $ticket;
}

sub escalate_ticket_ok {
    my $ticket = shift;
    my $id = $ticket->id;
    print "rt-crontool --search RT::Search::FromSQL --search-arg \"id = @{[$id]}\" --action RT::Action::LinearEscalate --action-arg \"RecordTransaction:$RecordTransaction; UpdateLastUpdated:$UpdateLastUpdated\"\n";
    print STDERR `/opt/rt3/bin/rt-crontool --search RT::Search::FromSQL --search-arg "id = @{[$id]}" --action RT::Action::LinearEscalate --action-arg "RecordTransaction:$RecordTransaction; UpdateLastUpdated:$UpdateLastUpdated"`;

    $ticket->Load($id);     # reload, because otherwise we get the cached value
    ok( $ticket->Priority != 0, "Escalated ticket" );
}
