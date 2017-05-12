use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More 0.94;

plan tests => 16;

my @module_files = (
    'MooseX/Runnable.pm',
    'MooseX/Runnable/Invocation.pm',
    'MooseX/Runnable/Invocation/MxRun.pm',
    'MooseX/Runnable/Invocation/Plugin/Debug.pm',
    'MooseX/Runnable/Invocation/Plugin/PAR.pm',
    'MooseX/Runnable/Invocation/Plugin/Profile.pm',
    'MooseX/Runnable/Invocation/Plugin/Restart.pm',
    'MooseX/Runnable/Invocation/Plugin/Restart/Auto.pm',
    'MooseX/Runnable/Invocation/Plugin/Restart/Base.pm',
    'MooseX/Runnable/Invocation/Plugin/Role/CmdlineArgs.pm',
    'MooseX/Runnable/Invocation/Role/WithParsedArgs.pm',
    'MooseX/Runnable/Invocation/Scheme/MooseX/Getopt.pm',
    'MooseX/Runnable/Run.pm',
    'MooseX/Runnable/Util/ArgParser.pm'
);

my @scripts = (
    'script/mx-run'
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

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

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
    my @flags = $1 ? split(' ', $1) : ();

    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, @flags, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', explain(\@warnings);

BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;
