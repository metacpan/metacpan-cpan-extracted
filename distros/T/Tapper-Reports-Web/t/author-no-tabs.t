
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/tapper_reports_web_cgi.pl',
    'bin/tapper_reports_web_create.pl',
    'bin/tapper_reports_web_fastcgi.pl',
    'bin/tapper_reports_web_fastcgi_live.pl',
    'bin/tapper_reports_web_fastcgi_public.pl',
    'bin/tapper_reports_web_server.pl',
    'bin/tapper_reports_web_test.pl',
    'lib/Tapper/Reports/Web.pm',
    'lib/Tapper/Reports/Web/Controller/Base.pm',
    'lib/Tapper/Reports/Web/Controller/Root.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/ContinuousTestruns.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Hardware.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Manual.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Metareports.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Overview.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Preconditions.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Preconditions/Id.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/ReportFile/Id.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Reports.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Reports/Id.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Reports/Tap.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Rss.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Schedule.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Start.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Testplan.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Testplan/Add.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Testplan/Id.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Testruns.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/Testruns/Id.pm',
    'lib/Tapper/Reports/Web/Controller/Tapper/User.pm',
    'lib/Tapper/Reports/Web/Model.pm',
    'lib/Tapper/Reports/Web/Model/TestrunDB.pm',
    'lib/Tapper/Reports/Web/Role/BehaviourModifications/Path.pm',
    'lib/Tapper/Reports/Web/Util.pm',
    'lib/Tapper/Reports/Web/Util/Filter.pm',
    'lib/Tapper/Reports/Web/Util/Filter/Overview.pm',
    'lib/Tapper/Reports/Web/Util/Filter/Report.pm',
    'lib/Tapper/Reports/Web/Util/Filter/Testplan.pm',
    'lib/Tapper/Reports/Web/Util/Filter/Testrun.pm',
    'lib/Tapper/Reports/Web/Util/Report.pm',
    'lib/Tapper/Reports/Web/Util/Testrun.pm',
    'lib/Tapper/Reports/Web/View/JSON.pm',
    'lib/Tapper/Reports/Web/View/Mason.pm',
    't/00-use.t',
    't/01app.t',
    't/02pod.t',
    't/03podcoverage.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/config.t',
    't/config/log4perl_webgui.cfg',
    't/controller-create-kernelboot-usecase.t',
    't/controller_Tapper-ReportFile-Id.t',
    't/controller_Tapper-Reports-Id.t',
    't/controller_Tapper-Reports.t',
    't/controller_Tapper-Schedule.t',
    't/controller_Tapper-Testruns.t',
    't/controller_Tapper.t',
    't/controller_edit_precondition.t',
    't/fixtures/testrundb/report.yml',
    't/fixtures/testrundb/report_util.yml',
    't/fixtures/testrundb/testruns.yml',
    't/model_ReportsDB.t',
    't/util_Tapper-Filter.t',
    't/view_Mason.t'
);

notabs_ok($_) foreach @files;
done_testing;
