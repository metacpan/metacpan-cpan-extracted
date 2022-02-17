package QQ::weixin::work::kf::customer;

=encoding utf8

=head1 Name

QQ::weixin::work::kf::customer

=head1 DESCRIPTION

「升级服务」配置

=cut

use strict;
use base qw(QQ::weixin::work::kf);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.06';
our @EXPORT = qw/ get_upgrade_service_config upgrade_service cancel_upgrade_service batchget /;

=head1 FUNCTION

=head2 get_upgrade_service_config(access_token, hash);

获取配置的专员与客户群

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94674#获取配置的专员与客户群>

=head3 请求说明：

企业需要在管理后台或移动端中的「微信客服」-「升级服务」中，配置专员和客户群。该接口提供获取配置的专员与客户群列表的能力。

=head4 参数说明：

    参数	必须	类型	说明
	access_token	是	string	调用接口凭证

=head3 权限说明

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微信客服权限->服务工具->配置「升级服务」”权限

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"member_range": {
			"userid_list": [
				"zhangsan",
				"lisi"
			],
			"department_id_list": [
				2,
				3
			]
		},
		"groupchat_range": {
			"chat_id_list": [
				"wraaaaaaaaaaaaaaaa",
				"wrbbbbbbbbbbbbbbb"
			]
		}
	}

=head4 RETURN 参数说明

    参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	member_range	object	专员服务配置范围
	member_range.userid_list	string	专员userid列表
	member_range.department_list	unsigned int	专员部门列表
	groupchat_range	object	客户群配置范围
	groupchat_range.chat_id_list	string	客户群列表

=cut

sub get_upgrade_service_config {
    if ( @_ && $_[0] ) {
        my $access_token = $_[0];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/kf/customer/get_upgrade_service_config?access_token=$access_token");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 upgrade_service(access_token, hash);

为客户升级为专员或客户群服务

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94674#为客户升级为专员或客户群服务>

=head3 请求说明：

企业可通过其他接口获知客户的 external_userid 以及客户与接待人员的聊天内容，因此可以结合实际业务场景，为客户推荐指定的服务专员或客户群。
通过该 API 为客户指定专员或客户群后，接待人员可在企业微信中，见到特殊的状态提示（Windows 为 icon 样式变化，移动端为出现一条 bar ），便于接待人员知晓企业的指定动作。

=head4 请求包结构体为：

=head4 升级专员服务:

    {
		"open_kfid": "kfxxxxxxxxxxxxxx",
		"external_userid": "wmxxxxxxxxxxxxxxxxxx",
		"type": 1,
		"member": {
			"userid": "zhangsan",
			"wording": "你好，我是你的专属服务专员zhangsan"
		}
	}

=head4 升级客户群服务:

	{
		"open_kfid": "kfxxxxxxxxxxxxxx",
		"external_userid": "wmxxxxxxxxxxxxxxxxxx",
		"type": 2,
		"groupchat": {
			"chat_id": "wraaaaaaaaaaaaaaaa",
			"wording": "欢迎加入你的专属服务群"
		}
	}

=head4 参数说明：

    参数	必须	说明
	access_token	是	调用接口凭证
	open_kfid	是	客服帐号ID
	external_userid	是	微信客户的external_userid
	type	是	表示是升级到专员服务还是客户群服务。1:专员服务。2:客户群服务
	member	否	推荐的服务专员，type等于1时有效
	member.userid	是	服务专员的userid
	member.wording	否	推荐语
	groupchat	否	推荐的客户群，type等于2时有效
	groupchat.chat_id	是	客户群id
	groupchat.wording	否	推荐语

=head3 权限说明

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微信客服权限->服务工具->配置「升级服务」”权限
要求userid/chatid已配置在微信客服中的“升级服务”中专员服务或客户群服务才可使用API进行设置，否则会返回95021错误码。
要求userid在“客户联系->权限配置->客户联系和客户群"的使用范围内

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

sub upgrade_service {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/customer/upgrade_service?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 cancel_upgrade_service(access_token, hash);

为客户取消推荐

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94674#为客户取消推荐>

=head3 请求说明：

当企业通过 API 为客户指定了专员或客户群后，如果客户已经完成服务升级，或是企业需要取消推荐，则可调用该接口清空之前为客户指定的专员或客户群。清空后，企业微信中的特殊状态提示也会同步消失。

=head4 请求包结构体为：

    {
		"open_kfid": "kfxxxxxxxxxxxxxx",
		"external_userid": "wmxxxxxxxxxxxxxxxxxx"
	}

=head4 参数说明：

    参数	必须	说明
	access_token	是	调用接口凭证
	open_kfid	是	客服帐号ID
	external_userid	是	微信客户的external_userid

=head3 权限说明

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微信客服权限->服务工具->配置「升级服务」”权限

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

sub cancel_upgrade_service {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/customer/cancel_upgrade_service?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 batchget(access_token, hash);

获取客户基础信息

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95159>

=head3 请求说明：

=head4 请求包结构体为：

    {
		"external_userid_list": [
			"wmxxxxxxxxxxxxxxxxxxxxxx",
			"zhangsan"
		]
	}

=head4 参数说明：

    参数	必须	说明
	access_token	是	调用接口凭证
	external_userid_list	是	external_userid列表
								可填充个数：1 ~ 100。超过100个需分批调用。

=head3 权限说明

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）。「API关闭」状态下也可调用。
第三方应用需具有“微信客服权限->获取基础信息”权限

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"customer_list": [
			{
				"external_userid": "wmxxxxxxxxxxxxxxxxxxxxxx",
				"nickname": "张三",
				"avatar": "http://xxxxx",
				"gender": 1,
				"unionid": "oxasdaosaosdasdasdasd"
			}
		],
		"invalid_external_userid": [
			"zhangsan"
		]
	}

=head4 RETURN 参数说明

    参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	customer_list	array	返回结果
	customer_list.external_userid	string	微信客户的external_userid
	customer_list.nickname	string	微信昵称
	customer_list.avatar	string	微信头像。第三方不可获取
	customer_list.gender	int	性别
	customer_list.unionid	string	unionid，需要绑定微信开发者帐号才能获取到，查看绑定方法。第三方不可获取

=cut

sub batchget {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/customer/batchget?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}



1;
__END__
