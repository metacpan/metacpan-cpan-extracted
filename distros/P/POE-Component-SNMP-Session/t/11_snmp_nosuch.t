# use lib q[/home/rob/work/poe/snmp/Component-SNMP/lib];

use Test::More; # qw/no_plan/;

use POE;

use lib qw(t);
use TestPCS;

my $CONF = do "config.cache";

if( $CONF->{skip_all_tests} or not keys %$CONF ) {
    $poe_kernel->run(); # quiets POE::Kernel warning
    plan skip_all => 'No SNMP data specified.';
}
else {
    plan tests => 11;
    require POE::Component::SNMP::Session;
}

# use POE::Component::DebugShell;
# POE::Component::DebugShell->spawn();

POE::Session->create
( inline_states =>
  {
    _start      => \&snmp_get_tests,
    _stop       => \&stop_session,
    snmp_get_cb => \&snmp_get_cb,
  },
);


$poe_kernel->run;

ok 1, "clean exit"; # clean exit
exit 0;


sub snmp_get_tests {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    # $POE::Component::SNMP::Session::Dispatcher::DEBUG = 1;

    POE::Component::SNMP::Session->create(
                                          Alias     => 'snmp',
                                          Version   => 2,
                                          # Version   => 1,
                                          Hostname  =>
                                          # DestHost  => # '10.253.239.129',
                                                       $CONF->{hostname} || 'localhost',
                                          Community => $CONF->{community}|| 'public',
                                          Debug     => $CONF->{debug},
                                          Retries   => 0,
                                          Timeout   => 5 * 1e6, # 5 seconds
                                         );

    # $SNMP::debugging = 2;
    $kernel->post( snmp => 'get', 'snmp_get_cb', new SNMP::VarList(['.1.3.6.1.2.1.1.1.0'], ['.1.3.6.1.2.1.1.9.1.2.99']));
    get_sent($heap);

    if (0) {
        $kernel->post( snmp => 'get', 'snmp_get_cb', 'sysObjectID.0');
        get_sent($heap);
    }
}

# store results for future processing
sub snmp_get_cb {
    my ($kernel, $heap, $aref) = @_[KERNEL, HEAP, ARG1];
    ok get_seen($heap), "get callback invoked";

    # use Spiffy qw/:XXX/; WWW $aref;

    # # my $session = shift @$aref;
    my $href = $aref->[0];
    ok ref $href eq 'SNMP::VarList', 'data type is sane'; # no error

    foreach my $k (@$href) {
	ok $heap->{results}{$k->[0]} = $k->[2], 'got results'; # got a result
    }

    if (check_done($heap)) {
	$kernel->post( snmp => 'finish' );
	ok check_done($heap), 'all done';
    }
}

sub stop_session {
    my $r = $_[HEAP]->{results};
    ok 1, '_stop'; # got here!
    ok ref $r eq 'HASH', '  with results';

    # ok exists($r->{'.1.3.6.1.2.1.1.1.0'}), 'known result';
    # ok exists($r->{'.1.3.6.1.2.1.1.2.0'}), 'known result';

    ok exists($r->{'sysDescr'}), 'known result: sysDescr exists';
    # if I did this right, there is a NOSUCHINSTANCE value for some unkown key.
    delete $r->{'sysDescr'};
    my @good = values %$r;
    ok @good == 1, 'unknown key returns value';
    ok $good[0] eq 'NOSUCHINSTANCE', 'value is NOSUCHINSTANCE';
}
