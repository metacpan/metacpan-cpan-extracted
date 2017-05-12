
use Test::More; #  qw/no_plan/;

# BEGIN { use_ok('POE::Component::SNMP::Session') };

use POE;

use lib qw(t);
use TestPCS;

my $CONF = do "config.cache";

if( $CONF->{skip_all_tests} or not keys %$CONF ) {
    $poe_kernel->run(); # quiets POE::Kernel warning
    plan skip_all => 'No SNMP data specified.';
}
else {
    plan tests => 34;
    require POE::Component::SNMP::Session;
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

ok 1; # clean exit
exit 0;


sub snmp_get_tests {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    POE::Component::SNMP::Session->create(
                                 alias     => 'snmp',
                                 hostname  => $CONF->{'hostname'},
                                 community => $CONF->{'community'},
                                          Version   => '2',
                                 debug     => $CONF->{debug},
                                );
    $kernel->post(
                  snmp => 'getbulk',
                  'snmp_get_cb',
                  # -nonrepeaters => 
                  1,
                  # -maxrepetitions => 
                  8,
                  # -varbindlist => [
                  new SNMP::VarList (['ifNumber'],
                                     ['ifSpeed'], ['ifDescr'],
                                     [ '.1.3.6.1.2.1.1' ])
                  # ],
                 );

    get_sent($heap);
}


# store results for future processing
sub snmp_get_cb {
    my ($kernel, $heap, $aref) = @_[KERNEL, HEAP, ARG1];
    ok get_seen($heap);

    ok ref $aref eq 'ARRAY', ref $aref;

    # my $session = shift @$aref;
    my $href = $aref->[0];
    ok ref $href, ref $href;

    # ok ref $href eq 'ARRAY', 'data type e sane'; # no error

    # use YAML; warn Dump($href);

    # foreach my $k (keys %$href) {
    foreach my $varlist ($href) {
	ok ref $varlist eq 'SNMP::VarList', ref ($varlist) . ' e SNMP::VarList';
        # if ref $varlist = 'SNMP::VarList'
        for my $var ( @$varlist ) {
            ok ref $var eq 'SNMP::Varbind', ref ($var) . ' e SNMP::Varbind';
            # varbinds are just array refs

            push @{$heap->{results}{$var->[0]}}, $var->[2]; # got a result
        }
    }

    if (check_done($heap)) {
	$kernel->post( snmp => 'finish' );
	ok check_done($heap);
    }
}

sub stop_session {
    my $r = $_[HEAP]->{results};
    ok 1;			# got here!

    ok ref $r eq 'HASH';


 SKIP: {
	skip "bad result", 7 unless ref $r eq 'HASH';
	ok keys %$r; # got data!
    }
}
