#!/usr/bin/perl
use strict;
use warnings;

use RT::Test tests => 24, testing => 'RT::Extension::OneTimeTo';

my ($baseurl, $m) = RT::Test->started_ok;
ok $m->login, 'logged in';

my $queue = RT::Queue->new($RT::Nobody);
my $qid = $queue->Load('General');
ok( $qid, "Loaded General queue" );

RT::Test->clean_caught_mails;

$m->form_name('CreateTicketInQueue');
$m->field( 'Queue', $qid );
$m->submit;
is( $m->status, 200, "request successful" );
$m->content_like( qr/Create a new ticket/, 'ticket create page' );

$m->form_name('TicketCreate');
$m->field( 'Subject', 'warning man' );
$m->field( 'Content', 'this is main content' );
$m->submit;
is( $m->status, 200, "request successful" );
$m->content_like( qr/warning man/,
    'we have subject on the page' );
$m->content_like( qr/this is main content/, 'main content' );

my ( $mail ) = RT::Test->fetch_caught_mails;
like( $mail, qr/this is main content/, 'email contains main content' );
# check the email link in page too
$m->follow_link_ok( { text => 'Show' }, 'show the email outgoing' );
$m->content_like( qr/this is main content/, 'email contains main content');
$m->back;

$m->follow_link_ok( { text => 'Reply' }, "reply to the ticket" );

$m->form_name('TicketUpdate');
# add UpdateCc so we can get email record
$m->field( 'UpdateTo',      'rt-to-test@example.com' );
$m->field( 'UpdateCc',      'rt-test@example.com' );
$m->field( 'UpdateContent', 'this is main reply content' );
$m->click('SubmitTicket');
is( $m->status, 200, "request successful" );

$m->content_like( qr/this is main reply content/, 'main reply content' );
$m->content_like(qr/RT-Send-CC:.*rt-test\@example.com/s, 'added Cc');
$m->content_like(qr/RT-Send-To:.*rt-to-test\@example.com/s, 'added To');

( $mail ) = RT::Test->fetch_caught_mails;
like( $mail, qr/this is main reply content/, 'email contains main reply content' );
like( $mail, qr/Cc:.*rt-test\@example.com/i, 'email contains Ccs');
like( $mail, qr/To:.*rt-to-test\@example.com/i, 'email contains Tos');

