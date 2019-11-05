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

our $VERSION = '1.10';
our @EXPORT = qw/ get_login_url /;

=head1 FUNCTION

=head2 get_login_url(access_token,userid);

获取登录企业邮的url

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10036>

=head3 步骤说明

    1.获取登录企业邮的url。如需使用个性域名，将域名替换成相应域名，并使用HTTP协议
    首次登录需要进行授权，用户需要输入正确的登录密码来完成授权。
    后续可直接一键跳转到企业邮
    
    2.修改密码或者重置CorpSecret都会取消授权关系

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	        是	成员UserID

=head3 RETURN 返回结果：

    {
    	"errcode": 0,
    	"errmsg": "ok",
    	"login_url": "https://exmail.qq.com/cgi-bin/login?fun=bizopenssologin&method=openapi&userid=zhangsanp@gzdev.com&authkey=XXXX",
    	"expires_in": 300,
    }

=head4 RETURN 参数说明：

    参数	        说明
    errcode	    返回码
    errmsg	    对返回码的文本描述内容
    login_url	登录跳转的url，一次性有效，不可多次使用。
                如需使用个性域名的，请将https://exmail.qq.com替换成相应的域名即可，并使用http协议。
    expires_in	url有效时长，单位为秒

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
