use strict;
use Test::More tests => 1;

use PHP::Session;

my $sid = "newline";
my $save_path = "t";

my $session = PHP::Session->new($sid, { save_path => $save_path });
is $session->get('data'), "foo\nbar";

