
use Test::More;

# BEGIN { use_ok('POE::Component::SNMP::Session') };

use POE;

use lib qw(t);
use TestPCS;

my $sysContact = '.1.3.6.1.2.1.1.4.0';
# my $sysContact = '.1.3.6.1.2.1.1.4.0';
# my $sysContact = 'sysContact';

my $CONF = do "config.cache";

if( $CONF->{skip_all_tests} or not keys %$CONF ) {
    POE::Kernel->run(); # quiets warning: POE::Kernel's run() method was never called.
    plan skip_all => 'No SNMP data specified.';
} elsif ( not length $CONF->{wcommunity} ) {
    POE::Kernel->run(); # quiets warning: POE::Kernel's run() method was never called.
    plan skip_all => 'No write community specified.';
} else {
    plan tests => 23;
    require POE::Component::SNMP::Session;
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

    POE::Component::SNMP::Session->create(
        alias     => 'snmp',
        hostname  => $CONF->{hostname} || 'localhost',
        Community => $CONF->{wcommunity} || 'public',
        Version   => 'snmpv2c',
        debug     => $CONF->{debug},
                                          Retries => 0,
                                          UseNumeric => 1,
    );

    # read it in
    $kernel->post(
        snmp => 'get',
        'snmp_get_cb',
                  # -varbindlist =>
                  [$sysContact],
    );

    get_sent($heap);
}

sub snmp_set_cb {
    my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG1];

    ok set_seen($heap);

    # print Dump { set_cb => $args };

    # my $session = shift @$args;
    my $results = $args->[0];
    ok ref $results eq 'SNMP::VarList'; # no error


    my $received = $results->[0][2] if ref $results eq 'SNMP::VarList';

    if (exists $heap->{$sysContact} and not $heap->{verifying_set}) {
	is $received, $heap->{$sysContact};
    } else {
	is $received, 'support@eli.net';
    }

    if (check_done($heap)) {
	$kernel->post( snmp => 'finish' );
	ok check_done($heap);
    }
}

sub snmp_get_cb {
    my ($kernel, $heap, $args) = @_[KERNEL, HEAP, ARG1];
    # my $session = shift @$args;
    my $results = $args->[0];

    ok get_seen($heap);

    ok ref $results eq 'SNMP::VarList'; # no error
    my $received = $results->[0][2] if ref $results eq 'SNMP::VarList';

    # print Dump { get_cb => $results };

    if (exists $heap->{$sysContact}) {

	# we've stashed the syscontact.
	if (exists $heap->{verifying_set}) {
	    ok 1; # verify came back

	SKIP: {
		skip "bad get", 2 unless ref $results eq 'SNMP::VarList';
		ok ref $results eq 'SNMP::VarList'; # no error

                # $heap->{$sysContact} = $results->[0][2];
		is $received, 'support@eli.net', 'set succeeded';
	    }

	    delete $heap->{verifying_set};

	    # set it BACK
	    $kernel->post( snmp => set =>
			   'snmp_set_cb',
			   # -varbindlist => 
                           # [$sysContact, 'OCTET_STRING', $heap->{$sysContact}],
                           $sysContact, $heap->{$sysContact},
			 );
	    set_sent($heap);

	    # read it back!
	    $kernel->post( snmp => get =>
			   'snmp_get_cb',
			   # -varbindlist => 
                           [$sysContact],
			 );
	    get_sent($heap);

	} else {

	    ok 1; # restore got this far
	    # verifying restore
	SKIP: {
		skip "bad get", 2 unless ref $results eq 'SNMP::VarList';
		ok ref $results eq 'SNMP::VarList'; # no error
		is $received, $heap->{$sysContact};
	    }

	}
    } else {

	ok 1; # got first result

    SKIP: {
	    skip "bad get", 1 unless ref $results eq 'SNMP::VarList';
	    ok ref $results eq 'SNMP::VarList';
	    # about to do a set. save this for later.
	    $heap->{$sysContact} = $received;

	    # is $results->{$sysContact}, 'support@eli.net';
	    ok defined $heap->{$sysContact};
	}

	# set it
	$kernel->post(
		      snmp => 'set',
		      'snmp_set_cb',
		      # -varbindlist => [$sysContact, 'OCTET_STRING', 'test@test.com'],
		      # -varbindlist =>
                      $sysContact, 'support@eli.net',
                        # [$sysContact, 'OCTET_STRING', 'support@eli.net'],
		     );

	set_sent($heap);

	# read it back!
	$kernel->post(
		      snmp => 'get',
		      'snmp_get_cb',
		      # -varbindlist =>
                      [$sysContact],
		     );
	get_sent($heap);

	$heap->{verifying_set}++;
    }

    if (check_done($heap)) {
	$kernel->post( snmp => 'finish' );
	ok check_done($heap);
    }

}
