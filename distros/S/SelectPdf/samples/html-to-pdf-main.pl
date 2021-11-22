local $| = 1;

use strict;
use JSON;
use SelectPdf;

print "This is SelectPdf-$SelectPdf::VERSION.\n";

my $url = "https://selectpdf.com/";
my $local_file = "Test.pdf";
my $apiKey = "Your API key here";

eval {
    my $client = new SelectPdf::HtmlToPdfClient($apiKey);
    
    # set parameters - see full list at https://selectpdf.com/html-to-pdf-api/
    $client
        # main properties
        
        ->setPageSize("A4") # PDF page size
        ->setPageOrientation("Portrait") # PDF page orientation
        ->setMargins(0) # PDF page margins
        ->setRenderingEngine('WebKit') # rendering engine
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
        #->setUserPassword('password') # secure the PDF with a password

        # generate automatic bookmarks
        
        #->setPdfBookmarksSelectors("H1, H2") # create outlines (bookmarks) for the specified elements
        #->setViewerPageMode(1) # 1 (Use Outlines) - display outlines (bookmarks) in viewer
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

    # get API usage
    my $usageClient = new SelectPdf::UsageClient($apiKey);
    my $usage = $usageClient->getUsage();
    print("Usage: " . encode_json($usage) . "\n");
    print("Conversions remained this month: ". $usage->{"available"});
};

if ($@) {
    print "An error occurred: $@\n";  
}