package SelectPdf::InvoiceClient;

use Encode ();
use IO::File;
use SelectPdf::ApiEnums;
use SelectPdf::AsyncJobClient;
use SelectPdf::HtmlToPdfClient;
use strict;
our @ISA = qw(SelectPdf::HtmlToPdfClient);

our $VERSION = '1.6.0';

=head1 NAME

SelectPdf::InvoiceClient - Create ZUGFeRD / Factur-X hybrid electronic invoices with SelectPdf Online API.

=head1 SYNOPSIS

Create a hybrid electronic invoice from an HTML string and save it into a file on disk.

    use SelectPdf;
    print "This is SelectPdf-$SelectPdf::VERSION\n";

    my $apiKey = "Your API key here";
    my $invoiceHtml = "<html><body><h1>Invoice INV-2026-001</h1></body></html>";
    my $invoiceXml = "factur-x.xml";
    my $local_file = "Invoice.pdf";

    eval {
        my $client = SelectPdf::InvoiceClient->new($apiKey);

        $client
            ->setInvoiceXmlFile($invoiceXml)
            ->setZugferdProfile(SelectPdf::ZugferdProfile::En16931)
            ->setDocTitle("Invoice INV-2026-001")
        ;

        $client->createFromHtmlStringToFile($invoiceHtml, $local_file);

        print "Finished! Number of pages: " . $client->getNumberOfPages() . ".\n";
    };

    if ($@) {
        print "An error occurred: $@\n";
    }

=head1 DESCRIPTION

A hybrid electronic invoice is one PDF/A-3 file carrying both halves of the invoice: the page a human reads,
and the XML a recipient's accounting system reads. This client converts a URL or an HTML string into the visible
invoice and embeds the XML into it as an associated file, with the metadata invoice software looks for.

It derives from SelectPdf::HtmlToPdfClient, so every conversion setting - page size, margins, headers, footers,
rendering engine - applies here too. Use the createFrom* methods rather than the inherited convert* methods:
the invoice endpoint takes a multipart request, because the XML is uploaded as a file part.

The carrier document must be PDF/A-3. The default is PdfA3A, the accessible level, which the standards recommend
because it makes the visible invoice readable by assistive technology as well as archivable. Because PdfA3A is a
tagged standard, a request that does not set a rendering engine is promoted to Chromium by the API, which reports
the engine used in the X-SelectPdf-Engine response header.

There is no way to attach an invoice XML to an existing PDF you already have: the XML can only be embedded into a
document created as PDF/A-3.

For more details and full list of parameters see L<Html To Pdf API Parameters|https://selectpdf.com/html-to-pdf-api-parameters/#invoicing>.

=head1 METHODS

=head2 new( $apiKey )

Construct the Invoice Client.

    my $client = SelectPdf::InvoiceClient->new($apiKey);

Unlike SelectPdf::HtmlToPdfClient, this client has no demo mode - the keyless demo endpoint does not produce
electronic invoices - so an API key is required. The constructor dies when no API key is supplied.

Parameters:

- $apiKey API Key.
=cut
sub new {
    my $type = shift;
    my $apiKey = shift;

    if (not defined($apiKey) or $apiKey eq "" or lc(_trim($apiKey)) eq "demo") {
        die "An API key is required to create electronic invoices. The keyless demo endpoint does not support them.";
    }

    my $self = $type->SUPER::new($apiKey);

    # API endpoint
    $self->{apiEndpoint} = "https://selectpdf.com/api2/invoice/";

    # The carrier has to be PDF/A-3; default to the accessible level, which
    # the standards recommend. Overridable with setPdfStandard.
    $self->{parameters}{"pdf_standard"} = SelectPdf::PdfStandard::PdfA3A;

    bless $self, $type;
    return $self;
}

sub _trim {
    my($value) = @_;
    $value =~ s/^\s+|\s+$//g;
    return $value;
}

=head2 setInvoiceXmlFile( $invoiceXmlFile )

Set the invoice XML from a local file.

Only the content of the file is used - the name recorded inside the PDF is the one the standard prescribes
("factur-x.xml", or "xrechnung.xml" for the XRECHNUNG profile), because recipients look it up by name.

Parameters:

- $invoiceXmlFile: Path to the local invoice XML file.

Returns:

