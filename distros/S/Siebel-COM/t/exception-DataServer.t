use Win32::OLE;
use Test::Most tests => 7;
use lib 't';
use Test::Exception::DataServer;

BEGIN { use_ok('Siebel::COM::Exception::DataServer') }

my $mock = Test::Exception::DataServer->new();

can_ok( $mock, qw(get_return_code check_error) );
isa_ok( $mock->get_return_code(), 'Win32::OLE::Variant' );
is( $mock->get_return_code()->Get(), 0, 'return code must be zero' );
lives_ok { $mock->check_error() } 'check_error must NOT raise an exception';
$mock->get_return_code()->Put(1);
is( $mock->get_return_code()->Get(), 1, 'return code must be one' );
dies_ok { $mock->check_error() } 'check_error must raise an exception';

