package QQ::weixin::work::kf::servicer;

=encoding utf8

=head1 Name

QQ::weixin::work::kf::servicer

=head1 DESCRIPTION

微信客服->接待人员管理

=cut

use strict;
use base qw(QQ::weixin::work::kf);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.06';
our @EXPORT = qw/ add del update list /;

=head1 FUNCTION

=head2 add(access_token, hash);

添加接待人员

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94646>

=head3 请求说明：

添加指定客服帐号的接待人员，每个客服帐号目前最多可添加500个接待人员。

=head4 请求包结构体为：

    {
		"open_kfid": "kfxxxxxxxxxxxxxx",
		"userid_list": ["zhangsan", "lisi"]
	}

=head4 参数说明：

    参数	必须	类型	说明
	access_token	是	调用接口凭证
	open_kfid	是	客服帐号ID
	userid_list	是	接待人员userid列表。第三方应用填密文userid，即open_userid
					可填充个数：1 ~ 100。超过100个需分批调用。

=head3 权限说明

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微信客服->管理帐号、分配会话和收发消息”权限。第三方应用仅可将应用可见范围内的成员添加为接待人员。

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"result_list": [
			{
				"userid": "zhangsan",
				"errcode": 0,
				"errmsg": "success"
			},
			{
				"userid": "lisi",
				"errcode": 0,
				"errmsg": "ignored"
			}
		]
	}

=head4 RETURN 参数说明

    参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	result_list	arrary	操作结果
	result_list.userid	string	接待人员的userid
	result_list.errcode	int	该userid的添加结果
	result_list.errmsg	string	结果信息

=cut

sub add {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/servicer/add?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del(access_token, hash);

删除接待人员

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94647>

=head3 请求说明：

从客服帐号删除接待人员

=head4 请求包结构体为：

    {
		"open_kfid": "kfxxxxxxxxxxxxxx",
		"userid_list": ["zhangsan", "lisi"]
	}

=head4 参数说明：

    参数	必须	类型	说明
	access_token	是	调用接口凭证
	open_kfid	是	客服帐号ID
	userid_list	是	接待人员userid列表。第三方应用填密文userid，即open_userid
					可填充个数：1 ~ 100。超过100个需分批调用。

=head3 权限说明

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微信客服->管理帐号、分配会话和收发消息”权限

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"result_list": [
			{
				"userid": "zhangsan",
				"errcode": 0,
				"errmsg": "success"
			},
			{
				"userid": "lisi",
				"errcode": 0,
				"errmsg": "ignored"
			}
		]
	}

=head4 RETURN 参数说明

    参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	result_list	arrary	操作结果
	result_list.userid	string	接待人员的userid
	result_list.errcode	int	该userid的删除结果
	result_list.errmsg	string	结果信息

=cut

sub del {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/servicer/del?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token);

获取接待人员列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94645>

=head3 请求说明：

获取某个客服帐号的接待人员列表

=head4 参数说明：

    参数	必须	说明
	access_token	是	调用接口凭证
	open_kfid	是	客服帐号ID

=head3 权限说明

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微信客服权限->获取基础信息”权限

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"servicer_list": [
			{
				"userid": "zhangsan",
				"status": 0
			},
			{
				"userid": "lisi",
				"status": 1
			}
		]
	}

=head4 RETURN 参数说明

    参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	servicer_list	arrary	客服帐号的接待人员列表
	servicer_list.userid	string	接待人员的userid。第三方应用获取到的为密文userid，即open_userid
	servicer_list.status	int	接待人员的接待状态。0:接待中,1:停止接待。第三方应用需具有“管理帐号、分配会话和收发消息”权限才可获取

=cut

sub list {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $open_kfid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/kf/account/list?access_token=$access_token&open_kfid=$open_kfid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
