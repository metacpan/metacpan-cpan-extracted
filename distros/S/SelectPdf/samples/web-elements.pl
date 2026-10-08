local $| = 1;

use strict;
use SelectPdf;

print "This is SelectPdf-$SelectPdf::VERSION.\n";

my $url = "https://selectpdf.com/";
my $local_file = "Test.pdf";

# Web elements lookup requires a paid API key (the demo endpoint
# does not expose the elements service).
my $apiKey = "Your API key here";

eval {
    my $client = SelectPdf::HtmlToPdfClient->new($apiKey);

    # CSS selectors used to identify HTML elements whose location in
    # the resulting PDF should be reported back. See the API docs for
    # selector syntax: https://selectpdf.com/html-to-pdf-api/
    $client
        ->setPageSize(SelectPdf::PageSize::A4)
        ->setMargins(0)
        ->setPdfWebElementsSelectors("H1, H2, *.menu, *#footer")
    ;

    print "Starting conversion ...\n";

    $client->convertUrlToFile($url, $local_file);

    print "Finished! Number of pages: " . $client->getNumberOfPages() . ".\n";

    # Retrieve element rectangles. Returns an empty list if no element
    # matched the configured selectors.
    my $elements = $client->getWebElements();
    print "Web elements found: " . scalar(@$elements) . ".\n";

    foreach my $element (@$elements) {
        my $rectangles = $element->{PdfRectangles};
        print " - <" . ($element->{HtmlElementTagName} // "") . ">"
            . " id='" . ($element->{HtmlElementId} // "") . "'"
            . " class='" . ($element->{HtmlElementCssClassName} // "") . "'"
            . " rectangles=" . (ref($rectangles) eq 'ARRAY' ? scalar(@$rectangles) : 0) . "\n";
    }

    print "Mode: " . $client->getMode() . ", Execution: " . $client->getExecutionMode() . ".\n";
    print "Credits remaining: " . ($client->getCreditsRemaining() // "n/a") . " / " . ($client->getCreditsTotal() // "n/a") . ".\n";
};

if ($@) {
    print "An error occurred: $@\n";
}
