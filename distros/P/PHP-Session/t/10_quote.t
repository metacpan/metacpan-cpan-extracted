use strict;
use Test::More tests => 2;

use PHP::Session;

my $sid = "quote";
my $save_path = "t";

my $session = PHP::Session->new($sid, { save_path => $save_path });
is $session->get('a')->{5}, -200;
is $session->get('a')->{6}, "B\";'z";