- Reference to the current object.
=cut
sub setInvoiceXmlFile($) {
    my($self, $invoiceXmlFile) = @_;

    delete $self->{binaryData}{"zugferd_xml"};
    $self->{files}{"zugferd_xml"} = $invoiceXmlFile;
    return $self;
}

=head2 setInvoiceXml( $invoiceXml )

Set the invoice XML from memory.

A character string (with the UTF-8 flag on) is encoded as UTF-8 before it is sent; any other string is sent as-is, as bytes.

Parameters:

- $invoiceXml: The invoice XML content.

Returns:

- Reference to the current object.
=cut
sub setInvoiceXml($) {
    my($self, $invoiceXml) = @_;

    $invoiceXml = "" if (not defined($invoiceXml));
    $invoiceXml = Encode::encode('UTF-8', $invoiceXml) if (utf8::is_utf8($invoiceXml));

    delete $self->{files}{"zugferd_xml"};
    $self->{binaryData}{"zugferd_xml"} = $invoiceXml;
    return $self;
}

=head2 setZugferdProfile( $profile )

Set the data profile of the invoice XML - how much of the EN 16931 semantic model it carries. Required.

Parameters:

- $profile: Invoice profile. Possible values: Minimum, Basic_WL, Basic, En16931, Extended, XRechnung (see SelectPdf::ZugferdProfile constants).

Returns:

- Reference to the current object.
=cut
sub setZugferdProfile($) {
    my($self, $profile) = @_;

    if (not defined($profile) or $profile !~ m/^(Minimum|Basic_WL|Basic|En16931|Extended|XRechnung)$/i) {
        die ("Allowed values for Zugferd Profile: Minimum, Basic_WL, Basic, En16931, Extended, XRechnung.");
    }

    $self->{parameters}{"zugferd_profile"} = $profile;
    return $self;
}

=head2 setZugferdRelationship( $relationship )

Set how the embedded invoice XML relates to the visible invoice page.

Optional. When not set, the API derives it from the profile: Alternative for Minimum and Basic_WL, and Data for the rest.
Minimum and Basic_WL combined with Data are rejected, because those profiles do not carry a complete invoice.

Parameters:

- $relationship: Relationship. Possible values: Data, Alternative, Source, Supplement (see SelectPdf::ZugferdRelationship constants).

Returns:

- Reference to the current object.
=cut
sub setZugferdRelationship($) {
    my($self, $relationship) = @_;

    if (not defined($relationship) or $relationship !~ m/^(Data|Alternative|Source|Supplement)$/i) {
        die ("Allowed values for Zugferd Relationship: Data, Alternative, Source, Supplement.");
    }

    $self->{parameters}{"zugferd_relationship"} = $relationship;
    return $self;
}

=head2 setZugferdSchema( $schema )

Set the metadata schema used to identify the hybrid invoice inside the PDF. Default is FacturX10.

Parameters:

- $schema: Schema. Possible values: FacturX10, Zugferd20 (see SelectPdf::ZugferdSchema constants).

Returns:

- Reference to the current object.
=cut
sub setZugferdSchema($) {
    my($self, $schema) = @_;

    if (not defined($schema) or $schema !~ m/^(FacturX10|Zugferd20)$/i) {
        die ("Allowed values for Zugferd Schema: FacturX10, Zugferd20.");
    }

    $self->{parameters}{"zugferd_schema"} = $schema;
    return $self;
}

=head2 createFromUrl( $url )

Create the hybrid invoice from the specified url. The page at the url becomes the visible invoice.

    $content = $client->createFromUrl($url);

Parameters:

- $url Address of the web page with the visible invoice.

Returns:

- Byte array containing the resulted PDF.
=cut
sub createFromUrl($) {
    my($self, $url) = @_;

    $self->_prepareUrl($url);
    $self->{parameters}{"async"} = "False";

    return $self->SUPER::performPostAsMultipartFormData();
}

=head2 createFromUrlToFile( $url, $filePath )

Create the hybrid invoice from the specified url and write it to a local file.

    $client->createFromUrlToFile($url, $filePath);

Parameters:

- $url Address of the web page with the visible invoice.

- $filePath Local file including path if necessary.
=cut
sub createFromUrlToFile($$) {
    my($self, $url, $filePath) = @_;

    my $content = $self->createFromUrl($url);
    _writeFile($filePath, $content);
}

=head2 createFromUrlAsync( $url )

