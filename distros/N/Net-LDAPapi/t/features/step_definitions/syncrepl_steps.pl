#!/usr/bin/perl

use strict;
use warnings;
  
use Net::LDAPapi;
use Test::More;
use Test::BDD::Cucumber::StepFile;

our %TestConfig = %main::TestConfig;

use Data::Dumper;

When qr/I've started listening for changes within the directory/i, sub {
 
  S->{'listen changes_result'} = 'skipped';

  return if S->{'bind_result'} eq 'skipped';

  my $func = 'listen_for_changes';
  my %args = ();
    
  $args{'-basedn'} = sprintf('%s,%s', $TestConfig{'data'}{'test_container_dn'}, $TestConfig{'ldap'}{'base_dn'});
  $args{'-scope'} = LDAP_SCOPE_SUBTREE;
  $args{'-filter'} = '(objectClass=*)';
  $args{'-cookie'} = $TestConfig{'syncrepl'}{'cookie_dir'} . "syncrepl.$$.cookie";
  
#  open(COOKIE, ">" . $args{'-cookie'});
#  close(COOKIE);
    
  S->{'listen changes_result'} = S->{'object'}->$func(%args);
  S->{'object'}->next_changed_entries(S->{'listen changes_result'}, 0, 1);
      
};

Then qr/the changes were successfully notified/i, sub {
  my $expected_container_dn = sprintf('%s,%s,%s', $TestConfig{'data'}{'container_dn'}, $TestConfig{'data'}{'test_container_dn'}, $TestConfig{'ldap'}{'base_dn'});
  my $expected_entry_dn = sprintf('%s,%s,%s', $TestConfig{'data'}{'entry_dn'}, $TestConfig{'data'}{'test_container_dn'}, $TestConfig{'ldap'}{'base_dn'});

  my $seen_expected = 0;

  my $timeout_start = time();
  my $timeout_length = 5;
  
  while(!$seen_expected) {
    if ((time() - $timeout_start) > $timeout_length) { last; }
    
    while(my @entries = S->{'object'}->next_changed_entries(S->{'listen changes_result'}, 0, 1)) {
      foreach my $entry (@entries) {
                    
        my $entry_dn = S->{'object'}->get_dn($entry->{'entry'});

        if (lc($entry_dn) eq lc($expected_container_dn) || lc($entry_dn) eq lc($expected_entry_dn)) {
          $seen_expected = 1;
          last;  
        }
      }
    }
  }
  
  ok($seen_expected, 'Have we seen a notification for an expected DN?');

  my %args;
  
  my $asn = Convert::ASN1->new();
  $asn->prepare(<<ASN);
cancelRequestValue ::= SEQUENCE {
  cancelID INTEGER
}
ASN

  $args{'-oid'} = '1.3.6.1.1.8';
  $args{'-result'} = \%{S->{'cancel_result code'}};
  $args{'-berval'} = $asn->encode(cancelID => S->{'listen changes_result'});
   
  my $cancel_status = S->{'object'}->extended_operation_s(%args);
  is(ldap_err2string($cancel_status), ldap_err2string(LDAP_SUCCESS), 'Was cancelling the sync successful?');
  S->{'object'}->{'entry'} = 0;
};

1;
