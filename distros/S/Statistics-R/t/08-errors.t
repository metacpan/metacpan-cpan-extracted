#! perl

use strict;
use warnings;
use Test::More;
use Statistics::R;


SKIP: {
   skip 'because tests hang on Win32 (bug #81159)', 1 if $^O =~ /^(MS)?Win32$/;

   ok my $R = Statistics::R->new(bin => '/foo/ba/R');
   eval {
      $R->run( qq`print("Hello");` );
   };
   #diag "Diagnostic: \n".$@."\n";
   ok $@, 'Executable not found';

   ok $R = Statistics::R->new();
   is $R->run(q`a <- 1;`), '';

   eval {
      $R->run( qq`print("Hello");\nprint(ASDF)` );
   };
   #diag "Diagnostic: \n".$@."\n";
   ok $@, 'Runtime error';

   is $R->run(q`a <- 1;`), '';

   ok $R = Statistics::R->new();
   eval {
      $R->run( qq`print("Hello");\nprint "ASDF"` );
   };
   #diag "Diagnostic: \n".$@."\n";
   ok $@, 'Syntax error';
   # Actual error message varies depending on locale

   is $R->run(q`a <- 1;`), '';

   use_ok 't::FlawedStatisticsR';
   ok $R = t::FlawedStatisticsR->new();
   eval {
      $R->run( qq`print("Hello");\ncolors<-c("red")` );
   };
   #diag "Diagnostic: \n".$@."\n";
   ok $@, 'Internal error';

};

done_testing;


