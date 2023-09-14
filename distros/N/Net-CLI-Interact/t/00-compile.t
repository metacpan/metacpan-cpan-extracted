use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 22 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Net/CLI/Interact.pm',
    'Net/CLI/Interact/Action.pm',
    'Net/CLI/Interact/ActionSet.pm',
    'Net/CLI/Interact/Logger.pm',
    'Net/CLI/Interact/Phrasebook.pm',
    'Net/CLI/Interact/Role/Engine.pm',
    'Net/CLI/Interact/Role/FindMatch.pm',
    'Net/CLI/Interact/Role/Iterator.pm',
    'Net/CLI/Interact/Role/Prompt.pm',
    'Net/CLI/Interact/Transport/Base.pm',
    'Net/CLI/Interact/Transport/Loopback.pm',
    'Net/CLI/Interact/Transport/Net_OpenSSH.pm',
    'Net/CLI/Interact/Transport/Platform/Unix.pm',
    'Net/CLI/Interact/Transport/Platform/Win32.pm',
    'Net/CLI/Interact/Transport/Role/ConnectCore.pm',
    'Net/CLI/Interact/Transport/Role/StripControlChars.pm',
    'Net/CLI/Interact/Transport/SSH.pm',
    'Net/CLI/Interact/Transport/Serial.pm',
    'Net/CLI/Interact/Transport/Telnet.pm',
    'Net/CLI/Interact/Transport/Wrapper/Base.pm',
    'Net/CLI/Interact/Transport/Wrapper/IPC_Run.pm',
    'Net/CLI/Interact/Transport/Wrapper/Net_Telnet.pm'
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


