use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 49 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Myriad.pm',
    'Myriad/API.pm',
    'Myriad/Bootstrap.pm',
    'Myriad/Class.pm',
    'Myriad/Commands.pm',
    'Myriad/Config.pm',
    'Myriad/Exception.pm',
    'Myriad/Exception/Base.pm',
    'Myriad/Exception/Builder.pm',
    'Myriad/Exception/General.pm',
    'Myriad/Exception/InternalError.pm',
    'Myriad/Plugin.pm',
    'Myriad/RPC.pm',
    'Myriad/RPC/Client.pm',
    'Myriad/RPC/Client/Implementation/Memory.pm',
    'Myriad/RPC/Client/Implementation/Redis.pm',
    'Myriad/RPC/Implementation/Memory.pm',
    'Myriad/RPC/Implementation/Redis.pm',
    'Myriad/RPC/Message.pm',
    'Myriad/Redis/Pending.pm',
    'Myriad/Registry.pm',
    'Myriad/Role/RPC.pm',
    'Myriad/Role/Storage.pm',
    'Myriad/Role/Subscription.pm',
    'Myriad/Service.pm',
    'Myriad/Service/Attributes.pm',
    'Myriad/Service/Implementation.pm',
    'Myriad/Service/Remote.pm',
    'Myriad/Service/Storage.pm',
    'Myriad/Service/Storage/Remote.pm',
    'Myriad/Storage.pm',
    'Myriad/Storage/Implementation/Memory.pm',
    'Myriad/Storage/Implementation/Redis.pm',
    'Myriad/Subscription.pm',
    'Myriad/Subscription/Implementation/Memory.pm',
    'Myriad/Subscription/Implementation/Redis.pm',
    'Myriad/Transport/HTTP.pm',
    'Myriad/Transport/Memory.pm',
    'Myriad/Transport/PostgreSQL.pm',
    'Myriad/Transport/Redis.pm',
    'Myriad/UI/Readline.pm',
    'Myriad/Util/Defer.pm',
    'Myriad/Util/Secret.pm',
    'Myriad/Util/UUID.pm',
    'Test/Myriad.pm',
    'Test/Myriad/Service.pm',
    'yriad.pm'
);

my @scripts = (
    'bin/myriad-dev.pl',
    'bin/myriad.pl'
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

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    @switches = (@switches, split(' ', $1)) if $1;

    close $fh and skip("$file uses -T; not testable with PERL5LIB", 1)
        if grep { $_ eq '-T' } @switches and $ENV{PERL5LIB};

    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-c', $file))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


