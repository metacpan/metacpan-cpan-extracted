#!/usr/bin/env perl

BEGIN {
  if ($] ge '5.012') {
    use strict;
    use warnings;
  }
}

use lib '.';
use Net::IPAddress::Util qw( :constr );
use Net::IPAddress::Util::Range;
use Net::IPAddress::Util::Collection;
use Test::More tests => 1;

$Net::IPAddress::Util::DIE_ON_ERROR = 1;
$Net::IPAddress::Util::PROMOTE_N32 = 0;

{
  # diag('autarch CVE');
  my $test = IP('010.168.0.1');
  is($test->str(), '8.168.0.1', "autarch CVE");
}
