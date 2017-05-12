use strict;
use Test;
BEGIN { plan test => 35; }

use Net::IPv6Addr;
ok(1);

my $w = new Net::IPv6Addr("ab:cd:ef:01:23:45:67:89");
ok($w->to_string_preferred(), "ab:cd:ef:1:23:45:67:89");
ok($w->to_string_compressed(), "ab:cd:ef:1:23:45:67:89");
eval { $w->to_string_ipv4(); };
ok($@);
ok($@, qr/not originally an IPv4 address/);
eval { $w->to_string_ipv4_compressed(); };
ok($@);
ok($@, qr/not originally an IPv4 address/);
ok($w->to_string_ip6_int(), "9.8.0.0.7.6.0.0.5.4.0.0.3.2.0.0.1.0.0.0.f.e.0.0.d.c.0.0.b.a.0.0.IP6.INT.");

my $x = new Net::IPv6Addr("::");
ok($x->to_string_preferred(), "0:0:0:0:0:0:0:0");
ok($x->to_string_compressed(), "::");
ok($x->to_string_ipv4(), "0:0:0:0:0:0:0.0.0.0");
ok($x->to_string_ipv4_compressed(), "::0.0.0.0");
ok($x->to_string_ip6_int(), "0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.IP6.INT.");

my $y = new Net::IPv6Addr("::1");
ok($y->to_string_preferred(), "0:0:0:0:0:0:0:1");
ok($y->to_string_compressed(), "::1");
ok($y->to_string_ipv4(), "0:0:0:0:0:0:0.0.0.1");
ok($y->to_string_ipv4_compressed(), "::0.0.0.1");
ok($y->to_string_ip6_int(), "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.IP6.INT.");

my $z = new Net::IPv6Addr("abcd:ef12::3456:789a");
ok($z->to_string_preferred(), "abcd:ef12:0:0:0:0:3456:789a");
ok($z->to_string_compressed(), "abcd:ef12::3456:789a");
eval { $w->to_string_ipv4(); };
ok($@);
ok($@, qr/not originally an IPv4 address/);
eval { $w->to_string_ipv4_compressed(); };
ok($@);
ok($@, qr/not originally an IPv4 address/);
ok($z->to_string_ip6_int(), "a.9.8.7.6.5.4.3.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.1.f.e.d.c.b.a.IP6.INT.");

my $p = new Net::IPv6Addr("::ffff:10.0.0.1");
ok($p->to_string_preferred(), "0:0:0:0:0:ffff:a00:1");
ok($p->to_string_compressed(), "::ffff:a00:1");
ok($p->to_string_ipv4(), "0:0:0:0:0:ffff:10.0.0.1");
ok($p->to_string_ipv4_compressed(), "::ffff:10.0.0.1");
ok($p->to_string_ip6_int(), "1.0.0.0.0.0.a.0.f.f.f.f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.IP6.INT.");

my $q = new Net::IPv6Addr("0:0:0:0:0:0:10.0.0.1");
ok($q->to_string_preferred(), "0:0:0:0:0:0:a00:1");
ok($q->to_string_compressed(), "::a00:1");
ok($q->to_string_ipv4(), "0:0:0:0:0:0:10.0.0.1");
ok($q->to_string_ipv4_compressed(), "::10.0.0.1");
ok($q->to_string_ip6_int(), "1.0.0.0.0.0.a.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.IP6.INT.");
