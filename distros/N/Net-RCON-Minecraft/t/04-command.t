#!perl
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Test::Exception;
use Test::More;
use Local::Helpers;

use Net::RCON::Minecraft;

# We're testing $rcon->command(), not a bunch of Minecraft commands.

# Make random junk of specified length
sub junk { join '', map { chr(rand(26) + ord('a')) } 1..$_[0] }

is cmd(help => 'help!'), 'help!', 'Basic command';
is cmd(foo  => 'bar'),   'bar',   'Consecutive commands';

throws_ok { cmd('', 'ERROR') }
    qr/Command required/, 'Blank command';

# Various fragmentation sizes, including boundary cases
for (qw/80 1024 4095 4096 4097 10240/) {
    my $junk = junk($_);
    is cmd(junk => $junk), $junk, "Frag:$_";
}

throws_ok {
    cmd_full('desync', [ '2:2:desync' => [3, RESPONSE_VALUE, 'whoops' ]]);
} qr/^\QDesync. Expected 2 (0x0002), got 3 (0x0003). Disconnected.\E/;

throws_ok {
    cmd_full('resp', [ '2:2:resp' => [2, 1, 'Wrong response type' ]]);
} qr/^\Qsize:29 id:2 got type 1, not RESPONSE_VALUE(0)\E/;

done_testing;
