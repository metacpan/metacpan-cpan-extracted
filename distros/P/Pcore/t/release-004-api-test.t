#!/usr/bin/env perl

package main v0.1.0;

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        require Test::More;

        Test::More::plan( skip_all => 'these tests are for release candidate testing' );
    }
}

use Pcore;
use Test::More;
use Pcore::App::Auth;
use Pcore::Node;

our $TESTS = 5;

plan tests => $TESTS;

package App {

    use Pcore -class;

    with qw[Pcore::App];

    our $PERMISSIONS = [ 'admin', 'user' ];

    # PERMISSIONS
    sub get_permissions ($self) {
        return $PERMISSIONS;
    }

    sub run { }

}

my $app = bless {
    cfg => {
        auth => {
            backend => 'sqlite:',
            node    => { workers => 1 }
        }
    },
    node => Pcore::Node->new(
        type     => 'main',
        requires => { 'Pcore::App::Auth::Node' => undef },
    ),
  },
  'App';

my $api = Pcore::App::Auth->new($app);

my $res = $api->init;
ok( $res, 'api_init' );

$res = $api->get_user('root');
ok( $res, 'get_user' );

my $sess = $api->create_session('root');
ok( $sess, 'create_session' );

my $auth;
$auth = $api->authenticate( $sess->{data}->{token} );
ok( $auth->{is_authenticated}, 'authenticate_session_token_1' );

$auth = $api->authenticate( [ 'root', 'fake_password' ] );
ok( !$auth->{is_authenticated}, 'authenticate_password_1' );

done_testing $TESTS;

1;
__END__
=pod

=encoding utf8

=cut
