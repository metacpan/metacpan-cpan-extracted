use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use POSIX ();
use lib 'lib';
use Peta::Synth::Output::Pulse;

# The client against a sound server of our own: one that speaks the
# PulseAudio native protocol as far as a player needs, asks for the sound in
# portions, and tells what it got. The real server is not touched.

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/native";
my $report = "$dir/report";
my $listen = IO::Socket::UNIX->new(Local => $path, Listen => 1) or die "cannot listen: $!";

my $pid = fork // die "cannot fork: $!";
if (!$pid) {
    alarm 30;
    my $c = $listen->accept or POSIX::_exit(1);
    my ($buffer, %got) = ('', bytes => 0, sound => '', commands => []);
    my $packet = sub ($channel, $payload) { print {$c} pack('N5', length $payload, $channel, 0, 0, 0) . $payload };
    my $reply  = sub ($tag, $body = '') { $packet->(0xFFFFFFFF, 'L' . pack('N', 2) . 'L' . pack('N', $tag) . $body) };
    my $portion = 16000;
    my $owed = 0;
    while (sysread $c, $buffer, 65536, length $buffer) {
        while (length $buffer >= 20) {
            my ($length, $channel) = unpack 'N2', $buffer;
            last if length $buffer < 20 + $length;
            my $payload = substr $buffer, 20, $length;
            substr($buffer, 0, 20 + $length) = '';
            if ($channel != 0xFFFFFFFF) {    # sound
                $got{bytes} += $length;
                $got{sound} .= $payload if length $got{sound} < 64;
                $owed += $length;
                if ($owed >= $portion) { $owed -= $portion; $packet->(0xFFFFFFFF, 'L' . pack('N', 61) . 'L' . pack('N', 0xFFFFFFFF) . 'L' . pack('N', 3) . 'L' . pack('N', $portion)) }
                next;
            }
            my ($command, $tag) = unpack 'x N x N', $payload;
            push @{ $got{commands} }, $command;
            if    ($command == 8)  { $got{cookie} = length($payload) == 10 + 5 + 5 + 256; $reply->($tag, 'L' . pack('N', 35)) }
            elsif ($command == 9)  { $got{name} = $payload =~ /application\.name/; $reply->($tag, 'L' . pack('N', 7)) }
            elsif ($command == 3)  {
                $got{spec} = unpack 'H*', substr $payload, 10, 7;    # 'a', format, channels, rate
                $reply->($tag, join '', map { 'L' . pack('N', $_) } 3, 11, $portion);
            }
            elsif ($command == 12) { $reply->($tag) }
            elsif ($command == 4)  {
                $reply->($tag);
                open my $fh, '>:raw', $report or POSIX::_exit(1);
                print {$fh} join "\n", $got{bytes}, unpack('H*', $got{sound}), $got{spec}, $got{cookie} ? 1 : 0, $got{name} ? 1 : 0, "@{ $got{commands} }";
                close $fh;
                POSIX::_exit(0);
            }
        }
    }
    POSIX::_exit(1);
}
close $listen;
END { if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }

local $ENV{PULSE_SERVER} = "unix:$path";
is(Peta::Synth::Output::Pulse::address(), $path, 'the server PULSE_SERVER names');
ok(Peta::Synth::Output::Pulse::available(), 'is there');

my $out = Peta::Synth::Output::Pulse->new(rate => 48000, latency => 0.1);
is($out->{version}, 32, 'the protocol both speak');
is($out->{channel}, 3, 'the stream the server gave');
my @left  = map { $_ / 1000 } 0 .. 23999;
my @right = map { -$_ / 1000 } 0 .. 23999;
$out->write([ @left[ 0 .. 11999 ] ], [ @right[ 0 .. 11999 ] ]);
$out->write([ @left[ 12000 .. 23999 ] ], [ @right[ 12000 .. 23999 ] ]);
is($out->sent, 0.5, 'half a second sent, as the server asked for it');
$out->close;
waitpid $pid, 0;
my $status = $?;
$pid = 0;
is($status, 0, 'the server saw the stream drained and deleted');

open my $fh, '<', $report or die "no report: $!";
chomp(my @report = <$fh>);
is($report[0], 24000 * 8, 'every byte arrived');
is_deeply([ (unpack 'f<*', pack 'H*', $report[1])[ 0 .. 7 ] ], [ map { unpack 'f', pack 'f', $_ } 0, 0, 0.001, -0.001, 0.002, -0.002, 0.003, -0.003 ],
    'floats, left and right in turn, in order');
is($report[2], unpack('H*', 'a' . pack 'C C N', 5, 2, 48000), 'the sample format: 32-bit floats, two channels, 48 kHz');
is($report[3], 1, 'the cookie sent');
is($report[4], 1, 'the client named');
is($report[5], '8 9 3 12 4', 'auth, name, stream, drain, delete');

done_testing;
