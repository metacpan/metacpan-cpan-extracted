#!/usr/bin/perl

use strict;
use warnings;
  
use Test::More;
use Test::BDD::Cucumber::StepFile;

our %TestConfig = %main::TestConfig;

use Data::Dumper;

When qr/I've (asynchronously )?added a new (entry|container) to the directory/i, sub {
  my $async = $1 ? 1 : 0;
  my $type = lc($2);
  
  S->{'new ' . $type . '_result'} = 'skipped';

  return if S->{'bind_result'} eq 'skipped';

  my $func = 'add_ext_s';
  my %args = ();
  
  if ($async) {
    $func = 'add_ext';
  }
  S->{'new ' . $type . '_async'} = $async;
  
  $args{'-dn'} = sprintf('%s,%s,%s', $TestConfig{'data'}{$type . '_dn'}, $TestConfig{'data'}{'test_container_dn'}, $TestConfig{'ldap'}{'base_dn'});
  $args{'-mod'} = $TestConfig{'data'}{$type . '_attributes'};
 
  S->{'new ' . $type . '_result'} = S->{'object'}->$func(%args);
};

1;
