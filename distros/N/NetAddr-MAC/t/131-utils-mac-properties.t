use strict;
use warnings;

use Test::More tests => 272;
use Test::Trap;

BEGIN {
    use_ok( 'NetAddr::MAC', qw( :properties ) )
      or die "# NetAddr::MAC not available\n";
}

{

    # 10 tests x2
    my @badmacs = (
        qw(
          1111
          abcdefghijiklmon
          00-aa-bb-cc-jj-kk
          hellothere
          zz-11-22-33-44-55
          azaa.0022.cdef
          00.ss.22.33.44.55.22.33.44
          00-aa-bb-cc-dd-jj-kk
          0000.1111.3333.aaaz
          ....
          )
    );

    local $NetAddr::MAC::die_on_error = 1;

    for my $mac (@badmacs) {
        trap { mac_is_eui48($mac) };
        ok( $trap->die,
            'mac_is_eui48 croaks if validation fails from ' . $mac )
        or print $trap->diag_all;
        trap { mac_is_eui64($mac) };
        ok( $trap->die,
            'mac_is_eui64 croaks if validation fails from ' . $mac );
    }

}

#          mac_is_eui48     mac_is_eui64
{

    # 10 tests x2
    my @eui48macs = (
        '001122334455',      '00-11-22-33-44-55',
        '00:11:22:33:44:55', '0011.2233.4455',
        '0-1-22-33-a-55',    '00-a1-2b-3c-4a-5f',
        '0:a:b:3:4:f',       '0-a-b-3-4-f',
        'abcdef012345',      '7890abcdef11',
        '1,6,00:22:33:44:55:aa',
    );

    for my $mac (@eui48macs) {
        ok( mac_is_eui48($mac),  'eui48 correctly identified from ' . $mac );
        ok( !mac_is_eui64($mac), 'eui64 = false from ' . $mac );
    }

}

