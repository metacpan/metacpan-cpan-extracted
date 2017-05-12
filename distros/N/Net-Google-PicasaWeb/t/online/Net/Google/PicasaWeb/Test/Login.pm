package Net::Google::PicasaWeb::Test::Login;
use Test::Able;
use Test::More;

with qw( Net::Google::PicasaWeb::Test::Role::Online );

test plan => 2, happy_login_ok => sub {
    my $self = shift;

    my $success = eval {
        $self->service->login(
            $Net::Google::PicasaWeb::Test::USER,
            $Net::Google::PicasaWeb::Test::PWD,
        );
    };

    ok(!$@, 'no error during login');
    ok($success, 'successful login');
};

test plan => 2, sad_login_ok => sub {
    my $self = shift;

    my $success = eval {
        $self->service->login(
            $Net::Google::PicasaWeb::Test::USER,
            $Net::Google::PicasaWeb::Test::PWD.'XXX',
        );
    };

    like($@, qr{^error logging in: BadAuthentication\b},
        'got a BadAuthentication error during login as expected');
    ok(!$success, 'login failed as expected');
};

1;
