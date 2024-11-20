use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 45 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Tapper/Reports/Web.pm',
    'Tapper/Reports/Web/Controller/Base.pm',
    'Tapper/Reports/Web/Controller/Root.pm',
    'Tapper/Reports/Web/Controller/Tapper.pm',
    'Tapper/Reports/Web/Controller/Tapper/ContinuousTestruns.pm',
    'Tapper/Reports/Web/Controller/Tapper/Hardware.pm',
    'Tapper/Reports/Web/Controller/Tapper/Manual.pm',
    'Tapper/Reports/Web/Controller/Tapper/Metareports.pm',
    'Tapper/Reports/Web/Controller/Tapper/Overview.pm',
    'Tapper/Reports/Web/Controller/Tapper/Preconditions.pm',
    'Tapper/Reports/Web/Controller/Tapper/Preconditions/Id.pm',
    'Tapper/Reports/Web/Controller/Tapper/ReportFile/Id.pm',
    'Tapper/Reports/Web/Controller/Tapper/Reports.pm',
    'Tapper/Reports/Web/Controller/Tapper/Reports/Id.pm',
    'Tapper/Reports/Web/Controller/Tapper/Reports/Info.pm',
    'Tapper/Reports/Web/Controller/Tapper/Reports/Tap.pm',
    'Tapper/Reports/Web/Controller/Tapper/Rss.pm',
    'Tapper/Reports/Web/Controller/Tapper/Schedule.pm',
    'Tapper/Reports/Web/Controller/Tapper/Start.pm',
    'Tapper/Reports/Web/Controller/Tapper/Testplan.pm',
    'Tapper/Reports/Web/Controller/Tapper/Testplan/Add.pm',
    'Tapper/Reports/Web/Controller/Tapper/Testplan/Id.pm',
    'Tapper/Reports/Web/Controller/Tapper/Testruns.pm',
    'Tapper/Reports/Web/Controller/Tapper/Testruns/Id.pm',
    'Tapper/Reports/Web/Controller/Tapper/User.pm',
    'Tapper/Reports/Web/Model.pm',
    'Tapper/Reports/Web/Model/TestrunDB.pm',
    'Tapper/Reports/Web/Role/BehaviourModifications/Path.pm',
    'Tapper/Reports/Web/Util.pm',
    'Tapper/Reports/Web/Util/Filter.pm',
    'Tapper/Reports/Web/Util/Filter/Overview.pm',
    'Tapper/Reports/Web/Util/Filter/Report.pm',
    'Tapper/Reports/Web/Util/Filter/Testplan.pm',
    'Tapper/Reports/Web/Util/Filter/Testrun.pm',
    'Tapper/Reports/Web/Util/Report.pm',
    'Tapper/Reports/Web/Util/Testrun.pm',
    'Tapper/Reports/Web/View/JSON.pm',
    'Tapper/Reports/Web/View/Mason.pm'
);

my @scripts = (
    'bin/tapper_reports_web_cgi.pl',
    'bin/tapper_reports_web_create.pl',
    'bin/tapper_reports_web_fastcgi.pl',
    'bin/tapper_reports_web_fastcgi_live.pl',
    'bin/tapper_reports_web_fastcgi_public.pl',
    'bin/tapper_reports_web_server.pl',
    'bin/tapper_reports_web_test.pl'
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


