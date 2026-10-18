#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::Most tests => 6;

BEGIN { use_ok('Test::Consumer::Contract', qw(run_consumer_contract)) }

can_ok('Test::Consumer::Contract',
	qw(new run run_consumer_contract workspace_present sets_key strip reads_of_results
		documented_accessors scanner_capabilities consumer_path i18n));

throws_ok { Test::Consumer::Contract->new(guaranteed => [qw(x)], producers => {}) }
	qr/needs a 'source'/, 'the source distribution has to be named';

throws_ok { Test::Consumer::Contract->new(source => 'S', producers => {}) }
	qr/needs a 'guaranteed'/, 'the guaranteed keys have to be named';

throws_ok { Test::Consumer::Contract->new(source => 'S', producers => {}, guaranteed => [], ignores => []) }
	qr/does not know the option\(s\): ignores/, 'a misspelt option is an error, not a silently ignored one';

# There is no default: the checker cannot guess what a producer calls the call
# that hands a result back, and a guessed name would quietly find nothing.
throws_ok { Test::Consumer::Contract->new(source => 'S', guaranteed => []) }
	qr/needs a 'methods'/, 'the producing calls have to be named';

done_testing();
