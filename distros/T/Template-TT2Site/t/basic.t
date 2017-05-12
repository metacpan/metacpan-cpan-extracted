#!/usr/bin/perl

use strict;
use Test::More tests => 2;

BEGIN { use_ok("Template::TT2Site"); }
BEGIN { use_ok("Template::TT2Site::Plugin::Mapper"); }

if ( 0 && $ENV{TT2SITE_LIB} ) {
    diag("You have the environment variable TT2SITE_LIB set.\n".
	 "This is no longer necessary, and may cause malfunctioning.\n".
	 "Please remove the setting before proceeding.\n");
    fail("TT2SITE_LIB");
}
