#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/SOAP-Lite/lib/";
use Server;

use SOAP::Transport::HTTP;

$SIG{PIPE} = 'IGNORE';

# change LocalPort to 81 if you want to test it with soapmark.pl

my $daemon = SOAP::Transport::HTTP::Daemon
  # if you do not specify LocalAddr then you can access it with 
  # any hostname/IP alias, including localhost or 127.0.0.1. 
  # if do you specify LocalAddr in ->new() then you can only access it 
  # from that interface. -- Michael Percy <mpercy@portera.com>
  -> new (LocalAddr => 'localhost', LocalPort => 8080, Reuse => 1,) 
  # you may also add other options, like 'Reuse' => 1 and/or 'Listen' => 128

  # specify list of objects-by-reference here 
  -> objects_by_reference(qw(My::PersistentIterator My::SessionIterator My::Chat))

  # specify path to My/Examples.pm here
  -> dispatch_to('Server') 

  # enable compression support
  -> options({compress_threshold => 10000})
;
print "Contact to SOAP server at ", $daemon->url, "\n";
$daemon->handle;
