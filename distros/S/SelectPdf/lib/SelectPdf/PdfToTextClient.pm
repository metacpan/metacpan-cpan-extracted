package SelectPdf::PdfToTextClient;

use JSON;
use SelectPdf::ApiClient;
use SelectPdf::AsyncJobClient;
use strict;
our @ISA = qw(SelectPdf::ApiClient);

=head1 NAME

SelectPdf::PdfToTextClient - Pdf To Text Conversion with SelectPdf Online API. Extract text from PDF. Search PDF.

=head1 SYNOPSIS

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

For more details and full list of parameters see L<Pdf To Text API|https://selectpdf.com/pdf-to-text-api/>.

=head1 METHODS

=head2 new( $apiKey )

Construct the Pdf To Text Client.

    my $client = SelectPdf::PdfToTextClient->new($apiKey);

Parameters:

- $apiKey: API Key.
=cut
sub new {
    my $type = shift;
    my $self = $type->SUPER::new;

    # API endpoint
    $self->{apiEndpoint} = "https://selectpdf.com/api2/pdftotext/";

    $self->{fileIdx} = 0;

    $self->{parameters}{"key"} = shift;

    bless $self, $type;
    return $self;
}

=head2 getTextFromFile( $inputPdf )

Get the text from the specified pdf.

    my $client = new SelectPdf::PdfToTextClient($apiKey);
    $text = $client->getTextFromFile($inputPdf);

Parameters:

- $inputPdf: Path to a local PDF file.

Returns:

- Extracted text.
=cut
sub getTextFromFile($) {
    my($self, $inputPdf) = @_;

    $self->{parameters}{"async"} = "False";
    $self->{parameters}{"action"} = "Convert";
    $self->{parameters}{"url"} = "";

    $self->{files} = {};
    $self->{files}{"inputPdf"} = $inputPdf;

    my $text = $self->SUPER::performPostAsMultipartFormData();
    $text =~ s/\r//g;

    return $text;
}

=head2 getTextFromFileToFile( $inputPdf, $outputFilePath )

Get the text from the specified pdf and write it to the specified text file.

    my $client = new SelectPdf::PdfToTextClient($apiKey);
    $client->getTextFromFileToFile($inputPdf, $outputFilePath);

Parameters:

- $inputPdf: Path to a local PDF file.

- $outputFilePath: The output file where the resulted text will be written.

=cut
sub getTextFromFileToFile($,$) {
    my($self, $inputPdf, $outputFilePath) = @_;

    my $result = $self->getTextFromFile($inputPdf);

    my $file = IO::File->new( $outputFilePath, '>:encoding(UTF-8)' ) or die "Unable to open output file - $!\n";
    $file->print( $result );
    $file->close;
}

=head2 getTextFromFileAsync( $inputPdf )

Get the text from the specified pdf with an asynchronous call.

    my $client = new SelectPdf::PdfToTextClient($apiKey);
    $text = $client->getTextFromFileAsync($inputPdf);

Parameters:

- $inputPdf: Path to a local PDF file.

Returns:

- Extracted text.
=cut
sub getTextFromFileAsync($) {
    my($self, $inputPdf) = @_;

    $self->{parameters}{"action"} = "Convert";
    $self->{parameters}{"url"} = "";

    $self->{files} = {};
    $self->{files}{"inputPdf"} = $inputPdf;

    my $JobID = $self->SUPER::startAsyncJobMultipartFormData() or die "An error occurred launching the asynchronous call.";

    my $noPings = 0;

    do
    {
        $noPings++;

        # sleep for a few seconds before next ping
        sleep($self->{AsyncCallsPingInterval});

        my $asyncJobClient = new SelectPdf::AsyncJobClient($self->{parameters}{"key"}, $JobID);
        $asyncJobClient->setApiEndpoint($self->{apiAsyncEndpoint});

        my $text = $asyncJobClient->getResult();

        if ($asyncJobClient->finished)
        {
            $self->{numberOfPages} = $asyncJobClient->getNumberOfPages();

            $text =~ s/\r//g;
            return $text;
        }

    } while ($noPings <= $self->{AsyncCallsMaxPings});

    die "Asynchronous call did not finish in expected timeframe.";
}

=head2 getTextFromFileToFileAsync( $inputPdf, $outputFilePath )

Get the text from the specified pdf with an asynchronous call and write it to the specified text file.

    my $client = new SelectPdf::PdfToTextClient($apiKey);
    $client->getTextFromFileToFileAsync($inputPdf, $outputFilePath);

Parameters:

- $inputPdf: Path to a local PDF file.

- $outputFilePath: The output file where the resulted text will be written.

