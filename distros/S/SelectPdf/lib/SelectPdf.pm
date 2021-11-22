package SelectPdf;

our $VERSION = '1.4.0';

require SelectPdf::HtmlToPdfClient;
require SelectPdf::PdfMergeClient;
require SelectPdf::PdfToTextClient;
require SelectPdf::UsageClient;

=head1 NAME
 
SelectPdf - SelectPdf Online REST API client library for Perl. Contains HTML to PDF converter, PDF merge, PDF to text extractor, search PDF.
 
=head1 SYNOPSIS
 
    use SelectPdf;
    print "This is SelectPdf-$SelectPdf::VERSION\n";

Convert HTML to PDF

    use SelectPdf;
    print "This is SelectPdf-$SelectPdf::VERSION\n";

    my $url = "https://selectpdf.com/";
    my $local_file = "Test.pdf";
    my $apiKey = "Your API key here";

    eval {
        my $client = new HtmlToPdfClient($apiKey);
        
        $client
            ->setPageSize("A4")
            ->setMargins(0)
            ->setShowPageNumbers('False')
            ->setPageBreaksEnhancedAlgorithm('True')
        ;

        $client->convertUrlToFile($url, $local_file);
    };

    if ($@) {
        print "An error occurred: $@\n";  
    }


Merge PDFs from local disk or public url and save result into a file on disk.

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

Extract text from PDF

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

Search PDF

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

=head1 DESCRIPTION
 
SelectPdf HTML To PDF Online REST API is a professional solution that lets you create PDF from web pages and raw HTML code in your applications. 
The API is easy to use and the integration takes only a few lines of code. The generated PDFs are perfect. 
That makes SelectPdf API the best html to pdf online service that can be used.

For more details and full list of parameters see L<Html To Pdf API|https://selectpdf.com/html-to-pdf-api/>.

=cut
1;
