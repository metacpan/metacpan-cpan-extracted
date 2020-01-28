#! perl

use Test::More;

BEGIN {
        use Class::C3;
        use MRO::Compat;
}

use Tapper::Reports::DPath::TT 'render';
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Data::Dumper;

# -------------------- path division --------------------

my $tt = new Tapper::Reports::DPath::TT;
my $result;
my $template;
my $path;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_scheduling_features.yml' );
# -----------------------------------------------------------------------------------------------------------------

diag 'Geht los...';

# -------------------- testrundata (with host info -> does not contain 'schedule')
$template = q|
Testruns:
[% search =  '{ "testrun.topic_name" => "ecc_topic" } :: { rows => 10, order_by =>  { -desc => "testrun.id" } } :: /testrun' -%]
[% res = search.testrundata() -%]
[% FOREACH r IN res -%]
  [% r.testrun_id() %] [% r.status() %]
[% END -%]
|;
$expected = q|
Testruns:
  1002 running
  1001 finished
|;
is($tt->render(template => $template), $expected, "testrundata without testruns in state schedule");

# -------------------- testrundata_nohost (without host info -> contains 'schedule')
$template = q|
Testruns:
[% search =  '{ "testrun.topic_name" => "ecc_topic" } :: { rows => 10, order_by =>  { -desc => "testrun.id" } } :: /testrun' -%]
[% res = search.testrundata_nohost() -%]
[% FOREACH r IN res -%]
  [% r.testrun_id() %] [% r.status() %]
[% END -%]
|;
$expected = q|
Testruns:
  1003 schedule
  1002 running
  1001 finished
|;
is($tt->render(template => $template), $expected, "testrundata_nohost with testruns in state schedule");

# -------------------- testrundata_nohost (without host info -> contains 'schedule')
$template = q|
Testruns:
[% search =  '{ "testrun.topic_name" => "ecc_topic", -or => [ status => "running", status => "finished" ] } :: { rows => 10, order_by =>  { -desc => "testrun.id" } } :: /testrun' -%]
[% res = search.testrundata_nohost() -%]
[% FOREACH r IN res -%]
  [% r.testrun_id() %] [% r.status() %]
[% END -%]
|;
$expected = q|
Testruns:
  1002 running
  1001 finished
|;
is($tt->render(template => $template), $expected, "testrundata_nohost with filtered state");


### END ###
done_testing;
