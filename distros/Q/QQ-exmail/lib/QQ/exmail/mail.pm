package QQ::exmail::mail;

=encoding utf8

=head1 Name

QQ::exmail::mail

=head1 DESCRIPTION

新邮件提醒

=cut

use strict;
use base qw(QQ::exmail);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '1.10';
our @EXPORT = qw/ newcount /;

=head1 FUNCTION

=head2 newcount(access_token, userid, hash);

获取邮件未读数

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10033>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"type": 0,
    	"begin_date": "2016-10-01",
    	"end_date": "2016-10-07"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	        是	成员UserID
    begin_date	    是	开始日期。格式为2016-10-01
    end_date	    是	结束日期。格式为2016-10-07

=head3 权限说明

系统应用须拥有指定成员的查看权限。

=head3 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
    	"count": 1
    }

=head4 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    count	未读邮件数

=cut

sub newcount {
    if ( @_ && $_[0] && $_[1] && ref $_[2] eq 'HASH' ) {
        my $access_token = $_[0];
        my $userid = $_[1];
        my $json = $_[2];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/mail/newcount?access_token=$access_token&userid=$userid",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
