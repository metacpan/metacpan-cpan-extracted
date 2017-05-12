use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;
use File::Spec;

use FindBin;
use Thrift::IDL;
use Thrift::Parser;
use Tapir::Validator;

my $idl = Thrift::IDL->parse_thrift_file(File::Spec->catfile($FindBin::Bin, 'thrift', 'example.thrift'));
my $validator = Tapir::Validator->new();
# Required to inject 'doc' into the idl types
$validator->audit_idl_document($idl);
my $parser = Thrift::Parser->new(idl => $idl, service => 'Accounts');

my $createAccount = Tappy::Accounts::createAccount->compose_message_call(
    username => 'thisistoolong',
    password => 'mypassword',
);
throws_ok { $validator->validate_parser_message($createAccount) } qr/longer than permitted/, "Username too long";

$createAccount = Tappy::Accounts::createAccount->compose_message_call(
    username => 'notlong',
    password => '',
);
throws_ok { $validator->validate_parser_message($createAccount) } qr/shorter than permitted/, "Password too short";

$createAccount = Tappy::Accounts::createAccount->compose_message_call(
    username => 'notlong',
    password => 'has a space',
);
throws_ok { $validator->validate_parser_message($createAccount) } qr/doesn't pass regex/, "Password fails regex";

$createAccount = Tappy::Accounts::createAccount->compose_message_call(
    username => 'notlong',
    password => 'okaylength',
);
lives_ok { $validator->validate_parser_message($createAccount) } "Just right";

my $account = $createAccount->compose_reply({
    id => 0,
    allocation => 958,
});
throws_ok { $validator->validate_parser_reply($account) } qr/smaller than permitted/, "Id too small";

$account = $createAccount->compose_reply({
    id => 100_000,
    allocation => 958,
});
throws_ok { $validator->validate_parser_reply($account) } qr/larger than permitted/, "Id too large";

$account = $createAccount->compose_reply({
    id => 1000,
    allocation => 958,
});
lives_ok { $validator->validate_parser_reply($account) } "Reply is just right";
