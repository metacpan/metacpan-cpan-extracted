package Server::Control::Test::PoliteApache;
use Moose;
extends 'Server::Control::Apache';
around 'status_as_string' => sub {
    my $orig = shift;
    my $self = shift;
    return $self->$orig(@_) . ", sir";
};

__PACKAGE__->meta->make_immutable();

1;
