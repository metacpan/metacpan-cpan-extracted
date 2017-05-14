package Test::OAuth2::Google::Plus;
use base qw(Test::Class);
use Test::More;
use Cwd qw|realpath|;
use Sub::Override;

use FindBin;
use lib "$FindBin::Bin/../lib";


use OAuth2::Google::Plus;

sub ENDPOINT {
    my ($dir) = realpath(__FILE__) =~ m/(.+)\/lib\/Test\/OAuth2.+/;
    return qq|file://$dir/t-resource/|;
}


sub test_authorization_uri : Test(2) {
    my $plus = OAuth2::Google::Plus->new(
        client_id     => 'CLIENT ID',
        client_secret => 'CLIENT SECRET',
        redirect_uri  => 'http://test/'
    );

    my $expect = 'https://accounts.google.com/o/oauth2/auth?access_type=offline&approval_prompt=force&client_id=CLIENT+ID&redirect_uri=http%3A%2F%2Ftest%2F&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email';

    isa_ok( $plus->authorization_uri, 'URI' );
    is( $plus->authorization_uri, $expect );
};


sub test_authorization_uri_state_param : Test(1) {
    my $plus = OAuth2::Google::Plus->new(
        client_id     => 'CLIENT ID',
        client_secret => 'CLIENT SECRET',
        redirect_uri  => 'http://test/',
        state         => 'abc',
    );

    my $expect = 'https://accounts.google.com/o/oauth2/auth?access_type=offline&approval_prompt=force&client_id=CLIENT+ID&redirect_uri=http%3A%2F%2Ftest%2F&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email&state=abc';

    is( $plus->authorization_uri, $expect );
};

sub test_authorize : Test(1) {
    # simulate POST by overriding it with GET.
    my $override_post = Sub::Override->new(
        'LWP::UserAgent::post' => sub {
            return LWP::UserAgent::get(@_);
        }
    );

    my $plus = OAuth2::Google::Plus->new(
        client_id     => 'CLIENT ID',
        client_secret => 'CLIENT SECRET',
        redirect_uri  => 'http://test/',
        _endpoint     => ENDPOINT(),
    );

    my $authorization_token = $plus->authorize( authorization_code => 'foobar' );

    is( $authorization_token, 123, 'Got expected token from json hash');
};

sub test_authorize_may_fail : Test(1) {
    # simulate POST by overriding it with GET.
    my $override_post = Sub::Override->new(
        'LWP::UserAgent::post' => sub {
            return LWP::UserAgent::get(@_);
        }
    );

    my $plus = OAuth2::Google::Plus->new(
        client_id     => 'CLIENT ID',
        client_secret => 'CLIENT SECRET',
        redirect_uri  => 'http://test/',
        _endpoint     => ENDPOINT() . 'does-not-exist',
    );

    my $authorization_token = $plus->authorize( authorization_code => 'foobar' );
    is( $authorization_token, undef, 'Faillure is handled ok');
};

1;