=cut
sub getTextFromFileToFileAsync($,$) {
    my($self, $inputPdf, $outputFilePath) = @_;

    my $result = $self->getTextFromFileAsync($inputPdf);

    my $file = IO::File->new( $outputFilePath, '>:encoding(UTF-8)' ) or die "Unable to open output file - $!\n";
    $file->print( $result );
    $file->close;
}


=head2 getTextFromUrl( $url )

Get the text from the specified pdf.

    my $client = new SelectPdf::PdfToTextClient($apiKey);
    $text = $client->getTextFromUrl($url);

Parameters:

- $url: Address of the PDF file.

Returns:

- Extracted text.
=cut
sub getTextFromUrl($) {
    my($self, $url) = @_;

    $self->{parameters}{"async"} = "False";
    $self->{parameters}{"action"} = "Convert";
    $self->{parameters}{"url"} = $url;

    $self->{files} = {};

    my $text = $self->SUPER::performPostAsMultipartFormData();
    $text =~ s/\r//g;

    return $text;
}

=head2 getTextFromUrlToFile( $url, $outputFilePath )

Get the text from the specified pdf and write it to the specified text file.

    my $client = new SelectPdf::PdfToTextClient($apiKey);
    $client->getTextFromUrlToFile($url, $outputFilePath);

Parameters:

- $url: Address of the PDF file.

- $outputFilePath: The output file where the resulted text will be written.

=cut
sub getTextFromUrlToFile($,$) {
    my($self, $url, $outputFilePath) = @_;

    my $result = $self->getTextFromUrl($url);

    my $file = IO::File->new( $outputFilePath, '>:encoding(UTF-8)' ) or die "Unable to open output file - $!\n";
    $file->print( $result );
    $file->close;
}

=head2 getTextFromUrlAsync( $url )

Get the text from the specified pdf with an asynchronous call.

    my $client = new SelectPdf::PdfToTextClient($apiKey);
    $text = $client->getTextFromUrlAsync($url);

Parameters:

- $url: Address of the PDF file.

Returns:

- Extracted text.
=cut
sub getTextFromUrlAsync($) {
    my($self, $url) = @_;

    $self->{parameters}{"action"} = "Convert";
    $self->{parameters}{"url"} = $url;

    $self->{files} = {};

    my $JobID = $self->SUPER::startAsyncJobMultipartFormData() or die "An error occurred launching the asynchronous call.";

    my $noPings = 0;

    do
    {
        $noPings++;

        # sleep for a few seconds before next ping
        sleep($self->{AsyncCallsPingInterval});

        my $asyncJobClient = new SelectPdf::AsyncJobClient($self->{parameters}{"key"}, $JobID);
        $asyncJobClient->setApiEndpoint($self->{apiAsyncEndpoint});

        my $text = $asyncJobClient->getResult();

        if ($asyncJobClient->finished)
        {
            $self->{numberOfPages} = $asyncJobClient->getNumberOfPages();

            $text =~ s/\r//g;
            return $text;
        }

    } while ($noPings <= $self->{AsyncCallsMaxPings});

    die "Asynchronous call did not finish in expected timeframe.";
}

=head2 getTextFromUrlToFileAsync( $url, $outputFilePath )

Get the text from the specified pdf with an asynchronous call and write it to the specified text file.

    my $client = new SelectPdf::PdfToTextClient($apiKey);
    $client->getTextFromUrlToFileAsync($url, $outputFilePath);

Parameters:

- $url: Address of the PDF file.

- $outputFilePath: The output file where the resulted text will be written.

=cut
sub getTextFromUrlToFileAsync($,$) {
    my($self, $url, $outputFilePath) = @_;

    my $result = $self->getTextFromUrlAsync($url);

    my $file = IO::File->new( $outputFilePath, '>:encoding(UTF-8)' ) or die "Unable to open output file - $!\n";
    $file->print( $result );
    $file->close;
}


=head2 searchFile( $inputPdf, $textToSearch, $caseSensitive, $wholeWordsOnly )

Search for a specific text in a PDF document.
Pages that participate to this operation are specified by setStartPage() and setEndPage() methods.

    my $client = new SelectPdf::PdfToTextClient($apiKey);
    $results = $client->searchFile($inputPdf, $textToSearch);

Parameters:

- $inputPdf: Path to a local PDF file.

- $textToSearch: Text to search.

- $caseSensitive: If the search is case sensitive or not.

- $wholeWordsOnly: If the search works on whole words or not.

Returns:

