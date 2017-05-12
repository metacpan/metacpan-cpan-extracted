use strict;
use warnings;
use Test::More tests => 12;

use Net::SNMP qw(:asn1);
use Net::SNMP::Util qw(:all);
use Data::Dumper;

my ($r,$e,$s);

# Hooking for test ============================================================
{
no warnings;

*{Net::SNMP::_send_pdu} = sub {

    my ($this ) = @_;

    foreach my $oid ( keys %{$this->{_pdu}{_var_bind_list}} ){
        $this->{_pdu}{_var_bind_list}{ $oid }
            = sprintf("Precure(%d%d)", $oid, $this->{_version}+1 );
    }

    return ($this->{_nonblocking}) ? 1 : $this->var_bind_list();
};

}
# =============================================================================

#diag( "snmpget()/snmpparaget() return values pattern check" );

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
$s = Net::SNMP->session();
($r,$e) = snmpget( hosts => {
                        "black" => $s,
                        "white" => {
                            -hostname => "localhost",
                            -version  => "SNMPv2c",
                        },
                        "luminous" => "127.0.0.1"
                   },
                   oids => {
                        mepple => "1",
                        mipple => [ "1", "2" ],
                   },
);
ok(
    $r->{black}{mepple}    eq 'Precure(11)' &&
    $r->{black}{mipple}[0] eq 'Precure(11)' &&
    $r->{black}{mipple}[1] eq 'Precure(21)' &&

    $r->{white}{mepple}    eq 'Precure(12)' &&
    $r->{white}{mipple}[0] eq 'Precure(12)' &&
    $r->{white}{mipple}[1] eq 'Precure(22)' &&

    $r->{luminous}{mepple}    eq 'Precure(11)' &&
    $r->{luminous}{mipple}[0] eq 'Precure(11)' &&
    $r->{luminous}{mipple}[1] eq 'Precure(21)',

    "'hosts' => {...}, oids => {...}"
);

# -- 2 --
($r,$e) = snmpget( hosts => {
                        "black" => $s,
                        "white" => {
                            -hostname => "localhost",
                            -version  => "SNMPv1",
                        },
                        "luminous" => "127.0.0.1"
                   },
                   snmp => {
                        -version => "SNMPv2c",
                   },
                   oids => "1",
);
ok(
    $r->{black}    eq 'Precure(11)' &&
    $r->{white}    eq 'Precure(11)' &&
    $r->{luminous} eq 'Precure(12)',
    "'hosts' => {...}, with 'snmp', 'oid' => string"
);

# -- 3 --
($r,$e) = snmpget( hosts => {
                        "black" => $s,
                        "white" => {
                            -hostname => "localhost",
                            -version  => "SNMPv2",
                        },
                        "luminous" => "127.0.0.1"
                   },
                   oids => [ "1", "2" ],
);
ok(
    $r->{black}[0] eq 'Precure(11)' &&
    $r->{black}[1] eq 'Precure(21)' &&

    $r->{white}[0] eq 'Precure(12)' &&
    $r->{white}[1] eq 'Precure(22)' &&

    $r->{luminous}[0] eq 'Precure(11)' &&
    $r->{luminous}[1] eq 'Precure(21)',

    "'hosts' => {...}, 'oid' => [...]"
);

# -- 4 --
($r,$e) = snmpget(
                hosts => [ "localhost", "127.0.0.1" ],
                oids => {
                        porrun => "1",
                        lulun  => [ "1", "2" ],
                },
);
ok(
    $r->{localhost  }{porrun}   eq 'Precure(11)' &&
    $r->{localhost  }{lulun}[0] eq 'Precure(11)' &&
    $r->{localhost  }{lulun}[1] eq 'Precure(21)' &&

    $r->{'127.0.0.1'}{porrun}   eq 'Precure(11)' &&
    $r->{'127.0.0.1'}{lulun}[0] eq 'Precure(11)' &&
    $r->{'127.0.0.1'}{lulun}[1] eq 'Precure(21)',
    "'hosts' => [...], oids => {...}"
);

# -- 5 --
($r,$e) = snmpget(
                hosts => [ "localhost", "127.0.0.1" ],
                snmp  => {
                    -version => "1",
                },
                oids  => "2",
);
ok(
    $r->{localhost  }    eq 'Precure(21)' &&
    $r->{'127.0.0.1'}    eq 'Precure(21)',
    "'hosts' => [...], with 'snmp', 'oid' => string"
);

# -- 6 --
($r,$e) = snmpget(
                hosts => [ "localhost", "127.0.0.1" ],
                oids  => [ "1", "2" ],
);
ok(
    $r->{localhost  }[0] eq 'Precure(11)' &&
    $r->{localhost  }[1] eq 'Precure(21)' &&

    $r->{'127.0.0.1'}[0] eq 'Precure(11)' &&
    $r->{'127.0.0.1'}[1] eq 'Precure(21)',
    "'hosts' => [...], 'oid' => [...]"
);


# -- 7 --
($r,$e) = snmpget(
                hosts => "localhost",
                oids => {
                        porrun => "1",
                        lulun  => [ "1", "2" ],
                },
);
ok(
    $r->{localhost  }{porrun}   eq 'Precure(11)' &&
    $r->{localhost  }{lulun}[0] eq 'Precure(11)' &&
    $r->{localhost  }{lulun}[1] eq 'Precure(21)',
    "'hosts' => string"
);

# -- 8 --
($r,$e) = snmpget(
                hosts => "127.0.0.1",
                snmp  => {
                    -version => "2",
                },
                oids  => "2",
);
ok(
    $r->{'127.0.0.1'}  eq 'Precure(22)',
    "'hosts' => string, with 'snmp', 'oid' => string"
);

# -- 9 --
($r,$e) = snmpget(
                hosts => "localhost",
                oids  => [ "1", "2" ],
);
ok(
    $r->{localhost}[0] eq 'Precure(11)' &&
    $r->{localhost}[1] eq 'Precure(21)',
    "'hosts' => string, 'oid' => [...]"
);


# 'snmp' type without 'host'
# -- 10 --
($r,$e) = snmpget(
                snmp => {
                    -hostname => "localhost",
                    -version  => "SNMPv2c",
                },
                oids => {
                    porrun => "1",
                    lulun  => [ "1", "2" ],
                },
);
ok(
    $r->{porrun}   eq 'Precure(12)' &&
    $r->{lulun}[0] eq 'Precure(12)' &&
    $r->{lulun}[1] eq 'Precure(22)',
    "'snmp' without 'hosts', oids => {...}"
);

# -- 11 --
($r,$e) = snmpget(
                snmp => {
                    -hostname => "localhost",
                    -version  => "SNMPv2c",
                },
                oids => "2",
);
ok(
    $r eq 'Precure(22)',
    "'snmp' without 'hosts', oids => string"
);

# -- 12 --
($r,$e) = snmpget(
                snmp => {
                    -hostname => "localhost",
                    -version  => "1",
                },
                oids => [ "1", "2" ],
);
ok(
    $r->[0] eq 'Precure(11)' &&
    $r->[1] eq 'Precure(21)',
    "'snmp' without 'hosts', oids => [...]"
);


