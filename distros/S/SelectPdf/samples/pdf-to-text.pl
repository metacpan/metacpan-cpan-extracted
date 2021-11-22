local $| = 1;

use strict;
use JSON;
use SelectPdf;

print "This is SelectPdf-$SelectPdf::VERSION.\n";

my $test_url = "https://selectpdf.com/demo/files/selectpdf.pdf";
my $test_pdf = "Input.pdf";
my $local_file = "Test.txt";
my $apiKey = "Your API key here";

eval {
    my $client = new SelectPdf::PdfToTextClient($apiKey);

    print "Starting pdf to text ...\n";

    # set parameters - see full list at https://selectpdf.com/pdf-to-text-api/
    $client
        ->setStartPage(1) # start page (processing starts from here)
        ->setEndPage(0) # end page (set 0 to process file til the end)
        ->setOutputFormat(0) # set output format - 0 (Text), 1 (Html)
    ;

    # convert local pdf to local text file
    $client->getTextFromFileToFile($test_pdf, $local_file);

    # extract text from local pdf to memory
    # my $text = $client->getTextFromFile($test_pdf);
    # print $text;

    # convert pdf from public url to local text file
    # $client->getTextFromUrlToFile($test_url, $local_file);

    # extract text from pdf from public url to memory
    # my $text = $client->getTextFromUrl($test_url);
    # print $text;

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