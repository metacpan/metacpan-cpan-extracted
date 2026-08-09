# Net-Firewall-BlockerHelper

Helps manage (un)blocking IPs via various firewalls.

Currently included local backends are and all should be well tested, especially pf and
ipfw...

- firewalld
- hosts_deny (TCP wrappers /etc/hosts.deny; libwrap aware daemons only)
- ipfw
- iptables (also supports tarpit/delude targets via xtables-addons)
- nftables
- npf
- openwrt (OpenWrt fw4, configured via UCI, locally or remotely over ubus JSON-RPC...
  both modes tested against OpenWrt 25.12.5 / firewall4)
- pf
- linux_ip_route (null/blackhole routes via iproute2)
- shorewall (dynamic blacklist via shorewall/shorewall6)
- ufw
- xdp (XDP/eBPF packet drops via xdp-filter from xdp-tools)

The following remote/API backends are available. These use LWP::UserAgent,
which is only loaded if they are used. Please note these have been built based
of existing samples else where or docs and not tested due to lack of access to systems to
test against at this time.

- abuseipdb (report banned IPs to AbuseIPDB; reporting only, blocks nothing itself)
- akamai (Akamai Network Lists via the v2 API, EdgeGrid authenticated)
- checkpoint (Check Point host object in a group via the Management API)
- cisco_fmc (Cisco Firepower network group via the FMC REST API)
- cloudflare
- f5_bigip (F5 BIG-IP firewall address-list via iControl REST)
- fastly (Fastly Edge ACL entries via the Fastly API)
- fortigate (Fortinet FortiGate address group via the FortiOS REST API)
- juniper_srx (Juniper SRX global address-book via the Junos REST API)
- netscaler
- opnsense (OPNsense firewall alias via the os-firewall alias_util API)
- panos (Palo Alto Networks PAN-OS dynamic address group via the User-ID XML API)
- pfsense (pfSense firewall alias via the pfSense-API package)
- routeros_api (MikroTik RouterOS address-list via the RouterOS 7 REST API)
- vyos (VyOS firewall address-group via the HTTP API)

The following cloud backends are available. These drive the provider's CLI.  Please note
these have been built based of existing samples else where or docs and not tested due to
lack of access to systems to test against at this time.

- aws_wafv2 (AWS WAFv2 IP sets via the aws CLI)
- azure (Azure NSG deny rule source prefixes via the az CLI)
- cloud_armor (GCP Cloud Armor rule source ranges via the gcloud CLI)

The following other remote backends are available.

- bgp_rtbh (BGP Remote Triggered Black Hole; announces /32 or /128 routes with
  the RFC 7999 blackhole community, or a FlowSpec discard rule, via ExaBGP,
  gobgp, or FRR/vtysh ... exabgp and gobgp have live tests if the available... none
  currently for FRR/vtysh)
- dns_rpz (DNS Response Policy Zone rpz-client-ip/rpz-ip triggers via nsupdate... live
  tests available if named is instaleld)
- nsupdate (DNS based blocklist via BIND dynamic updates...  live tests available if named
  is instaleld)
- routeros (MikroTik RouterOS address-list, driven over ssh... implemented based on found
  examples/docs and not currently tested due to lack of access)

The following generic backends are available.

- file_reload (render bans to a file, then run a reload hook)
- shell

And the following example/testing backends are available.

- dummy

```perl
    use Net::Firewall::BlockerHelper;

    # create a instance named ssh with a ipfw backend for port 22 tcp
    my $fw_helper;
    eval {
        $fw_helper = Net::Firewall::BlockerHelper->new(
                backend => 'ipfw',
                ports => ['22'],
                protocols => ['tcp'],
                name => 'ssh',
            );
    };
    if ($@) {
        print 'Error: '
            . $Error::Helper::error
            . "\nError String: "
            . $Error::Helper::errorString
            . "\nError Flag: "
            . $Error::Helper::errorFlag . "\n";
    }

    # start the backend
    $fw_helper->init_backend;

    # ban some IPs
    $fw_helper->ban(ban => '1.2.3.4');
    $fw_helper->ban(ban => '5.6.7.8');

    # unban a IP
    $fw_helper->unban(ban => '1.2.3.4');

    # ban/unban a CIDR range (backends that support it; others raise
    # the cidrNotSupported error)
    $fw_helper->ban_cidr(ban => '1.2.3.0/24');
    $fw_helper->unban_cidr(ban => '1.2.3.0/24');

    # get a list of banned IPs
    my @banned = $fw_helper->list;
    foreach my $ip (@banned) {
        print 'Banned IP: '.$ip."\n";
    }

    # get a list of banned CIDR ranges
    my @banned_cidrs = $fw_helper->list_cidr;

    # write out state the backend holds back from persistent storage
    # (only openwrt implements this; others raise commitNotSupported)
    $fw_helper->commit;

    # teardown the backend, re-init, and re-ban everything
    $fw_helper->re_init;

    # teardown the backend
    $fw_helper->teardown;
```

# Install

Requirements...

- Regexp::IPv4
- Regexp::IPv6
- Error::Helper

And if using any of the HTTP backends...

- LWP::UserAgent
- LWP::Protocol::https

## cpanm

```shell
cpanm Net::Firewall::BlockerHelper LWP::UserAgent LWP::Protocol::https
```

## From source

Clone the repo or grab and extract the tarball, then in it...

```shell
perl Makefile.PL
make
make test
make install
```

The requirements need installed first, either via packages as below or
cpanm.

## FreeBSD

Regexp::IPv4 is not ported, so cpanm is used for the final step.

```shell
pkg install perl5 p5-App-cpanminus p5-Error-Helper p5-Regexp-IPv6 p5-libwww p5-LWP-Protocol-https
cpanm Net::Firewall::BlockerHelper
```

## Debian

Regexp::IPv4 and Error::Helper are not packaged, so cpanm is used for the
final step.

```shell
apt-get install perl make cpanminus libregexp-ipv6-perl libwww-perl liblwp-protocol-https-perl
cpanm Net::Firewall::BlockerHelper
```
