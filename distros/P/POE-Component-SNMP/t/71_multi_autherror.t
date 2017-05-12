use Test::More; # qw/no_plan/;
use strict;

use POE qw/Component::SNMP/;

use lib qw(t);
use TestPCS;

my $CONF = do "config.cache";

if ( $CONF->{skip_all_tests} ) {
    POE::Kernel->run();
    plan skip_all => 'No SNMP data specified.';
} else {
    if (1) {
        plan tests => 37;
    } else {
        $poe_kernel->run(); # quiets POE::Kernel warning
        plan skip_all => 'not done yet';
    }
}

my %system = ( sysUptime   => '.1.3.6.1.2.1.1.3.0',
               sysName     => '.1.3.6.1.2.1.1.5.0',
               sysLocation => '.1.3.6.1.2.1.1.6.0',
             );

my @oids = # values %system;
  $system{sysName};
my $base_oid = '.1.3.6.1.2.1.1'; # system.*

my $session2 = 1;

sub snmp_run_tests {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    # no warnings;
    POE::Component::SNMP->create(
                                 alias     => 'snmp',
                                 hostname  => $CONF->{'hostname'},
                                 community => $CONF->{'community'},
				 version   => 'snmpv2c',
                                 debug     => $CONF->{debug},
                                 timeout   => 1,
                                 retries   => 0,

                                );
    ok $kernel->alias_resolve( 'snmp' ), "1st session created";
    # use warnings;

  SKIP: {
        skip "only testing with one for now", 1 unless $session2;

        POE::Component::SNMP->create(
                                     alias     => 'snmp_2',
                                     hostname  => $CONF->{'hostname'},
                                     community => 'invalid_community_string_123456789', # $CONF->{'community'},
				     version   => 'snmpv2c',
                                     debug     => $CONF->{debug},
                                     # debug => 0x0A,
                                     timeout   => 1,
                                     retries   => 0,
                                    );


        # ok $@, '-hostname parameter required';
        # this asserts that the alias does *not* exist
        ok $kernel->alias_resolve( 'snmp_2' ), "2nd session created";

    }

    # this next batch of tests sends a certain number of requests from
    # one session to one callback, to another session to the same
    # callback, and then a mix.  success is when the counts come out right.

    # 'walk' takes longer to return than 'get'. So we do it first to
    # arrange that the response to the second request, 'get', comes
    # BEFORE the first request, 'walk'.
    # $kernel->post( snmp => walk => walk_cb => -baseoid => $base_oid ); $heap->{pending}++;
    if ($session2) {
        $kernel->post( snmp_2 => get   => get_cb2   => -varbindlist => \@oids ); $heap->{pending}{snmp_2}++;
	get_sent($heap);

        if (0) {

            # sending two, to see how they queue up
            $kernel->post( snmp_2 => get   => get_cb2   => -varbindlist => [ $system{sysUptime} ] ); $heap->{pending}{snmp_2}++;
            get_sent($heap);

            $kernel->post( snmp_2 => getbulk => walk_cb =>
                           -varbindlist => [ $base_oid ], -maxrepetitions => 8 ); $heap->{pending}{snmp_2}++;
            set_sent($heap);

            $kernel->post( snmp_2 => getbulk => walk_cb2 =>
                           -varbindlist => [ $base_oid ], -maxrepetitions => 8 ); $heap->{pending}{snmp_2}++;
            set_sent($heap);
        }

    }


    $kernel->post( snmp   => get   => get_cb  => -varbindlist => \@oids ); $heap->{pending}{snmp}++;
    get_sent($heap);

    $kernel->post( snmp   => get   => get_cb  => -varbindlist => \@oids ); $heap->{pending}{snmp}++;
    get_sent($heap);

    if (0) {

        $kernel->post( snmp   => get   => get_cb2 => -varbindlist => \@oids ); $heap->{pending}{snmp}++;
        get_sent($heap);

        $kernel->post( snmp => getbulk => walk_cb =>
                       -varbindlist => [ $base_oid ], -maxrepetitions => 8 ); $heap->{pending}{snmp}++;
        set_sent($heap);

        $kernel->post( snmp => getbulk => walk_cb2 =>
                       -varbindlist => [ $base_oid ], -maxrepetitions => 8 ); $heap->{pending}{snmp}++;
        set_sent($heap);
    }
}

