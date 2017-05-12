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
        plan tests => 60;
    } else {
        $poe_kernel->run(); # quiets POE::Kernel warning
        plan skip_all => 'not done yet';
    }
}

my %system = ( # sysUptime   => '.1.3.6.1.2.1.1.3.0',
               sysName     => '.1.3.6.1.2.1.1.5.0',
               # sysLocation => '.1.3.6.1.2.1.1.6.0',
             );

my @oids = values %system;
my $base_oid = '.1.3.6.1.2.1.1'; # system.*

my $DEBUG_FLAG = 0x00; # none
# my $DEBUG_FLAG = 0x08; # dispatcher
# my $DEBUG_FLAG = 0x0B; # transport+dispatcher
# my $DEBUG_FLAG = 0x1B; # transport+dispatcher+message processing
# my $DEBUG_FLAG = 0xFF; # everything

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

                                 # timeout   => 5,

                                );
    ok $kernel->alias_resolve( 'snmp' ), "1st session created";
    # use warnings;

# #   Failed test in t/70_multi.t at line 246.
# Failed to bind UDP/IPv4 socket: Address already in use at t/70_multi.t line 60
# # Looks like you planned 60 tests but only ran 32.
# # Looks like you failed 24 tests of 32 run.
# # Looks like your test died just after 32.
# t/70_multi..............dubious                                              
#         Test returned status 255 (wstat 65280, 0xff00)
# DIED. FAILED tests 3-26, 33-60
#         Failed 52/60 tests, 13.33% okay


  SKIP: {
        skip "only testing with one for now", 1 unless $session2;

        POE::Component::SNMP->create(
                                     alias     => 'snmp_2',
                                     hostname  => $CONF->{'hostname'},
                                     community => $CONF->{'community'},
				     version   => 'snmpv2c',
                                     debug     => $CONF->{debug},

                                     # timeout   => 5,
                                    );


        # ok $@, '-hostname parameter required';
        # this asserts that the alias does *not* exist
        ok $kernel->alias_resolve( 'snmp_2' ), "2st session created";

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
        $kernel->post( snmp_2 => get   => get_cb   => -varbindlist => \@oids ); $heap->{pending}{snmp_2}++;
	get_sent($heap);

	$kernel->post( snmp_2 => getbulk => walk_cb =>
		       -varbindlist => [ $base_oid ], -maxrepetitions => 8 ); $heap->{pending}{snmp_2}++;
	set_sent($heap);

	$kernel->post( snmp_2 => getbulk => walk_cb2 =>
		       -varbindlist => [ $base_oid ], -maxrepetitions => 8 ); $heap->{pending}{snmp_2}++;
	set_sent($heap);

    }


    $kernel->post( snmp   => get   => get_cb  => -varbindlist => \@oids ); $heap->{pending}{snmp}++;
    get_sent($heap);
    $kernel->post( snmp   => get   => get_cb2 => -varbindlist => \@oids ); $heap->{pending}{snmp}++;
    get_sent($heap);

    $kernel->post( snmp => getbulk => walk_cb =>
		   -varbindlist => [ $base_oid ], -maxrepetitions => 8 ); $heap->{pending}{snmp}++;
    set_sent($heap);

    $kernel->post( snmp => getbulk => walk_cb2 =>
		   -varbindlist => [ $base_oid ], -maxrepetitions => 8 ); $heap->{pending}{snmp}++;
    set_sent($heap);
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

            if (0) {
                print "$host SNMP config ($cmd):\n";
                print "sysName:     $results->{$system{sysName}}\n";
                print "sysUptime:   $results->{$system{sysUptime}}\n";
                print "sysLocation: $results->{$system{sysLocation}}\n";
            }
        } else {
            print STDERR "$host SNMP error ($cmd => @args):\n$results\n";
        }
    }

    if (check_done_multi($heap, $alias)) {
	$kernel->post( $alias => 'finish' );
	ok check_done_multi($heap, $alias);
    }

}

sub get_cb2 {
    my ($kernel, $heap, $request, $response) = @_[KERNEL, HEAP, ARG0, ARG1];
    my ($alias,   $host, $cmd, @args) = @$request;
    my ($results)                     = @$response;

    ok get_seen($heap);
    ok ref $results eq 'HASH'; # no error

    $heap->{$alias}{$cmd}++;
    push @{$heap->{$alias}{log}}, $cmd;

    ok $cmd eq 'get', "callback destination is preserved (get)";

    if (check_done_multi($heap, $alias)) {
	$kernel->post( $alias => 'finish' );
	ok check_done_multi($heap, $alias);
    }

}

sub walk_cb {
    my ($kernel, $heap, $request, $response) = @_[KERNEL, HEAP, ARG0, ARG1];
    my ($alias,   $host, $cmd, @args) = @$request;
    my ($results)                     = @$response;

    ok set_seen($heap);
    ok ref $results eq 'HASH'; # no error

    $heap->{$alias}{$cmd}++;
    push @{$heap->{$alias}{log}}, $cmd;

    ok $cmd eq 'getbulk', "callback destination is preserved (getbulk)";

    # this is for testing aborts in mid-request
    0 and $heap->{pending}{snmp_2} = 0 if $alias eq 'snmp_2';

    if (check_done_multi($heap, $alias)) {
	$kernel->post( $alias => 'finish' );
	ok check_done_multi($heap, $alias);
    }

}

sub walk_cb2 {
    my ($kernel, $heap, $request, $response) = @_[KERNEL, HEAP, ARG0, ARG1];
    my ($alias,   $host, $cmd, @args) = @$request;
    my ($results)                     = @$response;

    ok set_seen($heap);
    ok ref $results eq 'HASH'; # no error

    $heap->{$alias}{$cmd}++;
    push @{$heap->{$alias}{log}}, $cmd;

    ok $cmd eq 'getbulk', "callback destination is preserved (getbulk)";

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
    ok $heap->{pending}{snmp} == 4;
    ok $heap->{pending}{snmp_2} == 4;


    ok exists $heap->{snmp};
    ok ref $heap->{snmp} eq 'HASH';
    ok exists $heap->{snmp}{get};
    ok exists $heap->{snmp}{getbulk};
    ok defined $heap->{snmp}{get};
    ok defined $heap->{snmp}{getbulk};
    ok $heap->{snmp}{get} == 2;
    ok $heap->{snmp}{getbulk} == 2;

    ok exists $heap->{snmp_2};
    ok ref $heap->{snmp_2} eq 'HASH';
    ok exists $heap->{snmp_2}{get};
    ok exists $heap->{snmp_2}{getbulk};
    ok defined $heap->{snmp_2}{get};
    ok defined $heap->{snmp_2}{getbulk};
    ok $heap->{snmp_2}{get} == 2;
    ok $heap->{snmp_2}{getbulk} == 2;

    ok $heap->{snmp}{get} + $heap->{snmp}{getbulk} == $heap->{pending}{snmp};
    ok $heap->{snmp_2}{get} + $heap->{snmp_2}{getbulk} == $heap->{pending}{snmp};

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
