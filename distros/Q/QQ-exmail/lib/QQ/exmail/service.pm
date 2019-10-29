package QQ::exmail::service;

=encoding utf8

=head1 Name
QQ::exmail::service

=head1 DESCRIPTION
单点登录
=cut

use strict;
use base qw(QQ::exmail);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '1.06';
our @EXPORT = qw/ get_login_url /;

=head2 get_login_url
get_login_url(access_token,userid);
获取登录企业邮的url
https://exmail.qq.com/qy_mng_logic/doc#10036
=cut

sub get_login_url {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $userid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/service/get_login_url?access_token=$access_token&userid=$userid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
