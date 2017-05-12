use strict;
use warnings;
use Test::More tests => 2;
use Test::Deep;
use File::Spec;

use FindBin;
use Thrift::IDL;
use Thrift::Parser;
use Tapir::MethodCall;

# We're using MethodCall in a synchronous context.  Call POE::Kernel->run now to avoid warnings being emitted
use POE;
POE::Kernel->run();

my $idl = Thrift::IDL->parse_thrift_file(File::Spec->catfile($FindBin::Bin, 'thrift', 'example.thrift'));
my $parser = Thrift::Parser->new(idl => $idl, service => 'Accounts');

my $message = Tappy::Accounts::createAccount->compose_message_call(
    username => 'johndoe',
    password => '12345',
);

my $call = Tapir::MethodCall->new(
    message => $message
);

our %call_history;

{
    package MyAPI::Handler;

    use Moose;
    use Tapir::Server::Handler::Signatures;
    extends 'Tapir::Server::Handler::Class';

    set_service 'Accounts';

    method createAccount ($username, $password) {
        push @{ $main::call_history{createAccount} }, {
            username => $username,
            password => $password,
            call     => $call,
            class    => $class,
        };
        return 19;
    }

    method getAccount {
    }
}

MyAPI::Handler->add_call_actions($call);

my $action = $call->get_next_action();
is $action->(), 19, "Handler add_call_actions() adds action that calls MyAPI::Handler->create_account";
cmp_deeply $call_history{createAccount}, [{
        username => 'johndoe',
        password => '12345',
        call     => $call,
        class    => 'MyAPI::Handler',
    }], "Recorded the call in %call_history";
