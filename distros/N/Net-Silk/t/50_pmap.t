use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use silktest;

use Test::More tests => 7;

use Net::Silk qw( :basic );

BEGIN { use_ok( SILK_PMAP_CLASS ) }

my %pmap_files = t_pmap_files();

sub new_ipv4_pmap { SILK_PMAP_IPV4_CLASS->new(@_) }

sub load_pmap      { SILK_PMAP_CLASS->load(@_)       }
sub load_ip_pmap   { load_pmap($pmap_files{ipmap})   }
sub load_ipv6_pmap { load_pmap($pmap_files{ipmapv6}) }
sub load_pp_pmap   { load_pmap($pmap_files{ppmap})   }

sub new_ip  { SILK_IPADDR_CLASS   ->new(@_) }
sub new_ip6 { SILK_IPV6ADDR_CLASS ->new(@_) }
sub new_pp  { SILK_PROTOPORT_CLASS->new(@_) }

sub new_range { SILK_RANGE_CLASS->new(@_) }

###

sub test_load {
  my $p;
  $p = load_ip_pmap();
  isa_ok($p, SILK_PMAP_CLASS);
  $p = load_pp_pmap();
  isa_ok($p, SILK_PMAP_CLASS);
  SKIP: {
    skip("ipv6 not enabled", 1) unless SILK_IPV6_ENABLED;
    $p = load_ipv6_pmap();
    isa_ok($p, SILK_PMAP_CLASS);
  }
}

###

sub t_ip_get {
  my($p, $k, $v) = @_;
  cmp_ok($p->get($k), 'eq', $v, "ip get($k):$v");
  cmp_ok($p->{$k},    'eq', $v, "ip{$k}:$v");
}

sub t_ip6_get {
  my($p, $k, $v) = @_;
  cmp_ok($p->get($k), 'eq', $v, "ip6 get($k):$v");
  cmp_ok($p->{$k},    'eq', $v, "ip6{$k}:$v");
}

sub test_get_ip {

  plan tests => 42;

  my($p, $v);

  $p = load_ip_pmap();

  t_ip_get($p, '192.168.4.5'     => 'internal');
  t_ip_get($p, '192.168.0.0'     => 'internal');
  t_ip_get($p, '192.168.255.255' => 'internal');
  t_ip_get($p, '172.17.0.0'      => 'internal services');
  t_ip_get($p, '172.31.0.0'      => 'internal services');
  t_ip_get($p, '172.16.0.0'      => 'ntp');
  t_ip_get($p, '172.24.0.0'      => 'dns');
  t_ip_get($p, '172.30.0.0'      => 'dhcp');
  t_ip_get($p, '0.0.0.0'         => 'external');
  t_ip_get($p, '255.255.255.255' => 'external');

  SKIP: {
    skip('ipv6 not enabled', 22) unless SILK_IPV6_ENABLED;
    t_ip_get($p, '::ffff:192.168.0.0' => 'internal');
    t_ip_get($p, '::ffff:0.0.0.0'     => 'external');
    ok(! defined $p->get('::'), "ip get(::):undef");
    ok(! defined $p->{'::'},        "ip{::}:undef");
    $p = load_ipv6_pmap();
    t_ip6_get($p, '2001:db8:c0:a8::1' =>  'internal');
    t_ip6_get($p, '2001:db8:ac:11::1' =>  'internal services');
    t_ip6_get($p, '2001:db8:ac:1f::1' =>  'internal services');
    t_ip6_get($p, '2001:db8:ac:10::1' =>  'ntp');
    t_ip6_get($p, '2001:db8:ac:18::1' =>  'dns');
    t_ip6_get($p, '2001:db8:ac:1e::1' =>  'dhcp');
    t_ip6_get($p, '192.168.0.0' => 'external');
    t_ip6_get($p, '0.0.0.0'    => 'external');
  }
}

###

sub t_pp_get {
  my($p, $prot, $port, $v) = @_;
  Carp::confess("oops") unless ref $p;
  my $pp = "$prot:$port";
  cmp_ok($p->get($prot, $port),   'eq', $v, "pp get($prot, $port):$v");
  cmp_ok($p->get([$prot, $port]), 'eq', $v, "pp get([$prot, $port]):$v");
  cmp_ok($p->get($pp),            'eq', $v, "pp get($prot:$port):$v");
  cmp_ok($p->{$pp},               'eq', $v, "pp{$prot:$port}:$v");
}

