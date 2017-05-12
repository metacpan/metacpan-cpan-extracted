use warnings;
use strict;
use Test::More tests => 47;
use Test::Moose 2.1405;
use Moose 2.1405;

require_ok('Siebel::SOAP::Auth');

my @attribs =
  qw(token_key header_ns user password token lookup_ns remain_ttl session_type last_fault auth_fault session_timeout token_timeout token_max_age _token_birth);

my $user = 'sadmin';
my $pass = 'UG(RT#(RVSPODGS*';
my $auth = Siebel::SOAP::Auth->new( { user => $user, password => $pass } );

foreach my $attrib (@attribs) {

    has_attribute_ok( $auth, $attrib, "instance has attribute $attrib" );

}

my @methods = (
    'get_token_key',       'get_header_ns',
    'set_header_ns',       'set_user',
    'get_user',            'get_pass',
    'set_pass',            'get_token',
    '_set_token',          'get_lookup_ns',
    'set_lookup_ns',       'get_remain_ttl',
    'get_session_type',    'get_last_fault',
    '_set_last_fault',     'get_auth_fault',
    'get_session_timeout', 'get_token_timeout',
    'get_token_max_age',   '_get_token_birth',
    '_set_token_birth',
);

foreach my $method (@methods) {

    can_ok( $auth, $method );

}

is(
    $auth->get_header_ns,
    'http://siebel.com/webservices',
    'get_header_ns has returns the correct value'
);
is( $auth->get_user, $user, 'get_user has returns the correct value' );
is( $auth->get_pass, $pass, 'get_pass has returns the correct value' );
is(
    $auth->get_lookup_ns,
    'http://schemas.xmlsoap.org/soap/envelope/',
    'get_lookup_ns has returns the correct value'
);
like( 'Error Code: 10944642',
    $auth->get_auth_fault,
    'get_auth_fault matches the expected error message' );
is(
    $auth->get_token_key,
    ( '{' . $auth->get_header_ns() . '}SessionToken' ),
    'get_token_key has returns the correct value'
);
is( $auth->get_remain_ttl, 10, 'get_remain_ttl has returns the correct value' );
is( $auth->get_session_type, 'Stateless',
    'get_session_type returns the correct value' );
is( $auth->get_session_timeout,
    900, 'get_session_timeout returns the correct value' );
is( $auth->get_token_timeout, 900, 'get_token_timeout' );
is( $auth->get_token_max_age, 172800,
    'get_token_max_age returns the correct value' );
