#!/usr/bin/perl -Tw
# -*- perl -*-

# t/002_taintload.t - check module loading under taint mode and warnings

use Test::More tests => 2;

BEGIN { use_ok( 'Net::Server::POP3' ); }

my $object = Net::Server::POP3->new ();
isa_ok ($object, 'Net::Server::POP3');


