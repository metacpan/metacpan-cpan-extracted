#!/usr/bin/perl

use strict;
use warnings;
  
use Test::More;
use Test::BDD::Cucumber::StepFile;

our %TestConfig = %main::TestConfig;

use Data::Dumper;

When qr/I've (asynchronously )?compared to an attribute on the new (entry|container)/i, sub {
  my $async = $1 ? 1 : 0;
  my $type = lc($2);
  
  S->{'new ' . $type . ' comparison_result'} = 'skipped';

  return if S->{'bind_result'} eq 'skipped';

  my $func = 'compare_ext_s';
  my %args = ();
  
  if ($async) {
    $func = 'compare_ext';
  }
  S->{'new ' . $type . ' comparison_async'} = $async;
  
  $args{'-dn'} = sprintf('%s,%s,%s', $TestConfig{'data'}{$type . '_dn'}, $TestConfig{'data'}{'test_container_dn'}, $TestConfig{'ldap'}{'base_dn'});
  $args{'-attr'} = $TestConfig{'compare'}{$type . '_attribute'};
  $args{'-value'} = $TestConfig{'data'}{$type . '_attributes'}{$args{'-attr'}};
  
  S->{'new ' . $type . ' comparison_result'} = S->{'object'}->$func(%args);
};

1;