sub get_cb {
    my ($kernel, $heap, $request, $response) = @_[KERNEL, HEAP, ARG0, ARG1];
    my ($alias,   $host, $cmd, @args) = @$request;
    my ($results)                     = @$response;

    ok get_seen($heap);

    $heap->{$alias}{$cmd}++;
    push @{$heap->{$alias}{log}}, $cmd;

    ok $cmd eq 'get', "callback destination is preserved (get)";

    if (1) {
        if (ref $results) {
	    ok ref $results eq 'HASH'; # no error
        } else {
            print STDERR "$host SNMP error ($cmd => @args):\n$results\n";
        }
    }

    if (check_done_multi($heap, $alias)) {
	$kernel->post( $alias => 'finish' );
	ok check_done_multi($heap, $alias);
    }

}

# this is the destination of the "invalid community string" request
sub get_cb2 {
    my ($kernel, $heap, $request, $response) = @_[KERNEL, HEAP, ARG0, ARG1];
    my ($alias,   $host, $cmd, @args) = @$request;
    my ($results)                     = @$response;

    ok get_seen($heap);
    ok ref $results ne 'HASH'; # GOT AN ERROR!

    ok ! ref $results, "Invalid community string returns: $results"; # Got a non-reference

    $heap->{$alias}{$cmd}++;
    push @{$heap->{$alias}{log}}, $cmd;

    ok $cmd eq 'get', "callback destination is preserved (get)";

    if (check_done_multi($heap, $alias)) {
	$kernel->post( $alias => 'finish' );
	ok check_done_multi($heap, $alias);
    }

}

sub stop_session {
    my ($heap) = $_[HEAP];
    ok 1; # got here!

    ok exists $heap->{pending};
    ok ref $heap->{pending} eq 'HASH';

    ok exists $heap->{pending}{snmp};
    ok exists $heap->{pending}{snmp_2};
    ok defined $heap->{pending}{snmp};
    ok defined $heap->{pending}{snmp_2};

    ok exists $heap->{snmp};
    ok ref $heap->{snmp} eq 'HASH';
    ok exists $heap->{snmp}{get};
    ok defined $heap->{snmp}{get};
    ok $heap->{snmp}{get} == 2;

    ok exists $heap->{snmp_2};
    ok ref $heap->{snmp_2} eq 'HASH';
    ok exists $heap->{snmp_2}{get};
    ok defined $heap->{snmp_2}{get};
    ok $heap->{snmp_2}{get} == 1;

    no warnings;
    ok $heap->{snmp}{get} + $heap->{snmp}{getbulk} == $heap->{pending}{snmp};
    # ok $heap->{snmp_2}{get} + $heap->{snmp_2}{getbulk} == $heap->{pending}{snmp};

    ok $heap->{snmp}{get} + $heap->{snmp_2}{get} == $heap->{get_seen};
    ok $heap->{snmp}{getbulk} + $heap->{snmp_2}{getbulk} == $heap->{set_seen};

    ok $heap->{snmp}{get} + $heap->{snmp_2}{get} == $heap->{get_sent};
    ok $heap->{snmp}{getbulk} + $heap->{snmp_2}{getbulk} == $heap->{set_sent};

}

### declarations done. let's run it!

POE::Session->create
( inline_states =>
  { _start   => \&snmp_run_tests,
    _stop    => \&stop_session,
    get_cb   => \&get_cb,
    get_cb2  => \&get_cb2,
    walk_cb  => \&walk_cb,
    walk_cb2 => \&walk_cb2,
  },
);

$poe_kernel->run;

ok 1; # clean exit
exit 0;

sub check_done_multi {
    my ($heap, $alias) = @_;
    no warnings;
    return $alias if $heap->{$alias}{get} + $heap->{$alias}{getbulk} == $heap->{pending}{$alias};
}
