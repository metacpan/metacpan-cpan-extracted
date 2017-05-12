# -*- perl -*-

use Test::More tests => 23;
use strict;
use warnings;

use NoZone;
use Config::Record;
use IO::Handle;
use IO::File;
use File::Temp qw /tempdir tempfile/;
use File::Spec::Functions qw /catfile/;

my $cfgdata = <<EOF;
zones = {
  common = {
    hostmaster = dan-hostmaster
    lifetimes = {
      refresh = 1H
      retry = 15M
      expire = 1W
      negative = 1H
      ttl = 1H
    }

    default = platinum

    mail = {
      mx0 = {
        priority = 10
        machine = gold
      }
      mx1 = {
        priority = 20
        machine = silver
      }
    }

    dns = {
      ns0 = gold
      ns1 = silver
    }

    names = {
      www = platinum
    }

    aliases = {
      db = gold
      backup = silver
    }

    wildcard = platinum
  }

  production = {
    inherits = common

    domains = (
        nozone.org
        nozone.com
    )

    machines = {
      platinum = {
        ipv4 = 12.32.56.1
        ipv6 = 2001:1234:6789::1
      }
      gold = {
        ipv4 = 12.32.56.2
        ipv6 = 2001:1234:6789::2
      }
      silver = {
        ipv4 = 12.32.56.3
        ipv6 = 2001:1234:6789::3
      }
    }
  }

  testing = {
    inherits = common

    domains = (
      qa.nozone.org
    )

    machines = {
      platinum = {
        ipv4 = 192.168.1.1
        ipv6 = fc00::1:1
      }
      gold = {
        ipv4 = 192.168.1.2
        ipv6 = fc00::1:2
      }
      silver = {
        ipv4 = 192.168.1.3
        ipv6 = fc00::1:3
      }
    }
  }
}
EOF


my $nozoneorgdata = <<EOF;
\$ORIGIN nozone.org.
\$TTL     1H ; queries are cached for this long
@        IN    SOA    ns1    hostmaster (
                           1363207738 ; Date 2013/03/13 20:48:58
                           1H  ; slave queries for refresh this often
                           15M ; slave retries refresh this often after failure
                           1W ; slave expires after this long if not refreshed
                           1H ; errors are cached for this long
         )

; Primary name records for unqualfied domain
@                    IN    A               12.32.56.1 ; Machine platinum
@                    IN    AAAA            2001:1234:6789::1 ; Machine platinum

; DNS server records
@                    IN    NS              ns0
@                    IN    NS              ns1
ns0                  IN    A               12.32.56.2 ; Machine gold
ns0                  IN    AAAA            2001:1234:6789::2 ; Machine gold
ns1                  IN    A               12.32.56.3 ; Machine silver
ns1                  IN    AAAA            2001:1234:6789::3 ; Machine silver

; E-Mail server records
@                    IN    MX       10     mx0
@                    IN    MX       20     mx1
mx0                  IN    A               12.32.56.2 ; Machine gold
mx0                  IN    AAAA            2001:1234:6789::2 ; Machine gold
mx1                  IN    A               12.32.56.3 ; Machine silver
mx1                  IN    AAAA            2001:1234:6789::3 ; Machine silver

; Primary names
gold                 IN    A               12.32.56.2
gold                 IN    AAAA            2001:1234:6789::2
platinum             IN    A               12.32.56.1
platinum             IN    AAAA            2001:1234:6789::1
silver               IN    A               12.32.56.3
silver               IN    AAAA            2001:1234:6789::3

; Extra names
www                  IN    A               12.32.56.1 ; Machine platinum
www                  IN    AAAA            2001:1234:6789::1 ; Machine platinum

; Aliased names
backup               IN    CNAME           silver
db                   IN    CNAME           gold

; Wildcard
*                    IN    A               12.32.56.1 ; Machine platinum
*                    IN    AAAA            2001:1234:6789::1 ; Machine platinum

EOF

my $nozonecomdata = <<EOF;
\$ORIGIN nozone.com.
\$TTL     1H ; queries are cached for this long
@        IN    SOA    ns1    hostmaster (
                           1363207738 ; Date 2013/03/13 20:48:58
                           1H  ; slave queries for refresh this often
                           15M ; slave retries refresh this often after failure
                           1W ; slave expires after this long if not refreshed
                           1H ; errors are cached for this long
         )

