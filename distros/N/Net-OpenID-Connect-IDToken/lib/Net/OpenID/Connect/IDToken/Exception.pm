package Net::OpenID::Connect::IDToken::Exception;
use strict;
use warnings;

use overload (
    q|""| => \&to_string,
);

use Carp qw//;


sub throw {
    my ($class, %args) = @_;
    Carp::croak bless \%args, $class;
}

sub code    { $_[0]->{code} }
sub message { $_[0]->{message} }

sub to_string {
    sprintf("<%s>: %s", $_[0]->code, $_[0]->message);
}

1;
