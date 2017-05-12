#!/usr/bin/perl

use strict;
use warnings;
  
use Test::More;
use Test::BDD::Cucumber::StepFile;

our %TestConfig = %main::TestConfig;

use Data::Dumper;

When qr/I've (asynchronously )?moved the new entry to the new container/i, sub {
  my $async = $1 ? 1 : 0;
  
  S->{'rename entry_result'} = 'skipped';

  return if S->{'bind_result'} eq 'skipped';

  my $func = 'rename_s';
  my %args = ();
  
  if ($async) {
    $func = 'rename';
  }
  S->{'rename entry_async'} = $async;
  
  $args{'-dn'} = sprintf('%s,%s,%s', $TestConfig{'data'}{'entry_dn'}, $TestConfig{'data'}{'test_container_dn'}, $TestConfig{'ldap'}{'base_dn'});
  $args{'-newsuper'} = sprintf('%s,%s,%s', $TestConfig{'rename'}{'new_super'}, $TestConfig{'data'}{'test_container_dn'}, $TestConfig{'ldap'}{'base_dn'});
  $args{'-newrdn'} = $TestConfig{'rename'}{'new_rdn'};
 
  S->{'rename entry_result'} = S->{'object'}->$func(%args);
};

1;
