
use Test::More;

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
    plan tests => 19;
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


# $POE::Component::SNMP::Session::Dispatcher::DEBUG = 1;

$poe_kernel->run;

ok 1; # clean exit
exit 0;

my $var = SNMP::Varbind->new( [sysDescr => 0] );

sub snmp_get_tests {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    POE::Component::SNMP::Session->create(
                                          Alias     => 'snmp',
                                          DestHost  => $CONF->{'hostname'} || 'localhost',
                                          Community => $CONF->{'community'} || 'public',
                                          Debug     => $CONF->{debug},
                                         );

    for my $oid (qw/sysDescr.0 sysLocation.0 sysServices.0 Srivathsan.0/) {

        $kernel->post(
                      snmp => 'getnext',
                      'snmp_get_cb',
                      $oid,
                     );
        get_sent($heap);

    }

}

# store results for future processing
sub snmp_get_cb {
    my ($kernel, $heap, $aref) = @_[KERNEL, HEAP, ARG1];
    ok get_seen($heap);

    # use YAML; print Dump { axl => $_[ARG0], axo => $_[ARG1] };

    # my $session = shift @$aref;
    my ($alias, undef, $session, $request, $parms) = @{$_[ARG0]};
    my $result = $aref->[0];

    if (defined $result) {
        ok ref $result eq 'SNMP::VarList', "SNMP::VarList eq " . ref $result; # no error

        foreach my $varlist ($result) {
            ok ref $varlist eq 'SNMP::VarList', ref ($var) . ' is SNMP::VarList';
            # if ref $varlist = 'SNMP::VarList'
            for my $var ( @$varlist ) {
                ok ref $var eq 'SNMP::Varbind', ref ($var) . ' is SNMP::Varbind';
                # varbinds are just array refs

                push @{$heap->{results}{$var->[0]}}, $var->[2]; # got a result
            }
        }

    } else {
        # $result is undef. confirm an error that we expected

        ok $session->{ErrorStr} =~ /^Unknown/, "Saw error message on invalid OID";
        $heap->{results}{$parms} = $session->{ErrorStr};
    }


#     foreach my $k (keys %$result) {
# 	ok $heap->{results}{$k} = $result->{$k}; # got a result
#     }

    if (check_done($heap)) {
	$kernel->post( snmp => 'finish' );
	ok check_done($heap);
    }
}

sub stop_session {
   my $r = $_[HEAP]->{results};
    ok 1; # got here!
    ok ref $r eq 'HASH', 'data type is sane';

   # use YAML; print Dump($_[HEAP]);

   my @results;
   for my $key (keys %$r) {
       push @results, ref $r->{$key} eq 'ARRAY' ? @{$r->{$key}} : $r->{$key};
   }

   ok @results == $_[HEAP]->{get_sent}, "all requests handled";

}
