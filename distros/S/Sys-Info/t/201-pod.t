#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More;
use constant NEW_PERL => 5.008;
use constant MIN_TPV => 1.26;
use constant MIN_PSV => 3.05;

my(@errors, $eok);
$eok = eval { require Test::Pod;   1; };
push @errors, 'Test::Pod is required for testing POD'   if $@ || ! $eok;
$eok = eval { require Pod::Simple; 1; };
push @errors, 'Pod::Simple is required for testing POD' if $@ || ! $eok;

if ( not @errors ) {
   my $tpv = Test::Pod->VERSION;
   my $psv = Pod::Simple->VERSION;

   if ( $tpv < MIN_TPV ) {
      push @errors, 'Upgrade Test::Pod to 1.26 to run this test. '
                   ."Detected version is: $tpv";
   }

   if ( $psv < MIN_PSV ) {
      push @errors, 'Upgrade Pod::Simple to 3.05 to run this test. '
                   ."Detected version is: $psv";
   }
}

if ( $] < NEW_PERL ) {
   # Any older perl does not have Encode.pm. Thus, Pod::Simple
   # can not handle utf8 encoding and it will die, the tests
   # will fail. This skip part, skips an inevitable failure.
   push @errors, '"=encoding utf8" directives in Pods don\'t work '
                .'with legacy perl.';
}

if ( @errors ) {
   plan skip_all => "Errors detected: @errors";
}
else {
   Test::Pod::all_pod_files_ok();
}
