#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
BEGIN { require "xt/test_suite.pl" };
use RT::Test testing => 'RT::Extension::TicketLocking', tests => undef;


my ($baseurl, $default_agent) = RT::Test->started_ok;
diag($baseurl);

my $queue = RT::Test->load_or_create_queue( Name => 'General' );
ok $queue && $queue->id, 'loaded or created the queue';

my $test_user = rtir_user();
ok $test_user && $test_user->id, 'loaded or created user';

RT::Test->set_rights(
    Principal => $test_user,
    Right     => [qw(SeeQueue CreateTicket OwnTicket ShowTicket ModifyTicket)],
);

my $agent = default_agent();

my $SUBJECT = "foo " . rand;

my $id = create_ticket($agent, 'General', {Subject => $SUBJECT});
ok $id, 'created a ticket';
my $ticket = RT::Ticket->new(RT::SystemUser());
$ticket->Load($id);
ok $ticket->id, 'loaded ticket '.$id;

$agent->follow_link_ok({text => 'Lock', n => '1'}, "Followed Lock link for Ticket #$id");
$agent->content_like(qr{<div class="locked-by-you.*">\s*You have locked this ticket\.}ims, "Added a hard lock on Ticket $id");
my $lock = $ticket->Locked();
ok( $lock && $lock->Content->{'Type'} eq 'Hard', "Lock is a Hard lock");
sleep 5;    #Otherwise, we run the risk of getting "You have locked this ticket" (see /Elements/ShowLock)
###Testing that the lock stays###

$agent->follow_link_ok({text => 'History', n => '1'}, "Followed History link for Ticket #$id");
$agent->content_like(qr{<div class="locked-by-you.*">\s*You have had this ticket locked for \d+ \w+\.\s*</div>}ims, "Ticket #$id still locked on History page");

$agent->follow_link_ok({text => 'Basics', n => '1'}, "Followed Basics link for Ticket #$id");
$agent->content_like(qr{<div class="locked-by-you.*">\s*You have had this ticket locked for \d+ \w+\.\s*</div>}ims, "Ticket #$id still locked on Basics page");

$agent->follow_link_ok({text => 'Dates', n => '1'}, "Followed Dates link for Ticket #$id");
$agent->content_like(qr{<div class="locked-by-you.*">\s*You have had this ticket locked for \d+ \w+\.\s*</div>}ims, "Ticket #$id still locked on Dates page");

$agent->follow_link_ok({text => 'People', n => '1'}, "Followed People link for Ticket #$id");
$agent->content_like(qr{<div class="locked-by-you.*">\s*You have had this ticket locked for \d+ \w+\.\s*</div>}ims, "Ticket #$id still locked on People page");

$agent->follow_link_ok({text => 'Links', n => '1'}, "Followed Links link for Ticket #$id");
$agent->content_like(qr{<div class="locked-by-you.*">\s*You have had this ticket locked for \d+ \w+\.\s*</div>}ims, "Ticket #$id still locked on Links page");

$agent->follow_link_ok({text => 'Reminders', n => '1'}, "Followed Reminders link for Ticket #$id");
$agent->content_like(qr{<div class="locked-by-you.*">\s*You have had this ticket locked for \d+ \w+\.\s*</div>}ims, "Ticket #$id still locked on Reminders page");

$agent->follow_link_ok({text => 'Jumbo', n => '1'}, "Followed Jumbo link for Ticket #$id");
$agent->content_like(qr{<div class="locked-by-you.*">\s*You have had this ticket locked for \d+ \w+\.\s*</div>}ims, "Ticket #$id still locked on Jumbo page");

$agent->follow_link_ok({text => 'Comment', n => '1'}, "Followed Comment link for Ticket #$id");
$agent->content_like(qr{<div class="locked-by-you.*">\s*You have had this ticket locked for \d+ \w+\.\s*</div>}ims, "Ticket #$id still locked on Comment page");
$agent->form_number(3);
$agent->click('SubmitTicket');
diag("Submitted Comment form") if $ENV{'TEST_VERBOSE'};
$agent->content_like(qr{<div class="locked-by-you.*">\s*You have had this ticket locked for \d+ \w+\.\s*</div>}ims, "Ticket #$id still locked after submitting comment");


$agent->follow_link_ok({text => 'Unlock', n => '1'}, "Followed Unlock link for Ticket #$id");
$agent->content_like(qr{You have unlocked this ticket. It was locked for \d+ \w+\.}ims, "Ticket #$id is not locked");

###Testing auto lock###

$agent->follow_link_ok({text => 'Comment', n => '1'}, "Followed Comment link for Ticket #$id");
$agent->content_like(qr{<div class="locked-by-you.*">\s*You have locked this ticket\.}ims, "Ticket $id is locked");
# Without this, the lock type doesn't seem to refresh, even on successive calls to Locked()
{
    my $ticket = RT::Ticket->new(RT::SystemUser());
    $ticket->Load($id);
    my $lock = $ticket->Locked();
    ok( $lock && $lock->Content->{'Type'} eq 'Auto', "Lock is an Auto lock");
    sleep 1; # submit too fast and Duration is 0
}
$agent->form_number(3);
$agent->click('SubmitTicket');
diag("Submitted Comment form") if $ENV{'TEST_VERBOSE'};
$agent->content_like(qr{<div class="locked-by-you.*">\s*You had this ticket locked for \d+ \w+\. It is now unlocked\.}ims, "Ticket #$id Auto lock is removed");

#removes all user's locks
$agent->follow_link_ok({text => 'Logout', n => '1'}, "Logging out rtir_test_user");

undef $default_agent;
done_testing;
