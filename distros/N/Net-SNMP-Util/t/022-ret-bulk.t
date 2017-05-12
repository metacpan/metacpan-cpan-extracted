use strict;
use warnings;
use Test::More tests => 14;

use Net::SNMP qw(:asn1);
use Net::SNMP::Util qw(:all);
use Data::Dumper;

my ($r,$e,$s);

# Hooking for test ============================================================
{
no warnings;

*{Net::SNMP::_send_pdu} = sub {

    my ( $this ) = @_;
    my %vlist = ();
    my @names = ();
    my %types = ();

    # here, oid .1 has sub oids 1.1, 1.2, ..., 1.10
    # and   oid .2 has sub oids 2.1, 2.2, ..., 2.7

    my $repetition = $this->{_pdu}{_error_index};
    # Net::SNMP::PDU saves repetition here

    my @names0 = @{$this->{_pdu}{_var_bind_names}};

    while ( $repetition-- ){
        for ( my $i=0; $i<=$#names0; $i++ )
        {
            my $oid = $names0[$i];
            my $n = '';
            my $t = OCTET_STRING;
            if ( $oid =~ /^(\d)\.(\d+)$/ ){
                if ( $1 == 1 ){
                    if ( $2<10 ){
                        $n = "$1.".($2+1);
                    } else {
                        $n = $1+1;
                    }
                } else {
                    $n = "$1.".($2+1);
                    if ( $2<7 ){
                    } else {
                        $t = ENDOFMIBVIEW;
                    }
                }
            } else {
                $n = "$oid.1";
            }
            $names0[$i] = $n;
            push @names, $n;
            $vlist{ $n }
                = sprintf("Precure(%s-%d)", $n, $this->{_version}+1 );
            $types{ $n } = $t;
        }
    }
    $this->{_pdu}{_var_bind_list}  = \%vlist;
    $this->{_pdu}{_var_bind_names} = \@names;
    $this->{_pdu}{_var_bind_types} = \%types;

# warn ">", Dumper({ names=>\@names, vlist=>\%vlist, types=>\%types }),"\n";

    return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
};

}
# =============================================================================

#diag( "snmpbulk()/snmpparabulk() return values pattern check" );

# 'hosts' type pattern;
#       hashref  - hosts => { somename => (Net::SNMP | hashref | string) }
#       arrayref - hosts => [ ... ]
#       string   - hosts => "..."
# 'oids' type pattern;
#       hashref  - oids => { somename => (arrayref | string) }
#       arrayref - oids => [ ... ]
#       string   - oids => "..."

# -- 1 --
undef $s;
$s = Net::SNMP->session( -version => "SNMPv2c" );
($r,$e) = snmpbulk(
                    hosts => {
                        "black" => $s,
                        "white" => {
                            -hostname => "localhost",
                            -version  => "SNMPv2c",
                        },
                        "luminous" => "127.0.0.1"
                    },
                    snmp => {
                        -version => "SNMPv2c",
                    },
                    oids => {
                        mepple => "1",
                        mipple => [ "1", "2" ],
                    },
                    -maxrepetitions => 1,
);
ok(
    $r->{black}{mepple}->{5}       eq 'Precure(1.5-2)' &&
    $r->{black}{mipple}[0]->{5}    eq 'Precure(1.5-2)' &&
    $r->{black}{mipple}[1]->{5}    eq 'Precure(2.5-2)' &&
    $r->{white}{mepple}->{5}       eq 'Precure(1.5-2)' &&
    $r->{white}{mipple}[0]->{5}    eq 'Precure(1.5-2)' &&
    $r->{white}{mipple}[1]->{5}    eq 'Precure(2.5-2)' &&
    $r->{luminous}{mepple}->{5}    eq 'Precure(1.5-2)' &&
    $r->{luminous}{mipple}[0]->{5} eq 'Precure(1.5-2)' &&
    $r->{luminous}{mipple}[1]->{5} eq 'Precure(2.5-2)' &&

    $r->{black}{mepple}->{10}       eq 'Precure(1.10-2)' &&
    $r->{black}{mipple}[0]->{10}    eq 'Precure(1.10-2)' &&
    $r->{black}{mipple}[1]->{7}     eq 'Precure(2.7-2)' &&
    $r->{white}{mepple}->{10}       eq 'Precure(1.10-2)' &&
    $r->{white}{mipple}[0]->{10}    eq 'Precure(1.10-2)' &&
    $r->{white}{mipple}[1]->{7}     eq 'Precure(2.7-2)' &&
    $r->{luminous}{mepple}->{10}    eq 'Precure(1.10-2)' &&
    $r->{luminous}{mipple}[0]->{10} eq 'Precure(1.10-2)' &&
    $r->{luminous}{mipple}[1]->{7}  eq 'Precure(2.7-2)' &&

    !defined($r->{black}{mepple}->{11})         &&
    !defined($r->{black}{mipple}[0]->{11})      &&
    !defined($r->{black}{mipple}[1]->{8})       &&
    !defined($r->{white}{mepple}->{11})         &&
    !defined($r->{white}{mipple}[0]->{11})      &&
    !defined($r->{white}{mipple}[1]->{8})       &&
    !defined($r->{luminous}{mepple}->{11})      &&
    !defined($r->{luminous}{mipple}[0]->{11})   &&
    !defined($r->{luminous}{mipple}[1]->{8}),

    "'hosts' => {...}, oids => {...}, repetitions = 1"
);


# -- 2 --
undef $s;
$s = Net::SNMP->session( -version => "SNMPv2c" );
($r,$e) = snmpbulk(
                    hosts => {
                        "black" => $s,
                        "white" => {
                            -hostname => "localhost",
                            -version  => "SNMPv2c",
                        },
                        "luminous" => "127.0.0.1"
                    },
                    snmp => {
                        -version => "SNMPv2c",
                    },
                    oids => {
                        mepple => "1",
                        mipple => [ "1", "2" ],
                    },
                    -maxrepetitions => 3,
);
ok(
    $r->{black}{mepple}->{5}       eq 'Precure(1.5-2)' &&
    $r->{black}{mipple}[0]->{5}    eq 'Precure(1.5-2)' &&
    $r->{black}{mipple}[1]->{5}    eq 'Precure(2.5-2)' &&
    $r->{white}{mepple}->{5}       eq 'Precure(1.5-2)' &&
    $r->{white}{mipple}[0]->{5}    eq 'Precure(1.5-2)' &&
    $r->{white}{mipple}[1]->{5}    eq 'Precure(2.5-2)' &&
    $r->{luminous}{mepple}->{5}    eq 'Precure(1.5-2)' &&
    $r->{luminous}{mipple}[0]->{5} eq 'Precure(1.5-2)' &&
    $r->{luminous}{mipple}[1]->{5} eq 'Precure(2.5-2)' &&

    $r->{black}{mepple}->{10}       eq 'Precure(1.10-2)' &&
    $r->{black}{mipple}[0]->{10}    eq 'Precure(1.10-2)' &&
    $r->{black}{mipple}[1]->{7}     eq 'Precure(2.7-2)' &&
    $r->{white}{mepple}->{10}       eq 'Precure(1.10-2)' &&
    $r->{white}{mipple}[0]->{10}    eq 'Precure(1.10-2)' &&
    $r->{white}{mipple}[1]->{7}     eq 'Precure(2.7-2)' &&
    $r->{luminous}{mepple}->{10}    eq 'Precure(1.10-2)' &&
    $r->{luminous}{mipple}[0]->{10} eq 'Precure(1.10-2)' &&
    $r->{luminous}{mipple}[1]->{7}  eq 'Precure(2.7-2)' &&

    !defined($r->{black}{mepple}->{11})         &&
    !defined($r->{black}{mipple}[0]->{11})      &&
    !defined($r->{black}{mipple}[1]->{8})       &&
    !defined($r->{white}{mepple}->{11})         &&
    !defined($r->{white}{mipple}[0]->{11})      &&
    !defined($r->{white}{mipple}[1]->{8})       &&
    !defined($r->{luminous}{mepple}->{11})      &&
    !defined($r->{luminous}{mipple}[0]->{11})   &&
    !defined($r->{luminous}{mipple}[1]->{8}),

    "'hosts' => {...}, oids => {...}, repetitions = 3"
);


# -- 3 --
$s = Net::SNMP->session( -version => "SNMPv2c" );
($r,$e) = snmpbulk(
                    hosts => {
                        "black" => $s,
                        "white" => {
                            -hostname => "localhost",
                            -version  => "SNMPv2c",
                        },
                        "luminous" => "127.0.0.1"
                    },
                    snmp => {
                        -version => "SNMPv2c",
                    },
                    oids => {
                        mepple => "1",
                        mipple => [ "1", "2" ],
                    },
                    -maxrepetitions => 15,
);
ok(
    $r->{black}{mepple}->{5}       eq 'Precure(1.5-2)' &&
    $r->{black}{mipple}[0]->{5}    eq 'Precure(1.5-2)' &&
    $r->{black}{mipple}[1]->{5}    eq 'Precure(2.5-2)' &&
    $r->{white}{mepple}->{5}       eq 'Precure(1.5-2)' &&
    $r->{white}{mipple}[0]->{5}    eq 'Precure(1.5-2)' &&
    $r->{white}{mipple}[1]->{5}    eq 'Precure(2.5-2)' &&
    $r->{luminous}{mepple}->{5}    eq 'Precure(1.5-2)' &&
    $r->{luminous}{mipple}[0]->{5} eq 'Precure(1.5-2)' &&
    $r->{luminous}{mipple}[1]->{5} eq 'Precure(2.5-2)' &&

    $r->{black}{mepple}->{10}       eq 'Precure(1.10-2)' &&
    $r->{black}{mipple}[0]->{10}    eq 'Precure(1.10-2)' &&
    $r->{black}{mipple}[1]->{7}     eq 'Precure(2.7-2)' &&
    $r->{white}{mepple}->{10}       eq 'Precure(1.10-2)' &&
    $r->{white}{mipple}[0]->{10}    eq 'Precure(1.10-2)' &&
    $r->{white}{mipple}[1]->{7}     eq 'Precure(2.7-2)' &&
    $r->{luminous}{mepple}->{10}    eq 'Precure(1.10-2)' &&
    $r->{luminous}{mipple}[0]->{10} eq 'Precure(1.10-2)' &&
    $r->{luminous}{mipple}[1]->{7}  eq 'Precure(2.7-2)' &&

    !defined($r->{black}{mepple}->{11})         &&
    !defined($r->{black}{mipple}[0]->{11})      &&
    !defined($r->{black}{mipple}[1]->{8})       &&
    !defined($r->{white}{mepple}->{11})         &&
    !defined($r->{white}{mipple}[0]->{11})      &&
    !defined($r->{white}{mipple}[1]->{8})       &&
    !defined($r->{luminous}{mepple}->{11})      &&
    !defined($r->{luminous}{mipple}[0]->{11})   &&
    !defined($r->{luminous}{mipple}[1]->{8}),

    "'hosts' => {...}, oids => {...}, repetitions = 15"
);


# -- 4 --
($r,$e) = snmpbulk( hosts => {
                        "black" => $s,
                        "white" => {
                            -hostname => "localhost",
                            -version  => "2",
                        },
                        "luminous" => "127.0.0.1"
                   },
                   snmp => {
                        -version => "2",
                   },
                   oids => "1",
                    -maxrepetitions => 5
);
ok(
    $r->{black}->{3}    eq 'Precure(1.3-2)' &&
    $r->{white}->{3}    eq 'Precure(1.3-2)' &&
    $r->{luminous}->{3} eq 'Precure(1.3-2)',
    "'hosts' => {...}, with 'snmp', 'oid' => string"
);

# -- 5 --
($r,$e) = snmpbulk( hosts => {
                        "black" => $s,
                        "white" => {
                            -hostname => "localhost",
                            -version  => "SNMPv2",
                        },
                        "luminous" => "127.0.0.1"
                   },
                   oids => [ "1", "2" ],
                    -maxrepetitions => 5
);

ok(
    $r->{black}[0]->{10} eq 'Precure(1.10-2)' &&
    $r->{black}[1]->{7}  eq 'Precure(2.7-2)'  &&
    !defined($r->{black}[1]->{8})             &&

    $r->{white}[0]->{10} eq 'Precure(1.10-2)' &&
    $r->{white}[1]->{7}  eq 'Precure(2.7-2)'  &&
    !defined($r->{white}[1]->{8})             &&

    !defined($r->{luminous}) && $e,

    "'hosts' => {...}, 'oid' => [...]"
);

# -- 6 --
($r,$e) = snmpbulk(
                hosts => [ "localhost", "127.0.0.1" ],
                oids => {
                        porrun => "1",
                        lulun  => [ "1", "2" ],
                },
                snmp  => {
                    -version => "2",
                },
                -maxrepetitions => 5
);
ok(
    $r->{localhost  }{porrun}->{5}   eq 'Precure(1.5-2)' &&
    $r->{localhost  }{lulun}[0]->{5} eq 'Precure(1.5-2)' &&
    $r->{localhost  }{lulun}[1]->{5} eq 'Precure(2.5-2)' &&

    $r->{'127.0.0.1'}{porrun}->{5}   eq 'Precure(1.5-2)' &&
    $r->{'127.0.0.1'}{lulun}[0]->{5} eq 'Precure(1.5-2)' &&
    $r->{'127.0.0.1'}{lulun}[1]->{5} eq 'Precure(2.5-2)',
    "'hosts' => [...], oids => {...}"
);


# -- 7 --
($r,$e) = snmpbulk(
                hosts => [ "localhost", "127.0.0.1" ],
                snmp  => {
                    -version => "2",
                },
                oids  => "2",
                -maxrepetitions => 5
);
ok(
    $r->{localhost  }->{1}    eq 'Precure(2.1-2)' &&
    $r->{'127.0.0.1'}->{2}    eq 'Precure(2.2-2)',
    "'hosts' => [...], with 'snmp', 'oid' => string"
);

# -- 8 --
($r,$e) = snmpbulk(
                hosts => [ "localhost", "127.0.0.1" ],
                oids  => [ "1", "2" ],
                snmp  => {
                    -version => "2",
                },
                -maxrepetitions => 5
);
ok(
    $r->{localhost  }[0]->{5} eq 'Precure(1.5-2)' &&
    $r->{localhost  }[1]->{5} eq 'Precure(2.5-2)' &&

    $r->{'127.0.0.1'}[0]->{5} eq 'Precure(1.5-2)' &&
    $r->{'127.0.0.1'}[1]->{5} eq 'Precure(2.5-2)',
    "'hosts' => [...], 'oid' => [...]"
);


# -- 9 --
($r,$e) = snmpbulk(
                hosts => "localhost",
                oids => {
                        porrun => "1",
                        lulun  => [ "1", "2" ],
                },
                snmp  => {
                    -version => "2",
                },
                -maxrepetitions => 5
);
ok(
    $r->{localhost  }{porrun}->{5}   eq 'Precure(1.5-2)' &&
    $r->{localhost  }{lulun}[0]->{5} eq 'Precure(1.5-2)' &&
    $r->{localhost  }{lulun}[1]->{5} eq 'Precure(2.5-2)',
    "'hosts' => string"
);

# -- 10 --
($r,$e) = snmpbulk(
                hosts => "127.0.0.1",
                snmp  => {
                    -version => "2",
                },
                oids  => "2",
                -maxrepetitions => 5
);
ok(
    $r->{'127.0.0.1'}->{6}  eq 'Precure(2.6-2)',
    "'hosts' => string, with 'snmp', 'oid' => string"
);

# -- 11 --
($r,$e) = snmpbulk(
                hosts => "localhost",
                oids  => [ "1", "2" ],
                snmp  => {
                    -version => "2",
                },
                -maxrepetitions => 5
);
ok(
    $r->{localhost}[0]->{5} eq 'Precure(1.5-2)' &&
    $r->{localhost}[1]->{5} eq 'Precure(2.5-2)',
    "'hosts' => string, 'oid' => [...]"
);


# 'snmp' type without 'host'
# -- 12 --
($r,$e) = snmpbulk(
                snmp => {
                    -hostname => "localhost",
                    -version  => "SNMPv2c",
                },
                oids => {
                    porrun => "1",
                    lulun  => [ "1", "2" ],
                },
                -maxrepetitions => 4
);
ok(
    $r->{porrun}->{5}   eq 'Precure(1.5-2)' &&
    $r->{lulun}[0]->{5} eq 'Precure(1.5-2)' &&
    $r->{lulun}[1]->{5} eq 'Precure(2.5-2)',
    "'snmp' without 'hosts', oids => {...}"
);

# -- 13 --
($r,$e) = snmpbulk(
                snmp => {
                    -hostname => "localhost",
                    -version  => "SNMPv2c",
                },
                oids => "2",
                -maxrepetitions => 5
);
ok(
    $r->{5} eq 'Precure(2.5-2)',
    "'snmp' without 'hosts', oids => string"
);

# -- 14 --
($r,$e) = snmpbulk(
                snmp => {
                    -hostname => "localhost",
                    -version  => "2",
                },
                oids => [ "1", "2" ],
                -maxrepetitions => 5
);
ok(
    $r->[0]->{7} eq 'Precure(1.7-2)' &&
    $r->[1]->{7} eq 'Precure(2.7-2)',
    "'snmp' without 'hosts', oids => [...]"
);


