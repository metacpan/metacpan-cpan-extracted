#!perl

use strict;
use warnings;

use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use Test::More;
use Test::Deep;
use Tapper::Cmd::Notification;
use Tapper::Model 'model';


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/reportsdb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $notification = Tapper::Cmd::Notification->new();
isa_ok($notification, 'Tapper::Cmd::Notification');

my $notification_id   = $notification->add({event      => "testrun_finished",
                                            filter  => "testrun('id') == 23",
                                            owner_login => 'anton',
                                            comment    => "Day watch is watching you",
                                            persist    => 0
                                           });
my $notification_rs = model('TestrunDB')->resultset('Notification')->search({id => $notification_id});
is($notification_rs->count, 1, 'Insert notification / notification id returned');


my $notification_id_updated = $notification->update($notification_id, {
                                                                       event      => "report_received",
                                                                       filter     => "updated condition",
                                                                       owner_login => 'alissa',
                                                                       comment    => "Night watch is watching you",
                                                                       persist    => 1,
                                                                      });

is($notification_id_updated, $notification_id, 'Notification updated in place');
my $notification_hash = model('TestrunDB')->resultset('Notification')->find({id => $notification_id_updated}, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' });
ok(defined($notification_hash), 'Update notification / success');
cmp_deeply($notification_hash, superhashof({
                                            'event' => 'report_received',
                                            'persist' => 1,
                                            'comment' => 'Night watch is watching you',
                                            'updated_at' => undef,
                                            'owner_id' => 2,
                                            'id' => 4,
                                            'filter' => 'updated condition'
                                           }), 'Notification updated');

my $error = $notification->del($notification_id);
is($error, 0, 'Delete notification / success');
my $notification_result = model('TestrunDB')->resultset('Notification')->find($notification_id);
is($notification_result, undef, 'Notification subscription really gone');


done_testing();

