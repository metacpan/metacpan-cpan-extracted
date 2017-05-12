
use Test::More;

use POE qw/Component::SNMP/;

use lib qw(t);
use TestPCS;

my $sysContact = '.1.3.6.1.2.1.1.4.0';

my $CONF = do "config.cache";

if( $CONF->{skip_all_tests} ) {
    POE::Kernel->run(); # quiets warning: POE::Kernel's run() method was never called.
    plan skip_all => 'No SNMP data specified.';
} elsif ( not $CONF->{wcommunity} ) {
    POE::Kernel->run(); # quiets warning: POE::Kernel's run() method was never called.
    plan skip_all => 'No write community specified.';
} else {
    plan tests => 23;
}

POE::Session->create
( inline_states =>
  {
    _start      => \&snmp_set_tests,
    snmp_set_cb => \&snmp_set_cb,
    snmp_get_cb => \&snmp_get_cb,
  },
);

$poe_kernel->run;

ok 1; # clean exit
exit 0;

# issue an initial get, of the current syscontact.
# get the current syscontact. stash it.
# issue set and get. they run one right after another.
# verify set to test value
# verify got test value
# issue set and get
# verify set to original value
# verify get original value

# extra points for issuing 'finish' at the right moment so your
# program isn't left hanging.

sub snmp_set_tests {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    POE::Component::SNMP->create(
        alias     => 'snmp',
        hostname  => $CONF->{hostname} || 'localhost',
        community => $CONF->{wcommunity} || 'public',
        version   => 'snmpv2c',
        debug     => $CONF->{debug},
    );

    # read it in
    $kernel->post(
        snmp => 'get',
        'snmp_get_cb',
        -varbindlist => [$sysContact],
    );

    get_sent($heap);
}

sub snmp_set_cb {
    my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG1];

    ok set_seen($heap);

    my $results = $args->[0];
    ok ref $results eq 'HASH'; # no error

    if (exists $heap->{$sysContact} and not $heap->{verifying_set}) {
	is $results->{$sysContact}, $heap->{$sysContact};
    } else {
	is $results->{$sysContact}, 'support@eli.net';
    }

    if (check_done($heap)) {
	$kernel->post( snmp => 'finish' );
	ok check_done($heap);
    }
}

sub snmp_get_cb {
    my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG1];
    my $results = $args->[0];

    ok get_seen($heap);

    ok ref $results eq 'HASH'; # no error

    if (exists $heap->{$sysContact}) {

	# we've stashed the syscontact.
	if (exists $heap->{verifying_set}) {
	    ok 1; # verify came back

	SKIP: {
		skip 2, "bad get" unless ref $results eq 'HASH';
		ok ref $results eq 'HASH'; # no error
		is $results->{$sysContact}, 'support@eli.net';
	    }

	    delete $heap->{verifying_set};

	    # set it BACK
	    $kernel->post( snmp => set =>
			   'snmp_set_cb',
			   -varbindlist => [$sysContact, 'OCTET_STRING', $heap->{$sysContact}],
			 );
	    set_sent($heap);

	    # read it back!
	    $kernel->post( snmp => get =>
			   'snmp_get_cb',
			   -varbindlist => [$sysContact],
			 );
	    get_sent($heap);

	} else {

	    ok 1; # restore got this far
	    # verifying restore
	SKIP: {
		skip 2, "bad get" unless ref $results eq 'HASH';
		ok ref $results eq 'HASH'; # no error
		is $results->{$sysContact}, $heap->{$sysContact};
	    }

	}
    } else {

	ok 1; # got first result

    SKIP: {
	    skip 1, "bad get" unless ref $results eq 'HASH';
	    ok ref $results eq 'HASH';
	    # about to do a set. save this for later.
	    $heap->{$sysContact} = $results->{$sysContact};

	    # is $results->{$sysContact}, 'support@eli.net';
	    ok defined $results->{$sysContact};
	}

	# set it
	$kernel->post(
		      snmp => 'set',
		      'snmp_set_cb',
		      # -varbindlist => [$sysContact, 'OCTET_STRING', 'test@test.com'],
		      -varbindlist => [$sysContact, 'OCTET_STRING', 'support@eli.net'],
		     );

	set_sent($heap);

	# read it back!
	$kernel->post(
		      snmp => 'get',
		      'snmp_get_cb',
		      -varbindlist => [$sysContact],
		     );
	get_sent($heap);

	$heap->{verifying_set}++;
    }

    if (check_done($heap)) {
	$kernel->post( snmp => 'finish' );
	ok check_done($heap);
    }

}
