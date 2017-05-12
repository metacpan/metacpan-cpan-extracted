# use lib q[/home/rob/work/poe/snmp/Component-SNMP/lib];

use Test::More; # qw/no_plan/;

use POE;

use lib qw(t);
use TestPCS;

my $CONF = do "config.cache";

if( $CONF->{skip_all_tests} ) {
    $poe_kernel->run(); # quiets POE::Kernel warning
    plan skip_all => 'No SNMP data specified.';
}
else {
    plan tests => 2;
    eval "use POE::Component::SNMP::Session";
}

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

    POE::Component::SNMP::Session->create(
                                          Alias     => 'snmp',
                                          DestHost  => # '10.253.239.129',
                                                       $CONF->{hostname} || 'localhost',
                                          Community => $CONF->{community}|| 'public',
                                          Debug     => $CONF->{debug},
                                          Retries   => 0,
                                         );



    $kernel->yield('snmp_get_cb');

}





# store results for future processing
sub snmp_get_cb {
    my ($kernel, $heap, $aref) = @_[KERNEL, HEAP, ARG1];

    $kernel->post(snmp => 'finish');

    return;

    # use Spiffy qw/:XXX/; WWW $aref;

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
}
