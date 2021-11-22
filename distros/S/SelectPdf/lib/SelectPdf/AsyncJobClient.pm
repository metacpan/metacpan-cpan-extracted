package SelectPdf::AsyncJobClient;

use SelectPdf::ApiClient;
use strict;
our @ISA = qw(SelectPdf::ApiClient);

=head1 NAME

SelectPdf::AsyncJobClient - Get the result of an asynchronous call.

=head1 METHODS

=head2 new( $apiKey, $JobId )

Construct the async job client.

    my $client = SelectPdf::AsyncJobClient->new($apiKey, $jobId);

Parameters:

- $apiKey API Key.

- $jobId Job ID.
=cut
sub new {
    my $type = shift;
    my $self = $type->SUPER::new;

    # API endpoint
    $self->{apiEndpoint} = "https://selectpdf.com/api2/asyncjob/";

    $self->{parameters}{"key"} = shift;
    $self->{parameters}{"job_id"} = shift;

    bless $self, $type;
    return $self;
}

=head2 getResult

Get result of the asynchronous job.

Returns:

- Byte array containing the resulted file if the job is finished. Returns 'undef' if the job is still running.
=cut
sub getResult() {
    my($self) = @_;

    my $result = $self->SUPER::performPost();

    if ($self->{jobId}) {
        return undef;
    }
    else {
        return $result;
    }
}

=head2 finished

Check if asynchronous job is finished.

Returns:

- True if job finished.
=cut
sub finished() {
    my($self) = @_;

    if ($self->{lastHTTPCode} eq 200) {
        return 1;
    }
    else {
        return 0;
    }
}

1;