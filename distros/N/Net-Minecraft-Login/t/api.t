
use strict;
use warnings;

use Test::More;
use Test::Fatal qw( exception success );
use Net::Minecraft::Login;

my $ex;
my $req;
my $res;

sub test_login {
  my (@arg) = @_;
  no warnings 'redefine';
  undef $req;
  undef $res;
  local *Net::Minecraft::Login::_do_request = sub {
    my ( $class, $base, $param, $config ) = @_;
    $req = $param;
    return {
      success => 1,
      status  => 200,
      content => '1343825972000:deprecated:SirCmpwn:7ae9007b9909de05ea58e94199a33b30c310c69c:dba0c48e1c584963b9e93a038a66bb98'
    };
  };
  return ( $res = Net::Minecraft::Login->new()->login(@arg) );
}

sub test_result {
  subtest result_check => sub {
    is( $res->current_version, '1343825972000',                            'Current Version' );
    is( $res->download_ticket, 'deprecated',                               'Download Ticket ( Deprecated )' );
    is( $res->user,            'SirCmpwn',                                 'Fixed username', );
    is( $res->session_id,      '7ae9007b9909de05ea58e94199a33b30c310c69c', 'session id' );
    is( $res->unique_id,       'dba0c48e1c584963b9e93a038a66bb98',         'unique id' );
  };
}

ok( not( $ex = exception { test_login( user => 'Foo', password => 'bar', ) } ), "Login with both args" ) or diag $ex;

ok( defined $req, 'Data in $req' );

is_deeply( $req, { user => 'Foo', password => 'bar', version => '13' }, 'Data structure matches' );

isa_ok( $res, 'Net::Minecraft::LoginResult' );
test_result();

ok( not( $ex = exception { test_login( { user => 'Foo', password => 'bar', } ); } ), "Login with both args ( ref )" ) or diag $ex;

ok( defined $req, 'Data in $req' );

is_deeply( $req, { user => 'Foo', password => 'bar', version => '13' }, 'Data structure matches' );
isa_ok( $res, 'Net::Minecraft::LoginResult' );
test_result();

ok( $ex = exception { test_login() }, "Login without args => Bad" );

note $ex;

ok( $ex = exception { test_login( \1 ) }, "Login 1 arg non-hash ref => Bad" );

note $ex;

ok( $ex = exception { test_login( 1, 2, 3 ) }, "Login with 3 args => bad" );

note $ex;

ok( $ex = exception { test_login( password => bar => ) }, "No user => bad" );

note $ex;

ok( $ex = exception { test_login( user => bar => ) }, "No password => bad" );

note $ex;

ok( $ex = exception { test_login( user => bar => password => bar => foo => quux => ) }, "Unknown params => bad" );

note $ex;
done_testing();

