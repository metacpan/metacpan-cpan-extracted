#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Data::Printer;

use PDK::Firewall::Element::Route::Asa;

my $route;

ok(
  do {
    eval { $route = PDK::Firewall::Element::Route::Asa->new(fwId => 1, network => '10.0.0.0', mask => '8') };
    warn $@ if !!$@;
    $route->isa('PDK::Firewall::Element::Route::Asa');

  },
  ' 生成 PDK::Firewall::Element::Route::Asa 对象'
);

ok(
  do {
    eval { $route = PDK::Firewall::Element::Route::Asa->new(fwId => 1, network => '10.0.0.0', mask => '8') };
    warn $@ if !!$@;
    $route->sign eq '10.0.0.0<|>8';
  },
  ' lazy生成 sign'
);

done_testing;

