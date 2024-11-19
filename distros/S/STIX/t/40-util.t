#!perl

use strict;
use warnings;

use Test::More;

use STIX qw(:all);
use STIX::Util;

my $sdo = vulnerability(
    name                => 'CVE-2016-1234',
    external_references => [external_reference(source_name => 'cve', external_id => 'CVE-2016-1234')]
);

my $sco = ipv4_addr(value => '198.51.100.3');

my $sro = sighting(sighting_of_ref => $sdo);

is(is_sdo($sdo), 1, 'Is STIX Domain object');
is(is_sco($sco), 1, 'Is STIX Cyber-observable object');
is(is_sro($sro), 1, 'Is STIX Relationship object');

is(get_type_from_id($sdo->id), 'vulnerability', 'Get type #1');
is(get_type_from_id($sco->id), 'ipv4-addr',     'Get type #2');
is(get_type_from_id($sro->id), 'sighting',      'Get type #3');

done_testing();
