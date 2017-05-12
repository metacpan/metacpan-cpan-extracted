
package Net::SSLeay::OO::X509::Store;

# wrapper for X509_STORE* functions
#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

use Moose;

has 'x509_store' => isa => 'Int',
	is       => "ro",
	required => 1,
	;

use Net::SSLeay::OO::Functions 'x509_store';

# add_cert()
# add_crl()
# set_flags()
# set_purpose()
# set_trust()

1;

__END__

=head1 NAME

Net::SSLeay::OO::X509::Store - wrapper for X509_STORE* pointers

=head1 SYNOPSIS

 my $store = $ctx->get_cert_store;
 $store->add_cert(...);
 $store->set_purpose(...);

=head1 DESCRIPTION

This is a class which represents the X509_STORE* pointers; it is
currently poorly understood, the best reference for understanding will
be relevant functions within L<Net::SSLeay> (especially the main
binding wrapper, F<SSLeay.xs>), and the OpenSSL source code.

You should not need to use this class for regular use of the module;
if you find a use for it, or would like to help complete or document
it, please submit a patch or pull request.

=head1 AUTHOR

Sam Vilain, L<samv@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2009  NZ Registry Services

This program is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0 or later.  You should
have received a copy of the Artistic License the file COPYING.txt.  If
not, see <http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

L<Net::SSLeay::OO>, L<Net::SSLeay::OO::Context/get_cert_store>

=cut

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
