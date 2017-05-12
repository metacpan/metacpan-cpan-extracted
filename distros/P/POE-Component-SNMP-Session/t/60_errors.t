use Test::More; # qw/no_plan/;
use strict;

# BEGIN { use_ok 'POE::Component::SNMP::Session' };

use POE;

use lib qw(t);
use TestPCS;

my $CONF = do "config.cache";

if (1) {
    $poe_kernel->run(); # quiets POE::Kernel warning
    plan skip_all => 'todo';
}

if ( $CONF->{skip_all_tests} ) {
    $poe_kernel->run(); # quiets POE::Kernel warning
    plan skip_all => 'No SNMP data specified.';
} else {
    plan tests => 27;
    require POE::Component::SNMP::Session;
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
	skip "parameter checks", 2
           if 0
          ; # if $ENV{POE_ASSERT_DEFAULT};
	eval {
	    # throws an error because no hostname:
	    POE::Component::SNMP::Session->create(
					 Alias     => 'snmp_no_hostname',
					 # DestHost  => $CONF->{'hostname'},
					 Community => $CONF->{'community'},
					 # debug     => $CONF->{debug},

					);
	};

	ok $@, '-hostname parameter required';
	# this asserts that the alias does *not* exist
	ok ! $kernel->alias_resolve( 'snmp_no_hostname' ), "session not created with missing hostname";
    }

    #### dupe sessions:

    # normal session
    POE::Component::SNMP::Session->create( Alias     => 'snmp',
                                  DestHost  => $CONF->{'hostname'},
                                  Community => $CONF->{'community'},
				  # timeout   => 2,
                                );
    ok $kernel->alias_resolve('snmp'), "normal session create";

  SKIP: {
	skip "dupe session check not safely trappable", 2
	 if  $POE::VERSION <= 0.95 and POE::Kernel::ASSERT_DEFAULT;
	#  if exists $ENV{POE_ASSERT_DEFAULT}; # and $POE::VERSION <= 0.34;

	eval
	  {
	      POE::Component::SNMP::Session->create( Alias     => 'snmp',
					    DestHost  => $CONF->{'hostname'},
					    Community => $CONF->{'community'},
					    # timeout   => 2,
					  );
	  };

	# warn $@;

	ok $@ =~ /'snmp' already exists|'snmp' is in use by another session/, "duplicate alias is fatal";
	ok $kernel->alias_resolve('snmp'), "existing session not affected";

    }

  SKIP: {
	skip "need secondary hostname", 3 unless 0!=0 and $CONF->{'hostname2'};

	my $LOCALPORT = 43128;
	eval {
	    POE::Component::SNMP::Session->create( Alias     => 'snmp_localport',
					  DestHost  => $CONF->{'hostname'},
					  Community => $CONF->{'community'},
					  # timeout   => 2,
					  localport => $LOCALPORT,
					);
	};

	ok $kernel->alias_resolve('snmp_localport'), "session created with localport $LOCALPORT";

      SKIP: {
            skip "not tested", 2;

	eval {
	    POE::Component::SNMP::Session->create( Alias     => 'snmp_localport_conflict',
					  DestHost  => $CONF->{'hostname2'},
					  Community => $CONF->{'community2'},
					  # timeout   => 2,
                                                   localport => $LOCALPORT,
					);
	};

	ok $@ =~ /Address already in use/, 'Eval returns Address in use';

	my $localport_close = 0;
	$localport_close and $kernel->call(snmp_localport => 'finish');	# close the session

        # skip "ASSERT_DEFAULT bug", 1 if $ENV{POE_ASSERT_DEFAULT} and $POE::VERSION <= 0.3401;
	    ok !$kernel->alias_resolve('snmp_localport_conflict'), "session NOT created with duplicate localport";
	    $localport_close and ok !$kernel->alias_resolve('snmp_localport'), "session NOT created with duplicate localport";
	}
    }

    $heap->{done} = 0;

    # send a valid request
    $heap->{planned}++;
    $kernel->post(
                  snmp => get =>
                  'snmp_get_cb',
                  # -baseoid =>
                  [$system_base],
                 );
    get_sent($heap);


    ###
    ### Throw some client-side errors:
    ###

  SKIP: {
        1 and
          skip "client stuff", 3;

        # wants baseoid, NOT varbindlist
        # Invalid argument '-varbindlist'
        $heap->{planned}++;
        $kernel->post(
                      snmp => walk =>
                      'snmp_get_cb',
                      # -varbindlist => $sysName,
                      ['sysName']
                     );
	get_sent($heap);

        # doesn't like empty baseoid parameter
        # Expected base OBJECT IDENTIFIER in dotted notation
        $heap->{planned}++;
        $kernel->post(
                      snmp => walk =>
                      'snmp_get_cb',
                      # -baseoid => '',
                      0, 1, ''
                     );
	get_sent($heap);

        # wants varbindlist, NOT baseoid
        # Invalid argument '-baseoid'
        $heap->{planned}++;
        $kernel->post(
                      snmp => get =>
                      'snmp_get_cb',
                      # -baseoid =>
                      0, 1, [$system_base],
                     );
	get_sent($heap);

    }

  SKIP: {
	###
	### Now throw some server-side errors:
	###

	1 and
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
		      # -varbindlist => undef,
                      undef
		     );
	get_sent($heap);


	# doesn't like empty varbindlist
	# Expected array reference for variable-bindings
	$heap->{planned}++;
	$kernel->post(
		      snmp => get =>
		      'snmp_get_cb',
		      # -varbindlist => '',
                      ''
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
			  # -varbindlist => $sysName,
                          $sysName,
			 );
	}


	# OID value out of range
	# An OBJECT IDENTIFIER must begin with either 0 (ccitt), 1 (iso), or 2 (joint-iso-ccitt)
	$heap->{planned}++;
	$kernel->post(
		      snmp => get =>
		      'snmp_get_cb',
		      # -varbindlist =>
                      [ '9.9.9.9.9.9.9' ],
		     );

	get_sent($heap);


	# no such variable in this MIB
	# Received noSuchName(2) error-status at error-index 1
	$heap->{planned}++;
	$kernel->post(
		      snmp => get =>
		      'snmp_get_cb',
		      # -varbindlist =>
                      [ '1.9.9.9.9.9.9' ],
		     );
	get_sent($heap);

    }

  SKIP: {

	###
	### do some bad 'set' requests
	###
	1 and
	  skip "write tests", 3;

	skip "no writeable SNMP device available", 3 + 6 if not length $CONF->{wcommunity};

	# I picked this OID at random because I figured it would be readonly:
	# system.sysORTable.sysOREntry.sysORDescr.1
	my $read_only_string_oid = ".1.3.6.1.2.1.1.9.1.3.1";


	# invalid parms for 'set'
	# Expected [OBJECT IDENTIFIER, ASN.1 type, object value] combination
	$heap->{planned}++;
	$kernel->post(
		      snmp => set =>
		      'snmp_get_cb',
		      # -varbindlist =>
                      [ '1.9.9.9.9.9.9' ],
		     );
	get_sent($heap);

	# invalid parms for 'set'
	# Unknown ASN.1 type [STRING]
	$heap->{planned}++;
	$kernel->post(
		      snmp => set =>
		      'snmp_get_cb',
		      # -varbindlist => 
                      [ $read_only_string_oid, 'STRING', 'hi mom' ],
		     );
	get_sent($heap);

	# write to a readonly value
	# Received noSuchName(2) error-status at error-index 0
	$heap->{planned}++;
	$kernel->post(
		      snmp => set =>
		      'snmp_get_cb',
		      # -varbindlist => 
                      [ $read_only_string_oid, 'OCTET_STRING', 'hi mom' ],
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
	ok ref $href eq 'SNMP::VarList'; # no error

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

        # use YAML; print Dump($href);

        foreach my $varlist ($href) {
            ok ref $varlist eq 'SNMP::VarList', ref ($varlist) . ' e SNMP::VarList';
            # if ref $varlist = 'SNMP::VarList'
            for my $var ( @$varlist ) {
                ok ref $var eq 'SNMP::Varbind', ref ($var) . ' e SNMP::Varbind';
                # varbinds are just array refs

                push @{$heap->{results}{$var->[0]}}, $var->[2]; # got a result
            }
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

   if (0) {
       ok $_[HEAP]->{saw_empty};
       ok !(ref $r eq 'HASH'); # $r should be *empty*, this tests generates no value results.
       ok ! keys %$r;
   }

#    # not exported by cygwin?
#    # ok exists($r->{'.1.3.6.1.2.1.1.7.0'});
#    ok exists($r->{'.1.3.6.1.2.1.1.8.0'});
}
