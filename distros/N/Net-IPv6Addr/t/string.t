use warnings;
use strict;
use Test::More;

use Net::IPv6Addr;

my $w = new Net::IPv6Addr("ab:cd:ef:01:23:45:67:89");
is($w->to_string_preferred(), "ab:cd:ef:1:23:45:67:89");
is($w->to_string_compressed(), "ab:cd:ef:1:23:45:67:89");
is ($w->to_string_ipv4(), "ab:cd:ef:1:23:45:0.103.0.137");
is ($w->to_string_ipv4_compressed(), "ab:cd:ef:1:23:45:0.103.0.137");

is($w->to_string_ip6_int(), "9.8.0.0.7.6.0.0.5.4.0.0.3.2.0.0.1.0.0.0.f.e.0.0.d.c.0.0.b.a.0.0.IP6.INT.");

my $x = new Net::IPv6Addr("::");
is($x->to_string_preferred(), "0:0:0:0:0:0:0:0");
is($x->to_string_compressed(), "::");
is($x->to_string_ipv4(), "0:0:0:0:0:0:0.0.0.0");
is($x->to_string_ipv4_compressed(), "::0.0.0.0");
is($x->to_string_ip6_int(), "0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.IP6.INT.");

my $y = new Net::IPv6Addr("::1");
is($y->to_string_preferred(), "0:0:0:0:0:0:0:1");
is($y->to_string_compressed(), "::1");
is($y->to_string_ipv4(), "0:0:0:0:0:0:0.0.0.1");
is($y->to_string_ipv4_compressed(), "::0.0.0.1");
is($y->to_string_ip6_int(), "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.IP6.INT.");

my $z = new Net::IPv6Addr("abcd:ef12::3456:789a");
is($z->to_string_preferred(), "abcd:ef12:0:0:0:0:3456:789a");
is($z->to_string_compressed(), "abcd:ef12::3456:789a");
is ($z->to_string_ipv4, 'abcd:ef12:0:0:0:0:52.86.120.154');
is($z->to_string_ip6_int(), "a.9.8.7.6.5.4.3.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.1.f.e.d.c.b.a.IP6.INT.");
is ($z->to_string_ipv4_compressed, 'abcd:ef12::52.86.120.154');

my $p = new Net::IPv6Addr("::ffff:10.0.0.1");
is($p->to_string_preferred(), "0:0:0:0:0:ffff:a00:1");
is($p->to_string_compressed(), "::ffff:a00:1");
is($p->to_string_ipv4(), "0:0:0:0:0:ffff:10.0.0.1");
is($p->to_string_ipv4_compressed(), "::ffff:10.0.0.1");
is($p->to_string_ip6_int(), "1.0.0.0.0.0.a.0.f.f.f.f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.IP6.INT.");

my $q;
$q = new Net::IPv6Addr("0:0:0:0:0:0:10.0.0.1");
is($q->to_string_preferred(), "0:0:0:0:0:0:a00:1");
is($q->to_string_compressed(), "::a00:1");
is($q->to_string_ipv4(), "0:0:0:0:0:0:10.0.0.1");
is($q->to_string_ipv4_compressed(), "::10.0.0.1");
is($q->to_string_ip6_int(), "1.0.0.0.0.0.a.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.IP6.INT.");

done_testing ();
