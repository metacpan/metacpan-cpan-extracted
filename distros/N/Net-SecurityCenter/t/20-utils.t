#!perl -T

use strict;
use warnings;
use Test::More;

require_ok('Net::SecurityCenter::Utils');

foreach my $id ( sort { $a <=> $b } keys %{$Net::SecurityCenter::Utils::NESSUS_SCANNER_STATUS} ) {
    my $name = $Net::SecurityCenter::Utils::NESSUS_SCANNER_STATUS->{$id};
    cmp_ok( Net::SecurityCenter::Utils::sc_decode_scanner_status($id), 'eq', $name, "$id - $name" );
}

cmp_ok( Net::SecurityCenter::Utils::trim(' trimmed '), 'eq', 'trimmed', 'Trimmed text' );

cmp_ok( Net::SecurityCenter::Utils::decamelize('SecurityCenter'), 'eq', 'security_center', 'Decamelize text' );

subtest(
    'SC Schedule' => sub {

        my $sc_schedule_now = Net::SecurityCenter::Utils::sc_schedule( type => 'now' );
        cmp_ok( $sc_schedule_now->{'repeatRule'}, 'eq', 'FREQ=NOW;INTERVAL=1', 'Schedule now' );

        my $sc_schedule_ical = Net::SecurityCenter::Utils::sc_schedule( type => 'ical', start => '19700101T000000Z' );
        cmp_ok( $sc_schedule_ical->{'start'}, 'eq', '19700101T000000Z', 'Start datetime' );

    }
);
done_testing();
