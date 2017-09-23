#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
  my @classes = qw( Rails::Assets Rails::Assets::Base Rails::Assets::Formatter
    Rails::Assets::Processor);
  use_ok( $_ ) or print "Bail out! $_ does not compile!\n" foreach @classes;
}

diag( "Testing Rails::Assets $Rails::Assets::VERSION, Perl $], $^X" );
