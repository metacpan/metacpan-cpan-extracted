#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

use_ok($_) for qw(Protocol::QUIC);

diag( "Testing Protocl::QUIC $Protocol::QUIC::VERSION, Perl $], $^X" );
