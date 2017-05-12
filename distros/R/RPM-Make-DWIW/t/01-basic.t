#!/usr/bin/perl -w

# $Header: /usr/local/cvsroot/apb/lib/RPM-Make-DWIW/t/01-basic.t,v 1.1 2010-02-22 07:04:22 asher Exp $

use strict;

use Test::More tests => 2;

BEGIN { use_ok("RPM::Make::DWIW") }

{
    ok(RPM::Make::DWIW::get_example_spec(), "example spec");
}

