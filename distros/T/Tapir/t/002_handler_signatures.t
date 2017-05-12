use strict;
use warnings;
use Test::More tests => 2;

{
    package MyAPI::Handler;

    use Moose;
    use Tapir::Server::Handler::Signatures;
    extends 'Tapir::Server::Handler::Class';

    set_service 'Accounts';

    method createAccount {
    }

    method getAccount {
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
