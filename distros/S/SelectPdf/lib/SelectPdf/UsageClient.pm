package SelectPdf::UsageClient;

use JSON;
use SelectPdf::ApiClient;
use strict;
our @ISA = qw(SelectPdf::ApiClient);

=head1 NAME

SelectPdf::UsageClient - Get usage details for SelectPdf Online API.

=head1 METHODS

=head2 new( $apiKey )

Construct the Usage client.

    my $client = SelectPdf::UsageClient->new($apiKey);

Parameters:

- $apiKey API Key.
=cut
sub new {
    my $type = shift;
    my $self = $type->SUPER::new;

    # API endpoint
    $self->{apiEndpoint} = "https://selectpdf.com/api2/usage/";

    $self->{parameters}{"key"} = shift;

    bless $self, $type;
    return $self;
}

=head2 getUsage( $getHistory )

Get API usage information with history, if specified.

    my $client = SelectPdf::UsageClient->new($apiKey);
    $usageInfo = $client->getUsage($getHistory);
    print("Conversions remained this month: ". $usageInfo->{"available"});

Parameters:

- $getHistory Get history or not.

Returns:

- Usage information.
=cut
sub getUsage($) {
    my($self, $getHistory) = @_;

    $self->{headers}{"Accept"} = "text/json";

    if ($getHistory) {
        $self->{parameters}{"get_history"} = "True";
    }

    my $result = $self->SUPER::performPost();

    if ($result) {
        return decode_json($result);
    }
    else {
        return {};
    }
}

1;