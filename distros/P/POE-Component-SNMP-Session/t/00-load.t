#!perl

use Test::More;
use POE;

$poe_kernel->run();         # quiets POE::Kernel warning

my $CONF = do "config.cache";
if ( $CONF->{skip_all_tests} ) {
    # plan skip_all => 'No SNMP data specified.';
    plan tests => 1;
    ok(1);
    exit;
} else {
    plan tests => 2;
    require_ok( 'POE::Component::SNMP::Session' );
}


# diag( "Testing POE::Component::SNMP::Session $SNMP::Session::POE::VERSION, Perl $], $^X" );
diag( "Testing POE::Component::SNMP::Session $POE::Component::SNMP::Session::VERSION, Perl $], $^X" );

ok (POE::Component::SNMP::Session->can('create'), 'POE constructor exists');