; Primary name records for unqualfied domain
@                    IN    A               12.32.56.1 ; Machine platinum
@                    IN    AAAA            2001:1234:6789::1 ; Machine platinum

; DNS server records
@                    IN    NS              ns0
@                    IN    NS              ns1
ns0                  IN    A               12.32.56.2 ; Machine gold
ns0                  IN    AAAA            2001:1234:6789::2 ; Machine gold
ns1                  IN    A               12.32.56.3 ; Machine silver
ns1                  IN    AAAA            2001:1234:6789::3 ; Machine silver

; E-Mail server records
@                    IN    MX       10     mx0
@                    IN    MX       20     mx1
mx0                  IN    A               12.32.56.2 ; Machine gold
mx0                  IN    AAAA            2001:1234:6789::2 ; Machine gold
mx1                  IN    A               12.32.56.3 ; Machine silver
mx1                  IN    AAAA            2001:1234:6789::3 ; Machine silver

; Primary names
gold                 IN    A               12.32.56.2
gold                 IN    AAAA            2001:1234:6789::2
platinum             IN    A               12.32.56.1
platinum             IN    AAAA            2001:1234:6789::1
silver               IN    A               12.32.56.3
silver               IN    AAAA            2001:1234:6789::3

; Extra names
www                  IN    A               12.32.56.1 ; Machine platinum
www                  IN    AAAA            2001:1234:6789::1 ; Machine platinum

; Aliased names
backup               IN    CNAME           silver
db                   IN    CNAME           gold

; Wildcard
*                    IN    A               12.32.56.1 ; Machine platinum
*                    IN    AAAA            2001:1234:6789::1 ; Machine platinum

EOF

my $qanozoneorgdata = <<EOF;
\$ORIGIN qa.nozone.org.
\$TTL     1H ; queries are cached for this long
@        IN    SOA    ns1    hostmaster (

                           1H  ; slave queries for refresh this often
                           15M ; slave retries refresh this often after failure
                           1W ; slave expires after this long if not refreshed
                           1H ; errors are cached for this long
         )

; Primary name records for unqualfied domain
@                    IN    A               192.168.1.1 ; Machine platinum
@                    IN    AAAA            fc00::1:1 ; Machine platinum

; DNS server records
@                    IN    NS              ns0
@                    IN    NS              ns1
ns0                  IN    A               192.168.1.2 ; Machine gold
ns0                  IN    AAAA            fc00::1:2 ; Machine gold
ns1                  IN    A               192.168.1.3 ; Machine silver
ns1                  IN    AAAA            fc00::1:3 ; Machine silver

; E-Mail server records
@                    IN    MX       10     mx0
@                    IN    MX       20     mx1
mx0                  IN    A               192.168.1.2 ; Machine gold
mx0                  IN    AAAA            fc00::1:2 ; Machine gold
mx1                  IN    A               192.168.1.3 ; Machine silver
mx1                  IN    AAAA            fc00::1:3 ; Machine silver

; Primary names
gold                 IN    A               192.168.1.2
gold                 IN    AAAA            fc00::1:2
platinum             IN    A               192.168.1.1
platinum             IN    AAAA            fc00::1:1
silver               IN    A               192.168.1.3
silver               IN    AAAA            fc00::1:3

; Extra names
www                  IN    A               192.168.1.1 ; Machine platinum
www                  IN    AAAA            fc00::1:1 ; Machine platinum

; Aliased names
backup               IN    CNAME           silver
db                   IN    CNAME           gold

; Wildcard
*                    IN    A               192.168.1.1 ; Machine platinum
*                    IN    AAAA            fc00::1:1 ; Machine platinum

EOF

my $nozoneorgconfmaster = <<EOF;
zone "nozone.org" in {
    type master;
    file "::FILE::/nozone.org.data";
};
EOF

my $nozonecomconfmaster = <<EOF;
zone "nozone.com" in {
    type master;
    file "::FILE::/nozone.com.data";
};
EOF

my $qanozoneorgconfmaster = <<EOF;
zone "qa.nozone.org" in {
    type master;
    file "::FILE::/qa.nozone.org.data";
};
EOF

