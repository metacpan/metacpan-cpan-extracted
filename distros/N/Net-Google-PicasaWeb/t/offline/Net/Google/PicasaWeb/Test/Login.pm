package Net::Google::PicasaWeb::Test::Login;
use Test::Able;
use Test::More;

with qw( Net::Google::PicasaWeb::Test::Role::Offline );

test plan => 1, happy_login_ok => sub {
    my $self = shift;
    my $service = $self->service;

    ok($service->login('username', 'password'), 'login success');
};

test plan => 3, sad_login_ok => sub {
    my $self = shift;
    my $service = $self->service;

    $self->response->set_always(is_success => '');
    $self->response->set_always(
        content => 'error=Testing'
    );

    eval {
        $service->login('username', 'password');
    };

    ok($@, 'got an error on bad response');
    like($@, qr/^error logging in: /, 'error starts correctly');
};

1;
