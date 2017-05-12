#!/usr/bin/perl
package Alice;
use Net::AIML;
use IO::Prompt;

my $bot = Net::AIML->new(botid=>a84468c2ae36697b); # Gir
my $cid;
while (prompt "You: ") {    
    my ($resp, $id) = $bot->tell($_, $cid);
    print "Alice: $resp\n";
    $cid = $id;
}