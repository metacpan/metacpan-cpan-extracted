#!/usr/bin/perl -w

##############################################################################
##
## OpenThought Apache Startup File
##
## Instead of changing this file, consider adding your changes to
## {$Prefix}/etc/OpenThought-startup-local.pl
##
###############################################################################


use strict;
use Apache2();
use Apache::RequestRec ();
use Apache::RequestIO  ();
use Apache::RequestUtil();

use Apache::Server     ();
use Apache::ServerUtil ();
use Apache::Connection ();
use Apache::Log();

use APR::Table ();

use ModPerl::Registry();

use Apache::Const -compile => ':common';
use APR::Const -compile => ':common';

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
