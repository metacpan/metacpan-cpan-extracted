
package Net::SSLeay::OO::X509;

use Moose;

has 'x509'       => isa => 'Int',
	is       => "ro",
	required => 1,
	;

has 'no_rvinc' => isa => "Bool",
	is     => "ro",
	;

sub DESTROY {
	my $self = shift;
	$self->free;
}

sub free {
	my $self    = shift;
	my $pointer = delete $self->{x509};
	unless ( !$pointer or $self->no_rvinc ) {
		Net::SSLeay::free($pointer);
	}
}

# free()
# get_ext()
# get_ext_by_NID()
# get_notAfter()
# get_notBefore()

BEGIN {
	no strict 'refs';
	for my $nameFunc (qw(subject_name issuer_name)) {
		my $get     = "get_$nameFunc";
		my $sslfunc = "Net::SSLeay::X509_$get";
		*$get = sub {
			my $self = shift;
			require Net::SSLeay::OO::X509::Name;
			my $name = &$sslfunc( $self->x509 );
			Net::SSLeay::OO::X509::Name->new(x509_name => $name );
		};
	}
}

use Net::SSLeay::OO::Functions 'x509';

# load_cert_crl_file()
# load_cert_file()
# load_crl_file()
# verify_cert_error_string()

1;

__END__

=head1 NAME

Net::SSLeay::OO::X509 - OpenSSL SSL certificate

=head1 SYNOPSIS

 # currently no way to create them with this module
 my $cert = $ssl->get_peer_certificate;

 # important stuff
 my $subject = $cert->get_subject_name;
 my $issuer  = $cert->get_issuer_name;

 say "This cert is for ".$subject->cn.
    ", and was issued by ".$issuer->cn;

 # see full description for a less cryptic example :)
 my $i = 0;
 my @names = grep { $i ^= 1 } $cert->get_subjectAltNames;
 say "This cert also covers @names";

=head1 DESCRIPTION

This module encapsulates X509 certificates, the C<X509*> type in
OpenSSL's C library.

The functions available to this library are focused on pulling useful
information out of the SSL certificates that were exchanged.

As a result, there are no methods for creating the certificates - and
there is seldom need to do such things outside of the typical OpenSSL
command-line set and existing programs to do that.  See
F<t/certs/make-test-certs.sh> in the distribution for a shell script
which uses the C<openssl req> and C<openssl ca> commands to create
certificates which are used for the test suite.

=head1 METHODS

=head2 Certificate Information Methods

=over

=item B<get_subject_name>

=item B<get_issuer_name>

The Subject Name is the X.509 Name which represents the identity of
this certificate.  Using a PGP analogy, it's like the KeyID.  It has
fields like country, cn / commonName (normally a domain name),
locality and what your favourite chicken species for sacrificial use
are.

The Issuer Name is another X.509 Name which represents the identity
which signs this certificate.  Unlike PGP, individual SSL certificates
can only have one signature attached, which needs to lead back to some
trusted root certificate.

These entities are not strings; they are L<Net::SSLeay::OO::X509::Name>
objects.

=item B<get_subjectAltNames>

This is a method in L<Net::SSLeay> which wraps up the new vhosting SSL
certificate support, so that you can see the alternate names on that
SSL certificate.

Unlike the C<get_*_name> methods, this method returns a list of pairs;
the first item in the pair being the type of name, and the second one
being a string representation of that name.

=item B<get_notBefore(cert)>

=item B<get_notAfter(cert)>

These methods probably return validity period times for the
certificate.  To be confirmed.

=item B<free()>

This method will cause the object to forget its internal pointer
reference.  Use if you have been given a reference which is not
refcounted, and the reference is going to expire soon.

=back

=head2 Arcane Internal Methods

The notes on L<Net::SSLeay::OO::Context> about the un-triaged methods all
apply to these methods.

=over

=item B<get_ext_by_NID(x,nid,loc)>

=item B<get_ext(x,loc)>

These probably have something to do with extensible additions to SSL
certificates; the subjectAltNames implementation calls these methods.

=item B<load_cert_file(ctx, file, type)>

=item B<load_crl_file(ctx, file, type)>

=item B<load_cert_crl_file(ctx, file, type)>

These methods take a C<X509_LOOKUP*> as their first argument.  I
really wouldn't recommend them.

=item B<verify_cert_error_string(n)>

Don't call this as a method.  It seems to be a function that takes an
error code from some other function and returns the string
corresponding to that error.

=back

=head1 AUTHOR

Sam Vilain, L<samv@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2009  NZ Registry Services

This program is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0 or later.  You should
have received a copy of the Artistic License the file COPYING.txt.  If
not, see <http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

L<Net::SSLeay::OO>, L<Net::SSLeay::OO::X509::Name>,
L<Net::SSLeay::OO::X509::Store>, L<Net::SSLeay::X509::Context>

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
