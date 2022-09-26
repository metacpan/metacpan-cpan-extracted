
#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;
use PDK::Firewall::Element::ServiceMeta::Netscreen;

my $serviceMeta;
ok(
  do {
    eval {
      $serviceMeta = PDK::Firewall::Element::ServiceMeta::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'tcp',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
    };
    warn $@ if !!$@;
    ref $serviceMeta eq 'PDK::Firewall::Element::ServiceMeta::Netscreen' ? 1 : 0;
  },
  ' 生成 PDK::Firewall::Element::ServiceMeta::Netscreen 对象'
);

ok(
  do {
    eval {
      $serviceMeta = PDK::Firewall::Element::ServiceMeta::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'tcp',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
    };
    warn $@ if !!$@;
    $serviceMeta->sign eq 'a<|>tcp<|>c<|>1525-1559';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $serviceMeta = PDK::Firewall::Element::ServiceMeta::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'tcp',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
    };
    warn $@ if !!$@;
    $serviceMeta->dstPortRange->min == 1525 and $serviceMeta->dstPortRange->max == 1559;
  },
  ' 自动生成dstPortRange'
);

done_testing;
