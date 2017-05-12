use strict;
use warnings;
use Test::More tests => 8;
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

isa_ok $call, 'Tapir::MethodCall';
is $call->message, $message, 'message()';
is $call->method, 'createAccount', 'method()';
isa_ok $call->arguments, 'Thrift::Parser::FieldSet', 'arguments()';

my %args_plain = $call->args;
my %args       = $call->args_thrift;

isa_ok $args{username}, 'Tappy::username';
isa_ok $args{username}, 'Thrift::Parser::Type::string';
is $args{username}->value, 'johndoe', "Dereference args() value";
is $args_plain{username}, 'johndoe', "args('plain') is already dereferenced";
