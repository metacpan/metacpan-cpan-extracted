#!/usr/bin/perl

use strict;
use warnings;
  
use Test::More;
use Test::BDD::Cucumber::StepFile;

our %TestConfig = %main::TestConfig;

use Data::Dumper;

When qr/I've (asynchronously )?deleted the new (entry|container) from the directory/i, sub {
  my $async = $1 ? 1 : 0;
  my $type = lc($2);
  
  S->{'delete ' . $type . '_result'} = 'skipped';

  return if S->{'bind_result'} eq 'skipped';

  my $func = 'delete_s';
  my %args = ();
  
  if ($async) {
    $func = 'delete';
  }
  S->{'delete ' . $type . '_async'} = $async;
  
  $args{'-dn'} = sprintf('%s,%s,%s', $TestConfig{'data'}{$type . '_dn'}, $TestConfig{'data'}{'test_container_dn'}, $TestConfig{'ldap'}{'base_dn'});
 
  S->{'delete ' . $type . '_result'} = S->{'object'}->$func(%args);
};

1;
