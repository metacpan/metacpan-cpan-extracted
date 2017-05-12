#!/usr/bin/perl
use strict;
use warnings;

use Net::Sieve;

my $sieve = Net::Sieve->new (
      server => 'imap.server.org',
      user => 'user',
      password => 'pass' ,
);


my $test_script='require "fileinto";
# Place all these in the "Test" folder
if header :contains "Subject" "[Test]" {
           fileinto "Test";
}
';

my $name_script = 'test';

# write
$sieve->put($name_script,$test_script);

# read
my %Script;
foreach my $script ( $sieve->list() ) {
    print 'name: ['.$script->{name}.'], status: '.$script->{status}."\n";
    print $sieve->get($script->{name});
    print "=====\n";
};

