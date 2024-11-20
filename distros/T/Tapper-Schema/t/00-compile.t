use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 79 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Tapper/RawSQL/ReportsDB/reports.pm',
    'Tapper/RawSQL/TestrunDB/reports.pm',
    'Tapper/RawSQL/TestrunDB/testruns.pm',
    'Tapper/Schema.pm',
    'Tapper/Schema/ReportsDB.pm',
    'Tapper/Schema/TestTools.pm',
    'Tapper/Schema/TestrunDB.pm',
    'Tapper/Schema/TestrunDB/Result/BenchAdditionalRelations.pm',
    'Tapper/Schema/TestrunDB/Result/BenchAdditionalTypeRelations.pm',
    'Tapper/Schema/TestrunDB/Result/BenchAdditionalTypes.pm',
    'Tapper/Schema/TestrunDB/Result/BenchAdditionalValues.pm',
    'Tapper/Schema/TestrunDB/Result/BenchBackupAdditionalRelations.pm',
    'Tapper/Schema/TestrunDB/Result/BenchBackupValues.pm',
    'Tapper/Schema/TestrunDB/Result/BenchSubsumeTypes.pm',
    'Tapper/Schema/TestrunDB/Result/BenchUnits.pm',
    'Tapper/Schema/TestrunDB/Result/BenchValues.pm',
    'Tapper/Schema/TestrunDB/Result/Benchs.pm',
    'Tapper/Schema/TestrunDB/Result/ChartAxisTypes.pm',
    'Tapper/Schema/TestrunDB/Result/ChartLineAdditionals.pm',
    'Tapper/Schema/TestrunDB/Result/ChartLineAxisColumns.pm',
    'Tapper/Schema/TestrunDB/Result/ChartLineAxisElements.pm',
    'Tapper/Schema/TestrunDB/Result/ChartLineAxisSeparators.pm',
    'Tapper/Schema/TestrunDB/Result/ChartLineRestrictionValues.pm',
    'Tapper/Schema/TestrunDB/Result/ChartLineRestrictions.pm',
    'Tapper/Schema/TestrunDB/Result/ChartLines.pm',
    'Tapper/Schema/TestrunDB/Result/ChartMarkings.pm',
    'Tapper/Schema/TestrunDB/Result/ChartTagRelations.pm',
    'Tapper/Schema/TestrunDB/Result/ChartTags.pm',
    'Tapper/Schema/TestrunDB/Result/ChartTinyUrlLines.pm',
    'Tapper/Schema/TestrunDB/Result/ChartTinyUrlRelations.pm',
    'Tapper/Schema/TestrunDB/Result/ChartTinyUrls.pm',
    'Tapper/Schema/TestrunDB/Result/ChartTypes.pm',
    'Tapper/Schema/TestrunDB/Result/ChartVersions.pm',
    'Tapper/Schema/TestrunDB/Result/Charts.pm',
    'Tapper/Schema/TestrunDB/Result/Contact.pm',
    'Tapper/Schema/TestrunDB/Result/DeniedHost.pm',
    'Tapper/Schema/TestrunDB/Result/Host.pm',
    'Tapper/Schema/TestrunDB/Result/HostFeature.pm',
    'Tapper/Schema/TestrunDB/Result/Message.pm',
    'Tapper/Schema/TestrunDB/Result/Notification.pm',
    'Tapper/Schema/TestrunDB/Result/NotificationEvent.pm',
    'Tapper/Schema/TestrunDB/Result/Owner.pm',
    'Tapper/Schema/TestrunDB/Result/PrePrecondition.pm',
    'Tapper/Schema/TestrunDB/Result/Precondition.pm',
    'Tapper/Schema/TestrunDB/Result/Preconditiontype.pm',
    'Tapper/Schema/TestrunDB/Result/Queue.pm',
    'Tapper/Schema/TestrunDB/Result/QueueHost.pm',
    'Tapper/Schema/TestrunDB/Result/Report.pm',
    'Tapper/Schema/TestrunDB/Result/ReportComment.pm',
    'Tapper/Schema/TestrunDB/Result/ReportFile.pm',
    'Tapper/Schema/TestrunDB/Result/ReportSection.pm',
    'Tapper/Schema/TestrunDB/Result/ReportTopic.pm',
    'Tapper/Schema/TestrunDB/Result/ReportgroupArbitrary.pm',
    'Tapper/Schema/TestrunDB/Result/ReportgroupTestrun.pm',
    'Tapper/Schema/TestrunDB/Result/ReportgroupTestrunStats.pm',
    'Tapper/Schema/TestrunDB/Result/Resource.pm',
    'Tapper/Schema/TestrunDB/Result/Scenario.pm',
    'Tapper/Schema/TestrunDB/Result/ScenarioElement.pm',
    'Tapper/Schema/TestrunDB/Result/State.pm',
    'Tapper/Schema/TestrunDB/Result/Suite.pm',
    'Tapper/Schema/TestrunDB/Result/Tap.pm',
    'Tapper/Schema/TestrunDB/Result/TestplanInstance.pm',
    'Tapper/Schema/TestrunDB/Result/Testrun.pm',
    'Tapper/Schema/TestrunDB/Result/TestrunDependency.pm',
    'Tapper/Schema/TestrunDB/Result/TestrunPrecondition.pm',
    'Tapper/Schema/TestrunDB/Result/TestrunRequestedFeature.pm',
    'Tapper/Schema/TestrunDB/Result/TestrunRequestedHost.pm',
    'Tapper/Schema/TestrunDB/Result/TestrunRequestedResource.pm',
    'Tapper/Schema/TestrunDB/Result/TestrunRequestedResourceAlternative.pm',
    'Tapper/Schema/TestrunDB/Result/TestrunScheduling.pm',
    'Tapper/Schema/TestrunDB/Result/Topic.pm',
    'Tapper/Schema/TestrunDB/Result/View010TestrunOverviewReports.pm',
    'Tapper/Schema/TestrunDB/Result/View020TestrunOverview.pm',
    'Tapper/Schema/TestrunDB/ResultSet/Host.pm',
    'Tapper/Schema/TestrunDB/ResultSet/Precondition.pm',
    'Tapper/Schema/TestrunDB/ResultSet/Queue.pm',
    'Tapper/Schema/TestrunDB/ResultSet/ReportgroupTestrun.pm',
    'Tapper/Schema/TestrunDB/ResultSet/Testrun.pm',
    'Tapper/Schema/TestrunDB/ResultSet/TestrunScheduling.pm'
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