sub test_get_pp {

  plan tests => 106;

  my($p, $v);

  $p = load_pp_pmap();

  t_pp_get($p, 1,  0      => 'ICMP');
  t_pp_get($p, 1,  0xffff => 'ICMP');
  t_pp_get($p, 17, 1      => 'UDP');
  t_pp_get($p, 17, 0xffff => 'UDP');
  t_pp_get($p, 17, 53     => 'UDP/DNS');
  t_pp_get($p, 17, 66     => 'UDP');
  t_pp_get($p, 17, 67     => 'UDP/DHCP');
  t_pp_get($p, 17, 68     => 'UDP/DHCP');
  t_pp_get($p, 17, 69     => 'UDP');
  t_pp_get($p, 17, 122    => 'UDP');
  t_pp_get($p, 17, 123    => 'UDP/NTP');
  t_pp_get($p, 17, 124    => 'UDP');
  t_pp_get($p, 6,  0      => 'TCP');
  t_pp_get($p, 6,  0xffff => 'TCP');
  t_pp_get($p, 6,  22     => 'TCP/SSH');
  t_pp_get($p, 6,  24     => 'TCP');
  t_pp_get($p, 6,  25     => 'TCP/SMTP');
  t_pp_get($p, 6,  26     => 'TCP');
  t_pp_get($p, 6,  80     => 'TCP/HTTP');
  t_pp_get($p, 6,  443    => 'TCP/HTTPS');
  t_pp_get($p, 6,  8080   => 'TCP/HTTP');
  t_pp_get($p, 2,  80     => 'unknown');
  t_pp_get($p, 5,  80     => 'unknown');
  t_pp_get($p, 7,  80     => 'unknown');
  t_pp_get($p, 0,  0      => 'unknown');
  eval { $v = $p->get('0.0.0.0') };
  like($@, qr/^invalid/i, "reject pp get(0.0.0.0)");
  eval { $v = $p->{'0.0.0.0'} };
  like($@, qr/^invalid/i, "reject pp{0.0.0.0}");
  eval { $v = $p->get(0x100, 1) };
  like($@, qr/^invalid.*out of range/i, "overflow pp get(0x100, 1)");
  eval { $v = $p->get(1, 0x10000) };
  like($@, qr/^invalid.*out of range/i, "overflow pp get(1, 0x10000)");
  eval { $v = $p->get(-1, 1) };
  like($@, qr/^invalid.*out of range/i, "overflow pp get(-1, 1)");
  eval { $v = $p->get(1, -1) };
  like($@, qr/^invalid.*out of range/i, "overflow pp get(1, -1)");

}

###

sub test_values {

  plan tests => 2;

  my($p, @ref, @res);

  $p = load_ip_pmap();
  @ref = sort((
    'external', 'internal', 'internal services',
    'ntp', 'dns', 'dhcp',
  ));
  @res = sort $p->iter_vals->();
  is_deeply(\@res, \@ref, "ip iter values");

  $p = load_pp_pmap();
  @ref = sort((
    'unknown', 'ICMP', 'UDP', 'UDP/DNS',
    'UDP/DHCP', 'UDP/NTP', 'TCP', 'TCP/SSH',
    'TCP/SMTP', 'TCP/HTTP', 'TCP/HTTPS',
  ));
  @res = sort $p->iter_vals->();
  is_deeply(\@res, \@ref, "pp iter values");

}

###

