#!/usr/bin/perl

use strict;
use warnings;
  
use Test::More;
use Test::BDD::Cucumber::StepFile;

our %TestConfig = %main::TestConfig;


When qr/I've (asynchronously )?issued a (.+?) extended operation to the directory/i, sub {
  my $async = $1 ? 1 : 0;
  my $extended_operation = lc($2);
  
  S->{$extended_operation . ' extended operation_result'} = "skipped";

  return if S->{"bind_result"} eq "skipped";

  my $func = "extended_operation_s";
  my %args = ();
  
  if ($async) {
    $func = "extended_operation";
  }
  S->{$extended_operation . ' extended operation_async'} = $async;
   
  if ($extended_operation eq "whoami") {
    $args{'-oid'} = '1.3.6.1.4.1.4203.1.11.3';
    $args{'-result'} = \%{S->{'whoami extended operation_authzid'}};
  }
   
  S->{$extended_operation . ' extended operation_result'} = S->{'object'}->$func(%args);
};

Then qr/the (.+?) extended operation matches/i, sub {
  my $extended_operation = lc($1);

  my $async = S->{$extended_operation . ' extended operation_async'};
  
  my $got = undef;
  if ($async) {
    $got = {S->{'object'}->parse_extended_result(S->{$extended_operation . ' extended operation_result_id'})};       
  }
      
  if ($extended_operation eq "whoami") {
    if (!$async) {
      $got = S->{$extended_operation . ' extended operation_authzid'};
    }
    
    is($got->{'retdatap'}, S->{'identity_got'}, 'Does ' . ($async ? 'asynchronous ' : '' ) . ' whoami extended_operation match native whoami?');
  } else {
    TODO: {
      todo_skip "$extended_operation matching unimplemented", 1;
    }
  }
};

1;
