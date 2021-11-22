package SelectPdf::ApiClient;

use strict;

use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Status qw(:constants :is status_message);

use constant MULTIPART_FORM_DATA_BOUNDARY => "------------SelectPdf_Api_Boundry_\$";
use constant NEW_LINE => "\r\n";

our $VERSION = '1.4.0';

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

# Create a POST request.
#
# @returns Response content.
sub performPost {
    my($self) = @_;

    # reset results
    $self->{numberOfPages} = 0;
    $self->{jobId} = "";
    $self->{lastHTTPCode} = "";

    # print "\nParameters (to endpoint $self->{apiEndpoint}):\n";
    # foreach my $k (keys(%{ $self->{parameters} })) {
    #     print "$k => $self->{parameters}{$k}\n";
    # }
    # print "\n";

    # prepare request
    my $ua = LWP::UserAgent->new;
    $ua->timeout(6000); # 6,000 seconds = 100 min

    # set headers
    $self->{headers}{"Content-type"} = "application/x-www-form-urlencoded";
    $self->{headers}{"selectpdf-api-client"} = "perl-$]-$VERSION";

    foreach my $k (keys(%{ $self->{headers} })) {
        $ua->default_header($k => $self->{headers}{$k});
    }

    # call the API
    my $response = $ua->request(POST $self->{apiEndpoint}, $self->{parameters});

    # get response
    my $code = $response->code;
    $self->{lastHTTPCode} = $code;
    # print ("HTTP Code: $self->{lastHTTPCode}.\n");

    if ($response->code == HTTP_OK) {
        $self->{numberOfPages} = int($response->header("selectpdf-api-pages")); 
        $self->{jobId} = $response->header("selectpdf-api-jobid"); 

        return $response->decoded_content;
    }
    elsif ($response->code == HTTP_ACCEPTED) {
        $self->{jobId} = $response->header("selectpdf-api-jobid"); 
        return undef;
    }
    else {
        my $message = $response->message;
        if ($response->decoded_content) {
            $message = $response->decoded_content;
        }

        die "($code) $message";
    }

}

# Create a POST request.
#
# @returns Response content.
sub performPostAsMultipartFormData {
    my($self) = @_;

    # reset results
    $self->{numberOfPages} = 0;
    $self->{jobId} = "";
    $self->{lastHTTPCode} = "";

    # print "\nParameters (to endpoint $self->{apiEndpoint}):\n";
    # foreach $k (keys(%{ $self->{parameters} })) {
    #     print "$k => $self->{parameters}{$k}\n";
    # }
    # print "\n";

    # prepare request
    my $ua = LWP::UserAgent->new;
    $ua->timeout(6000); # 6,000 seconds = 100 min

    # set headers
    $self->{headers}{"selectpdf-api-client"} = "perl-$]-$VERSION";

    foreach my $k (keys(%{ $self->{headers} })) {
        $ua->default_header($k => $self->{headers}{$k});
    }

    # merge parameters and files
    my $alldata = $self->{parameters};
    foreach my $k (keys(%{ $self->{files} })) {
        $alldata->{$k} = [$self->{files}{$k}];
    }

    # print "\nAll data (to endpoint $self->{apiEndpoint}):\n";
    # foreach my $k (keys %{$alldata}) {
    #     print "$k => $alldata->{$k}\n";
    # }
    # print "\n";

    # call the API
    my $response = $ua->request(POST $self->{apiEndpoint}, Content_Type => 'form-data', Content => $alldata);

    # get response
    my $code = $response->code;
    $self->{lastHTTPCode} = $code;
    # print ("HTTP Code: $self->{lastHTTPCode}.\n");

    if ($response->code == HTTP_OK) {
        $self->{numberOfPages} = int($response->header("selectpdf-api-pages")); 
        $self->{jobId} = $response->header("selectpdf-api-jobid"); 

        return $response->decoded_content;
    }
    elsif ($response->code == HTTP_ACCEPTED) {
        $self->{jobId} = $response->header("selectpdf-api-jobid"); 
        return undef;
    }
    else {
        my $message = $response->message;
        if ($response->decoded_content) {
            $message = $response->decoded_content;
        }

        die "($code) $message";
    }

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