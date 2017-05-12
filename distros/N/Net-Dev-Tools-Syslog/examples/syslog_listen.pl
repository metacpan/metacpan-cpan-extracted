#!/usr/bin/perl
#
# Perl script to test Net::Dev::Tools::Syslog listen
#
#


use strict;
use Net::Dev::Tools::Syslog;


my ($listen_obj, $error,
    $ok,
);

my $port  = 7971;
my $proto = 'udp';

# create object to listen
# CTRL-C will close sock and return to caller
($listen_obj, $error) =  Syslog->listen(
    -port       => $port,
    -proto      => $proto,
    #-verbose    => 3,
    #-packets    => 150,
    #-parseTag   => 1,
);

unless ($listen_obj) {
   printf("ERROR: syslog listen failed: %s\n", $error);
  exit(1);
}


exit(0);