- List with text positions in the current PDF document.
=cut
sub searchFile($,$,$,$) {
    my($self, $inputPdf, $textToSearch, $caseSensitive, $wholeWordsOnly) = @_;

    if (!$textToSearch) {
        die ("Search text cannot be empty.");
    }

    $self->{parameters}{"async"} = "False";
    $self->{parameters}{"action"} = "Search";
    $self->{parameters}{"url"} = "";
    $self->{parameters}{"search_text"} = $textToSearch;
    $self->{parameters}{"case_sensitive"} = $self->SUPER::serializeBoolean($caseSensitive);
    $self->{parameters}{"whole_words_only"} = $self->SUPER::serializeBoolean($wholeWordsOnly);

    $self->{files} = {};
    $self->{files}{"inputPdf"} = $inputPdf;

    $self->{headers}{"Accept"} = "text/json";

    my $result = $self->SUPER::performPostAsMultipartFormData();

    if ($result) {
        return decode_json($result);
    }
    else {
        return [];
    }
}

=head2 searchFileAsync( $inputPdf, $textToSearch, $caseSensitive, $wholeWordsOnly )

Search for a specific text in a PDF document with an asynchronous call.
Pages that participate to this operation are specified by setStartPage() and setEndPage() methods.

    my $client = new SelectPdf::PdfToTextClient($apiKey);
    $results = $client->searchFileAsync($inputPdf, $textToSearch);

Parameters:

- $inputPdf: Path to a local PDF file.

- $textToSearch: Text to search.

- $caseSensitive: If the search is case sensitive or not.

- $wholeWordsOnly: If the search works on whole words or not.

Returns:

- List with text positions in the current PDF document.
=cut
sub searchFileAsync($,$,$,$) {
    my($self, $inputPdf, $textToSearch, $caseSensitive, $wholeWordsOnly) = @_;

    if (!$textToSearch) {
        die ("Search text cannot be empty.");
    }

    $self->{parameters}{"action"} = "Search";
    $self->{parameters}{"url"} = "";
    $self->{parameters}{"search_text"} = $textToSearch;
    $self->{parameters}{"case_sensitive"} = $self->SUPER::serializeBoolean($caseSensitive);
    $self->{parameters}{"whole_words_only"} = $self->SUPER::serializeBoolean($wholeWordsOnly);

    $self->{files} = {};
    $self->{files}{"inputPdf"} = $inputPdf;

    $self->{headers}{"Accept"} = "text/json";

    my $JobID = $self->SUPER::startAsyncJobMultipartFormData() or die "An error occurred launching the asynchronous call.";

    my $noPings = 0;

    do
    {
        $noPings++;

        # sleep for a few seconds before next ping
        sleep($self->{AsyncCallsPingInterval});

        my $asyncJobClient = new SelectPdf::AsyncJobClient($self->{parameters}{"key"}, $JobID);
        $asyncJobClient->setApiEndpoint($self->{apiAsyncEndpoint});

        my $result = $asyncJobClient->getResult();

        if ($asyncJobClient->finished)
        {
            $self->{numberOfPages} = $asyncJobClient->getNumberOfPages();

            if ($result) {
                return decode_json($result);
            }
            else {
                return [];
            } 
        }

    } while ($noPings <= $self->{AsyncCallsMaxPings});

    die "Asynchronous call did not finish in expected timeframe.";

}

=head2 searchUrl( $url, $textToSearch, $caseSensitive, $wholeWordsOnly )

Search for a specific text in a PDF document.
Pages that participate to this operation are specified by setStartPage() and setEndPage() methods.

    my $client = new SelectPdf::PdfToTextClient($apiKey);
    $results = $client->searchUrl($url, $textToSearch);

Parameters:

- $url: Address of the PDF file.

- $textToSearch: Text to search.

- $caseSensitive: If the search is case sensitive or not.

- $wholeWordsOnly: If the search works on whole words or not.

Returns:

- List with text positions in the current PDF document.
=cut
sub searchUrl($,$,$,$) {
    my($self, $url, $textToSearch, $caseSensitive, $wholeWordsOnly) = @_;

    if (!$textToSearch) {
        die ("Search text cannot be empty.");
    }

    $self->{parameters}{"async"} = "False";
    $self->{parameters}{"action"} = "Search";
    $self->{parameters}{"search_text"} = $textToSearch;
    $self->{parameters}{"case_sensitive"} = $self->SUPER::serializeBoolean($caseSensitive);
    $self->{parameters}{"whole_words_only"} = $self->SUPER::serializeBoolean($wholeWordsOnly);

    $self->{files} = {};
    $self->{parameters}{"url"} = $url;

    $self->{headers}{"Accept"} = "text/json";

    my $result = $self->SUPER::performPostAsMultipartFormData();

    if ($result) {
        return decode_json($result);
    }
    else {
        return [];
    }
}

=head2 searchUrlAsync( $url, $textToSearch, $caseSensitive, $wholeWordsOnly )

Search for a specific text in a PDF document with an asynchronous call.
Pages that participate to this operation are specified by setStartPage() and setEndPage() methods.

    my $client = new SelectPdf::PdfToTextClient($apiKey);
    $results = $client->searchUrlAsync($url, $textToSearch);

Parameters:

- $url: Address of the PDF file.

- $textToSearch: Text to search.

