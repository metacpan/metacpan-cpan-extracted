#!/usr/bin/perl
# $Id$

use Test::More tests => 3;

use_ok('RPM4');
warn ">> RPM version: ", `rpm --version`, "\n";
can_ok('RPM4', qw(rpm2header stream2header dumprc dumpmacros newdb));

#Header

# Db
can_ok('RPM4::Transaction', qw(traverse transadd transremove transcheck transorder transrun
    importpubkey checkrpm transreset));
