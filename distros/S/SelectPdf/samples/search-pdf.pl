local $| = 1;

use strict;
use JSON;
use SelectPdf;

print "This is SelectPdf-$SelectPdf::VERSION.\n";

my $test_url = "https://selectpdf.com/demo/files/selectpdf.pdf";
my $test_pdf = "Input.pdf";
my $apiKey = "Your API key here";

eval {
    my $client = new SelectPdf::PdfToTextClient($apiKey);

    print "Starting search pdf ...\n";

    # set parameters - see full list at https://selectpdf.com/pdf-to-text-api/
    $client
        ->setStartPage(1) # start page (processing starts from here)
        ->setEndPage(0) # end page (set 0 to process file til the end)
        ->setOutputFormat(0) # set output format - 0 (Text), 1 (Html)
    ;

    # search local pdf
    my $results = $client->searchFile($test_pdf, "pdf", "True", "True");

    # search pdf from public url
    # my $results = $client->searchUrl($test_url, "pdf", "True", "True");

    my $count = keys @{$results};
    print("Number of search results: " . $count . "\n");
    print("Results: " . encode_json($results) . "\n");

    print "Finished! Number of pages processed: " . $client->getNumberOfPages() . ".\n";

    # get API usage
    my $usageClient = new SelectPdf::UsageClient($apiKey);
    my $usage = $usageClient->getUsage(0);
    print("Usage: " . encode_json($usage) . "\n");
    print("Conversions remained this month: ". $usage->{"available"});
};

if ($@) {
    print "An error occurred: $@\n";  
}