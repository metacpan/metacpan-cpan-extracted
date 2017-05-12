package Net::Google::PicasaWeb::Test::Role::Online;
use Test::Able::Role;

use Net::Google::PicasaWeb;

has service => (
    is        => 'rw',
    isa       => 'Net::Google::PicasaWeb',
);

setup order => -10, setup_service => sub {
    my $self = shift;
    $self->service( Net::Google::PicasaWeb->new );
};

sub do_login {
    my $self = shift;
    $self->service->login(
        $Net::Google::PicasaWeb::Test::USER,
        $Net::Google::PicasaWeb::Test::PWD,
    );
}

1;
