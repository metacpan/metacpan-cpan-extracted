use warnings; 
use strict;

use Test::More;

unless (`which trac-admin`) { plan skip_all => 'You need trac installed to run the tests'; }
plan tests => 30;

use_ok('Net::Trac::Connection');
use_ok('Net::Trac::Ticket');
require 't/setup_trac.pl';

use File::Temp qw(tempfile);


my $tr = Net::Trac::TestHarness->new();
ok($tr->start_test_server(), "The server started!");

my $trac = Net::Trac::Connection->new(
    url      => $tr->url,
    user     => 'hiro',
    password => 'yatta'
);

isa_ok( $trac, "Net::Trac::Connection" );
is($trac->url, $tr->url);
my $ticket = Net::Trac::Ticket->new( connection => $trac);
isa_ok($ticket, 'Net::Trac::Ticket');

can_ok($ticket => '_fetch_new_ticket_metadata');
ok($ticket->_fetch_new_ticket_metadata);
can_ok($ticket => 'create');
ok($ticket->create(summary => 'Summary #1'));

can_ok($ticket, 'load');
ok($ticket->load(1));
like($ticket->state->{'summary'}, qr/Summary #1/);
like($ticket->summary, qr/Summary #1/, "The summary looks correct");

can_ok($ticket => 'update');
ok($ticket->update( comment => 'I like moose.' ), "Creating comment about moose.");
is(@{$ticket->history->entries}, 2, "Got 2 history entries.");
like($ticket->history->entries->[1]->content, qr/I like moose./, "The comment looks correct.");

my ($fh, $filename) = tempfile(SUFFIX => '.txt');
my $alpha = join '', 'A'..'Z';
print $fh "$alpha\n"; # 27 bytes
close $fh;

ok(-e $filename, "temp file exists: $filename");
ok(-s $filename, "temp file has non-zero size");
can_ok($ticket => 'attach');
ok($ticket->attach( file => $filename, description => 'Test description' ), "Attaching file.");
is(@{$ticket->history->entries}, 3, "Got 3 history entries.");
is(@{$ticket->attachments}, 1, "Got one attachment");
is($ticket->attachments->[-1]->size, 27, "Got right size!");
is($ticket->attachments->[-1]->author, 'hiro', "Got right author!");
like($filename, qr/\E@{[$ticket->attachments->[-1]->filename]}\E/, "Got right filename!");
is($ticket->attachments->[-1]->description, 'Test description', "Got right description!");
is($ticket->attachments->[-1]->content, "$alpha\n", "Got right content!");
is($ticket->attachments->[-1]->content_type, "text/plain", "Got right content type!");

