#!/usr/bin/perl

# Extract non-NOERROR responses from a ch202 file. Useful for
# pre-parsing while looking for NXDOMAIN DGA names.

use strict;
use warnings;

use Net::Nmsg::Input;
use Net::WDNS qw(:func);

my $file = shift or die "ch202 filename required";

my $i = Net::Nmsg::Input->open($file);
while (my $m = <$i>) {
  my $rcode = $m->get_rcode();
  my $qname = $m->get_qname();
  my $qtype = $m->get_qtype();
  if ($rcode && $qname && $qtype) {
    printf("%s %s %s\n", rcode_to_str($rcode),
                         rrtype_to_str($qtype),
                         domain_to_str($qname));
  }
}
