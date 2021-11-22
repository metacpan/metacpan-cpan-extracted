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
        ->setMargins(0) # PDF page margins
        ->setPageBreaksEnhancedAlgorithm('True') # enhanced page break algorithm

        # header properties
        ->setShowHeader('True') # display header
        #->setHeaderHeight(50) # header height
        #->setHeaderUrl($url) # header url
        ->setHeaderHtml("This is the <b>HEADER</b>!!!!") # header html

        # footer properties
        ->setShowFooter('True') # display footer
        #->setFooterHeight(60) # footer height
        #->setFooterUrl($url) # footer url
        ->setFooterHtml("This is the <b>Footer</b>!!!!") # footer html

        # footer page numbers
        ->setShowPageNumbers('True') # show page numbers in footer
        ->setPageNumbersTemplate('{page_number} / {total_pages}') # page numbers template
        ->setPageNumbersFontName('Verdana') # page numbers font name
        ->setPageNumbersFontSize(12) # page numbers font size
        ->setPageNumbersAlignment(2) # page numbers alignment 2 = Center
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