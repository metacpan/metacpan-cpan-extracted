package Mozilla::IntermediateCerts::Cert;

use strict;
use warnings;

use utf8;
use Moo;

use namespace::clean;

# ABSTRACT: Wrapper for handling Mozilla Intermediate certificate

our $VERSION = 'v0.0003';

=head1 NAME
 
Mozilla::IntermediateCerts::Cert
 
=head1 WARNING
 
This module is in early development and may change.
 
=head1 SYNOPSIS
 
        $cert = Mozilla::IntermediateCerts::Cert( \%row )
 
=cut
 
=head1 DESCRIPTION

This is a module f or parsing a hashref of data taken from the Mozilla intermediate certificate list. 

https://wiki.mozilla.org/CA/Intermediate_Certificates 
 
This is a work in progress and contains incomplete test code, methods are likely to be refactored, you have been warned.
 
 
=head1 METHODS

=cut

has ca_owner => ( is => 'rw' );
has parent_name => ( is => 'rw' );
has certificate_name => ( is => 'rw' );
has certificate_issuer_common_name => ( is => 'rw' );
has certificate_issuer_organization => ( is => 'rw' );
has certificate_subject_common_name	=> ( is => 'rw' );
has certificate_subject_organization => ( is => 'rw' );
has certificate_serial_number => ( is => 'rw' );
has sha_256_fingerprint => ( is => 'rw' );
has certificate_id => ( is => 'rw' );
has valid_from_gmt => ( is => 'rw' );
has valid_to_gmt => ( is => 'rw' );
has public_key_algorithm => ( is => 'rw' );
has signature_hash_algorithm => ( is => 'rw' );
has extended_key_usage => ( is => 'rw' );
has cp_cps_same_as_parent => ( is => 'rw' );
has certificate_policy_cp => ( is => 'rw' );
has certification_practice_statement_cps => ( is => 'rw' );
has audits_same_as_parent => ( is => 'rw' );
has standard_audit => ( is => 'rw' );
has br_audit => ( is => 'rw' );
has auditor => ( is => 'rw' );
has standard_audit_statement_dt => ( is => 'rw' );
has management_assertions_by => ( is => 'rw' );
has comments => ( is => 'rw' );
has pem_info => ( is => 'rw' );

around BUILDARGS => sub {
	my ( $orig, $class, @args ) = @_;
	my %newargs;
	for my $key ( keys %{ $args[0] } )
	{
		my $newkey = lc $key;
		$newkey =~ s/\W+/_/g;	
		$newargs{$newkey} = $args[0]->{$key};
	}
	return $class->$orig(\%newargs);
};



=head2 ca_owner

returns CA Owner column
=cut
=head2 parent_name

returns Parent Name column
=cut
=head2 certificate_name

returns Certificate Name column
=cut
=head2 certificate_issuer_common_name

returns Certificate Issuer Common Name column
=cut
=head2 certificate_issuer_organization

returns Certificate Issuer Organization column
=cut
=head2 certificate_subject_common_name

returns Certificate Subject Common Name column
=cut
=head2 certificate_subject_organization

returns Certificate Subject Organization column
=cut
=head2 certificate_serial_number

returns Certificate Serial Number column
=cut
=head2 sha_256_fingerprint

returns SHA-256 Fingerprint column
=cut
=head2 certificate_id

returns Certificate ID column
=cut
=head2 valid_from_gmt

returns Valid From [GMT] column
=cut
=head2 valid_to_gmt

returns Valid To [GMT] column
=cut
=head2 public_key_algorithm

returns Public Key Algorithm column
=cut
=head2 signature_hash_algorithm

returns Signature Hash Algorithm column
=cut
=head2 extended_key_usage

returns Extended Key Usage column
=cut
=head2 cp_cps_same_as_parent

returns CP/CPS Same As Parent column
=cut
=head2 certificate_policy_cp

returns Certificate Policy (CP) column
=cut
=head2 certification_practice_statement_cps

returns Certification Practice Statement (CPS) column
=cut
=head2 audits_same_as_parent

returns Audits Same As Parent column
=cut
=head2 standard_audit

returns Standard Audit column
=cut
=head2 br_audit

returns BR Audit column
=cut
=head2 auditor

returns Auditor column
=cut
=head2 standard_audit_statement_dt

returns Standard Audit Statement Dt column
=cut
=head2 management_assertions_by

returns Management Assertions By column
=cut
=head2 comments

returns Comments column
=cut
 
=head2 pem_info

returns PEM Info column with enclosing quotes removed
=cut
around pem_info => sub {
 	my ($orig, $self) = @_;
  	$self->$orig( $self->$orig =~ s/'//gr );
};



=head1 SOURCE CODE

The source code for this module is held in a public git repository on Gitlab https://gitlab.com/rnewsham/mozilla_intermediate_cert

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2019 Richard Newsham
 
This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
 
=head1 BUGS AND LIMITATIONS
 
See rt.cpan.org for current bugs, if any.
 
=head1 INCOMPATIBILITIES
 
None known. 
 
=head1 DEPENDENCIES

	Moo
=cut

1;
