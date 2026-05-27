#!perl

use v5.14;
use warnings;

use Test2::Require::AuthorTesting;

use Test2::V0;
use Test::CVE 0.10;

has_no_cves(
  author => 1,
  core => 1,
  deps => 1,
  perl => 0,
);

done_testing;
