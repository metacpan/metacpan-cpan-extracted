use strict;
use Test::More tests => 1;

use PHP::Session;

my $sid = "bracket";
my $save_path = "t";

my $session = PHP::Session->new($sid, { save_path => $save_path });
is $session->get('a')->{7}, "foo}bar";


