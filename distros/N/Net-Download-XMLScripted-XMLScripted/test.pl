#!/usr/bin/perl -w
# Singh T. Junior
# A Simple Test Case
#
use Test::More tests => 3;

BEGIN { use_ok('Net::Download::XMLScripted::XMLScripted') };

my $xmlScripted = Net::Download::XMLScripted::XMLScripted->new();
ok( defined $xmlScripted , "new() returned something!");
ok( $xmlScripted->isa('Net::Download::XMLScripted::XMLScripted'), "right type of object!" );


