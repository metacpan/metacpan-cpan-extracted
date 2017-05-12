#!/usr/bin/perl
#
# This file is part of MooseX-Role-XMLRPC-Client
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::Role::XMLRPC::Client' );
}

diag( "Testing MooseX::Role::XMLRPC::Client $MooseX::Role::XMLRPC::Client::VERSION, Perl $], $^X" );
