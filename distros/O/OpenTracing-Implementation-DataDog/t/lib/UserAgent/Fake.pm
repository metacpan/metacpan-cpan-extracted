package UserAgent::Fake;

use HTTP::Response::Maker HTTPResponse => ( prefix => 'HTTP_Response_' );

sub new{ my @requests; bless \@requests }

sub request {
    my $self = shift;
    push @$self, @_;
    return HTTP_Response_OK
}

sub get_all_requests {
    my $self = shift;
    return @$self
}

1;
