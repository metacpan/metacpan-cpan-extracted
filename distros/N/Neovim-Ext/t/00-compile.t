use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 28 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Neovim/Ext.pm',
    'Neovim/Ext/Buffer.pm',
    'Neovim/Ext/Buffers.pm',
    'Neovim/Ext/Common.pm',
    'Neovim/Ext/Current.pm',
    'Neovim/Ext/ErrorResponse.pm',
    'Neovim/Ext/Funcs.pm',
    'Neovim/Ext/LuaFuncs.pm',
    'Neovim/Ext/MsgPack/RPC.pm',
    'Neovim/Ext/MsgPack/RPC/AsyncSession.pm',
    'Neovim/Ext/MsgPack/RPC/EventLoop.pm',
    'Neovim/Ext/MsgPack/RPC/Response.pm',
    'Neovim/Ext/MsgPack/RPC/Session.pm',
    'Neovim/Ext/MsgPack/RPC/Stream.pm',
    'Neovim/Ext/Plugin.pm',
    'Neovim/Ext/Plugin/Host.pm',
    'Neovim/Ext/Plugin/ScriptHost.pm',
    'Neovim/Ext/Range.pm',
    'Neovim/Ext/Remote.pm',
    'Neovim/Ext/RemoteApi.pm',
    'Neovim/Ext/RemoteMap.pm',
    'Neovim/Ext/RemoteSequence.pm',
    'Neovim/Ext/Tabpage.pm',
    'Neovim/Ext/Tie/Stream.pm',
    'Neovim/Ext/VIMCompat.pm',
    'Neovim/Ext/VIMCompat/Buffer.pm',
    'Neovim/Ext/VIMCompat/Window.pm',
    'Neovim/Ext/Window.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


