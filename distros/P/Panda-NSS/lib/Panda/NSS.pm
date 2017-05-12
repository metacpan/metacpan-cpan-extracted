package Panda::NSS;
use strict;
use warnings;
use Config ();

# ABSTRACT: Perl bindings to NSS Mozilla security library

our $VERSION = '0.004';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub add_builtins {
    my $suffix = $Config::Config{so};
    my $prefix = '';
    $prefix = 'lib' unless $suffix eq 'dll';
    Panda::NSS::SecMod::add_new_module("Builtins", "${prefix}nssckbi.$suffix");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Panda::NSS - Perl bindings to NSS Mozilla security library

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  # verify certificate
  use Panda::NSS;

  Panda::NSS::init($nssdb_path);
  Panda::NSS::add_builtins();

  my $cert = Panda::NSS::Cert->new($cert_data_in_der_format);

  if ($cert->simple_verify(Panda::NSS::CERTIFICATE_USAGE_OBJECT_SIGNER)) {
      print "Certificate OK\n";
  }
  else {
      print "Certificate NOT VALID\n";
  }

=head1 DESCRIPTION

This library is in very early stage of development. Any API can change.
Currently you can verify certificates with AIA extension (when not all chain exists locally).

=head1 FUNCTIONS

=over 4

=item C<< Panda::NSS::init( [ $certdb_path ] ) >>

This function initialize NSS library. It calls C<NSS_InitReadWrite(dbpath)>.
However you may not specify C<$certdb_path>, in that case C<NSS_NoDB_Init()>
called, that mode not very useful for certificate checks.

=item C<< Panda::NSS::reinit() >>

This function should be called after fork to reinitialize NSS library.
Any outstanding handles will become invalid, but new will work.

Actually this function compare current B<PID> with saved in previous C<init> or
C<reinit> one and calls C<< SECMOD_RestartModules(false) >> if needed.

Example:

  use Panda::NSS;

  Panda::NSS::init($nssdb_path);

  my $pid = fork();
  if ($pid == 0) {
      # child
      Panda::NSS::reinit();
      # ... other code in child
  }

=item C<< Panda::NSS::add_builtins() >>

This function load B<nssckbi> module, that contains default root certificates
in NSS. May croaks if library initialized without B<certdb>.

=back

=head1 CONSTANTS

=head2 Certificate usage

=over 4

=item C<< Panda::NSS::CERTIFICATE_USAGE_CHECK_ALL_USAGES >>

=item C<< Panda::NSS::CERTIFICATE_USAGE_SSL_CLIENT >>

=item C<< Panda::NSS::CERTIFICATE_USAGE_SSL_SERVER >>

=item C<< Panda::NSS::CERTIFICATE_USAGE_SSL_SERVER_WITH_STEP_UP >>

=item C<< Panda::NSS::CERTIFICATE_USAGE_SSL_CA >>

=item C<< Panda::NSS::CERTIFICATE_USAGE_EMAIL_SIGNER >>

=item C<< Panda::NSS::CERTIFICATE_USAGE_EMAIL_RECIPIENT >>

=item C<< Panda::NSS::CERTIFICATE_USAGE_OBJECT_SIGNER >>

=item C<< Panda::NSS::CERTIFICATE_USAGE_USER_CERT_IMPORT >>

=item C<< Panda::NSS::CERTIFICATE_USAGE_VERIFY_CA >>

=item C<< Panda::NSS::CERTIFICATE_USAGE_PROTECTED_OBJECT_SIGNER >>

=item C<< Panda::NSS::CERTIFICATE_USAGE_STATUS_RESPONDER >>

=item C<< Panda::NSS::CERTIFICATE_USAGE_ANY_CA >>

=back

=head1 CLASSES

=head2 C<< Panda::NSS::Cert >>

=head3 CONSTRUCTOR

=over 4

=item C<< $cert = Panda::NSS::Cert->new( $data ) >>

Constructs certificate object.

C<< $data >> can be certificate in B<DER> binary format or in B<PEM> format
(Base64 encoded B<DER> certificate, enclosed between I<"-----BEGIN CERTIFICATE-----">
and I<"-----END CERTIFICATE-----">). Format is auto-detected.

=back

=head3 PROPERTIES

=over 4

=item C<< $cert->version >>

Returns certificate version. 1, 2 or 3.

=item C<< $cert->serial_number >>

Returns certificate serial number as a binary string.

=item C<< $cert->serial_number_hex >>

Returns certificate serial number as a hex encoded string.

=item C<< $cert->subject >>

Returns certificate subject as a string.

=item C<< $cert->issuer >>

Returns certificate issuer as a string.

=item C<< $cert->common_name >>

Returns common name extracted from subject.

=item C<< $cert->country_name >>

Returns country name extracted from subject.

=item C<< $cert->locality_name >>

Returns locality name extracted from subject.

=item C<< $cert->state_name >>

Returns state field extracted from subject.

=item C<< $cert->org_name >>

Returns organization name extracted from subject.

=item C<< $cert->org_unit_name >>

Returns organization unit extracted from subject.

=item C<< $cert->domain_component_name >>

Returns domain component extracted from subject.

=back

=head3 METHODS

=over 4

=item C<< $rv = $cert->simple_verify( [ $usage ], [ $time ]) >>

Arguments:

=over 2

=item C<< $usage >> (Default: C<CERTIFICATE_USAGE_CHECK_ALL_USAGES>)

Certificate usage. One of C<CERTIFICATE_USAGE_*> constants.

=item C<< $time >> (Default: current time)

Time at which the certificate should be valid.

=back

Method do verification process (it uses C<CERT_PKIXVerifyCert> from I<NSS>).

Returns C<true> if certificate valid.

=item C<< $rv = $cert->verify_signed_data( $data, $signature, [ $time ]) >>

Verify the signature of a signed data with the given certificate.

Returns C<true> if signature match.

=back

=head1 SEE ALSO

=over 4

=item L<Crypt::NSS::X509>

Another try to bind NSS to Perl.

=item L<Crypt::OpenSSL::X509>

Allow to work with certificates, but can't validate with AIA.

=back

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/vovkasm/perl-Panda-NSS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/vovkasm/perl-Panda-NSS>

  git clone https://github.com/vovkasm/perl-Panda-NSS.git

=head1 AUTHOR

Vladimir Timofeev <vovkasm@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Vladimir Timofeev.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
