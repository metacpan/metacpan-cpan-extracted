use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $secret = 'a02655d46dd0f2160529acaccd4dbf979c6e6e50';

sub test_auth {
    my %config = @_;

    my $app = sub { return [ 200, [ ], [ ] ] };

    $app = builder {
        enable "Auth::AccessToken", authenticator => \&check_token, %config;
        $app;
    };

    my $url = ($config{reject_http} ? 'https' : 'http') . '://localhost/';

    test_psgi $app => sub {
        my $cb = shift;

        my $res = $cb->(GET $url);
        is $res->code, 401;
        is $res->content, 'Authorization required';

        $res = $cb->(GET $url, "Authorization" => "bearer $secret");
        is $res->code, 200;

        $res = $cb->(GET $url, "Authorization" => "bearer 123");
        is $res->code, 401;
        is $res->content, 'Bad credentials';

        $res = $cb->(GET "$url?access_token=$secret");
        is $res->code, 200;

        if ($config{reject_http}) {
            $res = $cb->(GET "http://localhost/?access_token=$secret");
            is $res->code, 401;
            is $res->content, 'Bad credentials';
            is $secret, undef;
        }
    };
}

sub check_token {
    my $token = shift;
    return $token eq $secret;
}

sub revoke_token {
    $secret = undef;
}

test_auth( token_type => 'Bearer' );
test_auth( reject_http => \&revoke_token );

done_testing;
