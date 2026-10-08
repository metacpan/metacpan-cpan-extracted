package SelectPdf::ApiClient;

use strict;

use Encode ();
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Status qw(:constants :is status_message);
use SelectPdf::DemoExceptions;

use constant MULTIPART_FORM_DATA_BOUNDARY => "------------SelectPdf_Api_Boundry_\$";
use constant NEW_LINE => "\r\n";

our $VERSION = '1.6.0';

=head1 NAME

SelectPdf::ApiClient - Base class for API clients. Do not use this directly.

=head1 METHODS

=head2 new

ApiClient Constructor. Do not use this directly.
=cut
sub new {
    my $type = shift;
    my $self = {};

    # API endpoint
    $self->{apiEndpoint} = "https://selectpdf.com/api2/convert/";

    # API async jobs endpoint
    $self->{apiAsyncEndpoint} = "https://selectpdf.com/api2/asyncjob/";

    # API web elements endpoint
    $self->{apiWebElementsEndpoint} = "https://selectpdf.com/api2/webelements/";

    # Parameters that will be sent to the API.
    $self->{parameters} = {};

    # HTTP Headers that will be sent to the API.
    $self->{headers} = {};

    # Files that will be sent to the API.
    $self->{files} = {};

    # Binary data that will be sent to the API.
    $self->{binaryData} = {};

    # Number of pages of the pdf document resulted from the conversion.
    $self->{numberOfPages} = 0;

    # Job ID for asynchronous calls or for calls that require a second request.
    $self->{jobId} = "";

    # Last HTTP Code
    $self->{lastHTTPCode} = "";

    # Subscription monthly conversion limit, parsed from X-SelectPdf-Credits-Total.
    # -1 indicates unlimited (Dedicated tier). Undef when the header is absent.
    $self->{creditsTotal} = undef;

    # Conversions remaining in the current month, parsed from X-SelectPdf-Credits-Remaining.
    # -1 for unlimited subscriptions. Undef when the header is absent.
    $self->{creditsRemaining} = undef;

    # Endpoint mode of the most recent response, parsed from X-SelectPdf-Mode ("production" or "demo").
    $self->{mode} = "";

    # Server-side execution path of the most recent response, parsed from X-SelectPdf-Execution.
    $self->{executionMode} = "";

    # Ping interval in seconds for asynchronous calls. Default value is 3 seconds.
    $self->{AsyncCallsPingInterval} = 3;

    # Maximum number of pings for asynchronous calls. Default value is 1,000 pings.
    $self->{AsyncCallsMaxPings} = 1000;

    bless $self, $type;
    return $self;
}

=head2 setApiEndpoint( $apiEndpoint )

Set a custom SelectPdf API endpoint. Do not use this method unless advised by SelectPdf.

    $client->setApiEndpoint($apiEndpoint);

Parameters:

- $apiEndpoint API endpoint.
=cut
sub setApiEndpoint {
    my($self, $apiEndpoint) = @_;
    $self->{apiEndpoint} = $apiEndpoint if defined($apiEndpoint);
    return $self->{apiEndpoint};
}

=head2 setApiAsyncEndpoint( $apiAsyncEndpoint )

Set a custom SelectPdf API endpoint for async jobs. Do not use this method unless advised by SelectPdf.

    $client->setApiAsyncEndpoint($apiAsyncEndpoint);

Parameters:

- $apiAsyncEndpoint API async jobs endpoint.
=cut
sub setApiAsyncEndpoint {
    my($self, $apiAsyncEndpoint) = @_;
    $self->{apiAsyncEndpoint} = $apiAsyncEndpoint if defined($apiAsyncEndpoint);
    return $self->{apiAsyncEndpoint};
}

=head2 setApiWebElementsEndpoint( $apiWebElementsEndpoint )

Set a custom SelectPdf API endpoint for web elements. Do not use this method unless advised by SelectPdf.

    $client->setApiWebElementsEndpoint($apiWebElementsEndpoint);

Parameters:

- $apiWebElementsEndpoint API web elements endpoint.
=cut
sub setApiWebElementsEndpoint {
    my($self, $apiWebElementsEndpoint) = @_;
    $self->{apiWebElementsEndpoint} = $apiWebElementsEndpoint if defined($apiWebElementsEndpoint);
    return $self->{apiWebElementsEndpoint};
}

