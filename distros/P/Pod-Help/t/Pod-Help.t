# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Pod-Help.t'

#########################

use Test::More tests => 10;

BEGIN { use_ok('Pod::Help') };

#########################

my $text = `$^X examples/helper1.pl`;
like($text, qr/program output/, 'automatic mode, not triggered');

$text = `$^X examples/helper1.pl -h`;
like($text, qr/pod text/, 'automatic mode, triggered by parameter 1');

$text = `$^X examples/helper1.pl --help`;
like($text, qr/pod text/, 'automatic mode, triggered by parameter 2');

$text = `$^X examples/helper1.pl --wrongparam`;
like($text, qr/pod text/, 'automatic mode, not triggered, manually activated');

$text = `$^X examples/helper2.pl`;
like($text, qr/program output/, 'manual mode, not triggered');

$text = `$^X examples/helper2.pl -h`;
like($text, qr/program output/, 'manual mode, not triggered by parameter 1');

$text = `$^X examples/helper2.pl --help`;
like($text, qr/program output/, 'manual mode, not triggered by parameter 2');

$text = `$^X examples/helper2.pl --wrongparam`;
like($text, qr/pod text/, 'manual mode, not triggered, manually activated');

#########################

ok(1); # so we cannot die after the last test
