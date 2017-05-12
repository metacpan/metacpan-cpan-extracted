use Test::More; # qw/no_plan/;
use strict;

use POE;
use POE::Component::SNMP;

use lib qw(t);
use TestPCS;

my $CONF = do "config.cache";

if ( $CONF->{skip_all_tests} ) {
    POE::Kernel->run();
    plan skip_all => 'No SNMP data specified.';
} else {
    plan tests => 47;
}


POE::Session->create
( inline_states =>
  { _start      => \&snmp_run_tests,
    _stop       => \&stop_session,
    snmp_get_cb => \&snmp_get_cb,
  },
);

$poe_kernel->run;

ok 1; # clean exit
exit 0;

my $sysName = "1.3.6.1.2.1.1.5.0";
my $system_base  = "1.3.6.1.2.1.1";

sub snmp_run_tests {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

  SKIP: {
	skip "parameter checks", 2; # if $ENV{POE_ASSERT_DEFAULT};
	eval {
	    # throws an error because no hostname:
	    POE::Component::SNMP->create(
					 alias     => 'snmp_no_hostname',
					 # hostname  => $CONF->{'hostname'},
					 community => $CONF->{'community'},
					 debug     => $CONF->{debug},

					);
	};

	ok $@, '-hostname parameter required';
	# this asserts that the alias does *not* exist
	ok ! $kernel->alias_resolve( 'snmp_no_hostname' ), "session not created with missing hostname";
    }

    #### dupe sessions:

    # normal session
    POE::Component::SNMP->create( alias     => 'snmp',
                                  hostname  => $CONF->{'hostname'},
                                  community => $CONF->{'community'},
				  timeout   => 2,
                                );
    ok $kernel->alias_resolve('snmp'), "normal session create";

  SKIP: {
	skip "dupe session check not safely trappable", 2
	; #  if $POE::VERSION <= 0.37 and POE::Kernel::ASSERT_DEFAULT;
	#  if exists $ENV{POE_ASSERT_DEFAULT}; # and $POE::VERSION <= 0.34;

	eval
	  {
	      POE::Component::SNMP->create( alias     => 'snmp',
					    hostname  => $CONF->{'hostname'},
					    community => $CONF->{'community'},
					    timeout   => 2,
					  );
	  };

	warn $@;

	ok $@ =~ /'snmp' already exists|'snmp' is in use by another session/, "duplicate alias is fatal";
	ok $kernel->alias_resolve('snmp'), "existing session not affected";

    }

  SKIP: {
	skip "need secondary hostname", 3 unless $CONF->{'hostname2'};

	my $LOCALPORT = 43128;
	eval {
	    POE::Component::SNMP->create( alias     => 'snmp_localport',
					  hostname  => $CONF->{'hostname'},
					  community => $CONF->{'community'},
					  timeout   => 2,
					  localport => $LOCALPORT,
					);
	};

	ok $kernel->alias_resolve('snmp_localport'), "session created with localport $LOCALPORT";

	eval {
	    POE::Component::SNMP->create( alias     => 'snmp_localport_conflict',
					  hostname  => $CONF->{'hostname2'},
					  community => $CONF->{'community2'},
					  timeout   => 2,
					  -localport => $LOCALPORT,
					);
	};

	ok $@ =~ /Address already in use/;

	my $localport_close = 0;
	$localport_close and $kernel->call(snmp_localport => 'finish');	# close the session

      SKIP: {
	    skip "ASSERT_DEFAULT bug", 1 if $ENV{POE_ASSERT_DEFAULT} and $POE::VERSION <= 0.3401;
	    ok !$kernel->alias_resolve('snmp_localport_conflict'), "session NOT created with duplicate localport";
	    $localport_close and ok !$kernel->alias_resolve('snmp_localport'), "session NOT created with duplicate localport";
	}
    }

    $heap->{done} = 0;

    ###
    ### Throw some client-side errors:
    ###

  SKIP: {
        0 and
          skip "client stuff", 3;

        # wants baseoid, NOT varbindlist
        # Invalid argument '-varbindlist'
        $heap->{planned}++;
        $kernel->post(
                      snmp => walk =>
                      'snmp_get_cb',
                      -varbindlist => $sysName,
                     );
	get_sent($heap);

        # doesn't like empty baseoid parameter
        # Expected base OBJECT IDENTIFIER in dotted notation
        $heap->{planned}++;
        $kernel->post(
                      snmp => walk =>
                      'snmp_get_cb',
                      -baseoid => '',
                     );
	get_sent($heap);

        # wants varbindlist, NOT baseoid
        # Invalid argument '-baseoid'
        $heap->{planned}++;
        $kernel->post(
                      snmp => get =>
                      'snmp_get_cb',
                      -baseoid => $system_base,
                     );
	get_sent($heap);

    }

  SKIP: {
	###
	### Now throw some server-side errors:
	###

	0 and
	  skip "server stuff", 5;

	###
	### THIS DOES *NOT* throw an error!
	###
        ##
	## This returns an empty, VALID result hash!
	## NOT to be confused with an empty string.
	$heap->{planned}++;
	$kernel->post(
		      snmp => get =>
		      'snmp_get_cb',
		      -varbindlist => undef,
		     );
	get_sent($heap);


	# doesn't like empty varbindlist
	# Expected array reference for variable-bindings
	$heap->{planned}++;
	$kernel->post(
		      snmp => get =>
		      'snmp_get_cb',
		      -varbindlist => '',
		     );
	get_sent($heap);

	if (0) {
	    # I expected this to complain, like the others, because
	    # sysname isn't an array ref.  It didn't.  I'll figure it
	    # out later.


	    # doesn't like string varbindlist, wants an array ref:
	    # Expected array reference for variable-bindings
	    $heap->{planned}++;
	    $kernel->post(
			  snmp => get =>
			  'snmp_get_cb',
			  -varbindlist => $sysName,
			 );
	}


	# OID value out of range
	# An OBJECT IDENTIFIER must begin with either 0 (ccitt), 1 (iso), or 2 (joint-iso-ccitt)
	$heap->{planned}++;
	$kernel->post(
		      snmp => get =>
		      'snmp_get_cb',
		      -varbindlist => [ '9.9.9.9.9.9.9' ],
		     );

	get_sent($heap);


	# no such variable in this MIB
	# Received noSuchName(2) error-status at error-index 1
	$heap->{planned}++;
	$kernel->post(
		      snmp => get =>
		      'snmp_get_cb',
		      -varbindlist => [ '1.9.9.9.9.9.9' ],
		     );
	get_sent($heap);

    }

  SKIP: {

	###
	### do some bad 'set' requests
	###
	0 and
	  skip "write tests", 3;

	skip "no writeable SNMP device available", 3 + 6 if not $CONF->{wcommunity};

	# I picked this OID at random because I figured it would be readonly:
	# system.sysORTable.sysOREntry.sysORDescr.1
	my $read_only_string_oid = ".1.3.6.1.2.1.1.9.1.3.1";


	# invalid parms for 'set'
	# Expected [OBJECT IDENTIFIER, ASN.1 type, object value] combination
	$heap->{planned}++;
	$kernel->post(
		      snmp => set =>
		      'snmp_get_cb',
		      -varbindlist => [ '1.9.9.9.9.9.9' ],
		     );
	get_sent($heap);

	# invalid parms for 'set'
	# Unknown ASN.1 type [STRING]
	$heap->{planned}++;
	$kernel->post(
		      snmp => set =>
		      'snmp_get_cb',
		      -varbindlist => [ $read_only_string_oid, 'STRING', 'hi mom' ],
		     );
	get_sent($heap);

	# write to a readonly value
	# Received noSuchName(2) error-status at error-index 0
	$heap->{planned}++;
	$kernel->post(
		      snmp => set =>
		      'snmp_get_cb',
		      -varbindlist => [ $read_only_string_oid, 'OCTET_STRING', 'hi mom' ],
		     );
	get_sent($heap);

    }

}

