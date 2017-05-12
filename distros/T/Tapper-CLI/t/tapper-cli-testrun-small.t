#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Tapper::Schema::TestTools;
use Tapper::Model 'model';
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------------------------------------

# --------------------------------------------------

my $retval = `$^X -Ilib bin/tapper testrun-list --id=3002 -v`;
like($retval,qr/Id: 3002\s+Topic: old_topic\s+Shortname: ccc2-kernel\s+State: schedule\s+Queue: Kernel\s+Requested Host's: iring\s+Auto rerun: no\s+Notes: ccc2\s+Precondition Id's: 9, 10, 8, 5/, 'List testrun / by id');

$retval = `$^X -Ilib bin/tapper testrun-list --host=iring --schedule`;
is($retval, "3002\n3001\n", 'List testrun / by host, schedule');

done_testing();
