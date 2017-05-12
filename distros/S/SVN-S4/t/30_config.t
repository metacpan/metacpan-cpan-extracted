#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2002-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test::More;
use Cwd;

BEGIN { plan tests => 5 }
BEGIN { require "./t/test_utils.pl"; }

$ENV{S4_CONFIG} = getcwd."/t/30_config.dat";
$ENV{S4_CONFIG_SITE} = getcwd."/t/30_config_site.dat";
#$SVN::S4::Debug = 1;

use SVN::S4;
ok(1,'use');

my $s4 = SVN::S4->new;
is($s4->config_get('s4','test-option'), 'foo', 'get property');
is($s4->config_get_bool('s4','test-bool-yes'), 1, 'get property');
is($s4->config_get_bool('s4','test-bool-no'), 0, 'get property');
is($s4->config_get_bool('s4','test-bool-undef'), undef, 'get property');
