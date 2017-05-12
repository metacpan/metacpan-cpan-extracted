#!/usr/bin/perl -w

use strict;

use Test::More tests => 3;
use Test::Refcount;

use Net::LibAsyncNS::Constants;

ok( defined Net::LibAsyncNS::Constants::EAI_AGAIN, 'defined EAI_AGAIN' );

ok( defined Net::LibAsyncNS::Constants::AI_PASSIVE, 'defined AI_PASSIVE' );

ok( defined Net::LibAsyncNS::Constants::NI_NUMERICHOST, 'defined NI_NUMERICHOST' );
