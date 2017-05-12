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
    plan tests => 40;
}

POE::Session->create
( inline_states =>
  {
    _start         => \&snmp_get_tests,
    _stop          => \&stop_session,
    snmp_get_true  => \&snmp_get_true,
    snmp_get_false => \&snmp_get_false,
    snmp_get_none  => \&snmp_get_none,
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

    my @args;
    @args = (1, 2, 3);

    # set
    $kernel->post( snmp => get => 'snmp_get_true', -varbindlist => ['.1.3.6.1.2.1.1.1.0'], -callback_args => \@args);
    get_sent($heap);

    my @args2 = ('A', 'B', 'C');

    # $kernel->post( snmp => callback_args => @args );
    $kernel->post( snmp => get => 'snmp_get_true', -varbindlist => ['.1.3.6.1.2.1.1.1.0'], -callback_args => \@args2);
    get_sent($heap);

    # $kernel->post( snmp => callback_args => () );

    # false
    $kernel->post( snmp => get => 'snmp_get_false', -varbindlist => ['.1.3.6.1.2.1.1.2.0'], -callback_args => ['']);
    get_sent($heap);

    # false
    $kernel->post( snmp => get => 'snmp_get_false', -varbindlist => ['.1.3.6.1.2.1.1.2.0'], -callback_args => [0]);
    get_sent($heap);

    # false
    $kernel->post( snmp => get => 'snmp_get_false', -varbindlist => ['.1.3.6.1.2.1.1.2.0'], -callback_args => ['0']);
    get_sent($heap);

    # empty
    $kernel->post( snmp => get => 'snmp_get_none',  -varbindlist => ['.1.3.6.1.2.1.1.2.0'], -callback_args => ());
    get_sent($heap);

}

# callback receives a list
sub snmp_get_true {
    my ($kernel, $heap, $aref) = @_[KERNEL, HEAP, ARG1];
    ok get_seen($heap);

    ok ref $aref eq 'ARRAY'; # no error

    my (undef, @args) = @$aref;
    if ($heap->{list_seen} && $heap->{list_seen} == 1) {
        ok @args;
        ok @args == 3;
        ok $args[0] eq 'A';
        ok $args[1] eq 'B';
        ok $args[2] eq 'C';
    } else {
        $heap->{list_seen}++;

        ok @args;
        ok @args == 3;
        ok $args[0] == 1;
        ok $args[1] == 2;
        ok $args[2] == 3;
    }

    if (check_done($heap)) {
	$kernel->post( snmp => 'finish' );
	ok check_done($heap);
    }
}

# callback receives a single false argument
sub snmp_get_false {
    my ($kernel, $heap, $aref) = @_[KERNEL, HEAP, ARG1];
    ok get_seen($heap);

    ok ref $aref eq 'ARRAY'; # no error

    my (undef, @args) = @$aref;

    ok @args;
        ok @args == 1;
        ok $#args == 0;
        ok !$args[0];

    if (check_done($heap)) {
	$kernel->post( snmp => 'finish' );
	ok check_done($heap);
    }
}

sub snmp_get_none {
    my ($kernel, $heap, $aref) = @_[KERNEL, HEAP, ARG1];
    ok get_seen($heap);

    ok ref $aref eq 'ARRAY'; # no error

    my (undef, @args) = @$aref;

    ok $#$aref == 0;
    ok ! @args;
    ok @args == 0;


    if (check_done($heap)) {
	$kernel->post( snmp => 'finish' );
	ok check_done($heap);
    }
}

sub stop_session {
    ok 1; # got here!
}
