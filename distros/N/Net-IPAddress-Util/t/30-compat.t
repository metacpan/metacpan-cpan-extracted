#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
  if ($] ge '5.026') {
    use lib '.';
  }
}

use Test::More tests => 5;

SKIP: {

  my (
    $old_dq, $old_num, $old_vld, $old_nvd, $old_msk, $old_hn, $old_dn,
    $new_dq, $new_num, $new_vld, $new_nvd, $new_msk, $new_hn, $new_dn,
  );

  my $std_dq  = '192.168.0.1';
  my $std_num = 3232235521;
  my $std_msk = '192.168.0.0';
  my $std_vld = 1;
  my $std_nvd = 0;

  my $std_fqdn = 'www.cpan.org';
  my $std_hn   = 'www';
  my $std_dn   = 'cpan.org';

  {
    eval "require Net::IPAddress";
    skip("Net::IPAddress cannot be loaded for compatibility testing", 5) if $@;
    $old_num = Net::IPAddress::ip2num($std_dq);
    $old_dq  = Net::IPAddress::num2ip($std_num);
    $old_vld = Net::IPAddress::validaddr($std_dq) || 0;
    $old_nvd = Net::IPAddress::validaddr('foo')   || 0;
    $old_msk = Net::IPAddress::mask($std_dq, '255.255.255.0');
    ($old_hn, $old_dn) = Net::IPAddress::fqdn($std_fqdn);
  }

diag('Some deprecation warnings here are normal') if $^W;

  {
    eval "require Net::IPAddress::Util";
    skip("Something horrible has happened: $@", 5) if $@;
    $new_num = Net::IPAddress::Util::ip2num($std_dq);
    $new_dq  = Net::IPAddress::Util::num2ip($std_num);
    $new_vld = Net::IPAddress::Util::validaddr($std_dq) || 0;
    $new_nvd = Net::IPAddress::Util::validaddr('foo')   || 0;
    $new_msk = Net::IPAddress::Util::mask($std_dq, '255.255.255.0');
    ($new_hn, $new_dn) = Net::IPAddress::Util::fqdn($std_fqdn);
  };

  ok($old_num   ==  $new_num  && $new_num   == $std_num  , 'ip2num()');
  ok("$old_dq"  eq "$new_dq"  && "$new_dq"  eq "$std_dq" , 'num2ip()');
  ok($old_vld   ==  $new_vld  && $old_nvd   == $new_nvd  , 'validaddr()');
  ok("$old_msk" eq "$new_msk" && "$new_msk" eq "$std_msk", 'mask()');
  ok(
    "$old_hn"    eq "$new_hn"
    && "$old_dn" eq "$new_dn"
    && "$old_hn" eq "$std_hn"
    && "$old_dn" eq "$std_dn",
    'fqdn()'
  );

};
