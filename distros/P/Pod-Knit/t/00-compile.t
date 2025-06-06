use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.052

use Test::More;

plan tests => 21 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Pod/Knit.pm',
    'Pod/Knit/DOM/Mojo.pm',
    'Pod/Knit/DOM/WebQuery.pm',
    'Pod/Knit/Document.pm',
    'Pod/Knit/Document/Mojo.pm',
    'Pod/Knit/Document/WebQuery.pm',
    'Pod/Knit/Manual.pm',
    'Pod/Knit/Output/Pod.pm',
    'Pod/Knit/Plugin.pm',
    'Pod/Knit/Plugin/Abstract.pm',
    'Pod/Knit/Plugin/Attributes.pm',
    'Pod/Knit/Plugin/Authors.pm',
    'Pod/Knit/Plugin/HeadsToSections.pm',
    'Pod/Knit/Plugin/Legal.pm',
    'Pod/Knit/Plugin/Methods.pm',
    'Pod/Knit/Plugin/NamedSections.pm',
    'Pod/Knit/Plugin/Sort.pm',
    'Pod/Knit/Plugin/Version.pm',
    'Pod/Knit/PodParser.pm',
    'Pod/Knit/Zilla.pm'
);

my @scripts = (
    'bin/podknit'
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


