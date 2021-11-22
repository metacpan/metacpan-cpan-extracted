package SelectPdf::WebElementsClient;

use JSON;
use SelectPdf::ApiClient;
use strict;
our @ISA = qw(SelectPdf::ApiClient);

=head1 NAME

SelectPdf::WebElementsClient - Get the locations of certain web elements. 
This is retrieved if pdf_web_elements_selectors parameter was set during the initial conversion call and elements were found to match the selectors.

=head1 METHODS

=head2 new( $apiKey, $jobId )

Construct the web elements client.

    my $client = SelectPdf::WebElementsClient->new($apiKey, $jobId);

Parameters:

- $apiKey API Key.
- $jobId Job ID.
=cut
sub new {
    my $type = shift;
    my $self = $type->SUPER::new;

    # API endpoint
    $self->{apiEndpoint} = "https://selectpdf.com/api2/webelements/";

    $self->{parameters}{"key"} = shift;
    $self->{parameters}{"job_id"} = shift;

    bless $self, $type;
    return $self;
}

=head2 getWebElements

Get the locations of certain web elements. This is retrieved if pdf_web_elements_selectors parameter is set and elements were found to match the selectors.

    my $client = SelectPdf::WebElementsClient->new($apiKey, $jobId);
    $elements = $client->getWebElements();

Returns:

- List of web elements locations.
=cut
sub getWebElements {
    my($self) = @_;

    $self->{headers}{"Accept"} = "text/json";

    my $result = $self->SUPER::performPost();

    if ($result) {
        return decode_json($result);
    }
    else {
        return [];
    }
}

1;