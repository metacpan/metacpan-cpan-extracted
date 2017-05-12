#!perl -T
use Test::More tests => 1;
BEGIN { use_ok('MySQL::Privilege::Reader') || print "Bail out!"; }
diag(   'Testing MySQL::Privilege::Reader '
      . qq{$MySQL::Privilege::Reader::VERSION, Perl $], $^X} );
