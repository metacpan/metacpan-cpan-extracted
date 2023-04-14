package UserAgent::Fake;

use HTTP::Response::Maker HTTPResponse => ( prefix => 'HTTP_Response_' );

my $HTTP_STATUS = HTTP_Response_OK;

sub new{ my @requests; bless \@requests }

sub request {
    my $self = shift;
    push @$self, @_;
    return $HTTP_STATUS;
}

sub get_all_requests {
    my $self = shift;
    return @$self
}

sub break_connection {
    my $self = shift;
    $HTTP_STATUS = HTTP_Response_SERVICE_UNAVAILABLE;
}

1;
