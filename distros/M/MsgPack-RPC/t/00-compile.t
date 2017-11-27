use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.052

use Test::More;

plan tests => 26 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'MsgPack/Decoder.pm',
    'MsgPack/Decoder/Event/Decoded.pm',
    'MsgPack/Decoder/Generator.pm',
    'MsgPack/Decoder/Generator/Any.pm',
    'MsgPack/Decoder/Generator/Array.pm',
    'MsgPack/Decoder/Generator/ArraySize.pm',
    'MsgPack/Decoder/Generator/Boolean.pm',
    'MsgPack/Decoder/Generator/Ext.pm',
    'MsgPack/Decoder/Generator/FixInt.pm',
    'MsgPack/Decoder/Generator/Float.pm',
    'MsgPack/Decoder/Generator/Int.pm',
    'MsgPack/Decoder/Generator/Nil.pm',
    'MsgPack/Decoder/Generator/Noop.pm',
    'MsgPack/Decoder/Generator/Size.pm',
    'MsgPack/Decoder/Generator/Str.pm',
    'MsgPack/Decoder/Generator/UInt.pm',
    'MsgPack/Encoder.pm',
    'MsgPack/RPC.pm',
    'MsgPack/RPC/Event/Receive.pm',
    'MsgPack/RPC/Event/Write.pm',
    'MsgPack/RPC/Message.pm',
    'MsgPack/RPC/Message/Notification.pm',
    'MsgPack/RPC/Message/Request.pm',
    'MsgPack/RPC/Message/Response.pm',
    'MsgPack/Type/Boolean.pm',
    'MsgPack/Type/Ext.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


