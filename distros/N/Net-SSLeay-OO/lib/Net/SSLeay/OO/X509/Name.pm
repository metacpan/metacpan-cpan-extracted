
package Net::SSLeay::OO::X509::Name;

use Moose;
use Carp qw(croak confess);

has 'x509_name'  => isa => 'Int',
	is       => "ro",
	required => 1,
	;

our %field_to_NID = qw(
	cn NID_commonName
	country NID_countryName
	locality NID_localityName
	state NID_stateOrProvinceName
	org NID_organizationName
	org_unit NID_organizationalUnitName
	subject_key NID_subject_key_identifier
	key_usage NID_key_usage
	serial NID_serialNumber
	name NID_name
);

sub get_text_by_NID {
	my $self = shift;
	my $nid  = shift;
	my $val  =
		Net::SSLeay::X509_NAME_get_text_by_NID( $self->x509_name,$nid,
		);
	&Net::SSLeay::OO::Error::die_if_ssl_error("get_text_by_nid($nid)");

	# work around a bug in X509_NAME_get_text_by_NID
	chop($val) if substr( $val, -1, 1 ) eq "\0";
	$val;
}

use Net::SSLeay::OO::Functions 'x509_name';

sub AUTOLOAD {
	no strict 'refs';
	my $self = shift;
	our $AUTOLOAD =~ m{::([^:]*)$};
	my $field = $1;
	$self->{$field} ||= do {
		my $nid_name = $field_to_NID{$field}
			or croak "unknown method/field '$field'";
		if ( !defined &{$nid_name} ) {
			eval {
				Net::SSLeay::OO::Constants->import($nid_name);
				1;
			}
				or croak "unknown NID '$nid_name'?; $@";
		}
		$self->get_text_by_NID(&$nid_name);
	};
}

1;

__END__

=head1 NAME

Net::SSLeay::OO::X509::Name - methods to call on SSL certificate names

=head1 SYNOPSIS

 my $name = $cert->get_subject_name;

 # for 'common' attributes
 print "Summary of cert: ".$name->oneline."\n";
 print "Common name is ".$name->cn."\n";

 # others...
 use Net::SSLeay::OO::Constants qw(NID_pbe_WithSHA1And2_Key_TripleDES_CBC);
 my $val = $name->get_text_by_NID(NID_pbe_WithSHA1And2_Key_TripleDES_CBC);

=head1 DESCRIPTION

This object represents the X509_NAME structure in OpenSSL.  It has a
bunch of fields such as "common name", etc.

Two methods are imported from the OpenSSL library;

=over

=item B<oneline>

Returns a string, such as:

 /C=NZ/ST=Wellington/O=Catalyst IT/OU=Security/CN=Test Client

=item B<get_text_by_NID(NID_xxx)>

Return a given field from the name.  See F<openssl/objects.h> for the
complete list.

=back

Convenience methods have been added which return the following common
fields:

        cn           NID_commonName
	country      NID_countryName
	locality     NID_localityName
	state        NID_stateOrProvinceName
	org          NID_organizationName
	org_unit     NID_organizationalUnitName
	subject_key  NID_subject_key_identifier
	key_usage    NID_key_usage
	serial       NID_serialNumber

=head1 AUTHOR

Sam Vilain, L<samv@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2009  NZ Registry Services

This program is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0 or later.  You should
have received a copy of the Artistic License the file COPYING.txt.  If
not, see <http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

L<Net::SSLeay::OO>, L<Net::SSLeay::OO::X509>

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