# store results for future processing
sub snmp_get_cb {
    my ($kernel, $heap, $request, $aref) = @_[KERNEL, HEAP, ARG0, ARG1];
    ok get_seen($heap);

    ok ref $aref eq 'ARRAY';

    my $href = $aref->[0];

    if (ref $href) { # got server results
	ok ref $href eq 'HASH'; # no error

	# catch the results of $kernel->post( snmp => get => -varbindlist => undef )
	# which should be: [ {}, '' ]
	if ($request->[2] eq 'get' and
	    $request->[3] eq '-varbindlist' and
	    not defined $request->[4]) {
	    ok keys %$href == 0;

	    # no extra args supplied, we didn't specify any callback_args
            ok @$aref == 1;
	    ok ++$heap->{saw_empty}, "empty_request returned for undef -varbindlist";
	}

	foreach my $k (keys %$href) {
	    ok $heap->{results}{$k} = $href->{$k}, "got a result"; # got a result
	}

    } elsif (defined $href) {
	my $message = $href;

	ok $message, "received error: $message";
    }

    if (check_done($heap)) {
	$kernel->post( snmp => 'finish' );
	ok check_done($heap);

	# INTENTIONALLY double-dealloc. this should be completely harmless.
	$kernel->post( snmp => 'finish' );
    }

    # $kernel->post( snmp => 'finish' ) if ++$heap->{done} == $heap->{planned};

    # INTENTIONALLY double-dealloc
    # $kernel->post( snmp => 'finish' ) if ++$heap->{done} >= $heap->{planned};
}

sub stop_session {
   my $r = $_[HEAP]->{results};
   ok 1; # got here!

   ok $_[HEAP]->{saw_empty};
   ok !(ref $r eq 'HASH');   # $r should be *empty*, this tests generates no value results.
   ok ! keys %$r;


#    # not exported by cygwin?
#    # ok exists($r->{'.1.3.6.1.2.1.1.7.0'});
#    ok exists($r->{'.1.3.6.1.2.1.1.8.0'});
}
