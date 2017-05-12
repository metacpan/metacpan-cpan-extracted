#!/usr/bin/perl -w

##############################################################################
#
# OpenThought Apache Startup File
#
# Instead of changing this file, consider adding your changes to
# {$Prefix}/etc/OpenThought-startup-local.pl
#
##############################################################################

use strict;

use Apache::Registry();

BEGIN \{
    if ( -f "{$OpenThoughtPrefix}/etc/OpenThought-startup-local.pl" ) \{
        require "{$OpenThoughtPrefix}/etc/OpenThought-startup-local.pl"
    \}
\}

use OpenPlugin::Application();
use OpenThought();

$OpenPlugin::Config::Src = "{$OpenThoughtPrefix}/etc/OpenThought.conf" unless $OpenPlugin::Config::Src;
OpenPlugin->new();

1;
