#!/usr/bin/perl
require 5.006_001;
use Test::More tests => 3;

use_ok('RPSL::Parser');

my $class = 'RPSL::Parser';

can_ok $class, qw( new parse );

{   my $parser = new RPSL::Parser;
    isa_ok $parser, $class;
}
