#!/usr/bin/perl -w
use strict;
use FindBin;
use lib ("$FindBin::Bin/../../lib");
use Mobile::UserAgentFactory;

my $factory = Mobile::UserAgentFactory->instance();


# loopy loopy to see if the factory's cache works.
for (0..1) {
  my $mua = $factory->getMobileUserAgent('Nokia6600/1.0 (4.09.1) SymbianOS/7.0s Series60/2.0 Profile/MIDP-2.0 Configuration/CLDC-1.0', {'debug' => 1});

  if (defined($mua)) {
    print ref($mua) . " instance created.\n";
    if ($mua->success()) {
      print ref($mua) . " instance is usable.\n";
      printf("Vendor: %s\nModel: %s\n", $mua->vendor(), $mua->model());
    }
    else {
      print ref($mua) . " instance is useless.\n";
    }
  }
  else {
    print "Failed to parse useragent. This sux!\n";
  }
}
