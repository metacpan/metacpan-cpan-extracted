use strict;

# cgi environment no defined in command line
no warnings 'uninitialized';

use Test::More tests => 3;

BEGIN { use_ok('Nes') };

my $output = `$^X t/test.cgi`;
ok($output =~ /Testing Nes Templates/i,"Nes templates worked");

$output = `$^X t/include.cgi`;
ok($output =~ /Testing Nes Templates/i,"Nes includes worked");
