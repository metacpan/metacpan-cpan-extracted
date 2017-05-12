package SampleDAIAApp;
use parent 'Plack::App::DAIA';

sub init {
    my $self = shift;
    $self->idformat( qr{^foo:.+} ) unless $self->idformat;
}

sub retrieve {
    my ($self, $id, %idparts) = @_;

    my $daia = DAIA::Response->new;

    $daia->addDocument( id => ($id || "foo:default") );

    # construct full response ...

    return $daia;
}

1;
