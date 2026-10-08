package SelectPdf::ApiEnums;

use strict;

our $VERSION = '1.6.0';

=head1 NAME

SelectPdf::ApiEnums - Named constants for the values accepted by the SelectPdf Online API client setters.

=head1 SYNOPSIS

Every setter that takes one of these values also accepts the plain value (for example C<"PdfA3B">, C<"Chromium"> or C<2>).
The constants exist so the allowed values are discoverable and typos are caught at compile time:

    use SelectPdf;

    my $client = SelectPdf::HtmlToPdfClient->new($apiKey);
    $client
        ->setRenderingEngine(SelectPdf::RenderingEngine::Chromium)
        ->setPdfStandard(SelectPdf::PdfStandard::PdfA3B)
        ->setPageNumbersAlignment(SelectPdf::PageNumbersAlignment::Center)
    ;

    my $invoice = SelectPdf::InvoiceClient->new($apiKey);
    $invoice->setZugferdProfile(SelectPdf::ZugferdProfile::En16931);

The same constants can also be called as class methods, e.g. C<< SelectPdf::PdfStandard->PdfA3B >>.

=head1 CONSTANTS

=head2 SelectPdf::PageSize

PDF page size: C<Custom>, C<A0>, C<A1>, C<A2>, C<A3>, C<A4>, C<A5>, C<A6>, C<A7>, C<A8>, C<Letter>, C<HalfLetter>, C<Ledger>, C<Legal>.

=head2 SelectPdf::PageOrientation

PDF page orientation: C<Portrait>, C<Landscape>.

=head2 SelectPdf::RenderingEngine

Rendering engine used for HTML to PDF conversion: C<WebKit>, C<Restricted> (WebKit Restricted), C<Blink>, C<Chromium>.

=head2 SelectPdf::SecureProtocol

Protocol used for secure (HTTPS) connections: C<Tls11OrNewer> (0, recommended), C<Tls10> (1), C<Ssl3> (2).

=head2 SelectPdf::PageLayout

The page layout used when the PDF document is opened in a viewer: C<SinglePage> (0), C<OneColumn> (1), C<TwoColumnLeft> (2), C<TwoColumnRight> (3).

=head2 SelectPdf::PageMode

The PDF document's page mode: C<UseNone> (0), C<UseOutlines> (1), C<UseThumbs> (2), C<FullScreen> (3), C<UseOC> (4), C<UseAttachments> (5).

=head2 SelectPdf::PageNumbersAlignment

Alignment for page numbers: C<Left> (1), C<Center> (2), C<Right> (3).

=head2 SelectPdf::StartupMode

Converter startup mode: C<Automatic> (the conversion starts right after the page loads), C<Manual> (the conversion starts only when called from JavaScript).

=head2 SelectPdf::TextLayout

Output text layout for PDF to text calls: C<Original> (0), C<Reading> (1).

=head2 SelectPdf::OutputFormat

Output format for PDF to text calls: C<Text> (0), C<Html> (1).

=head2 SelectPdf::PdfStandard

PDF conformance target for the generated document:

=over

=item * C<Full> - the complete PDF feature set. Default.

=item * C<PdfA> - PDF/A, long term archiving.

=item * C<PdfA2B> - PDF/A-2B, long term archiving, transparencies allowed.

=item * C<PdfA3A> - PDF/A-3A, the accessible level of PDF/A-3. Implies a tagged document and can carry a ZUGFeRD / Factur-X electronic invoice.

=item * C<PdfA3B> - PDF/A-3B, long term archiving with arbitrary embedded files. Can carry a ZUGFeRD / Factur-X electronic invoice.

=item * C<PdfA3U> - PDF/A-3U, PDF/A-3B with Unicode mapping for all text. Can carry a ZUGFeRD / Factur-X electronic invoice.

=item * C<PdfX> - PDF/X, graphics exchange.

=item * C<PdfSiqQ_A> - PDF/SiqQ Level A, suitable for digital signatures, external links disabled.

=item * C<PdfSiqQ_B> - PDF/SiqQ Level B, suitable for digital signatures.

=back

Tagged standards (PdfA3A) require the Blink or Chromium rendering engine. When no engine is specified the API promotes the
request to Chromium and reports the engine used in the X-SelectPdf-Engine response header.

=head2 SelectPdf::ZugferdProfile

The data profile of a ZUGFeRD / Factur-X hybrid electronic invoice:

=over

