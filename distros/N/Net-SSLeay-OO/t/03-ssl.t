#!/usr/bin/perl -w
#
#  t/03-ssl.t - test the Net::SSLeay::OO::SSL binding
#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

use strict;
use Test::More qw(no_plan);
use FindBin qw($Bin);

BEGIN {
	use_ok("Net::SSLeay::OO::SSL");
}

use Net::SSLeay::OO::Constants qw(OP_ALL VERIFY_NONE FILETYPE_PEM);

my $destroyed;
my $ssl_id;
{
	my $ssl = Net::SSLeay::OO::SSL->new;

	isa_ok( $ssl, "Net::SSLeay::OO::SSL", "new Net::SSLeay::SSL" );

	$ssl_id = $ssl->ssl;
	ok( $ssl_id, "has a ssl" );

	$ssl->set_options(OP_ALL);
	is( $ssl->get_options, OP_ALL,
		"takes options like a good little ssl" );

	eval {
		$ssl->use_certificate_file(
			"$Bin/certs/no-such-server-cert.pem", FILETYPE_PEM, );
	};
	isa_ok( $@,       "Net::SSLeay::OO::Error", "exception" );
	isa_ok( $@->next, "Net::SSLeay::OO::Error", "exception trace" );

	#diag $@;

	my $old_sub = \&Net::SSLeay::OO::SSL::free;
	no warnings 'redefine';
	*Net::SSLeay::OO::SSL::free = sub {
		$destroyed = $_[0]->ssl;
		$old_sub->(@_);
	};
}
is( $destroyed, $ssl_id, "Called SSL_free" );

# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>

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
