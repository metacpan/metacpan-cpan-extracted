#!/usr/bin/perl -w
#
#  t/01-constants.t - test that constants are correctly exported
#                     by Net::SSLeay::OO::Constants
#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

use strict;
use Test::More qw(no_plan);

BEGIN {
	use_ok( "Net::SSLeay::OO::Constants", "OP_ALL",
		"VERIFY_NONE",                "VERIFY_PEER"
	);
}

ok( &OP_ALL, "Imported OP_ALL" );
cmp_ok( &VERIFY_PEER, '!=', &VERIFY_NONE, "Values are making some sense" );

eval { Net::SSLeay::OO::Constants->import("OP_YO_MOMMA") };
isnt( $@, '', 'Trying to import bad symbol failed' );

# Local Variables:
# mode:cperl
# indent-tabs-mode: t
# cperl-continued-statement-offset: 8
# cperl-brace-offset: 0
# cperl-close-paren-offset: 0
# cperl-continued-brace-offset: 0
# cperl-continued-statement-offset: 8
# cperl-extra-newline-before-brace: nil
# cperl-indent-level: 8
# cperl-indent-parens-as-block: t
# cperl-indent-wrt-brace: nil
# cperl-label-offset: -8
# cperl-merge-trailing-else: t
# End:
# vim: filetype=perl:noexpandtab:ts=3:sw=3
