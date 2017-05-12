#!/usr/bin/perl

use Test::More tests => 21;
use Test::Deep;

use qbit;

use lib::abs qw(../lib ./lib);

require_ok 'TestApplication';

my $app = TestApplication->new();

$app->pre_run();

my $error;
try {
    $app->session;
}
catch {
    my ($exception) = @_;

    $error = TRUE;

    is(ref($exception),     'Exception::Authorization',    'throw exception');
    is($exception->message, gettext('Add salt in config'), 'Corrected error');
}
finally {
    ok($error, 'need salt');
};

$app->set_option('salt' => 's3cret');

is(ref($app->session), 'QBit::Application::Model::Authorization', 'new');

my $session = $app->session->registration(['name-surname@mail.ru', 'login'], 'password');

is($app->session->check_session($session), 'login', 'check_session');

my $session2 = $app->session->check_auth('name-surname@mail.ru', 'password');

is($app->session->check_session($session2), 'name-surname@mail.ru', 'check_session 2');

ok($session ne $session2, 'diff sessions');

$app->session->delete('name-surname@mail.ru');

$error = FALSE;
try {
    $app->session->check_auth('name-surname@mail.ru', 'password');
}
catch {
    my ($exception) = @_;

    $error = TRUE;

    is(ref($exception), 'Exception::Authorization::NotFound', 'throw exception');
    is($exception->message, gettext('"%s" not found', 'name-surname@mail.ru'), 'Corrected error');
}
finally {
    ok($error, 'Error if not found auth');
};

$error = FALSE;
try {
    $app->session->check_auth('login', 'drowssap');
}
catch {
    my ($exception) = @_;

    $error = TRUE;

    is(ref($exception),     'Exception::Authorization::BadPassword', 'throw exception');
    is($exception->message, gettext('Invalid password'),             'Corrected error');
}
finally {
    ok($error, 'Error if bad password');
};

my $bad_session = $app->session->_get_session('login', '12345678');

$error = FALSE;
try {
    $app->session->check_session($bad_session);
}
catch {
    my ($exception) = @_;

    $error = TRUE;

    is(ref($exception),     'Exception::Authorization::BadSession', 'throw exception');
    is($exception->message, gettext('Invalid session'),             'Corrected error');
}
finally {
    ok($error, 'Error if bad session');
};

$app->session->process('qb_s', '+2d', $app->request, $app->response, sub {$app->set_option('cur_user', $_[0])});

is($app->get_option('cur_user'), 'login', 'process');
