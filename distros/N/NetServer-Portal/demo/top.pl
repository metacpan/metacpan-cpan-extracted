#!./perl -w

use strict;
use Event qw(loop);
use NetServer::Portal qw($Port);

for (1..40) { 
    my $i = 1 + rand;
    Event->timer(interval => $i, cb => sub {}, desc => sprintf("%.2f",$i));
}

my $top = NetServer::Portal->default_start();
warn "Listening on port $Port...\n";

loop();
