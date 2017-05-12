#!/usr/bin/perl

use strict;
use OpenInteract;
use OpenInteract::ApacheStartup;

my $BASE_CONFIG = '%%WEBSITE_DIR%%/conf/base.conf';

OpenInteract::ApacheStartup->initialize( $BASE_CONFIG );

1;
