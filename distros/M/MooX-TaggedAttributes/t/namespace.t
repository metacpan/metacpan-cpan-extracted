#! perl

use Test2::V0;

use Test::CleanNamespaces;
use Test::Lib;

namespaces_clean( qw[
      T12
      T2
      C7
      B1
      R1
      R2
      B3
      T1
      C8
      C9
      C2
      C1
      C5
      C31
      B2
      R3
      C6
      B4
      C10
      C3
      C4

] );

done_testing;
