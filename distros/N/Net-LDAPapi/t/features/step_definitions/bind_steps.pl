#!/usr/bin/perl

use strict;
use warnings;

#use Net::LDAPapi;
use Test::More;
use Test::BDD::Cucumber::StepFile;

our %TestConfig = %main::TestConfig;

When qr/I've (asynchronously )?bound with (.+?) authentication to the directory/, sub {
  my $async = $1 ? 1 : 0;
  my $type = lc($2);

  my $func = "bind_s";
  my %args = ();
  
  if ($async) {
    $func = "bind";
  }
  S->{'bind_async'} = $async;
      
  if ($type eq "default") {
    $type = lc($TestConfig{'ldap'}{'default_bind_type'});
  }
  S->{'bind_type'} = $type;

  S->{'bind_result'} = "skipped";
  
  if ($type eq "anonymous") {
    return if $TestConfig{'ldap'}{'bind_types'}{'anonymous'}{'enabled'} != 1;
  } elsif ($type eq "simple") {
    return if $TestConfig{'ldap'}{'bind_types'}{'simple'}{'enabled'} != 1;

    %args = (
        -dn => $TestConfig{'ldap'}{'bind_types'}{'simple'}{'bind_dn'},
        -password => $TestConfig{'ldap'}{'bind_types'}{'simple'}{'bind_pw'}
    );
  } elsif ($type eq "sasl") {
    return if $TestConfig{'ldap'}{'bind_types'}{'sasl'}{'enabled'} != 1;
    
    S->{'object'}->sasl_parms(%{$TestConfig{'ldap'}{'bind_types'}{'sasl'}{'sasl_parms'}});

    %args = (
        -type => S->{'object'}->LDAP_AUTH_SASL
    );
  }
    
  S->{'bind_result'} = S->{'object'}->$func(%args);
};

1;
