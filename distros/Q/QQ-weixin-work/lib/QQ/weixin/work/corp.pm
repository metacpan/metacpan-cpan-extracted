package QQ::weixin::work::corp;

=encoding utf8

=head1 Name

QQ::weixin::work::corp

=head1 DESCRIPTION

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.04';
our @EXPORT = qw/ get_join_qrcode /;

=head1 FUNCTION

=head2 get_join_qrcode(access_token, size_type);

获取加入企业二维码

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/91714>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    size_type	否	qrcode尺寸类型，1: 171 x 171; 2: 399 x 399; 3: 741 x 741; 4: 2052 x 2052

=head4 权限说明：

须拥有通讯录的管理权限，使用通讯录同步的Secret。

=head3 RETURN 返回结果：

    {
    	"errcode": 0,
    	"errmsg": "ok",
      "join_qrcode": "https://work.weixin.qq.com/wework_admin/genqrcode?action=join&vcode=3db1fab03118ae2aa1544cb9abe84&r=hb_share_api_mjoin&qr_size=3"
    }

=head4 RETURN 参数说明：

    参数	        说明
    errcode	    出错返回码，为0表示成功，非0表示调用失败
    errmsg	对返回码的文本描述内容
    join_qrcode	二维码链接，有效期7天

=cut

sub get_join_qrcode {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $size_type = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/corp/get_join_qrcode?access_token=$access_token&size_type=$size_type");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
