package QQ::weixin::work::kf::account;

=encoding utf8

=head1 Name

QQ::weixin::work::kf::account

=head1 DESCRIPTION

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

添加客服帐号

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94662>

=head3 请求说明：

添加客服帐号，并可设置客服名称和头像。目前一家企业最多可添加10个客服帐号。

=head4 请求包结构体为：

    {
		"name": "新建的客服帐号",
		"media_id": "294DpAog3YA5b9rTK4PjjfRfYLO0L5qpDHAJIzhhQ2jAEWjb9i661Q4lk8oFnPtmj"
	}

=head4 参数说明：

    参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	name	是	string	客服名称
						不多于16个字符
	media_id	是	string	客服头像临时素材。可以调用上传临时素材接口获取。
							不多于128个字节

=head3 权限说明

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）；
第三方应用需具有“微信客服->管理帐号、分配会话和收发消息”权限

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"open_kfid": "wkAJ2GCAAAZSfhHCt7IFSvLKtMPxyJTw"
	}

=head4 RETURN 参数说明

    参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	open_kfid	string	新创建的客服帐号ID

=cut

sub add {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/account/add?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del(access_token, hash);

添加客服帐号

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94663>

=head3 请求说明：

删除已有的客服帐号

=head4 请求包结构体为：

    {
		"open_kfid": "wkAJ2GCAAAZSfhHCt7IFSvLKtMPxyJTw"
	}

=head4 参数说明：

    参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	open_kfid	是	string	客服帐号ID。
							不多于64字节

=head3 权限说明

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微信客服->管理帐号、分配会话和收发消息”权限

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

    参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=cut

sub del {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/account/del?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update(access_token, hash);

修改客服帐号

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94664>

=head3 请求说明：

修改已有的客服帐号，可修改客服名称和头像。

=head4 请求包结构体为：

    {
		"open_kfid": "wkAJ2GCAAAZSfhHCt7IFSvLKtMPxyJTw",
		"name": "修改客服名",
		"media_id": "294DpAog3YA5b9rTK4PjjfRfYLO0L5qpDHAJIzhhQ2jAEWjb9i661Q4lk8oFnPtmj"
	}

=head4 参数说明：

    参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	open_kfid	是	string	要修改的客服帐号ID。
							不多于64字节
	name	否	string	新的客服名称，如不需要修改可不填。
						不多于16个字符
	media_id	否	string	新的客服头像临时素材，如不需要修改可不填。可以调用上传临时素材接口获取。
							不多于128个字节

=head3 权限说明

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微信客服->管理帐号、分配会话和收发消息”权限

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

    参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=cut

sub update {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/account/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token);

获取客服帐号列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94661>

=head3 请求说明：

获取客服帐号列表，包括所有的客服帐号的客服ID、名称和头像。

=head4 参数说明：

    参数	必须	类型	说明
	access_token	是	string	调用接口凭证

=head3 权限说明

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微信客服->获取基础信息”权限

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"account_list": [
			{
				"open_kfid": "wkAJ2GCAAASSm4_FhToWMFea0xAFfd3Q",
				"name": "咨询客服",
				"avatar": "https://wework.qpic.cn/wwhead/duc2TvpEgSSjibPZlNR6chpx9W3dtd9Ogp8XEmSNKGa6uufMWn2239HUPuwIFoYYZ7Ph580FPvo8/0"
			}
		]
	}

=head4 RETURN 参数说明

    参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	account_list	obj[]	帐号信息列表
	account_list.open_kfid	string	客服帐号ID
	account_list.name	string	客服名称
	account_list.avatar	string	客服头像URL

=cut

sub list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/account/list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
