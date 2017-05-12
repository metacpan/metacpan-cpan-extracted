
use strict;
use warnings;

# needed to load the mibfile if /etc/snmp/snmp.conf isn't setup correctly
$ENV{'MIBS'}='+IF-MIB';

use Test::More;
use SNMP::OID::Translate qw (translate translateObj);

my $iftable_tags = [ 'ifDescr','ifSpeed','ifHighSpeed','ifAdminStatus', 'ifAlias' ];

my $output = [
            '.1.3.6.1.2.1.2.2.1.2',
            '.1.3.6.1.2.1.2.2.1.5',
            '.1.3.6.1.2.1.31.1.1.1.15',
            '.1.3.6.1.2.1.2.2.1.7',
            '.1.3.6.1.2.1.31.1.1.1.18'
          ];

is_deeply(translate($iftable_tags), $output, 'Can we translate some things?');
is_deeply(translate(@$iftable_tags), $output, 'Does an array work for translate?');
is_deeply(translate($output), $iftable_tags, 'Can we reverse translate?');

is(translateObj('.1.3.6.1.2.1.2.2.1.2',1),
    '.iso.org.dod.internet.mgmt.mib-2.interfaces.ifTable.ifEntry.ifDescr',
    'Do long_names work?');
is(translateObj('.1.3.6.1.2.1.2.2.1.2',0,1), 'IF-MIB::ifDescr', 'Does MIBNAME prepend work?');
is(translateObj(undef), undef, 'return undef if not defined obj');

# these may not be right
$SNMP::OID::Translate::best_guess=0;
is(translateObj('ifDescr.0'), '.1.3.6.1.2.1.2.2.1.2.0', 'Do dotted lookups work if best_guess=0');
$SNMP::OID::Translate::best_guess=1;
is(translateObj('if.escr'), '.1.3.6.1.2.1.2.2.1.2', 'Do regex lookups work if best_guess=1');
$SNMP::OID::Translate::best_guess=2;
is(translateObj('ifDescr'), '.1.3.6.1.2.1.2.2.1.2', 'Do random access lookups work if best_guess=2');

done_testing();