# Reset the results of the previous call.
sub resetResults {
    my($self) = @_;

    $self->{numberOfPages} = 0;
    $self->{jobId} = "";
    $self->{lastHTTPCode} = "";
    $self->{creditsTotal} = undef;
    $self->{creditsRemaining} = undef;
    $self->{mode} = "";
    $self->{executionMode} = "";
}

# Create the user agent used for API calls and set the request headers.
sub createUserAgent {
    my($self) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(6000); # 6,000 seconds = 100 min

    $self->{headers}{"selectpdf-api-client"} = "perl-$]-$VERSION";

    foreach my $k (keys(%{ $self->{headers} })) {
        $ua->default_header($k => $self->{headers}{$k});
    }

    return $ua;
}

# Send the request to the API.
#
# Responses can carry long headers (for example the web elements locations, when
# pdf_web_elements_selectors is set), so the default Net::HTTP limits (8 KB per header
# line, 128 header lines) are lifted for SelectPdf API calls only.
sub sendRequest {
    my($self, $ua, $request) = @_;

    require LWP::Protocol::http;
    local @LWP::Protocol::http::EXTRA_SOCK_OPTS = (@LWP::Protocol::http::EXTRA_SOCK_OPTS, MaxLineLength => 0, MaxHeaderLines => 0);

    return $ua->request($request);
}

# Read the standard X-SelectPdf-* response headers.
sub readStandardResponseHeaders {
    my($self, $response) = @_;

    my $pages = $response->header("X-SelectPdf-Pages");
    if (defined($pages) and $pages =~ m/^\s*-?\d+\s*$/) {
        $self->{numberOfPages} = int($pages);
    }

    my $jobId = $response->header("X-SelectPdf-Job-Id");
    if (defined($jobId) and $jobId ne "") {
        $self->{jobId} = $jobId;
    }

    my $total = $response->header("X-SelectPdf-Credits-Total");
    if (defined($total) and $total =~ m/^\s*-?\d+\s*$/) {
        $self->{creditsTotal} = int($total);
    }

    my $remaining = $response->header("X-SelectPdf-Credits-Remaining");
    if (defined($remaining) and $remaining =~ m/^\s*-?\d+\s*$/) {
        $self->{creditsRemaining} = int($remaining);
    }

    my $mode = $response->header("X-SelectPdf-Mode");
    if (defined($mode) and $mode ne "") {
        $self->{mode} = $mode;
    }

    my $executionMode = $response->header("X-SelectPdf-Execution");
    if (defined($executionMode) and $executionMode ne "") {
        $self->{executionMode} = $executionMode;
    }
}

# Hook called after a successful response (200 or 202), with the HTTP::Response object.
# Subclasses can override it to capture endpoint-specific headers. Default implementation does nothing.
sub onResponseHeadersReceived {
    my($self, $response) = @_;
}

# Process the API response.
#
# @returns Response content.
sub processResponse {
    my($self, $response) = @_;

    my $code = $response->code;
    $self->{lastHTTPCode} = $code;

    if ($code == HTTP_OK) {
        $self->readStandardResponseHeaders($response);
        eval { $self->onResponseHeadersReceived($response); };

        return $response->decoded_content;
    }
    elsif ($code == HTTP_ACCEPTED) {
        # request accepted (for asynchronous jobs)
        $self->readStandardResponseHeaders($response);
        eval { $self->onResponseHeadersReceived($response); };

        return undef;
    }
    else {
        my $message = $response->message;
        my $content = $response->decoded_content;
        if ($content) {
            $message = $content;
        }

        # The demo endpoint returns JSON error bodies for 400 / 413 / 429 / 503.
        # Parse those into typed exceptions so callers can react programmatically.
        my $contentType = $response->header("Content-Type");
        if (defined($contentType) and $contentType =~ m/application\/json/i) {
            my $demoException = SelectPdf::DemoException->fromResponse($code, $content, $response->header("Retry-After"));
            die $demoException if defined($demoException);
        }

        die "($code) $message";
    }
}

