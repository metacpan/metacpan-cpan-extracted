use strict;
use Test::More tests => 1;

use PHP::Session;

my $session = PHP::Session->new("refcnt", { save_path => "t" });
ok $session;
