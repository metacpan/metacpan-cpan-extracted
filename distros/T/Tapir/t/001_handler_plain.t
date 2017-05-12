use strict;
use warnings;
use Test::More tests => 2;

{
    package MyAPI::Handler;

    use Moose;
    extends 'Tapir::Server::Handler::Class';

    __PACKAGE__->service('Accounts');

    __PACKAGE__->add_method('createAccount');
    sub createAccount {
    }

    __PACKAGE__->add_method('getAccount');
    sub getAccount {
    }
}

is(MyAPI::Handler->service, 'Accounts', "service()");
is_deeply(
    MyAPI::Handler->methods,
    {
        createAccount => 'normal',
        getAccount    => 'normal',
    },
    "methods()"
);
