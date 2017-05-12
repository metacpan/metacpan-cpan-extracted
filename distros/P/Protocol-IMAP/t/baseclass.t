use strict;
use warnings;

use Test::More tests => 5;
use Protocol::IMAP;

my $imap = new_ok('Protocol::IMAP');
can_ok($imap, $_) for qw{debug state write new};

