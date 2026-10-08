local $| = 1;

use strict;
use SelectPdf;

# ZUGFeRD / Factur-X hybrid electronic invoice.

print "This is SelectPdf-$SelectPdf::VERSION.\n";

# A minimal, well-formed EN 16931 CrossIndustryInvoice, inline so the
# sample runs without any extra files. A real integration produces this
# from its own invoice data - the API embeds the bytes as given and does
# not validate the invoice content.
my $invoiceXml =
    '<?xml version="1.0" encoding="UTF-8"?>' .
    '<rsm:CrossIndustryInvoice' .
    ' xmlns:rsm="urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100"' .
    ' xmlns:ram="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100"' .
    ' xmlns:udt="urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100">' .
      '<rsm:ExchangedDocumentContext>' .
        '<ram:GuidelineSpecifiedDocumentContextParameter>' .
          '<ram:ID>urn:cen.eu:en16931:2017</ram:ID>' .
        '</ram:GuidelineSpecifiedDocumentContextParameter>' .
      '</rsm:ExchangedDocumentContext>' .
      '<rsm:ExchangedDocument>' .
        '<ram:ID>INV-2026-001</ram:ID>' .
        '<ram:TypeCode>380</ram:TypeCode>' .
        '<ram:IssueDateTime>' .
          '<udt:DateTimeString format="102">20260924</udt:DateTimeString>' .
        '</ram:IssueDateTime>' .
      '</rsm:ExchangedDocument>' .
    '</rsm:CrossIndustryInvoice>';

my $invoiceHtml =
    '<html><head><title>Invoice INV-2026-001</title></head><body>' .
    '<h1>Invoice INV-2026-001</h1>' .
    '<p>Seller Ltd &#8212; Buyer GmbH</p>' .
    '<table>' .
      '<tr><th>Item</th><th>Total</th></tr>' .
      '<tr><td>Consulting</td><td>1000.00 EUR</td></tr>' .
    '</table>' .
    '</body></html>';

my $local_file = "Invoice.pdf";

# Electronic invoices require an API key - the keyless demo endpoint
# does not produce them, and SelectPdf::InvoiceClient refuses a demo key
# rather than failing later on the server.
my $apiKey = "Your API key here";

eval {
    my $client = SelectPdf::InvoiceClient->new($apiKey);

    # set parameters - see full list at https://selectpdf.com/html-to-pdf-api-parameters/#invoicing
    $client
        # The invoice XML. From memory here; from disk with
        #   $client->setInvoiceXmlFile("factur-x.xml");
        # Either way the name recorded inside the PDF is the one the
        # standard prescribes - recipients look it up by name, so it is
        # not taken from your file name.
        ->setInvoiceXml($invoiceXml)

        # How much of the EN 16931 model the XML carries. Required.
        #   Minimum / Basic_WL - not complete invoices
        #   Basic / En16931 / Extended - complete, increasing detail
        #   XRechnung - German public sector; the embedded file is then
        #               named xrechnung.xml instead of factur-x.xml
        ->setZugferdProfile(SelectPdf::ZugferdProfile::En16931)
    ;

    # Optional. Left unset, the API derives the relationship from the
    # profile: Alternative for Minimum and Basic_WL, where the visible
    # page carries more than the XML, and Data for the rest, where both
    # carry the same content - which Germany mandates for BASIC,
    # EN 16931, EXTENDED and XRECHNUNG. Minimum or Basic_WL combined
    # with Data is rejected, because it would not be true.
    #
    #     $client->setZugferdRelationship(SelectPdf::ZugferdRelationship::Data);

    # Optional. Factur-X 1.0 is the current schema and the default;
    # ZUGFeRD 2.0 is deprecated and only for recipients that require it.
    #
    #     $client->setZugferdSchema(SelectPdf::ZugferdSchema::Zugferd20);

    # The carrier must be PDF/A-3. It defaults to PdfA3A, the accessible
    # level, which the standards recommend because it also makes the
    # visible invoice readable by assistive technology. PdfA3B and
    # PdfA3U are accepted; anything else is rejected.
    #
    #     $client->setPdfStandard(SelectPdf::PdfStandard::PdfA3B);

    # Every ordinary conversion setting applies here as well, because
    # SelectPdf::InvoiceClient derives from SelectPdf::HtmlToPdfClient.
    $client->setMargins(20);

    print "Starting invoice conversion ...\n";

    # create the hybrid invoice from raw html, into a local file
    $client->createFromHtmlStringToFile($invoiceHtml, $local_file);

    # ... or from the invoice page your application already renders
    # $client->createFromUrlToFile("https://your-app.example/invoices/INV-2026-001", $local_file);

    # ... or into memory
    # my $pdf = $client->createFromHtmlString($invoiceHtml);

    # ... or asynchronously, for long invoice runs
    # $client->createFromHtmlStringToFileAsync($invoiceHtml, $local_file);

    print "Finished! Number of pages: " . $client->getNumberOfPages() . ".\n";
    print "Wrote $local_file - a PDF/A-3 document with factur-x.xml embedded.\n";

    # response telemetry
    print "Mode: " . $client->getMode() . ", Execution: " . $client->getExecutionMode() . ".\n";
    print "Credits remaining: " . ($client->getCreditsRemaining() // "n/a") . " / " . ($client->getCreditsTotal() // "n/a") . ".\n";
};

if ($@) {
    print "An error occurred: $@\n";
}
