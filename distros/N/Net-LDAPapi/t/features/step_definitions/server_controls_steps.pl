#!/usr/bin/perl

use strict;
use warnings;
  
use Test::More;
use Test::BDD::Cucumber::StepFile;

use Net::LDAPapi;
use Convert::ASN1;

our %TestConfig = %main::TestConfig;

use Data::Dumper;

Given qr/the server side sort control definition/i, sub { 
  if (!defined(S->{'asn'}{'server side sort'})) {
    S->{'asn'}{'server side sort'} = Convert::ASN1->new;
  
    S->{'asn'}{'server side sort'}->prepare(<<ASN) or die "prepare: ", S->{'asn'}{'server side sort'}->error;
  
  SortKey ::= SEQUENCE {
    attributeType   OCTET STRING,
    orderingRule    [0] OCTET STRING OPTIONAL,
    reverseOrder    [1] BOOLEAN }

  SortKeyList ::= SEQUENCE OF SortKey

  SortResult ::= SEQUENCE {
    sortResult  ENUMERATED,
    attributeType [0] OCTET STRING OPTIONAL }

ASN
  }
};

Given qr/the virtual list view control definition/i, sub { 
  if (!defined(S->{'asn'}{'virtual list view'})) {
    S->{'asn'}{'virtual list view'} = Convert::ASN1->new;
  
    S->{'asn'}{'virtual list view'}->prepare(<<ASN) or die "prepare: ", S->{'asn'}{'virtual list view'}->error;
  
  VirtualListViewRequest ::= SEQUENCE {
    beforeCount    INTEGER,
    afterCount     INTEGER,
    target       CHOICE {
      byOffset        [0] SEQUENCE {
        offset          INTEGER,
        contentCount    INTEGER
      },
      greaterThanOrEqual [1] OCTET STRING
    },
    contextID OCTET STRING OPTIONAL
  }

  VirtualListViewResponse ::= SEQUENCE {
    targetPosition    INTEGER,
    contentCount     INTEGER,
    virtualListViewResult ENUMERATED,
    contextID OCTET STRING OPTIONAL
  }

ASN
  }
};

When qr/I've created a server side sort control/i, sub {
  my $sss = S->{'asn'}{'server side sort'}->find('SortKeyList');

  my $sss_berval = $sss->encode($TestConfig{'server_controls'}{'sss'}) or die S->{'asn'}{'server side sort'}->error;

  my $sss_ctrl = S->{'object'}->create_control(
    -oid => '1.2.840.113556.1.4.473',
    -berval => $sss_berval,
  );

  S->{'server_controls'}{'server side sort'} = $sss_ctrl;
};

When qr/I've created a virtual list view control/i, sub {
  my $vlv = S->{'asn'}{'virtual list view'}->find('VirtualListViewRequest');

  my $vlv_berval = $vlv->encode($TestConfig{'server_controls'}{'vlv'}) or die S->{'asn'}{'virtual list view'}->error;

  my $vlv_ctrl = S->{'object'}->create_control(
    -oid => '2.16.840.1.113730.3.4.9',
    -berval => $vlv_berval,
  );

  S->{'server_controls'}{'virtual list view'} = $vlv_ctrl;
};

Then qr/the server side sort control was successfully used/i, sub {
  my $sss_response = S->{'asn'}{'server side sort'}->find('SortResult');

  my $berval = undef;
  
  foreach my $ctrl (@{S->{'cache'}{'serverctrls'}}) {
    my $ctrl_oid = S->{'object'}->get_control_oid($ctrl);
    
    if ($ctrl_oid eq '1.2.840.113556.1.4.474') {
      $berval = S->{'object'}->get_control_berval($ctrl);
      last;
    }
  }
  
  isnt($berval, undef, "Was a berval returned?");
  
  my $result = $sss_response->decode($berval) || ok(0, $sss_response->error);

  is(ldap_err2string($result->{'sortResult'}), ldap_err2string(LDAP_SUCCESS), "Does server side sort result code match?");        
};

Then qr/the virtual list view control was successfully used/i, sub {
  my $vlv_response = S->{'asn'}{'virtual list view'}->find('VirtualListViewResponse');

  my $berval = undef;
  
  foreach my $ctrl (@{S->{'cache'}{'serverctrls'}}) {
    my $ctrl_oid = S->{'object'}->get_control_oid($ctrl);
    
    if ($ctrl_oid eq '2.16.840.1.113730.3.4.10') {
      $berval = S->{'object'}->get_control_berval($ctrl);
      last;
    }
  }
  
  isnt($berval, undef, "Was a berval returned?");
  
  my $result = $vlv_response->decode($berval) || ok(0, $vlv_response->error);

  is(ldap_err2string($result->{'virtualListViewResult'}), ldap_err2string(LDAP_SUCCESS), "Does virtual list view result code match?");        
};


1;
