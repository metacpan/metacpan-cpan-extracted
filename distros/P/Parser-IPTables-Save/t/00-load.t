#!perl -T

use Test::More tests => 7;


use_ok( 'Carp' ); 
require_ok( 'Carp' );

use_ok( 'Tie::File' );
require_ok( 'Tie::File' );

use_ok('Parser::IPTables::Save');
use File::Spec;

my $iptables_save = Parser::IPTables::Save->new(File::Spec->catfile('t', 'iptables-save.out'));
ok($iptables_save);

ok($iptables_save->table('filter') eq 'filter', 'Get correct table');
