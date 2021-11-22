local $| = 1;

use strict;
use JSON;
use SelectPdf;

print "This is SelectPdf-$SelectPdf::VERSION\n";

my $test_url = "https://selectpdf.com/demo/files/selectpdf.pdf";
my $test_pdf = "Input.pdf";
my $local_file = "Result.pdf";
my $apiKey = "Your API key here";

eval {
    my $client = new SelectPdf::PdfMergeClient($apiKey);

    # set parameters - see full list at https://selectpdf.com/pdf-merge-api/
    $client
        # specify the pdf files that will be merged (order will be preserved in the final pdf)

        ->addFile($test_pdf) # add PDF from local file
        ->addUrlFile($test_url) # add PDF From public url
        #->addFileWithPassword($test_pdf, "pdf_password") # add PDF (that requires a password) from local file
        #->addUrlFileWithPassword($test_url, "pdf_password") # add PDF (that requires a password) from public url
    ;

    print "Starting pdf merge ...\n";

    # merge pdfs to local file
    $client->saveToFile($local_file);

    # merge pdfs to memory
    # my $pdf = $client->save();

    print "Finished! Number of pages: " . $client->getNumberOfPages() . ".\n";

    # get API usage
    my $usageClient = new SelectPdf::UsageClient($apiKey);
    my $usage = $usageClient->getUsage(0);
    print("Usage: " . encode_json($usage) . "\n");
    print("Conversions remained this month: ". $usage->{"available"});
};

if ($@) {
    print "An error occurred: $@\n";  
}