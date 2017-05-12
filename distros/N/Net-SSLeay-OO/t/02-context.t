#!/usr/bin/perl -w
#
#  t/02-context.t - test the Net::SSLeay::OO::Context binding
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
	use_ok("Net::SSLeay::OO::Context");
}

use Net::SSLeay::OO::Constants qw(OP_ALL VERIFY_NONE FILETYPE_PEM);

my $destroyed;
my $ctx_id;
{
	my $ctx = Net::SSLeay::OO::Context->new;

	isa_ok( $ctx, "Net::SSLeay::OO::Context","new Net::SSLeay::Context" );

	$ctx_id = $ctx->ctx;
	ok( $ctx_id, "has a ctx" );

	$ctx->set_options(OP_ALL);
	is( $ctx->get_options, OP_ALL,
		"takes options like a good little ctx" );

	$ctx->load_verify_locations( "", "$Bin/certs" );

	eval {
		$ctx->use_certificate_chain_file(
			"$Bin/certs/no-such-server-cert.pem");
	};
	isa_ok( $@, "Net::SSLeay::OO::Error", "exception" );

	#&& diag $@;

	$ctx->set_default_passwd_cb( sub {"secr1t"} );
	$ctx->use_PrivateKey_file( "$Bin/certs/server-key.pem",FILETYPE_PEM );
	$ctx->use_certificate_chain_file("$Bin/certs/server-cert.pem");

	my $store = $ctx->get_cert_store;
	isa_ok( $store, "Net::SSLeay::OO::X509::Store", "get_cert_store()" );

	my $old_sub = \&Net::SSLeay::OO::Context::free;
	no warnings 'redefine';
	*Net::SSLeay::OO::Context::free = sub {
		$destroyed = $_[0]->ctx;
		$old_sub->(@_);
	};
}
is( $destroyed, $ctx_id, "Called CTX_free" );

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
