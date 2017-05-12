#!/usr/bin/perl

use strict;
use warnings;
  
use Test::More;
use Test::BDD::Cucumber::StepFile;

our %TestConfig = %main::TestConfig;
use Data::Dumper;

When qr/I've (asynchronously )?searched for records with scope ([^, ]+)(?:, with server control(?:s)? (.+((?:(,|and) .+)*)))?(?:, with timeout (\d+))?/, sub {
  my $async = $1 ? 1 : 0;
  my $scope = $2;
  my $timeout = $6;

  my @server_ctrls = $3 ? map { S->{'server_controls'}{$_} } split(/\s*(?:,|and)\s*/, $3) : undef;

  my $func = "search_ext_s";
  if ($async) {
    $func = "search_ext";
  }
  
  S->{'search_async'} = $async;

  my %args = ();
  
  S->{'search_result'} = S->{'object'}->$func(
    -basedn => $TestConfig{'ldap'}{'base_dn'},
    -scope => S->{'object'}->$scope,
    -filter => $TestConfig{'search'}{'filter'},
    -attrs => \@{['cn']},
    -attrsonly => 0,
    -sctrls => [@server_ctrls],
    -timeout => $timeout);
};

Then qr/the search count matches/, sub {
  is(S->{'object'}->count_entries, $TestConfig{'search'}{'count'}, "Does the search count match?");
};

Then qr/using get_all_entries for each entry returned the dn and all attributes are valid/, sub {
  my $entries = S->{'object'}->get_all_entries();

  foreach my $entry_dn (keys %{$entries}) {
    isnt($entry_dn, "", "Is the dn for the entry empty?");
    
    foreach my $attribute (keys %{$entries->{$entry_dn}}) {
      my @vals = $entries->{$entry_dn}{$attribute};
      
      ok(($#vals >= 0), "Are values returned?");
    }
  }
};

Then qr/using (.+) for each entry returned the dn and all attributes using (.+?) are valid/, sub {
  my $entry_iterate_mode = lc($1);
  my $attribute_iterate_mode = lc($2);
    
  my $attribute_tests = sub {
    my $attr = shift;
    my @vals = S->{'object'}->get_values($attr);

    ok(($#vals >= 0), "Are values returned?");
    
  };
  
  my $attribute_block = sub {
    if ($attribute_iterate_mode eq "next_attribute") {
      for (my $attr = S->{'object'}->first_attribute; $attr; $attr = S->{'object'}->next_attribute) {
        $attribute_tests->($attr);
      }        
    } elsif ($attribute_iterate_mode eq "entry_attribute") {
      foreach my $attr (S->{'object'}->entry_attribute) {
        $attribute_tests->($attr);        
      }
    }
  };
 
  my $entry_tests = sub {
    isnt(S->{'object'}->get_dn(), "", "Is the dn for the entry empty?");    
  };
  
  if ($entry_iterate_mode eq "next_entry") {
    my $ent = S->{'object'}->first_entry;
    
    my %ent_result = S->{'object'}->parse_result();
    S->{'cache'}{'serverctrls'} = $ent_result{'serverctrls'};
        
    for (; $ent; $ent = S->{'object'}->next_entry) {
      $entry_tests->($ent);
        
      $attribute_block->($ent);
    }
  } elsif ($entry_iterate_mode eq "result_entry") {        
    foreach my $ent (S->{'object'}->result_entry) {
      $entry_tests->($ent);
      
      $attribute_block->($ent);
    }
  }

};

1;
