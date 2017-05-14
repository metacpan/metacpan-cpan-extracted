package Example::HelloWorldImpl;
use Moose;
use MooseX::FollowPBP;

use namespace::autoclean;

sub sayHello {
    my ($self, $body, $header) = @_;
    my $name = $body->get_name();
    my $givenName = $body->get_givenName();

    return Example::Elements::sayHelloResponse->new({
	sayHelloResult => "Hello $givenName $name",
    });
}

__PACKAGE__->meta()->make_immutable();

