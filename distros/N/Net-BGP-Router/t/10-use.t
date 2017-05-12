#!/usr/bin/perl -wT

# $Id: 10-use.t,v 1.1 2003/06/01 23:40:12 unimlo Exp $

use strict;
use warnings;

use Test::More tests => 7;

# Use
use_ok('Net::ACL');       # Prereq!
use_ok('Net::BGP::Peer'); # Prereq!
use_ok('Net::BGP::Policy');
use_ok('Net::BGP::RIBEntry');
use_ok('Net::BGP::RIB');
use_ok('Net::BGP::Router');
use_ok('Net::BGP::ContextRouter');