{

    # 10 tests x2
    my @eui64macs = (
        '0011223344556677',        '00-11-22-33-44-55-66-77',
        '00:11:22:33:44:55:66:77', '0011.2233.4455.6677',
        '0-1-22-33-a-55-6-77',     '00-a1-2b-3c-4a-5f-6e-7d',
        '0:a:b:3:4:f:5:d',         '0-a-b-3-4-f-5-d',
        'abcdef0123456733',        '7890abcdef112233',
    );

    for my $mac (@eui64macs) {
        ok( mac_is_eui64($mac),  'eui64 correctly identified from ' . $mac );
        ok( !mac_is_eui48($mac), 'eui48 = false from ' . $mac );
    }

#          mac_is_unicast   mac_is_multicast   mac_is_broadcast
#          mac_is_vrrp    mac_is_hsrp    mac_is_hsrp2

    my @unicasteui48macs = qw(
      c82a14eeeeee
      001122334455
      003344aaccdd
      00.11.22.33.44.aa
    );

    my @unicasteui64macs = qw(
      c82a14eeeeeeeeee
      0011223344556677
      00aabbcc223344aa
      00.bb.cc.aa.55.66
    );

    for my $mac ( @unicasteui48macs, @unicasteui64macs ) {
        ok( mac_is_unicast($mac), 'unicast correctly identified from ' . $mac );
        ok( !mac_is_multicast($mac), 'multicast = false from ' . $mac );
        ok( !mac_is_broadcast($mac), 'broadcast = false from ' . $mac );
    }

    my @multicasteui48macs = qw(
      011122334455
      013344aaccdd
      01.11.22.33.44.aa
    );

    my @multicasteui64macs = qw(
      0111223344556677
      01aabbcc223344aa
      01.bb.cc.aa.55.66
    );

    for my $mac ( @multicasteui48macs, @multicasteui64macs ) {
        ok( mac_is_multicast($mac),
            'multicast correctly identified from ' . $mac );
        ok( !mac_is_unicast($mac), 'unicast = false from ' . $mac );
        ok( !mac_is_broadcast($mac), 'broadcast = false from ' . $mac );
    }

    my @broadcasteui48macs = qw(
      ffffffffffff
    );

    for my $mac ( @broadcasteui48macs ) {
        ok( mac_is_broadcast($mac),
            'broadcast correctly identified from ' . $mac );
        ok( !mac_is_unicast($mac), 'unicast = false from ' . $mac );
        ok( !mac_is_multicast($mac), 'multicast = false from ' . $mac );
    }

    my @vrrpeui48macs = qw(
      00-00-5E-00-01-12
      00-00-5E-00-01-A5
      00-00-5E-00-01-CF
      00-00-5E-00-01-3B
    );

    my @hsrpeui48macs = qw(
      0000.0C07.AC12
      0000.0C07.ACA5
      0000.0C07.ACCF
      0000.0C07.AC3B
    );

    my @hsrp2eui48macs = qw(
      0000.0C9F.F001
      0000.0C9F.FC12
      0000.0C9F.F1C3
      0000.0C9F.F12A
      0000.0C9F.FF2A
      0000.0C9F.FABC
    );

    my @msnlbeui48macs = qw(
      02bf.0C9F.F001
      03bf.0C9F.FC12
    );

    for my $mac ( @unicasteui64macs, @multicasteui64macs ) {
        ok( !mac_is_vrrp($mac),  'eui64 is never vrrp from ' . $mac);
        ok( !mac_is_hsrp($mac),  'eui64 is never hsrp from ' . $mac);
        ok( !mac_is_hsrp2($mac), 'eui64 is never hsrp2 from ' . $mac);
        ok( !mac_is_msnlb($mac), 'eui64 is never msnlb from ' . $mac);
    }

    for my $mac ( @unicasteui48macs, @unicasteui48macs ) {
        ok( !mac_is_vrrp($mac),  'vrrp  = false from ' . $mac);
        ok( !mac_is_hsrp($mac),  'hsrp  = false from ' . $mac);
        ok( !mac_is_hsrp2($mac), 'hsrp2  = false from ' . $mac);
        ok( !mac_is_msnlb($mac), 'msnlb  = false from ' . $mac);
    }

    for my $mac ( @vrrpeui48macs ) {
        ok( mac_is_vrrp($mac), 'vrrp correctly identified from ' . $mac);
        ok( !mac_is_hsrp($mac),  'hsrp  = false from ' . $mac);
        ok( !mac_is_hsrp2($mac), 'hsrp2  = false from ' . $mac);
        ok( !mac_is_msnlb($mac), 'msnlb  = false from ' . $mac);
    }

    for my $mac ( @hsrpeui48macs) {
        ok( mac_is_hsrp($mac), 'hsrp correctly identified from ' . $mac);
        ok( !mac_is_vrrp($mac),  'vrrp  = false from ' . $mac);
        ok( !mac_is_hsrp2($mac), 'hsrp2  = false from ' . $mac);
        ok( !mac_is_msnlb($mac), 'msnlb  = false from ' . $mac);
    }

    for my $mac ( @hsrp2eui48macs) {
        ok( mac_is_hsrp2($mac), 'hsrp2 correctly identified from ' . $mac);
        ok( !mac_is_vrrp($mac), 'vrrp  = false from ' . $mac);
        ok( !mac_is_hsrp($mac), 'hsrp  = false from ' . $mac);
        ok( !mac_is_msnlb($mac), 'msnlb  = false from ' . $mac);
    }

    for my $mac ( @msnlbeui48macs) {
        ok( mac_is_msnlb($mac), 'msnlb correctly identified from ' . $mac);
        ok( !mac_is_vrrp($mac), 'vrrp  = false from ' . $mac);
        ok( !mac_is_hsrp($mac), 'hsrp  = false from ' . $mac);
        ok( !mac_is_hsrp2($mac), 'hsrp2  = false from ' . $mac);
    }
}

#      is_local    is_universal
{

    my @localeui48macs = qw(
      02aa.bbcc.2233
      02aabbcc2233
      02-aa-bb-cc-22-33
      03:aa:cc:12:33:56
      03aacc123356
    );

    my @localeui64macs = qw(
      02aa.bbcc.2233.abcd
      02aabbcc2233abcd
      02-aa-bb-cc-22-33-aa-bb
      03:aa:cc:12:33:56:ab:cd
      03aacc123356aadd
    );

    my @universaleui48macs = qw(
      00aa.bbcc.2233
      00aabbcc2233
      01-aa-bb-cc-22-33
      00:aa:cc:12:33:56
      00aacc123356
    );

    my @universaleui64macs = qw(
      00aa.bbcc.2233.abcd
      00aabbcc2233abcd
      01-aa-bb-cc-22-33-aa-bb
      00:aa:cc:12:33:56:ab:cd
      00aacc123356aadd
    );

    for my $mac ( @localeui48macs, @localeui64macs ) {
        ok( mac_is_local($mac), 'local correctly identified from ' . $mac );
        ok( !mac_is_universal($mac), 'universal = false from ' . $mac );
    }

    for my $mac ( @universaleui48macs, @universaleui64macs ) {
        ok( mac_is_universal($mac),
            'universal correctly identified from ' . $mac );
        ok( !mac_is_local($mac), 'local = false from ' . $mac );
    }

}

1
