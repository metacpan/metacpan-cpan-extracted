use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.051

use Test::More;

plan tests => 24 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Protocol/SPDY.pm',
    'Protocol/SPDY/Base.pm',
    'Protocol/SPDY/Client.pm',
    'Protocol/SPDY/Compress.pm',
    'Protocol/SPDY/Constants.pm',
    'Protocol/SPDY/Frame.pm',
    'Protocol/SPDY/Frame/Control.pm',
    'Protocol/SPDY/Frame/Control/CREDENTIAL.pm',
    'Protocol/SPDY/Frame/Control/GOAWAY.pm',
    'Protocol/SPDY/Frame/Control/HEADERS.pm',
    'Protocol/SPDY/Frame/Control/PING.pm',
    'Protocol/SPDY/Frame/Control/RST_STREAM.pm',
    'Protocol/SPDY/Frame/Control/SETTINGS.pm',
    'Protocol/SPDY/Frame/Control/SYN_REPLY.pm',
    'Protocol/SPDY/Frame/Control/SYN_STREAM.pm',
    'Protocol/SPDY/Frame/Control/SynReply.pm',
    'Protocol/SPDY/Frame/Control/SynStream.pm',
    'Protocol/SPDY/Frame/Control/WINDOW_UPDATE.pm',
    'Protocol/SPDY/Frame/Data.pm',
    'Protocol/SPDY/Frame/HeaderSupport.pm',
    'Protocol/SPDY/Server.pm',
    'Protocol/SPDY/Stream.pm',
    'Protocol/SPDY/Test.pm',
    'Protocol/SPDY/Tracer.pm'
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