sub test_ranges {

  plan tests => 3;

  my($p, @ref, @res);

  $p = load_ip_pmap();
  # range keys will stringify
  @ref = (
    ['0.0.0.0-172.15.255.255'      =>          'external'],
    ['172.16.0.0-172.16.255.255'   =>               'ntp'],
    ['172.17.0.0-172.23.255.255'   => 'internal services'],
    ['172.24.0.0-172.24.255.255'   =>               'dns'],
    ['172.25.0.0-172.29.255.255'   => 'internal services'],
    ['172.30.0.0-172.30.255.255'   =>              'dhcp'],
    ['172.31.0.0-172.31.255.255'   => 'internal services'],
    ['172.32.0.0-192.167.255.255'  =>          'external'],
    ['192.168.0.0-192.168.255.255' =>          'internal'],
    ['192.169.0.0-255.255.255.255' =>          'external']
  );
  @res = $p->iter_ranges->();;
  is_deeply(\@res, \@ref, "ip iter ranges");

  $p = load_pp_pmap();
  @ref = (
    [ [[0,    0], [0,   65535]],   'unknown' ],
    [ [[1,    0], [1,   65535]],      'ICMP' ],
    [ [[2,    0], [5,   65535]],   'unknown' ],
    [ [[6,    0], [6,      21]],       'TCP' ],
    [ [[6,   22], [6,      22]],   'TCP/SSH' ],
    [ [[6,   23], [6,      24]],       'TCP' ],
    [ [[6,   25], [6,      25]],  'TCP/SMTP' ],
    [ [[6,   26], [6,      79]],       'TCP' ],
    [ [[6,   80], [6,      80]],  'TCP/HTTP' ],
    [ [[6,   81], [6,     442]],       'TCP' ],
    [ [[6,  443], [6,     443]], 'TCP/HTTPS' ],
    [ [[6,  444], [6,    8079]],       'TCP' ],
    [ [[6, 8080], [6,    8080]],  'TCP/HTTP' ],
    [ [[6, 8081], [6,   65535]],       'TCP' ],
    [ [[7,    0], [16,  65535]],   'unknown' ],
    [ [[17,   0], [17,     52]],       'UDP' ],
    [ [[17,  53], [17,     53]],   'UDP/DNS' ],
    [ [[17,  54], [17,     66]],       'UDP' ],
    [ [[17,  67], [17,     68]],  'UDP/DHCP' ],
    [ [[17,  69], [17,    122]],       'UDP' ],
    [ [[17, 123], [17,    123]],   'UDP/NTP' ],
    [ [[17, 124], [17,  65535]],       'UDP' ],
    [ [[18,   0], [255, 65535]],   'unknown' ],
  );
  foreach my $i (0 .. $#ref) {
    $ref[$i][0] = join('-', new_pp($ref[$i][0][0]), new_pp($ref[$i][0][1]));
  }
  @res = $p->iter_ranges->();
  is_deeply(\@res, \@ref, "pp iter ranges");

  SKIP: {
    skip('ipv6 not enabled', 1) unless SILK_IPV6_ENABLED;
    $p = load_ipv6_pmap();
    @ref = (
      [ '::-2001:db8:ac:f:ffff:ffff:ffff:ffff',
        'external' ],
      [ '2001:db8:ac:10::-2001:db8:ac:10:ffff:ffff:ffff:ffff',
        'ntp' ],
      [ '2001:db8:ac:11::-2001:db8:ac:17:ffff:ffff:ffff:ffff',
        'internal services'],
      [ '2001:db8:ac:18::-2001:db8:ac:18:ffff:ffff:ffff:ffff',
        'dns' ],
      [ '2001:db8:ac:19::-2001:db8:ac:1d:ffff:ffff:ffff:ffff',
        'internal services' ],
      [ '2001:db8:ac:1e::-2001:db8:ac:1e:ffff:ffff:ffff:ffff',
        'dhcp' ],
      [ '2001:db8:ac:1f::-2001:db8:ac:1f:ffff:ffff:ffff:ffff',
        'internal services' ],
      [ '2001:db8:ac:20::-2001:db8:c0:a7:ffff:ffff:ffff:ffff',
        'external' ],
      [ '2001:db8:c0:a8::-2001:db8:c0:a8:ffff:ffff:ffff:ffff',
        'internal' ],
      [ '2001:db8:c0:a9::-ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
        'external'],
    );
    @res = $p->iter_ranges->();
    is_deeply(\@res, \@ref, "ip6 iter ranges");
  }

}

