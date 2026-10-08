local $| = 1;

use strict;
use SelectPdf;

print "This is SelectPdf-$SelectPdf::VERSION.\n";

my $url = "https://selectpdf.com/";
my $local_file = "Test.pdf";

# Async conversions are not supported on the demo endpoint -
# this sample requires a paid API key.
my $apiKey = "Your API key here";

eval {
    my $client = SelectPdf::HtmlToPdfClient->new($apiKey);

    # Tune polling for the async job (optional).
    # The client polls /api2/asyncjob/ every AsyncCallsPingInterval
    # seconds, up to AsyncCallsMaxPings times, then gives up.
    $client->{AsyncCallsPingInterval} = 3; # seconds between polls
    $client->{AsyncCallsMaxPings} = 1000;  # max polls before timeout

    $client
        ->setPageSize(SelectPdf::PageSize::A4)
        ->setPageOrientation(SelectPdf::PageOrientation::Portrait)
        ->setMargins(0)
        ->setPageBreaksEnhancedAlgorithm('True')
    ;

    print "Starting async conversion ...\n";

    # url to file (async)
    $client->convertUrlToFileAsync($url, $local_file);

    # url to memory (async)
    # my $pdf = $client->convertUrlAsync($url);

    # html string to file (async)
    # $client->convertHtmlStringToFileAsync("This is some <b>html</b>.", $local_file);

    # html string to memory (async)
    # my $pdf = $client->convertHtmlStringAsync("This is some <b>html</b>.");

    print "Finished! Number of pages: " . $client->getNumberOfPages() . ".\n";

    # response telemetry
    print "Mode: " . $client->getMode() . ", Execution: " . $client->getExecutionMode() . ".\n";
    print "Credits remaining: " . ($client->getCreditsRemaining() // "n/a") . " / " . ($client->getCreditsTotal() // "n/a") . ".\n";
};

if ($@) {
    print "An error occurred: $@\n";
}
