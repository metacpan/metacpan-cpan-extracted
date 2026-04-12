package SimpleMock::Mocks::LWP::UserAgent;
use strict;
use warnings;

our $VERSION = '0.01';

# adds a handler to LWP::UserAgent to mock HTTP requests

require LWP::UserAgent;
    
no warnings 'redefine';
my $orig = \&LWP::UserAgent::new;

*LWP::UserAgent::new = sub {
    my ($class, @args) = @_;
    my $ua = $orig->($class, @args);

    # This remains in the model to avoid circular deps
    require SimpleMock::Model::LWP_UA;
    $ua->add_handler(request_send => \&SimpleMock::Model::LWP_UA::mock_send_request);

    return $ua;
};

1;

=head1 NAME

SimpleMock::Mocks::LWP::UserAgent - Mock LWP::UserAgent for testing

=head1 DESCRIPTION

This module overrides the constructor of LWP::UserAgent to add a custom request handler that allows for mocking HTTP requests in tests.

=cut