my $nozoneorgconfslave = <<EOF;
zone "nozone.org" in {
    type slave;
    file "::FILE::/nozone.org.data";
    masters { 10.0.0.1 ; 10.0.0.2 ; };
};
EOF

my $nozonecomconfslave = <<EOF;
zone "nozone.com" in {
    type slave;
    file "::FILE::/nozone.com.data";
    masters { 10.0.0.1 ; 10.0.0.2 ; };
};
EOF

my $qanozoneorgconfslave = <<EOF;
zone "qa.nozone.org" in {
    type slave;
    file "::FILE::/qa.nozone.org.data";
    masters { 10.0.0.1 ; 10.0.0.2 ; };
};
EOF

my $mainconf = <<EOF;
include "::FILE::/nozone.com.conf";
include "::FILE::/nozone.org.conf";
include "::FILE::/qa.nozone.org.conf";
EOF

my %zonedata = (
    "nozone.org" => $nozoneorgdata,
    "nozone.com" => $nozonecomdata,
    "qa.nozone.org" => $qanozoneorgdata,
);
my %zoneconfmaster = (
    "nozone.org" => $nozoneorgconfmaster,
    "nozone.com" => $nozonecomconfmaster,
    "qa.nozone.org" => $qanozoneorgconfmaster,
);
my %zoneconfslave = (
    "nozone.org" => $nozoneorgconfslave,
    "nozone.com" => $nozonecomconfslave,
    "qa.nozone.org" => $qanozoneorgconfslave,
);


my ($cfgfh, $cfgfile) = tempfile UNLINK => 1;

print $cfgfh $cfgdata;
seek $cfgfh, 0, 0;

my $file = IO::Handle->new;
$file->fdopen(fileno $cfgfh, "r");
my $cfg = Config::Record->new();
$cfg->load($file);

my $tmpdir = tempdir CLEANUP => 1;

my $nozone = NoZone->new(datadir => $tmpdir,
			 confdir => $tmpdir);

$nozone->load_config($cfg);
$nozone->generate_zones(1);

my $mainfile = catfile($tmpdir, "nozone.conf");
ok(-f $mainfile, "$mainfile exists");

{
    my $mainfh = IO::File->new($mainfile, "<") or die "cannot read $mainfile";
    local $/ = undef;
    my $gotmain = <$mainfh>;
    my $wantmain = $mainconf;

    $wantmain =~ s/::FILE::/$tmpdir/g;

    is($gotmain, $wantmain, "main conf");
}
unlink $mainfile;

foreach my $zone (keys %zonedata) {
    my $conffile = catfile($tmpdir, $zone . ".conf");
    my $datafile = catfile($tmpdir, $zone . ".data");
    ok(-f $conffile, "$conffile exists");
    ok(-f $datafile, "$datafile exists");

    my $conffh = IO::File->new($conffile, "<") or die "cannot read $conffile";
    local $/ = undef;
    my $gotconf = <$conffh>;
    my $wantconf = $zoneconfmaster{$zone};

    $wantconf =~ s/::FILE::/$tmpdir/;

    is($gotconf, $wantconf, "$zone conf");

    my $datafh = IO::File->new($datafile, "<") or die "cannot read $datafile";
    local $/ = undef;
    my $gotdata = <$datafh>;
    my $wantdata = $zonedata{$zone};

    $gotdata =~ s/^.*Date.*$//m;
    $wantdata =~ s/^.*Date.*$//m;

    is($gotdata, $wantdata, "$zone data");

    unlink $conffile;
    unlink $datafile;
}


$nozone = NoZone->new(datadir => $tmpdir,
		      confdir => $tmpdir,
		      masters => ["10.0.0.1", "10.0.0.2"]);

$nozone->load_config($cfg);
$nozone->generate_zones(1);


foreach my $zone (keys %zonedata) {
    my $conffile = catfile($tmpdir, $zone . ".conf");
    my $datafile = catfile($tmpdir, $zone . ".data");
    ok(-f $conffile, "$conffile exists");
    ok(!-f $datafile, "$datafile does not exist");

    my $conffh = IO::File->new($conffile, "<") or die "cannot read $conffile";
    local $/ = undef;
    my $gotconf = <$conffh>;
    my $wantconf = $zoneconfslave{$zone};

    $wantconf =~ s/::FILE::/$tmpdir/;

    is($gotconf, $wantconf, "$zone conf");
}
