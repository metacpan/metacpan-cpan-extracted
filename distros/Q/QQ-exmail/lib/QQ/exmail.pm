package QQ::exmail;

=pod

=encoding utf8

=head1 Name

QQ::exmail

=head1 DESCRIPTION

腾讯企业邮->接口文档

L<https://exmail.qq.com/qy_mng_logic/doc#10001>  

=head1 SYNOPSIS

腾讯企业邮开放平台旨在为企业拓展、定制邮箱的功能。我们为开发者提供了五大开放接口：通讯录管理、新邮件提醒、单点登录、系统日志、功能设置。希望帮助企业提升开发效率、降低开发成本和难度，从而提升生产和管理之间的协作效率。

企业开发流程如下：

1.获取企业邮的CorpID和CorpSecret：企业邮管理员通过启用应用，获取CorpID和CorpSecret

2.开发对接相关接口：开发测试应用，对接企业邮接口

=cut

use strict;
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '1.10';
our @EXPORT = qw/ gettoken /;

=head1 FUNCTION

=head2 gettoken(corpid,corpsecrect);

获取ACCESS_TOKEN

=head3 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10003>

=head3 参数说明

    参数	        必须	说明  
    corpid	    是	企业id  
    corpsecret	是	应用的凭证密钥

=head3 权限说明

每个应用有不同的secret，代表了对应用的不同权限

=head3 RETURN 返回结果

    {
       "access_token": "accesstoken000001",
       "expires_in": 7200
    }

=head4 RETURN 参数说明

    参数	            说明
    access_token	获取到的凭证。长度为64至512个字节
    expires_in	    凭证的有效时间（秒）

=head4 RETURN 出错返回示例

    {
       "errcode": 40001,
       "errmsg": "invalid credential"
    }

=cut

sub gettoken {
    if ( @_ && $_[0] && $_[1] ) {
        my $corpid = $_[0];
        my $corpsecret = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/gettoken?corpid=$corpid&corpsecret=$corpsecret");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
