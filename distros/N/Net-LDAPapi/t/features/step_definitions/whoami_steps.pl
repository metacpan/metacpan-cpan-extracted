#!/usr/bin/perl

use strict;
use warnings;
  
use Test::More;
use Test::BDD::Cucumber::StepFile;

our %TestConfig = %main::TestConfig;

When qr/I\'ve (asynchronously )?queried the directory for my identity/, sub {
  my $async = $1 ? 1 : 0;

  S->{'identity_authzid'} = undef;
  S->{'identity_result'} = "skipped";

  return if S->{"bind_result"} eq "skipped";

  my $func = "whoami_s";
  my %args = ();
  
  if ($async) {
    $func = "whoami";
  } else {
    %args = ('-authzid' => \S->{'identity_authzid'});
  }
  S->{'identity_async'} = $async;
   
  S->{'identity_result'} = S->{'object'}->$func(%args);
};

Then qr/the identity matches/, sub {
  SKIP: {
    
    skip(S->{'bind_type'} . " authentication disabled in t/test-config.pl", 1) if S->{"bind_result"} eq "skipped";

    my ($got, $expected);
    
    if (S->{'identity_async'}) {
      $got = S->{'object'}->parse_whoami(S->{'identity_result_id'});       
    } else {
      $got = S->{'identity_authzid'};
    }

    S->{'identity_got'} = $got;
        
    if (S->{'bind_type'} eq "anonymous") {
      $expected = "";
    } elsif (S->{'bind_type'} eq "simple") {
      my ($attr, $value) = split(/:/, $got);
      
      $got = $value;
      $expected = $TestConfig{'ldap'}{'bind_types'}{'simple'}{'bind_dn'};
    } elsif (S->{'bind_type'} eq "sasl") {
      my ($attr, $value) = split(/:/, $got);
      
      $got = $value;
      $expected = $TestConfig{'ldap'}{'bind_types'}{'sasl'}{'identity'};
    }
    
    is(lc($got), lc($expected), "Does expected identity match received identity?");    
  }
};

1;
