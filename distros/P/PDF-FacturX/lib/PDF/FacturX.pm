package PDF::FacturX;
use strict;
use warnings;
use utf8;
use Exporter 'import';

use PDF::FacturX::XML   qw(build_xml validate_xml);
use PDF::FacturX::Embed qw(embed_xml_pdfa3);

our $VERSION = '0.01';

our @EXPORT_OK = qw(generate);

###############################################################################
# generate(%opts) — façade end-to-end :
#   1. Validate the invoice hash (fast, in-Perl, French error messages)
#   2. Build the Factur-X CrossIndustryInvoice XML for the requested profile
#   3. Validate the XML against the bundled official XSD (unless validate=>0)
#   4. Embed the XML into a PDF/A-3 envelope with proper XMP, AF, OutputIntent
#
# Returns (1, $info) on success or (0, $error) on failure. Never dies on
# expected error paths — die-on-error stays inside the lower-level modules
# only when called directly.
###############################################################################
sub generate {
    my (%opt) = @_;

    my $invoice = $opt{invoice};
    return (0, 'invoice requis') unless ref $invoice eq 'HASH';

    my $profile = $opt{profile} || 'basic';
    my $do_validate = exists $opt{validate} ? $opt{validate} : 1;

    # 1+2. Build XML (validation maison happens inside build_xml)
    my $xml = eval { build_xml($invoice, $profile) };
    if ($@) {
        my $err = $@;
        chomp $err;
        return (0, "build_xml KO : $err");
    }

    # 3. XSD validation (optional)
    if ($do_validate) {
        my ($xsd_ok, $xsd_msg) = validate_xml($xml, $profile);
        return (0, "XSD validation KO : $xsd_msg") unless $xsd_ok;
    }

    # 4. Embed into PDF/A-3
    my ($ok, $msg) = eval {
        embed_xml_pdfa3(
            pdf_in     => $opt{pdf_in},
            pdf_out    => $opt{pdf_out},
            xml        => $xml,
            profile    => $profile,
            title      => $opt{title},
            author     => $opt{author},
            creator    => $opt{creator},
            tmp_dir    => $opt{tmp_dir},
            gs         => $opt{gs},
            icc_path   => $opt{icc_path},
            on_warning => $opt{on_warning},
        );
    };
    if ($@) {
        my $err = $@;
        chomp $err;
        return (0, "embed KO : $err");
    }
    return ($ok, $msg);
}

1;

__END__

=encoding utf-8

=head1 NAME

PDF::FacturX - Generate Factur-X / ZUGFeRD-compatible PDF/A-3 invoices

=head1 SYNOPSIS

    use PDF::FacturX qw(generate);

    my ($ok, $msg) = generate(
        pdf_in  => 'invoice-source.pdf',   # any visual PDF
        pdf_out => 'invoice-facturx.pdf',  # PDF/A-3 with XML attached
        invoice => {
            number   => 'FA-2026-0042',
            date     => '2026-04-19',
            due_date => '2026-05-19',
            currency => 'EUR',
            seller   => {
                name      => 'Acme SARL',
                siret     => '12345678901234',
                vat       => 'FR12345678901',
                address_1 => '1 rue de la Paix',
                postcode  => '75001',
                city      => 'Paris',
                country   => 'FR',
            },
            buyer => {
                name      => 'Kunde GmbH',
                address_1 => 'Hauptstrasse 1',
                postcode  => '10115',
                city      => 'Berlin',
                country   => 'DE',
            },
            lines => [
                { name => 'Consulting', qty => 8, unit_price => 125,
                  vat_rate => 20, vat_cat => 'S' },
            ],
            payment => {
                terms => 'Net 30',
                iban  => 'FR7612345678901234567890123',
                bic   => 'BNPAFRPP',
            },
        },
        profile => 'en16931',
        title   => 'Facture FA-2026-0042',
        author  => 'Acme SARL',
    );
    die "Factur-X generation failed: $msg" unless $ok;

=head1 DESCRIPTION

C<PDF::FacturX> generates compliant Factur-X / ZUGFeRD invoices: a PDF/A-3
file embedding the structured CrossIndustryInvoice XML defined by the
European Norm L<EN 16931|https://www.beuth.de/en/standard/din-en-16931-1/267253268>.
Factur-X is the joint Franco-German specification published by FNFE-MPE
(France) and FeRD (Germany) and is the reference format for the French
B2B e-invoicing reform (mandatory rollout 2026-2027) and the German
ZUGFeRD ecosystem.

The module orchestrates two lower-level modules:

=over 4

=item * L<PDF::FacturX::XML> — builds and validates the XML against the
official XSD bundled with this distribution.

=item * L<PDF::FacturX::Embed> — wraps an existing PDF into a PDF/A-3
envelope with the XML attached as an associated file (AFRelationship =
/Data) and the XMP metadata stream required by PDF/A-3.

=back

=head1 SUPPORTED PROFILES

=over 4

=item * C<minimum>      — header data only

=item * C<basicwl>      — without lines

=item * C<basic>        — line items + tax breakdown (compliant EN 16931)

=item * C<en16931>      — full European Norm

=back

=head1 FUNCTIONS

=head2 generate(%opts)

Returns C<(1, $info)> on success or C<(0, $error_message)> on failure.

Required options:

=over 4

=item C<pdf_in>      — path to the source PDF

=item C<pdf_out>     — path to write the resulting PDF/A-3

=item C<invoice>     — invoice hash (see L<PDF::FacturX::XML>)

=back

Optional options:

=over 4

=item C<profile>     — one of C<minimum|basicwl|basic|en16931> (default C<basic>)

=item C<validate>    — 1 to validate XML against XSD before embedding (default 1)

=item C<title>, C<author>, C<creator> — PDF metadata

=item C<tmp_dir>     — directory for ephemeral files (default: system temp)

=item C<gs>          — Ghostscript binary (default C<gs>)

=item C<icc_path>    — path to sRGB ICC profile (default: auto-detect)

=item C<on_warning>  — coderef called with PDF::Builder warnings

=back

=head1 REQUIREMENTS

=over 4

=item * Perl 5.20 or later

=item * L<XML::LibXML>, L<PDF::Builder>, L<File::ShareDir>

=item * Ghostscript 10.x or later (system binary)

=back

=head1 SEE ALSO

=over 4

=item * L<https://fnfe-mpe.org/factur-x/> — French specification (FNFE-MPE)

=item * L<https://www.ferd-net.de/standards/zugferd/> — German specification (FeRD / ZUGFeRD)

=item * L<https://services.fnfe-mpe.org/> — official online validator

=item * L<https://unece.org/trade/uncefact> — UN/CEFACT Cross Industry Invoice

=back

=head1 LICENSE

This software is copyright (c) 2026 by huguesmax.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself: the
L<Artistic License 2.0|https://opensource.org/licenses/Artistic-2.0>.

=cut
