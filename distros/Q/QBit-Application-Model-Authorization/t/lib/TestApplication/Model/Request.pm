package TestApplication::Model::Request;

use qbit;

use base qw(QBit::Application::Model);

sub cookie {
    return $_[0]->app->session->check_auth('login', 'password');
}

TRUE;
