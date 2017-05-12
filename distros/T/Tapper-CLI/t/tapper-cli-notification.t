#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use YAML::Syck 'Load';
use Test::Deep;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/reportsdb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $id = `$^X -Ilib bin/tapper notification-new --file=t/files/notification.yml --user=sschwigo`;
diag $id;
chomp $id;
like($id, qr/^\d+$/, 'New notification substitution registered');

BAIL_OUT("Can not get subscription id, but is needed for further tests.") if not $id =~ m/^\d+$/;

my $list = `$^X -Ilib bin/tapper notification-list`;
cmp_deeply(Load($list), {
                         comment => "Testrun id 42 finished",
                         event => "testrun_finished",
                         filter => "testrun('id') == 42",
                         id => 1,
                         persist => 1,
                         owner_id => 1,
                        },
           'List of notifications after notification-new');

$id = `$^X -Ilib bin/tapper notification-update --file=t/files/notification_updated.yml --id=$id`;
chomp $id;
like($id, qr/^\d+$/, 'Notification update');

$list = `$^X -Ilib bin/tapper notification-list`;
cmp_deeply(Load($list), { comment => "Testrun id 43 finished",
                          event   => "testrun_finished",
                          filter  => "testrun('id') == 43",
                          id      => 1,
                          persist => 1,
                          owner_id => 1,
                        },
           'List of notifications after notification-update');

`$^X -Ilib bin/tapper notification-del --id=$id`;
$list = `$^X -Ilib bin/tapper notification-list`;
is($list, '','List of notifications after notification-del');


done_testing();
