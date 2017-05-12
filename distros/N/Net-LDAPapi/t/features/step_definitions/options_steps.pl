#!/usr/bin/perl

use strict;
use warnings;
  
use Net::LDAPapi;  
use Test::More;
use Test::BDD::Cucumber::StepFile;

our %TestConfig = %main::TestConfig;

When qr/I've set option (.+?) with value (.+)/i, sub {
  my $option = $1;
  my $value = int($2);
  
  my $status = S->{'object'}->set_option(S->{'object'}->$option, $value);
  
  is(ldap_err2string($status), ldap_err2string(LDAP_SUCCESS), "Was option successfully set?");
};

Then qr/option (.+?) has value (.+)/i, sub {
  my $option = $1;
  my $value = $2;
  
  my $data;
  
  my $status = S->{'object'}->get_option(S->{'object'}->$option, \$data);
  
  is(ldap_err2string($status), ldap_err2string(LDAP_SUCCESS), "Was option successfully retrieved?");
  is($data, $value, "Is the option set to the expected value?");
};

1;
