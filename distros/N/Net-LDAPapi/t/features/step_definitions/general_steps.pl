#!/usr/bin/perl

use strict;
use warnings;

use Net::LDAPapi;
use Test::More;
use Test::BDD::Cucumber::StepFile;

our %TestConfig = %main::TestConfig;

Given qr/a usable (\S+) class/, sub {  use_ok($1); };
Given qr/a Net::LDAPapi object that has been connected to the (.+?)?\s?LDAP server/, sub {
  my $type = $1;
 
  if (!defined($type)) {
    $type = $TestConfig{'ldap'}{'default_server'};
  }
  
  my $object = Net::LDAPapi->new(%{$TestConfig{'ldap'}{'server'}{$type}});

  ok( $object, 'Net::LDAPapi object created');
  
  S->{'object'} = $object;
};

When qr/a test container has been created/, sub { 
  my %args = ();
  
  $args{'-dn'} = sprintf('%s,%s', $TestConfig{'data'}{'test_container_dn'}, $TestConfig{'ldap'}{'base_dn'});
  $args{'-mod'} = $TestConfig{'data'}{'test_container_attributes'};
 
  my $status = S->{'object'}->add_s(%args);
  
  is(ldap_err2string($status), ldap_err2string(LDAP_SUCCESS), 'Was adding the test container successful?');
};

Then qr/the test container has been deleted/, sub {
  my %search_args = ();
  my @delete_dns = ();
  
  $search_args{'-basedn'} = sprintf('%s,%s', $TestConfig{'data'}{'test_container_dn'}, $TestConfig{'ldap'}{'base_dn'});
  $search_args{'-scope'} = LDAP_SCOPE_SUBTREE;
  $search_args{'-filter'} = '(objectClass=*)';
  $search_args{'-attrs'} = ['objectClass'];
  
  my $search_status = S->{'object'}->search_s(%search_args);

  is(ldap_err2string($search_status), ldap_err2string(LDAP_SUCCESS), 'Was searching for the test container to delete successful?');

  while( my $ent = S->{'object'}->result_entry) {
    push(@delete_dns, S->{'object'}->get_dn());
  }

  foreach my $dn (sort { length($b) <=> length($a) } @delete_dns) {
    my %delete_args = ('-dn' => $dn);

    my $status = S->{'object'}->delete_s(%delete_args);
    is(ldap_err2string($status), ldap_err2string(LDAP_SUCCESS), 'Was deleting test container contents "' . $dn . '" successful?');
  }
};

Then qr/(after waiting for all results, )?the (.+) result message type is (.+)/, sub {
  my $wait_for_all = $1 ? 1 : 0;
  my $test_function = $2;
  my $desired_result = $3;

  SKIP: {
            
    skip(C->{'scenario'}->{'name'} . " skipped", 1) if S->{$test_function . '_result'} eq "skipped";

    isnt( S->{$test_function . '_result'}, undef, "Do we have result from $test_function?");
  
    if (is( S->{$test_function . '_async'}, 1, "Was $test_function asynchronous?")) {
      S->{$test_function . '_result_id'} = S->{'object'}->result(S->{$test_function . '_result'}, $wait_for_all, 1);

      is(S->{'object'}->msgtype2str(S->{'object'}->{"status"}), $desired_result, "Does expected result message type match?");  
    }
    
  }
};

Then qr/the (.+) result is (.+)/, sub {
  my $test_function = $1;
  my $desired_result = $2;
  
  SKIP: {
            
    skip(C->{'scenario'}->{'name'} . " skipped", 1) if S->{$test_function . '_result'} eq "skipped";

    if (isnt( S->{$test_function . '_result'}, undef, "Do we have result from $test_function?")) {

      if (S->{$test_function . '_async'}) {
        my $ref = {S->{'object'}->parse_result(S->{$test_function . '_result_id'})};

        is(ldap_err2string($ref->{'errcode'}), ldap_err2string(S->{'object'}->$desired_result), "Does expected async result code match?");        
      } else {
        is(ldap_err2string(S->{$test_function . '_result'}), ldap_err2string(S->{'object'}->$desired_result), "Does expected result code match?");        
      }
    }            
  }
};

1;
