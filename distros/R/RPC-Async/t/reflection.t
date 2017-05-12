use strict;
use warnings;

use Test::More tests => 2;
use RPC::Async::Client;
use IO::EventMux;

my $mux = IO::EventMux->new();

# Set the user for the server to run under.
$ENV{'IO_URL_USER'} ||= 'root';

my $rpc = RPC::Async::Client->new($mux, "perl://./test-server.pl") or die;

$rpc->methods(defs => 1, sub {
    my (%ans) = @_;
    #use Data::Dumper;
    #print Dumper(\%ans);
    is($ans{methods}{callback}{in}{'01calls'}, 'integer32', 
        "Check that callback was converted");
    is($ans{methods}{get_id}{out}{'egid'}, 'integer32:pos', 
        "Check that get_id was converted");
});

while ($rpc->has_requests) {
    my $event = $mux->mux;
    $rpc->io($event);
}

$rpc->disconnect;
