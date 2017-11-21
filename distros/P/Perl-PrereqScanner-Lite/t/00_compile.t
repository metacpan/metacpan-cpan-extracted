#!perl

use strict;
use Test::More;

use_ok $_ for qw(
    Perl::PrereqScanner::Lite
    Perl::PrereqScanner::Lite::Constants
    Perl::PrereqScanner::Lite::Scanner::Moose
    Perl::PrereqScanner::Lite::Scanner::Version
);

done_testing;

