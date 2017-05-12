#!/usr/bin/perl

# $Id: 03_log.t,v 1.2 2002/10/12 04:00:21 andreychek Exp $

use strict;
use Test::More  tests => 5;

use lib "./t";
use OpenPluginTests( "get_config" );
use OpenPlugin();

my $data = get_config( "log_log4perl" );
my $OP = OpenPlugin->new( config => { data => $data });

# Test 1: Not at DEBUG level
{
    ok( !$OP->log->is_debug, "Not at DEBUG level" );
}

# Test 2: Not at INFO level
{
    ok( !$OP->log->is_info, "Not at INFO level" );
}

# Test 3: At WARN level
{
    ok( $OP->log->is_warn, "At WARN level" );
}

# Test 4: At ERROR level
{
    ok( $OP->log->is_error, "At ERROR level" );
}

# Test 5: At FATAL level
{
    ok( $OP->log->is_warn, "At FATAL level" );
}

