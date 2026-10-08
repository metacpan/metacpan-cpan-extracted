local $| = 1;

use strict;
use JSON;
use SelectPdf;

print "This is SelectPdf-$SelectPdf::VERSION.\n";

my $url = "https://selectpdf.com/";
my $local_file = "Test.pdf";

# Replace with your API key for full production output.
# Pass undef, "" or "demo" instead to use the keyless demo endpoint
# (output is watermarked, capped at 5 pages, Chromium engine only):
#   my $apiKey = undef;
my $apiKey = "Your API key here";

eval {
    my $client = SelectPdf::HtmlToPdfClient->new($apiKey);

    # set parameters - see full list at https://selectpdf.com/html-to-pdf-api/
    $client
        # main properties

        ->setPageSize(SelectPdf::PageSize::A4) # PDF page size
        ->setPageOrientation(SelectPdf::PageOrientation::Portrait) # PDF page orientation
        ->setMargins(0) # PDF page margins
        ->setRenderingEngine(SelectPdf::RenderingEngine::WebKit) # rendering engine (demo mode forces Chromium)
        ->setConversionDelay(1) # conversion delay
        ->setNavigationTimeout(30) # navigation timeout
        ->setShowPageNumbers('False') # page numbers
        ->setPageBreaksEnhancedAlgorithm('True') # enhanced page break algorithm

        # additional properties

        #->setUseCssPrint('True') # enable CSS media print
        #->setDisableJavascript('True') # disable javascript
        #->setDisableInternalLinks('True') # disable internal links
        #->setDisableExternalLinks('True') # disable external links
        #->setKeepImagesTogether('True') # keep images together
        #->setScaleImages('True') # scale images to create smaller pdfs
        #->setSinglePagePdf('True') # generate a single page PDF
        #->setUserPassword('password') # secure the PDF with a password (paid keys only)

        # generate automatic bookmarks

        #->setPdfBookmarksSelectors("H1, H2") # create outlines (bookmarks) for the specified elements
        #->setViewerPageMode(SelectPdf::PageMode::UseOutlines) # display outlines (bookmarks) in viewer
    ;

    print "Starting conversion ...\n";

    # convert url to file
    $client->convertUrlToFile($url, $local_file);

    # convert url to memory
    # my $pdf = $client->convertUrl($url);

    # convert html string to file
    # $client->convertHtmlStringToFile("This is some <b>html</b>.", $local_file);

    # convert html string to memory
    # my $pdf = $client->convertHtmlString("This is some <b>html</b>.");

    print "Finished! Number of pages: " . $client->getNumberOfPages() . ".\n";

    # response telemetry
    print "Mode: " . $client->getMode() . ", Execution: " . $client->getExecutionMode() . ".\n";

    if ($client->isDemoMode()) {
        print "Demo clamped: " . join(", ", $client->getClampedFields()) . ".\n" if $client->wasClamped();
        print "Demo dropped: " . join(", ", $client->getDroppedFields()) . ".\n" if $client->wasAnyFieldDropped();
    }
    else {
        print "Credits remaining: " . $client->getCreditsRemaining() . " / " . $client->getCreditsTotal() . ".\n";

        # get API usage (paid keys only - the demo endpoint has no usage account)
        my $usageClient = new SelectPdf::UsageClient($apiKey);
        my $usage = $usageClient->getUsage();
        print("Usage: " . encode_json($usage) . "\n");
        print("Conversions remained this month: ". $usage->{"available"} . ".\n");
    }
};

if (my $err = $@) {
    if (ref $err && $err->isa('SelectPdf::DemoRateLimitException')) {
        # reason is one of: per_ip, daily_cap, concurrency
        print "Demo rate limit (" . $err->reason() . "). Retry after " . $err->retryAfter() . "s. Upgrade: " . $err->upgradeUrl() . "\n";
    }
    elsif (ref $err && $err->isa('SelectPdf::DemoSafetyException')) {
        # demo only converts public URLs - internal/private hosts are rejected
        print "Demo safety guard rejected '" . $err->field() . "' (reason=" . $err->reason() . ").\n";
    }
    elsif (ref $err && $err->isa('SelectPdf::DemoUnsupportedException')) {
        # feature not available on the demo endpoint (e.g. setUserPassword)
        print "Feature '" . $err->field() . "' not available in demo mode. Upgrade: " . $err->upgradeUrl() . "\n";
    }
    else {
        print "An error occurred: $err\n";
    }
}
