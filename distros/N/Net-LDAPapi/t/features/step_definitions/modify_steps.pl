#!/usr/bin/perl

use strict;
use warnings;
  
use Test::More;
use Test::BDD::Cucumber::StepFile;

our %TestConfig = %main::TestConfig;

use Data::Dumper;

When qr/I've (asynchronously )?added a new attribute to the new entry/i, sub {
  my $async = $1 ? 1 : 0;
  
  S->{'new attribute_result'} = 'skipped';

  return if S->{'bind_result'} eq 'skipped';

  my $func = 'modify_ext_s';
  my %args = ();
  
  if ($async) {
    $func = 'modify_ext';
  }
  S->{'new attribute_async'} = $async;
  
  $args{'-dn'} = sprintf('%s,%s,%s', $TestConfig{'data'}{'entry_dn'}, $TestConfig{'data'}{'test_container_dn'}, $TestConfig{'ldap'}{'base_dn'});
  $args{'-mod'} = $TestConfig{'modify'}{'new_attribute'};
 
  S->{'new attribute_result'} = S->{'object'}->$func(%args);
};

When qr/I've (asynchronously )?modified the new attribute on the new entry/i, sub {
  my $async = $1 ? 1 : 0;
  
  S->{'modified attribute_result'} = 'skipped';

  return if S->{'bind_result'} eq 'skipped';

  my $func = 'modify_s';
  my %args = ();
  
  if ($async) {
    $func = 'modify';
  }
  S->{'modified attribute_async'} = $async;
  
  $args{'-dn'} = sprintf('%s,%s,%s', $TestConfig{'data'}{'entry_dn'}, $TestConfig{'data'}{'test_container_dn'}, $TestConfig{'ldap'}{'base_dn'});
  $args{'-mod'} = $TestConfig{'modify'}{'modify_attribute'};
 
  S->{'modified attribute_result'} = S->{'object'}->$func(%args);
};

When qr/I've (asynchronously )?removed the new attribute from the new entry/i, sub {
  my $async = $1 ? 1 : 0;
  
  S->{'removed attribute_result'} = 'skipped';

  return if S->{'bind_result'} eq 'skipped';

  my $func = 'modify_s';
  my %args = ();
  
  if ($async) {
    $func = 'modify';
  }
  S->{'removed attribute_async'} = $async;
  
  $args{'-dn'} = sprintf('%s,%s,%s', $TestConfig{'data'}{'entry_dn'}, $TestConfig{'data'}{'test_container_dn'}, $TestConfig{'ldap'}{'base_dn'});
  $args{'-mod'} = $TestConfig{'modify'}{'remove_attribute'};
 
  S->{'removed attribute_result'} = S->{'object'}->$func(%args);
};

1;
