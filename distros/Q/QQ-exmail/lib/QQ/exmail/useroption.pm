package QQ::exmail::useroption;

=encoding utf8

=head1 Name

QQ::exmail::useroption

=head1 DESCRIPTION

功能设置

=cut

use strict;
use base qw(QQ::exmail);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '1.10';
our @EXPORT = qw/ get update /;

=head1 FUNCTION

=head2 get(access_token, hash);

获取功能属性

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10020>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"userid": "zhangsan@gzdev.com",
    	"type":[1,2,3]
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	        是	成员UserID
    type	        是	功能设置属性类型
                        1: 强制启用安全登录
                        2: IMAP/SMTP服务
                        3: POP/SMTP服务
                        4: 是否启用安全登录

=head3 权限说明

系统应用须拥有指定成员的查看权限

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
    	"option":[{"type":1,"value":"0"}, {"type":2,"value":"1"}, {"type":3,"value":"0"}]}
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    option	功能设置属性
            type：属性类型。value:属性值（字符型）
            1: 强制微信动态码
            2: IMAP/SMTP服务
            3: POP/SMTP服务
            4: 是否启用微信动态码

=cut

sub get {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/useroption/get?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update(access_token, hash);

更改功能属性

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10020>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"userid": "zhangsan@gzdev.com",
    	"option": [{"type":1,"value":"0"},{"type":2,"value":"1"},{"type":3,"value":"0"}]}
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	        是	成员UserID。企业邮帐号名，邮箱格式
    option	        是	功能设置属性
                    type：属性类型。value:属性值（字符型）
                    1: 强制启用安全登录
                    2: IMAP/SMTP服务
                    3: POP/SMTP服务
                    4: 是否启用安全登录，不可用

=head3 权限说明

系统应用须拥有指定成员的查看权限

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "update"
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

=cut

sub update {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/useroption/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