=item * C<Minimum> - MINIMUM, accounting information only. Not a complete invoice.

=item * C<Basic_WL> - BASIC WL, header and footer data without invoice lines. Not a complete invoice.

=item * C<Basic> - BASIC, a subset of EN 16931 covering simple invoices, with lines.

=item * C<En16931> - EN 16931 (formerly COMFORT), the full European semantic standard.

=item * C<Extended> - EXTENDED, EN 16931 plus additional business terms.

=item * C<XRechnung> - XRECHNUNG, the German public-sector reference profile. The embedded file is named xrechnung.xml instead of factur-x.xml.

=back

=head2 SelectPdf::ZugferdRelationship

How the embedded invoice XML relates to the visible invoice page:

=over

=item * C<Data> - the XML and the visible page carry exactly the same invoice content. Mandatory in Germany for the Basic, En16931, Extended and XRechnung profiles.

=item * C<Alternative> - the visible page carries more than the XML does (always the case for the Minimum and Basic_WL profiles), or the page was generated from the XML.

=item * C<Source> - the XML is the source the visible page was produced from.

=item * C<Supplement> - the XML supplements the visible page.

=back

When not set, the API derives this from the profile: Alternative for Minimum and Basic_WL, Data for the rest.
Minimum and Basic_WL combined with Data are rejected, because those profiles do not carry a complete invoice.

=head2 SelectPdf::ZugferdSchema

The metadata schema used to identify a hybrid invoice inside the PDF:

=over

=item * C<FacturX10> - Factur-X 1.0 / ZUGFeRD 2.x, the current schema. Default.

=item * C<Zugferd20> - ZUGFeRD 2.0, the legacy schema, deprecated but still accepted. Use only for recipients that explicitly require it.

=back

=cut

package SelectPdf::PageSize;
use constant {
    Custom => 'Custom', A0 => 'A0', A1 => 'A1', A2 => 'A2', A3 => 'A3', A4 => 'A4', A5 => 'A5',
    A6 => 'A6', A7 => 'A7', A8 => 'A8', Letter => 'Letter', HalfLetter => 'HalfLetter',
    Ledger => 'Ledger', Legal => 'Legal',
};

package SelectPdf::PageOrientation;
use constant {
    Portrait => 'Portrait', Landscape => 'Landscape',
};

package SelectPdf::RenderingEngine;
use constant {
    WebKit => 'WebKit', Restricted => 'Restricted', Blink => 'Blink', Chromium => 'Chromium',
};

package SelectPdf::SecureProtocol;
use constant {
    Tls11OrNewer => 0, Tls10 => 1, Ssl3 => 2,
};

package SelectPdf::PageLayout;
use constant {
    SinglePage => 0, OneColumn => 1, TwoColumnLeft => 2, TwoColumnRight => 3,
};

package SelectPdf::PageMode;
use constant {
    UseNone => 0, UseOutlines => 1, UseThumbs => 2, FullScreen => 3, UseOC => 4, UseAttachments => 5,
};

package SelectPdf::PageNumbersAlignment;
use constant {
    Left => 1, Center => 2, Right => 3,
};

package SelectPdf::StartupMode;
use constant {
    Automatic => 'Automatic', Manual => 'Manual',
};

package SelectPdf::TextLayout;
use constant {
    Original => 0, Reading => 1,
};

package SelectPdf::OutputFormat;
use constant {
    Text => 0, Html => 1,
};

package SelectPdf::PdfStandard;
use constant {
    Full => 'Full', PdfA => 'PdfA', PdfA2B => 'PdfA2B', PdfA3A => 'PdfA3A', PdfA3B => 'PdfA3B',
    PdfA3U => 'PdfA3U', PdfX => 'PdfX', PdfSiqQ_A => 'PdfSiqQ_A', PdfSiqQ_B => 'PdfSiqQ_B',
};

package SelectPdf::ZugferdProfile;
use constant {
    Minimum => 'Minimum', Basic_WL => 'Basic_WL', Basic => 'Basic', En16931 => 'En16931',
    Extended => 'Extended', XRechnung => 'XRechnung',
};

package SelectPdf::ZugferdRelationship;
use constant {
    Data => 'Data', Alternative => 'Alternative', Source => 'Source', Supplement => 'Supplement',
};

package SelectPdf::ZugferdSchema;
use constant {
    FacturX10 => 'FacturX10', Zugferd20 => 'Zugferd20',
};

1;
