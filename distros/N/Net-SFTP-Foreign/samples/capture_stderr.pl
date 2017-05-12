#!/usr/bin/perl

use strict;
use warnings;

use Net::SFTP::Foreign;
use File::Temp;

my $hostname = shift // 'localhost';

my $ssherr = File::Temp->new or die "tempfile failed";

my $sftp = Net::SFTP::Foreign->new($hostname, more => qw(-v), stderr_fh => $ssherr);

if ($sftp->error) {
  print "sftp error: ".$sftp->error."\n";
  seek($ssherr, 0, 0);
  while (<$ssherr>) {
    print " ssh error: $_";
  }
}

close $ssherr;

