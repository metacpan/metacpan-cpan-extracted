package TestApplication::Model::Response;

use Test::More;
use Test::Deep;

use qbit;

use base qw(QBit::Application::Model);

sub add_cookie {
    my ($self, $cookie_name, $session, %opts) = @_;

    is($cookie_name, 'qb_s', 'Cookie name');

    ok($session ne $self->app->request->cookie($cookie_name), 'New session');

    cmp_deeply(\%opts, {expires => '+2d'}, 'params');
}

TRUE;