- $caseSensitive: If the search is case sensitive or not.

- $wholeWordsOnly: If the search works on whole words or not.

Returns:

- List with text positions in the current PDF document.
=cut
sub searchUrlAsync($,$,$,$) {
    my($self, $url, $textToSearch, $caseSensitive, $wholeWordsOnly) = @_;

    if (!$textToSearch) {
        die ("Search text cannot be empty.");
    }

    $self->{parameters}{"action"} = "Search";
    $self->{parameters}{"search_text"} = $textToSearch;
    $self->{parameters}{"case_sensitive"} = $self->SUPER::serializeBoolean($caseSensitive);
    $self->{parameters}{"whole_words_only"} = $self->SUPER::serializeBoolean($wholeWordsOnly);

    $self->{files} = {};
    $self->{parameters}{"url"} = $url;

    $self->{headers}{"Accept"} = "text/json";

    my $JobID = $self->SUPER::startAsyncJobMultipartFormData() or die "An error occurred launching the asynchronous call.";

    my $noPings = 0;

    do
    {
        $noPings++;

        # sleep for a few seconds before next ping
        sleep($self->{AsyncCallsPingInterval});

        my $asyncJobClient = new SelectPdf::AsyncJobClient($self->{parameters}{"key"}, $JobID);
        $asyncJobClient->setApiEndpoint($self->{apiAsyncEndpoint});

        my $result = $asyncJobClient->getResult();

        if ($asyncJobClient->finished)
        {
            $self->{numberOfPages} = $asyncJobClient->getNumberOfPages();

            if ($result) {
                return decode_json($result);
            }
            else {
                return [];
            } 
        }

    } while ($noPings <= $self->{AsyncCallsMaxPings});

    die "Asynchronous call did not finish in expected timeframe.";

}


=head2 setCustomParameter( $parameterName, $parameterValue )

Set a custom parameter. Do not use this method unless advised by SelectPdf.

Parameters:

- $parameterName: Parameter name.

- $parameterValue: Parameter value.

Returns:

- Reference to the current object.
=cut
sub setCustomParameter($,$) {
    my($self, $parameterName, $parameterValue) = @_;

    $self->{parameters}{$parameterName} = $parameterValue;
    return $self;
}

=head2 setTimeout( $timeout )

Set the maximum amount of time (in seconds) for this job.
The default value is 30 seconds. 
Use a larger value (up to 120 seconds allowed) for pages that take a long time to load.

Parameters:

- $timeout:  Timeout in seconds.

Returns:

- Reference to the current object.
=cut
sub setTimeout($) {
    my($self, $timeout) = @_;

    $self->{parameters}{"timeout"} = $timeout;
    return $self;
}

=head2 setStartPage( $startPage )

Set Start Page number. Default value is 1 (first page of the document).

Parameters:

- $startPage: Start page number (1-based).

Returns:

- Reference to the current object.
=cut
sub setStartPage($) {
    my($self, $startPage) = @_;

    $self->{parameters}{"start_page"} = $startPage;
    return $self;
}

=head2 setEndPage( $endPage )

Set End Page number. Default value is 0 (process till the last page of the document).

Parameters:

- $endPage: End page number (1-based).

Returns:

- Reference to the current object.
=cut
sub setEndPage($) {
    my($self, $endPage) = @_;

    $self->{parameters}{"end_page"} = $endPage;
    return $self;
}

=head2 setUserPassword( $userPassword )

Set PDF user password.

Parameters:

- $userPassword: PDF user password.

Returns:

- Reference to the current object.
=cut
sub setUserPassword($) {
    my($self, $userPassword) = @_;

    $self->{parameters}{"user_password"} = $userPassword;
    return $self;
}


=head2 setTextLayout( $textLayout )

Set the text layout. The default value is 0 (Original).

Parameters:

- $textLayout: The text layout. Possible values: 0 (Original), 1 (Reading).

Returns:

- Reference to the current object.
=cut
sub setTextLayout($) {
    my($self, $textLayout) = @_;

    if ($textLayout ne 0 and $textLayout ne 1) {
        die ("Allowed values for Text Layout: 0 (Original), 1 (Reading).");
    }

    $self->{parameters}{"text_layout"} = $textLayout;
    return $self;
}

=head2 setOutputFormat( $outputFormat )

Set the output format. The default value is 0 (Text).

Parameters:

- $outputFormat: The output format. Possible values: 0 (Text), 1 (Html).

Returns:

- Reference to the current object.
=cut
sub setOutputFormat($) {
    my($self, $outputFormat) = @_;

    if ($outputFormat ne 0 and $outputFormat ne 1) {
        die ("Allowed values for Output Format: 0 (Text), 1 (Html).");
    }

    $self->{parameters}{"output_format"} = $outputFormat;
    return $self;
}


1;