# Create a POST request.
#
# @returns Response content.
sub performPost {
    my($self) = @_;

    # reset results
    $self->resetResults();

    # set headers
    $self->{headers}{"Content-type"} = "application/x-www-form-urlencoded";

    # prepare request
    my $ua = $self->createUserAgent();

    # call the API
    my $response = $self->sendRequest($ua, POST($self->{apiEndpoint}, $self->{parameters}));

    return $self->processResponse($response);
}

# Create a POST request.
#
# @returns Response content.
sub performPostAsMultipartFormData {
    my($self) = @_;

    # reset results
    $self->resetResults();

    # prepare request
    my $ua = $self->createUserAgent();

    # merge parameters, files and binary data
    my $alldata = {};
    foreach my $k (keys(%{ $self->{parameters} })) {
        my $v = $self->{parameters}{$k};
        $v = Encode::encode('UTF-8', $v) if (defined($v) and utf8::is_utf8($v));
        $alldata->{$k} = $v;
    }
    foreach my $k (keys(%{ $self->{files} })) {
        $alldata->{$k} = [$self->{files}{$k}];
    }
    foreach my $k (keys(%{ $self->{binaryData} })) {
        $alldata->{$k} = [undef, $k, Content_Type => 'application/octet-stream', Content => $self->{binaryData}{$k}];
    }

    # call the API
    my $response = $self->sendRequest($ua, POST($self->{apiEndpoint}, Content_Type => 'form-data', Content => $alldata));

    return $self->processResponse($response);
}

# Start an asynchronous job.
#
# @returns Asynchronous job ID.
sub startAsyncJob {
    my($self) = @_;

    $self->{parameters}{"async"} = "True";
    $self->performPost();

    return $self->{jobId};
}

# Start an asynchronous job that requires multipart form data.
#
# @returns Asynchronous job ID.
sub startAsyncJobMultipartFormData {
    my($self) = @_;

    $self->{parameters}{"async"} = "True";
    $self->performPostAsMultipartFormData();

    return $self->{jobId};
}

=head2 getNumberOfPages

Get the number of pages of the PDF document resulted from the API call.

    $pages = $client->getNumberOfPages();

Returns:

- Number of pages of the PDF document.
=cut
sub getNumberOfPages {
    my($self) = @_;
    return $self->{numberOfPages};
}

=head2 getCreditsTotal

Get the subscription monthly conversion limit reported by the server (X-SelectPdf-Credits-Total response header).

    $total = $client->getCreditsTotal();

Returns:

- Monthly conversion limit. -1 means unlimited (Dedicated tier). Undef when the most recent response did not include credit information (e.g. demo endpoint, error response).
=cut
sub getCreditsTotal {
    my($self) = @_;
    return $self->{creditsTotal};
}

=head2 getCreditsRemaining

Get the number of conversions remaining in the current month, as reported by the server (X-SelectPdf-Credits-Remaining response header).

    $remaining = $client->getCreditsRemaining();

Returns:

- Conversions remaining this month. -1 means unlimited (Dedicated tier). Undef when the most recent response did not include credit information.
=cut
sub getCreditsRemaining {
    my($self) = @_;
    return $self->{creditsRemaining};
}

=head2 getMode

Get the endpoint mode of the most recent response (X-SelectPdf-Mode response header).

    $mode = $client->getMode();

Returns:

- "production" or "demo". Empty string when the response did not include the header.
=cut
sub getMode {
    my($self) = @_;
    return $self->{mode};
}

=head2 getExecutionMode

Get the server-side execution path of the most recent conversion (X-SelectPdf-Execution response header).

    $executionMode = $client->getExecutionMode();

Returns:

- "in-process" or "worker". Empty string for endpoints that do not perform a conversion (e.g. usage, web elements) or when the header is absent.
=cut
sub getExecutionMode {
    my($self) = @_;
    return $self->{executionMode};
}

# Serialize boolean values as "True" or "False" for the API.
#
# @returns Serialized value.
sub serializeBoolean {
    my($self, $value) = @_;

    if (not defined($value) or $value eq 'undef') {
        $value = 0;
    }
    else {
        $value =~ s/^\s+|\s+$//g;
        $value = lc $value;

        if ($value eq 'false' or $value eq 'no' or $value eq '0' or $value eq 'off') {
            $value = 0;
        }
    }
    return $value ? 'True' : 'False';
}

1;
