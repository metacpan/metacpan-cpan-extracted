use strict;
use warnings;

use Test::More;

use Net::Continental;

{
  my $zone = Net::Continental->zone('ru');

  isa_ok($zone, 'Net::Continental::Zone');
  is($zone->code, 'ru', 'ru is ru');
  like($zone->description, qr{russia}i, 'ru is Russia');
  ok($zone->is_tld, 'ru is a tld');
  is($zone->nerd_response, '127.0.2.131', 'ru has expected nerd response');
}

{
  my $zone = Net::Continental->zone('tw');

  isa_ok($zone, 'Net::Continental::Zone');
  is($zone->code, 'tw', 'tw is tw');
  like($zone->description, qr{Taiwan}i, 'tw is Taiwan');
  ok($zone->is_tld, 'tw is a tld');
  is($zone->nerd_response, '127.0.0.158', 'tw has expected nerd response');
}

{
  my $zone = Net::Continental->zone('gb');

  isa_ok($zone, 'Net::Continental::Zone');
  is($zone->code, 'gb', 'gb is gb');
  is($zone->tld,  'uk', 'gb tld is uk');
  like($zone->description, qr{United Kingdom}i, 'gb is United Kingdom');
  ok($zone->is_tld, 'uk is not a tld');
  is($zone->nerd_response, '127.0.3.58', 'gb has expected nerd response');
}

{
  my $zone = Net::Continental->zone('uk');

  isa_ok($zone, 'Net::Continental::Zone');
  is($zone->code, 'gb', 'uk is gb');
  is($zone->tld,  'uk', 'uk tld is uk');
  like($zone->description, qr{United Kingdom}i, 'uk is United Kingdom');
  ok($zone->is_tld, 'uk is a tld');
  is($zone->nerd_response, '127.0.3.58', 'uk has expected nerd response');
}

{
  my $zone = Net::Continental->zone('ax');

  isa_ok($zone, 'Net::Continental::Zone');
  is($zone->code, 'ax', 'ax is ax');
  like($zone->description, qr{aland islands}i, 'ax is Aland Islands');
  ok($zone->is_tld, 'ax is a tld');
}

{
  my $zone = Net::Continental->zone_for_nerd_ip('127.0.3.72');
  is($zone ? $zone->code : undef, 'us', "127.0.3.72 means US ip");
}

{
  my $zone = eval { Net::Continental->zone_for_nerd_ip() };

  ok(! $zone, "you can't get the zone for a non-IP");
}

{
  my $zone = eval { Net::Continental->zone('oo') };

  ok(! $zone, "there is no oo zone");
}

done_testing;
