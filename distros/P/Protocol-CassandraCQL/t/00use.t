#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "Protocol::CassandraCQL" );
use_ok( "Protocol::CassandraCQL::Client" );
use_ok( "Protocol::CassandraCQL::ColumnMeta" );
use_ok( "Protocol::CassandraCQL::Frame" );
use_ok( "Protocol::CassandraCQL::Result" );

done_testing;
