use warnings;
use strict;
use Test::Most tests => 3;
use Siebel::Srvrmgr;

can_ok( 'Siebel::Srvrmgr', qw(logging_cfg gimme_logger) );

dies_ok { Siebel::Srvrmgr->gimme_logger( [] ) }
'gimme_logger dies with received a non-scalar value as package name';
dies_ok { Siebel::Srvrmgr->gimme_logger('*&%') }
'gimme_logger dies with received a invalid string as package name';
