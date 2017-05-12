use warnings;
use strict;
use Test::Most tests => 7;
use Siebel::Srvrmgr::Nagios::Config;

my $cfg = Siebel::Srvrmgr::Nagios::Config->new( { file => 't/data/ok.xml' } );

is( $cfg->srvrmgrPath(), 'C:\Siebel\8.1\Client_1\BIN',
    'connection parameter has the correct value' );
is( $cfg->srvrmgrBin(), 'srvrmgr.exe',
    'connection parameter has the correct value' );
is( $cfg->enterprise(), 'foobar',
    'connection parameter has the correct value' );
is( $cfg->gateway(), 'siebelgw', 'connection parameter has the correct value' );
is( $cfg->user(),    'sadmin',   'connection parameter has the correct value' );
is( $cfg->password(), 'sadmin', 'connection parameter has the correct value' );

dies_ok(
    sub { Siebel::Srvrmgr::Nagios::Config->new( { file => 't/data/bad.xml' } ) }
    ,
    'dies dues missing component group configuration'
);
