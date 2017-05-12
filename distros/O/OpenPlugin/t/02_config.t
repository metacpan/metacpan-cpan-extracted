#!/usr/bin/perl

# $Id: 02_config.t,v 1.8 2002/10/11 20:37:14 andreychek Exp $

use strict;
use Test::More  tests => 3;

# Pathing so it works in my test environment
use OpenPlugin();

my $OP = OpenPlugin->new( config => { src => "t/02_config.conf" });

# Test 1: OpenPlugin Object
{
    ok( ref $OP eq "OpenPlugin", "load config" );
}

# Test 2: View first level hash keys
{
    my $keys = join(" ", sort( keys %{ $OP } ));

    ok( $keys eq "_instance _plugin _pluginconf _state _toggle",
        "read plugin config");
}

# Test 3: View drivermap keys
{
    my $plugins = join(" ", sort( keys %{ $OP->{_instance}{config}{'built-in'}{drivermap} } ));

    ok( $plugins eq "authenticate cache config cookie datasource exception httpheader log param request session upload", "read plugin config");
}