Create the hybrid invoice from the specified url, using an asynchronous call.

    $content = $client->createFromUrlAsync($url);

Parameters:

- $url Address of the web page with the visible invoice.

Returns:

- Byte array containing the resulted PDF.
=cut
sub createFromUrlAsync($) {
    my($self, $url) = @_;

    $self->_prepareUrl($url);
    return $self->_runAsyncJob();
}

=head2 createFromUrlToFileAsync( $url, $filePath )

Create the hybrid invoice from the specified url, using an asynchronous call, and write it to a local file.

    $client->createFromUrlToFileAsync($url, $filePath);

Parameters:

- $url Address of the web page with the visible invoice.

- $filePath Local file including path if necessary.
=cut
sub createFromUrlToFileAsync($$) {
    my($self, $url, $filePath) = @_;

    my $content = $self->createFromUrlAsync($url);
    _writeFile($filePath, $content);
}

=head2 createFromHtmlString( $htmlString )

Create the hybrid invoice from the specified HTML string, which becomes the visible invoice.

    $content = $client->createFromHtmlString($htmlString);

Parameters:

- $htmlString HTML string with the visible invoice.

Returns:

- Byte array containing the resulted PDF.
=cut
sub createFromHtmlString($) {
    my($self, $htmlString) = @_;

    return $self->createFromHtmlStringWithBaseUrl($htmlString, "");
}

=head2 createFromHtmlStringWithBaseUrl( $htmlString, $baseUrl )

Create the hybrid invoice from the specified HTML string. Use a base url to resolve relative paths to resources.

    $content = $client->createFromHtmlStringWithBaseUrl($htmlString, $baseUrl);

Parameters:

- $htmlString HTML string with the visible invoice.

- $baseUrl Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.

Returns:

- Byte array containing the resulted PDF.
=cut
sub createFromHtmlStringWithBaseUrl($$) {
    my($self, $htmlString, $baseUrl) = @_;

    $self->_prepareHtml($htmlString, $baseUrl);
    $self->{parameters}{"async"} = "False";

    return $self->SUPER::performPostAsMultipartFormData();
}

=head2 createFromHtmlStringToFile( $htmlString, $filePath )

Create the hybrid invoice from the specified HTML string and write it to a local file.

    $client->createFromHtmlStringToFile($htmlString, $filePath);

Parameters:

- $htmlString HTML string with the visible invoice.

- $filePath Local file including path if necessary.
=cut
sub createFromHtmlStringToFile($$) {
    my($self, $htmlString, $filePath) = @_;

    $self->createFromHtmlStringWithBaseUrlToFile($htmlString, "", $filePath);
}

=head2 createFromHtmlStringWithBaseUrlToFile( $htmlString, $baseUrl, $filePath )

Create the hybrid invoice from the specified HTML string and write it to a local file. Use a base url to resolve relative paths to resources.

    $client->createFromHtmlStringWithBaseUrlToFile($htmlString, $baseUrl, $filePath);

Parameters:

- $htmlString HTML string with the visible invoice.

- $baseUrl Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.

- $filePath Local file including path if necessary.
=cut
sub createFromHtmlStringWithBaseUrlToFile($$$) {
    my($self, $htmlString, $baseUrl, $filePath) = @_;

    my $content = $self->createFromHtmlStringWithBaseUrl($htmlString, $baseUrl);
    _writeFile($filePath, $content);
}

=head2 createFromHtmlStringAsync( $htmlString )

Create the hybrid invoice from the specified HTML string, using an asynchronous call.

    $content = $client->createFromHtmlStringAsync($htmlString);

Parameters:

- $htmlString HTML string with the visible invoice.

Returns:

- Byte array containing the resulted PDF.
=cut
sub createFromHtmlStringAsync($) {
    my($self, $htmlString) = @_;

    return $self->createFromHtmlStringWithBaseUrlAsync($htmlString, "");
}

=head2 createFromHtmlStringWithBaseUrlAsync( $htmlString, $baseUrl )

Create the hybrid invoice from the specified HTML string, using an asynchronous call. Use a base url to resolve relative paths to resources.

    $content = $client->createFromHtmlStringWithBaseUrlAsync($htmlString, $baseUrl);

Parameters:

- $htmlString HTML string with the visible invoice.

- $baseUrl Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.

Returns:

