package Test::OAuth2::Google::Plus::UserInfo;
use base qw(Test::Class);
use Test::More;
use Cwd qw|realpath|;
use Sub::Override;

use FindBin;
use lib "$FindBin::Bin/../lib";


use OAuth2::Google::Plus::UserInfo;

sub ENDPOINT {
    my ($dir) = realpath(__FILE__) =~ m/(.+)\/lib\/Test\/OAuth2.+/;
    return qq|file://$dir/t-resource/userinfo|;
}


sub test_userinfo : Test(4) {
    my $info = OAuth2::Google::Plus::UserInfo->new(
        access_token => 'ABC',
        _endpoint   => ENDPOINT(),
    );

    is( $info->email, 'someone@example.com' );
    is( $info->id, '123' );
    is( $info->verified_email, 'true' );
    is( $info->is_success, 1 );
};

sub test_userinfo_fail : Test(4) {
    my $info = OAuth2::Google::Plus::UserInfo->new(
        access_token => 'ABC',
        _endpoint   => '',
    );

    is( $info->email, undef );
    is( $info->id, undef );
    is( $info->verified_email, undef );
    is( $info->is_success, '' );
};

1;