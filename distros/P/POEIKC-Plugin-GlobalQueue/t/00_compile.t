use strict;
use Test::More tests => 3;

SKIP: {
	eval q{ use POEIKC::Daemon };
    skip "POEIKC::Daemon is not installed.", 1 if $@;
	use_ok 'POEIKC::Plugin::GlobalQueue';
}

BEGIN { use_ok 'POEIKC::Plugin::GlobalQueue::Message' }
BEGIN { use_ok 'POEIKC::Plugin::GlobalQueue::ClientLite' }

