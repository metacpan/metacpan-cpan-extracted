#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::Input;

use IO::Select;

@ARGV || die "socket spec required\n";

my $spec = @ARGV == 2 ? join('/', @ARGV) : shift;

my $n = Net::Nmsg::Input->open($spec);

my $s = IO::Select->new($n);

my $count = 0;

while (1) {
  if ($s->can_read(1)) {
    my $m = $n->read;
    ++$count;
    printf "got nmsg %d: %s\n", $count, $m->headers_as_str();
  }
  else {
    printf "time is now %s\n", scalar(gmtime());
  }
}
