package Test::Net::Async::Webservice::UPS::TestCache;
use Moo;
use Types::Standard qw(HashRef);

has data => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

sub get {
    my ($self,$key) = @_;
    return $self->data->{$key};
}

sub set {
    my ($self,$key,$value) = @_;
    $self->data->{$key} = $value;
    return;
}

1;
