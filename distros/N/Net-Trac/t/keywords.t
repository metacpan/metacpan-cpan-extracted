use warnings; 
use strict;

use Test::More;

unless (`which trac-admin`) { plan skip_all => 'You need trac installed to run the tests'; }
plan tests => 39;

use_ok('Net::Trac::Connection');
use_ok('Net::Trac::Ticket');
use_ok('Net::Trac::TicketSearch');
require 't/setup_trac.pl';

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
ok($ticket->update( status => 'closed' ), "status = closed");
is(@{$ticket->history->entries}, 2, "Got 2 history entries.");
is($ticket->status, 'closed', "Got updated status");
sleep(1); # I hate trac
{
    
    ok($ticket->update( keywords => 'foo bar' ), "I set the keywords");
is(@{$ticket->history->entries}, 3, "Got 3 history entries.");
my @entries = @{$ticket->history->entries};
my $keywords_change = pop @entries;
my $prop_changes = $keywords_change->prop_changes;
is_deeply ( [keys %$prop_changes], ['keywords']);
my $pc = $prop_changes->{'keywords'};
is ($pc->old_value, '');
is ($pc->new_value, 'bar foo');

}
sleep(1);
{
ok($ticket->update( keywords => 'foo bar baz' ), "I set the keywords");
is(@{$ticket->history->entries}, 4, "Got n history entries.");
my @entries = @{$ticket->history->entries};
my $keywords_change = pop @entries;
my $prop_changes = $keywords_change->prop_changes;
is_deeply ( [keys %$prop_changes], ['keywords'] , "I found the keywords propchange");
my $pc = $prop_changes->{'keywords'};
is ($pc->old_value, 'bar foo');
is ($pc->new_value, 'bar baz foo');


}
sleep(1);
{
ok($ticket->update( keywords => 'baz foo' ), "I set the keywords");
is(@{$ticket->history->entries}, 5, "Got n history entries.");
my @entries = @{$ticket->history->entries};
my $keywords_change = pop @entries;
my $prop_changes = $keywords_change->prop_changes;
is_deeply ( [keys %$prop_changes], ['keywords']);
my $pc = $prop_changes->{'keywords'};
is ($pc->old_value, 'bar baz foo');
is ($pc->new_value, 'baz foo');
}
sleep(1);
{
    #Trac thinks we change from "Baz foo" to "foo baz";
ok($ticket->update( keywords => 'foo baz' ), "I set the keywords");
is(@{$ticket->history->entries}, 6, "Got n history entries.");
my @entries = @{$ticket->history->entries};
my $keywords_change = pop @entries;
my $prop_changes = $keywords_change->prop_changes;
is_deeply ( [keys %$prop_changes], ['keywords']);
my $pc = $prop_changes->{'keywords'};
is ($pc->old_value, 'baz foo');
is ($pc->new_value, 'baz foo');



}


