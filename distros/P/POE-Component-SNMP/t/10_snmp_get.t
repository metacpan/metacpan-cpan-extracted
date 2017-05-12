use Test::More;

use POE;
use POE::Component::SNMP;

use lib qw(t);
use TestPCS;

my $CONF = do "config.cache";

if( $CONF->{skip_all_tests} ) {
    POE::Kernel->run();
    plan skip_all => 'No SNMP data specified.';
}
else {
    plan tests => 12;
}

$|++;

POE::Session->create
( inline_states =>
  {
    _start      => \&snmp_get_tests,
    _stop       => \&stop_session,
    snmp_get_cb => \&snmp_get_cb,
  },
);

$poe_kernel->run;

ok 1; # clean exit
exit 0;


sub snmp_get_tests {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    POE::Component::SNMP->create(
				 -alias     => 'snmp',
				 -hostname  => $CONF->{hostname} || 'localhost',
				 -community => $CONF->{community}|| 'public',
                                 -debug     => $CONF->{debug},
                                 -retries   => 0,
				);

    $kernel->post( snmp => 'get', 'snmp_get_cb', -varbindlist => ['.1.3.6.1.2.1.1.1.0']);
    get_sent($heap);
    $kernel->post( snmp => 'get', 'snmp_get_cb', -varbindlist => ['.1.3.6.1.2.1.1.2.0']);
    get_sent($heap);
}

# store results for future processing
sub snmp_get_cb {
    my ($kernel, $heap, $aref) = @_[KERNEL, HEAP, ARG1];
    ok get_seen($heap);

    my $href = $aref->[0];
    ok ref $href eq 'HASH'; # no error

    foreach my $k (keys %$href) {
	ok $heap->{results}{$k} = $href->{$k}; # got a result
    }

    if (check_done($heap)) {
	$kernel->post( snmp => 'finish' );
	ok check_done($heap);
    }
}

sub stop_session {
    my $r = $_[HEAP]->{results};
    ok 1; # got here!
    ok ref $r eq 'HASH';

    ok exists($r->{'.1.3.6.1.2.1.1.1.0'});
    ok exists($r->{'.1.3.6.1.2.1.1.2.0'});
}