- Byte array containing the resulted PDF.
=cut
sub createFromHtmlStringWithBaseUrlAsync($$) {
    my($self, $htmlString, $baseUrl) = @_;

    $self->_prepareHtml($htmlString, $baseUrl);
    return $self->_runAsyncJob();
}

=head2 createFromHtmlStringToFileAsync( $htmlString, $filePath )

Create the hybrid invoice from the specified HTML string, using an asynchronous call, and write it to a local file.

    $client->createFromHtmlStringToFileAsync($htmlString, $filePath);

Parameters:

- $htmlString HTML string with the visible invoice.

- $filePath Local file including path if necessary.
=cut
sub createFromHtmlStringToFileAsync($$) {
    my($self, $htmlString, $filePath) = @_;

    $self->createFromHtmlStringWithBaseUrlToFileAsync($htmlString, "", $filePath);
}

=head2 createFromHtmlStringWithBaseUrlToFileAsync( $htmlString, $baseUrl, $filePath )

Create the hybrid invoice from the specified HTML string, using an asynchronous call, and write it to a local file.
Use a base url to resolve relative paths to resources.

    $client->createFromHtmlStringWithBaseUrlToFileAsync($htmlString, $baseUrl, $filePath);

Parameters:

- $htmlString HTML string with the visible invoice.

- $baseUrl Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.

- $filePath Local file including path if necessary.
=cut
sub createFromHtmlStringWithBaseUrlToFileAsync($$$) {
    my($self, $htmlString, $baseUrl, $filePath) = @_;

    my $content = $self->createFromHtmlStringWithBaseUrlAsync($htmlString, $baseUrl);
    _writeFile($filePath, $content);
}

# --- internals -------------------------------------------------------

sub _prepareUrl {
    my($self, $url) = @_;

    if (not defined($url) or $url !~ m/^https?:\/\//i) {
        die "The supported protocols for the converted webpage are http:// and https://.";
    }
    if ($url =~ m/^http:\/\/localhost/i) {
        die "Cannot convert local urls. SelectPdf online API can only convert publicly available urls.";
    }

    $self->_requireInvoiceXml();
    $self->{parameters}{"url"} = $url;
    $self->{parameters}{"html"} = "";
    $self->{parameters}{"base_url"} = "";
}

sub _prepareHtml {
    my($self, $htmlString, $baseUrl) = @_;

    $self->_requireInvoiceXml();
    $self->{parameters}{"url"} = "";
    $self->{parameters}{"html"} = $htmlString;
    $self->{parameters}{"base_url"} = defined($baseUrl) ? $baseUrl : "";
}

# Fail here rather than spending a round trip on a request the API will
# reject with the same message.
sub _requireInvoiceXml {
    my($self) = @_;

    if (not exists($self->{files}{"zugferd_xml"}) and not exists($self->{binaryData}{"zugferd_xml"})) {
        die "The invoice XML was not specified. Call setInvoiceXmlFile or setInvoiceXml before creating the invoice.";
    }
    if (not defined($self->{parameters}{"zugferd_profile"}) or $self->{parameters}{"zugferd_profile"} eq "") {
        die "The invoice profile was not specified. Call setZugferdProfile before creating the invoice.";
    }
}

sub _runAsyncJob {
    my($self) = @_;

    my $JobID = $self->SUPER::startAsyncJobMultipartFormData() or die "An error occurred launching the asynchronous call.";

    my $noPings = 0;

    while ($noPings < $self->{AsyncCallsMaxPings}) {
        $noPings++;

        # sleep for a few seconds before next ping
        sleep($self->{AsyncCallsPingInterval});

        my $asyncJobClient = new SelectPdf::AsyncJobClient($self->{parameters}{"key"}, $JobID);
        $asyncJobClient->setApiEndpoint($self->{apiAsyncEndpoint});

        my $result = $asyncJobClient->getResult();

        if ($asyncJobClient->finished) {
            $self->{numberOfPages} = $asyncJobClient->getNumberOfPages();
            $self->{creditsTotal} = $asyncJobClient->getCreditsTotal();
            $self->{creditsRemaining} = $asyncJobClient->getCreditsRemaining();

            return $result;
        }
    }

    die "Asynchronous call did not finish in expected timeframe.";
}

sub _writeFile {
    my($filePath, $content) = @_;

    my $file = IO::File->new( $filePath, '>' ) or die "Unable to open output file - $!\n";
    $file->binmode;
    $file->print( $content );
    $file->close;
}

1;