sub test_construction {

  plan tests => 12;

  my @ranges = (
    ["1.2.3.0-1.2.3.31"         => "label1"],
    ["1.2.3.32-1.2.3.127"       => "label2"],
    ["10.11.12.0-10.11.12.31"   => "label3"],
    ["10.11.12.32-10.11.12.127" => "label4"],
  );

  my @prefixes = (
    ["1.2.3.4/25"     => "label1"],
    ["1.2.3.4/27"     => "label2"],
    ["10.11.12.13/25" => "label3"],
    ["10.11.12.13/27" => "label4"],
  );

  my @ref_range = map { [SILK_RANGE_CLASS->new($_->[0]), $_->[1]] } (
    ["0.0.0.0-1.2.2.255"            => "UNKNOWN"],
    ["1.2.3.0-1.2.3.31"             =>  "label1"],
    ["1.2.3.32-1.2.3.127"           =>  "label2"],
    ["1.2.3.128-10.11.11.255"       => "UNKNOWN"],
    ["10.11.12.0-10.11.12.31"       =>  "label3"],
    ["10.11.12.32-10.11.12.127"     =>  "label4"],
    ["10.11.12.128-255.255.255.255" => "UNKNOWN"],
  );

  my @ref_prefix = map { [SILK_CIDR_CLASS->new($_->[0]), $_->[1]] } (
    ["0.0.0.0/8"       => "UNKNOWN"],
    ["1.0.0.0/15"      => "UNKNOWN"],
    ["1.2.0.0/23"      => "UNKNOWN"],
    ["1.2.2.0/24"      => "UNKNOWN"],
    ["1.2.3.0/27"      =>  "label2"],
    ["1.2.3.32/27"     =>  "label1"],
    ["1.2.3.64/26"     =>  "label1"],
    ["1.2.3.128/25"    => "UNKNOWN"],
    ["1.2.4.0/22"      => "UNKNOWN"],
    ["1.2.8.0/21"      => "UNKNOWN"],
    ["1.2.16.0/20"     => "UNKNOWN"],
    ["1.2.32.0/19"     => "UNKNOWN"],
    ["1.2.64.0/18"     => "UNKNOWN"],
    ["1.2.128.0/17"    => "UNKNOWN"],
    ["1.3.0.0/16"      => "UNKNOWN"],
    ["1.4.0.0/14"      => "UNKNOWN"],
    ["1.8.0.0/13"      => "UNKNOWN"],
    ["1.16.0.0/12"     => "UNKNOWN"],
    ["1.32.0.0/11"     => "UNKNOWN"],
    ["1.64.0.0/10"     => "UNKNOWN"],
    ["1.128.0.0/9"     => "UNKNOWN"],
    ["2.0.0.0/7"       => "UNKNOWN"],
    ["4.0.0.0/6"       => "UNKNOWN"],
    ["8.0.0.0/7"       => "UNKNOWN"],
    ["10.0.0.0/13"     => "UNKNOWN"],
    ["10.8.0.0/15"     => "UNKNOWN"],
    ["10.10.0.0/16"    => "UNKNOWN"],
    ["10.11.0.0/21"    => "UNKNOWN"],
    ["10.11.8.0/22"    => "UNKNOWN"],
    ["10.11.12.0/27"   =>  "label4"],
    ["10.11.12.32/27"  =>  "label3"],
    ["10.11.12.64/26"  =>  "label3"],
    ["10.11.12.128/25" => "UNKNOWN"],
    ["10.11.13.0/24"   => "UNKNOWN"],
    ["10.11.14.0/23"   => "UNKNOWN"],
    ["10.11.16.0/20"   => "UNKNOWN"],
    ["10.11.32.0/19"   => "UNKNOWN"],
    ["10.11.64.0/18"   => "UNKNOWN"],
    ["10.11.128.0/17"  => "UNKNOWN"],
    ["10.12.0.0/14"    => "UNKNOWN"],
    ["10.16.0.0/12"    => "UNKNOWN"],
    ["10.32.0.0/11"    => "UNKNOWN"],
    ["10.64.0.0/10"    => "UNKNOWN"],
    ["10.128.0.0/9"    => "UNKNOWN"],
    ["11.0.0.0/8"      => "UNKNOWN"],
    ["12.0.0.0/6"      => "UNKNOWN"],
    ["16.0.0.0/4"      => "UNKNOWN"],
    ["32.0.0.0/3"      => "UNKNOWN"],
    ["64.0.0.0/2"      => "UNKNOWN"],
    ["128.0.0.0/1"     => "UNKNOWN"],
  );

  my($pmap, @entries, @results);

  my $test_ranges = sub {
    my($entries, $label) = @_;
    $pmap = new_ipv4_pmap();
    for (@$entries) {
      $pmap->add($_);
    }
    @results = $pmap->iter_ranges->();
    is_deeply(\@results, \@ref_range, "add range $label");
    $pmap = new_ipv4_pmap();
    $pmap->add_all($entries);
    @results = $pmap->iter_ranges->();
    is_deeply(\@results, \@ref_range, "add_all range $label");
  };

  @entries = @ranges;
  $test_ranges->(\@entries, "[k, l]");
  @entries = map { [split(/-/, $_->[0]), $_->[1]] } @ranges;
  $test_ranges->(\@entries, "[hi, lo, l]");
  @entries = map { [[split(/-/, $_->[0])], $_->[1]] } @ranges;
  $test_ranges->(\@entries, "[[hi, lo], l]");
  @entries = map { [SILK_RANGE_CLASS->new($_->[0]), $_->[1]] } @ranges;
  $test_ranges->(\@entries, "[range, l]");

  my $test_prefixes = sub {
    my($entries, $label) = @_;
    $pmap = new_ipv4_pmap();
    for (@$entries) {
      $pmap->add($_);
    }
    @results = $pmap->iter_cidr->();
    is_deeply(\@results, \@ref_prefix, "add cidr $label");
    $pmap = new_ipv4_pmap();
    $pmap->add_all($entries);
    @results = $pmap->iter_cidr->();
    is_deeply(\@results, \@ref_prefix, "add_all cidr $label");
  };

  @entries = @prefixes;
  $test_prefixes->(\@entries, "[k, l]");
  @entries = map { [SILK_CIDR_CLASS->new($_->[0]), $_->[1]] } @prefixes;
  $test_prefixes->(\@entries, "[cidr, l]");

}

###

sub test_all {
  SKIP: {
    skip("pmap test files not present", 5) unless t_pmap_files_exist();
    subtest "load"         => \&test_load;
    subtest "get ip"       => \&test_get_ip;
    subtest "get pp"       => \&test_get_pp;
    subtest "values"       => \&test_values;
    subtest "ranges"       => \&test_ranges;
    subtest "construction" => \&test_construction;
  }
}

test_all();

###
