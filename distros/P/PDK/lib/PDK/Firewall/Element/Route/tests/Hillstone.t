#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;

use PDK::Firewall::Element::Route::Netscreen;

my $route;

ok(
  do {
    eval { $route = PDK::Firewall::Element::Route::Netscreen->new(fwId => 1, network => '10.0.0.0', mask => '8') };
    warn $@ if !!$@;
    $route->isa('PDK::Firewall::Element::Route::Netscreen');

  },
  ' 生成 PDK::Firewall::Element::Route::Netscreen 对象'
);

ok(
  do {
    eval { $route = PDK::Firewall::Element::Route::Netscreen->new(fwId => 1, network => '10.0.0.0', mask => '8') };
    warn $@ if !!$@;
    p $route->sign;
    $route->sign eq '10.0.0.0<|>8';
  },
  ' lazy生成 sign'
);

done_testing;

