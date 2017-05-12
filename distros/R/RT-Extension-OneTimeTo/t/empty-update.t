#!/usr/bin/perl
use strict;
use warnings;

use RT::Test tests => 7, testing => 'RT::Extension::OneTimeTo';

my $ticket = RT::Ticket->new(RT->SystemUser);
my ($ok, $txn, $msg) = $ticket->Create( Subject => 'testing', Queue => 'General' );

ok $ok, $msg;
ok $txn;
ok $ticket->id, "created ticket";

($ok, $msg, $txn) = $ticket->_RecordNote( Content => '' );
ok !$ok, "can't record note without content or mimeobj ($msg)";

