package QQ::weixin::work::externalcontact;

=encoding utf8

=head1 Name

QQ::weixin::work::externalcontact

=head1 DESCRIPTION

客户联系

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.06';
our @EXPORT = qw/ get_follow_user_list
				add_contact_way get_contact_way list_contact_way update_contact_way del_contact_way close_temp_chat
				list get remark
				get_corp_tag_list add_corp_tag edit_corp_tag del_corp_tag
				get_strategy_tag_list add_strategy_tag edit_strategy_tag del_strategy_tag
				mark_tag
				transfer_customer transfer_result
				get_unassigned_list
				opengid_to_chatid
				add_moment_task get_moment_task_result
				get_moment_list get_moment_task get_moment_customer_list get_moment_send_result get_moment_comments
				add_msg_template
				get_groupmsg_list_v2 get_groupmsg_task get_groupmsg_send_result
				send_welcome_msg get_user_behavior_data
				add_product_album get_product_album get_product_album_list update_product_album delete_product_album
				add_intercept_rule get_intercept_rule_list get_intercept_rule update_intercept_rule del_intercept_rule /;
 
=head1 FUNCTION

=head2 get_follow_user_list(access_token);

获取配置了客户联系功能的成员列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92571>

=head3 请求说明：

企业和第三方服务商可通过此接口获取配置了客户联系功能的成员列表。

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证

=head4 权限说明：

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）；
第三方应用需具有“企业客户权限->客户基础信息”权限
第三方/自建应用只能获取到可见范围内的配置了客户联系功能的成员。

=head3 RETURN 返回结果：

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "follow_user":[
			"zhangsan",
			"lissi"
	   ]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	follow_user	配置了客户联系功能的成员userid列表

=cut

sub get_follow_user_list {
    if ( @_ && $_[0] ) {
        my $access_token = $_[0];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_follow_user_list?access_token=$access_token");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 add_contact_way(access_token, hash);

配置客户联系「联系我」方式

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92572#配置客户联系「联系我」方式>

=head3 请求说明：

企业可以在管理后台-客户联系-加客户中配置成员的「联系我」的二维码或者小程序按钮，客户通过扫描二维码或点击小程序上的按钮，即可获取成员联系方式，主动联系到成员。
企业可通过此接口为具有客户联系功能的成员生成专属的「联系我」二维码或者「联系我」按钮。
如果配置的是「联系我」按钮，需要开发者的小程序接入小程序插件。

注意:
通过API添加的「联系我」不会在管理端进行展示，每个企业可通过API最多配置50万个「联系我」。
用户需要妥善存储返回的config_id，config_id丢失可能导致用户无法编辑或删除「联系我」。
临时会话模式不占用「联系我」数量，但每日最多添加10万个，并且仅支持单人。
临时会话模式的二维码，添加好友完成后该二维码即刻失效。

=head4 请求包结构体为：

	{
	   "type" :1,
	   "scene":1,
	   "style":1,
	   "remark":"渠道客户",
	   "skip_verify":true,
	   "state":"teststate",
	   "user" : ["zhangsan", "lisi", "wangwu"],
	   "party" : [2, 3],
	   "is_temp":true,
	   "expires_in":86400,
	   "chat_expires_in":86400,
	   "unionid":"oxTWIuGaIt6gTKsQRLau2M0AAAA",
	   "conclusions":
	   {
			"text": 
			{
				"content":"文本消息内容"
			},
			"image": 
			{
				"media_id": "MEDIA_ID"
			},
			"link":
			{
				"title": "消息标题",
				"picurl": "https://example.pic.com/path",
				"desc": "消息描述",
				"url": "https://example.link.com/path"
			},
			"miniprogram":
			{
				"title": "消息标题",
				"pic_media_id": "MEDIA_ID",
				"appid": "wx8bd80126147dfAAA",
				"page": "/path/index.html"
			}
	   }
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	type	是	联系方式类型,1-单人, 2-多人
	scene	是	场景，1-在小程序中联系，2-通过二维码联系
	style	否	在小程序中联系时使用的控件样式，详见附表
	remark	否	联系方式的备注信息，用于助记，不超过30个字符
	skip_verify	否	外部客户添加时是否无需验证，默认为true
	state	否	企业自定义的state参数，用于区分不同的添加渠道，在调用“获取外部联系人详情”时会返回该参数值，不超过30个字符
	user	否	使用该联系方式的用户userID列表，在type为1时为必填，且只能有一个
	party	否	使用该联系方式的部门id列表，只在type为2时有效
	is_temp	否	是否临时会话模式，true表示使用临时会话模式，默认为false
	expires_in	否	临时会话二维码有效期，以秒为单位。该参数仅在is_temp为true时有效，默认7天，最多为14天
	chat_expires_in	否	临时会话有效期，以秒为单位。该参数仅在is_temp为true时有效，默认为添加好友后24小时，最多为14天
	unionid	否	可进行临时会话的客户unionid，该参数仅在is_temp为true时有效，如不指定则不进行限制
	conclusions	否	结束语，会话结束时自动发送给客户，可参考“结束语定义”，仅在is_temp为true时有效

=head3 权限说明

注意，每个联系方式最多配置100个使用成员（包含部门展开后的成员）
当设置为临时会话模式时（即is_temp为true），联系人仅支持配置为单人，暂不支持多人
使用unionid需要调用方（企业或服务商）的企业微信“客户联系”中已绑定微信开发者账户

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "config_id":"42b34949e138eb6e027c123cba77fAAA",
	   "qr_code":"http://p.qpic.cn/wwhead/duc2TvpEgSdicZ9RrdUtBkv2UiaA/0"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	config_id	新增联系方式的配置id
	qr_code	联系我二维码链接，仅在scene为2时返回

=cut

sub add_contact_way {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/add_contact_way?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_contact_way(access_token, hash);

获取企业已配置的「联系我」方式

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92572#获取企业已配置的「联系我」方式>

=head3 请求说明：

获取企业配置的「联系我」二维码和「联系我」小程序按钮。

=head4 请求包结构体为：

	{
	   "config_id":"42b34949e138eb6e027c123cba77fad7"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	config_id	是	联系方式的配置id

=head3 权限说明

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "contact_way":
		{
			"config_id":"42b34949e138eb6e027c123cba77fAAA",
			"type":1,
			"scene":1,
			"style":2,
			"remark":"test remark",
			"skip_verify":true,
			"state":"teststate",
			"qr_code":"http://p.qpic.cn/wwhead/duc2TvpEgSdicZ9RrdUtBkv2UiaA/0",
			"user" : ["zhangsan", "lisi", "wangwu"],
			"party" : [2, 3],
			"is_temp":true,
			"expires_in":86400,
			"chat_expires_in":86400,
			"unionid":"oxTWIuGaIt6gTKsQRLau2M0AAAA",
			"conclusions":
			{
				"text": 
				{
					"content":"文本消息内容"
				},
				"image": 
				{
					"pic_url": "http://p.qpic.cn/pic_wework/XXXXX"
				},
				"link": 
				{
					"title": "消息标题",
					"picurl": "https://example.pic.com/path",
					"desc": "消息描述",
					"url": "https://example.link.com/path"
				},
				"miniprogram": 
				{
					"title": "消息标题",
					"pic_media_id": "MEDIA_ID",
					 "appid": "wx8bd80126147dfAAA",
					"page": "/path/index"
				}
			}
		}
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	config_id	新增联系方式的配置id
	type	联系方式类型，1-单人，2-多人
	scene	场景，1-在小程序中联系，2-通过二维码联系
	is_temp	是否临时会话模式，默认为false，true表示使用临时会话模式
	remark	联系方式的备注信息，用于助记
	skip_verify	外部客户添加时是否无需验证
	state	企业自定义的state参数，用于区分不同的添加渠道，在调用“获取外部联系人详情”时会返回该参数值
	style	小程序中联系按钮的样式，仅在scene为1时返回，详见附录
	qr_code	联系二维码的URL，仅在scene为2时返回
	user	使用该联系方式的用户userID列表
	party	使用该联系方式的部门id列表
	expires_in	临时会话二维码有效期，以秒为单位
	chat_expires_in	临时会话有效期，以秒为单位
	unionid	可进行临时会话的客户unionid
	conclusions	结束语，可参考“结束语定义”

=cut

sub get_contact_way {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_contact_way?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list_contact_way(access_token, hash);

获取企业已配置的「联系我」列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92572#获取企业已配置的「联系我」列表>

=head3 请求说明：

获取企业配置的「联系我」二维码和「联系我」小程序插件列表。不包含临时会话。
注意，该接口仅可获取2021年7月10日以后创建的「联系我」

=head4 请求包结构体为：

	{
	   "start_time":1622476800,
	   "end_time":1625068800,
	   "cursor":"CURSOR",
	   "limit":1000
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	start_time	否	「联系我」创建起始时间戳, 默认为90天前
	end_time	否	「联系我」创建结束时间戳, 默认为当前时间
	cursor	否	分页查询使用的游标，为上次请求返回的 next_cursor
	limit	否	每次查询的分页大小，默认为100条，最多支持1000条

=head3 权限说明

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok",
		"contact_way":
		[
			{
				"config_id":"534b63270045c9ABiKEE814ef56d91c62f"
			}，
			{
				"config_id":"87bBiKEE811c62f63270041c62f5c9A4ef"
			}
		],
		"next_cursor":"NEXT_CURSOR"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	contact_way.config_id	联系方式的配置id
	next_cursor	分页参数，用于查询下一个分页的数据，为空时表示没有更多的分页

=cut

sub list_contact_way {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/list_contact_way?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update_contact_way(access_token, hash);

更新企业已配置的「联系我」方式

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92572#更新企业已配置的「联系我」方式>

=head3 请求说明：

更新企业配置的「联系我」二维码和「联系我」小程序按钮中的信息，如使用人员和备注等。

=head4 请求包结构体为：

	{
	   "config_id":"42b34949e138eb6e027c123cba77fAAA",
	   "remark":"渠道客户",
	   "skip_verify":true,
	   "style":1,
	   "state":"teststate",
	   "user" : ["zhangsan", "lisi", "wangwu"],
	   "party" : [2, 3],
		"expires_in":86400,
		"chat_expires_in":86400,
		 "unionid":"oxTWIuGaIt6gTKsQRLau2M0AAAA",
		 "conclusions":
		 {
			"text":
			{
				"content":"文本消息内容"
			},
			"image": 
			{
				"media_id": "MEDIA_ID"
			},
			"link": 
			{
				"title": "消息标题",
				"picurl": "https://example.pic.com/path",
				"desc": "消息描述",
				"url": "https://example.link.com/path"
			},
			"miniprogram": 
			{
				"title": "消息标题",
				"pic_media_id": "MEDIA_ID",
				"appid": "wx8bd80126147dfAAA",
				"page": "/path/index"
			}
	   }
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	config_id	是	企业联系方式的配置id
	remark	否	联系方式的备注信息，不超过30个字符，将覆盖之前的备注
	skip_verify	否	外部客户添加时是否无需验证
	style	否	样式，只针对“在小程序中联系”的配置生效
	state	否	企业自定义的state参数，用于区分不同的添加渠道，在调用“获取外部联系人详情”时会返回该参数值
	user	否	使用该联系方式的用户列表，将覆盖原有用户列表
	party	否	使用该联系方式的部门列表，将覆盖原有部门列表，只在配置的type为2时有效
	expires_in	否	临时会话二维码有效期，以秒为单位，该参数仅在临时会话模式下有效
	chat_expires_in	否	临时会话有效期，以秒为单位，该参数仅在临时会话模式下有效
	unionid	否	可进行临时会话的客户unionid，该参数仅在临时会话模式有效，如不指定则不进行限制
	conclusions	否	结束语，会话结束时自动发送给客户，可参考“结束语定义”，仅临时会话模式（is_temp为true）可设置

注意：已失效的临时会话联系方式无法进行编辑
当临时会话模式时（即is_temp为true），联系人仅支持配置为单人，暂不支持多人

=head3 权限说明

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub update_contact_way {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/update_contact_way?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del_contact_way(access_token, hash);

删除企业已配置的「联系我」方式

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92572#删除企业已配置的「联系我」方式>

=head3 请求说明：

删除一个已配置的「联系我」二维码或者「联系我」小程序按钮。

=head4 请求包结构体为：

	{
	   "config_id":"42b34949e138eb6e027c123cba77fAAA"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	config_id	是	企业联系方式的配置id

=head3 权限说明

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub del_contact_way {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/del_contact_way?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 close_temp_chat(access_token, hash);

结束临时会话

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92572#结束临时会话>

=head3 请求说明：

将指定的企业成员和客户之前的临时会话断开，断开前会自动下发已配置的结束语。

=head4 请求包结构体为：

	{
		"userid":"zhangyisheng",
		"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACHAAA"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	userid	是	企业成员的userid
	external_userid	是	客户的外部联系人userid

注意：请保证传入的企业成员和客户之间有仍然有效的临时会话, 通过其他方式的添加外部联系人无法通过此接口关闭会话。

=head3 权限说明

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=head3 结束语定义

=head4 字段内容：

    "conclusions":
	{
		"text":
			{
				"content":"文本消息内容"
			},
			"image": 
			{
				"media_id": "MEDIA_ID",
				"pic_url": "http://p.qpic.cn/pic_wework/XXXXX"
			},
			"link": 
			{
				"title": "消息标题",
				"picurl": "https://example.pic.com/path",
				"desc": "消息描述",
				"url": "https://example.link.com/path"
			},
			"miniprogram": 
			{
				"title": "消息标题",
				"pic_media_id": "MEDIA_ID",
				"appid": "wx8bd80126147dfAAA",
				"page": "/path/index"
			}
	   }
	}

=head4 参数说明

	参数	说明
	text.content	消息文本内容,最长为4000字节
	image.media_id	图片的media_id
	image.pic_url	图片的url
	link.title	图文消息标题，最长为128字节
	link.picurl	图文消息封面的url
	link.desc	图文消息的描述，最长为512字节
	link.url	图文消息的链接
	miniprogram.title	小程序消息标题，最长为64字节
	miniprogram.pic_media_id	小程序消息封面的mediaid，封面图建议尺寸为520*416
	miniprogram.appid	小程序appid，必须是关联到企业的小程序应用
	miniprogram.page	小程序page路径

text、image、link和miniprogram四者不能同时为空；
text与另外三者可以同时发送，此时将会以两条消息的形式触达客户;
image、link和miniprogram只能有一个，如果三者同时填，则按image、link、miniprogram的优先顺序取参，也就是说，如果image与link同时传值，则只有image生效;
media_id可以通过素材管理接口获得;
构造结束语使用image消息时，只能填写meida_id字段,获取含有image结构的联系我方式时，返回pic_url字段。

=cut

sub close_temp_chat {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/close_temp_chat?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token);

获取客户列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92113>

=head3 请求说明：

企业可通过此接口获取指定成员添加的客户列表。客户是指配置了客户联系功能的成员所添加的外部联系人。没有配置客户联系功能的成员，所添加的外部联系人将不会作为客户返回。

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	是	企业成员的userid

=head4 权限说明：

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）；
第三方应用需具有“企业客户权限->客户基础信息”权限
第三方/自建应用只能获取到可见范围内的配置了客户联系功能的成员。

=head3 RETURN 返回结果：

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "external_userid":
	   [
		"woAJ2GCAAAXtWyujaWJHDDGi0mACAAA",
		   "wmqfasd1e1927831291723123109rAAA"
	   ]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	external_userid	外部联系人的userid列表

=cut

sub list {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $userid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/list?access_token=$access_token&userid=$userid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token);

获取客户详情

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92114>

=head3 请求说明：

企业可通过此接口，根据外部联系人的userid（如何获取?），拉取客户详情。

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    external_userid	是	外部联系人的userid，注意不是企业成员的帐号
	cursor	否	上次请求返回的next_cursor
	
=head4 权限说明：

企业需要使用系统应用“客户联系”或配置到“可调用应用”列表中的自建应用的secret所获取的accesstoken来调用（accesstoken如何获取？）；
第三方应用需具有“企业客户权限->客户基础信息”权限
第三方/自建应用调用时，返回的跟进人follow_user仅包含应用可见范围之内的成员。
当客户在企业内的跟进人超过500人时需要使用cursor参数进行分页获取

=head3 RETURN 返回结果：

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "external_contact":
	   {
			"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACHAAA",
			"name":"李四",
			"position":"Manager",
			"avatar":"http://p.qlogo.cn/bizmail/IcsdgagqefergqerhewSdage/0",
			"corp_name":"腾讯",
			"corp_full_name":"腾讯科技有限公司",
			"type":2,
			"gender":1,
			"unionid":"ozynqsulJFCZ2z1aYeS8h-nuasdAAA",
			"external_profile":
			{
				 "external_attr":
				  [
					{
					  "type":0,
					  "name":"文本名称",
					   "text":
						{
						   "value":"文本"
						}
					},
					{
					  "type":1,
					  "name":"网页名称",
					  "web":
					  {
						  "url":"http://www.test.com",
						  "title":"标题"
					  }
					},
					{
					  "type":2,
					  "name":"测试app",
					  "miniprogram":
					  {
						  "appid": "wx8bd80126147df384",
						  "pagepath": "/index",
						  "title": "my miniprogram"
					  }
					}
				  ]
		  }
		 },
		 "follow_user":
		  [
			{
			  "userid":"rocky",
			  "remark":"李部长",
			  "description":"对接采购事务",
			  "createtime":1525779812,
			  "tags":
			   [
				   {
					  "group_name":"标签分组名称",
					  "tag_name":"标签名称",
					  "tag_id":"etAJ2GCAAAXtWyujaWJHDDGi0mACHAAA",
					  "type":1
				   },
				   {
					  "group_name":"标签分组名称",
					  "tag_name":"标签名称",
					  "type":2
				   },
				   {
					  "group_name":"标签分组名称",
					  "tag_name":"标签名称",
					  "tag_id":"stAJ2GCAAAXtWyujaWJHDDGi0mACHAAA",
					  "type":3
				   }
			   ],
			   "remark_corp_name":"腾讯科技",
			   "remark_mobiles":
				[
				  "13800000001",
				  "13000000002"
				],
			   "oper_userid":"rocky",
			   "add_way":1
			},
			{
			  "userid":"tommy",
			  "remark":"李总",
			  "description":"采购问题咨询",
			  "createtime":1525881637,
			  "state":"外联二维码1",
			  "oper_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACHAAA",
			   "add_way":3
			 }
		 ],
		 "next_cursor":"NEXT_CURSOR"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	external_userid	外部联系人的userid
	name	外部联系人的名称[注1]
	avatar	外部联系人头像，代开发自建应用需要管理员授权才可以获取，第三方不可获取，上游企业不可获取下游企业客户该字段
	type	外部联系人的类型，1表示该外部联系人是微信用户，2表示该外部联系人是企业微信用户
	gender	外部联系人性别 0-未知 1-男性 2-女性。第三方不可获取，上游企业不可获取下游企业客户该字段，返回值为0，表示未定义
	unionid	外部联系人在微信开放平台的唯一身份标识（微信unionid），通过此字段企业可将外部联系人与公众号/小程序用户关联起来。仅当联系人类型是微信用户，且企业绑定了微信开发者ID有此字段。查看绑定方法。第三方不可获取，上游企业不可获取下游企业客户的unionid字段
	position	外部联系人的职位，如果外部企业或用户选择隐藏职位，则不返回，仅当联系人类型是企业微信用户时有此字段
	corp_name	外部联系人所在企业的简称，仅当联系人类型是企业微信用户时有此字段
	corp_full_name	外部联系人所在企业的主体名称，仅当联系人类型是企业微信用户时有此字段
	external_profile	外部联系人的自定义展示信息，可以有多个字段和多种类型，包括文本，网页和小程序，仅当联系人类型是企业微信用户时有此字段，字段详情见对外属性；
	follow_user.userid	添加了此外部联系人的企业成员userid
	follow_user.remark	该成员对此外部联系人的备注
	follow_user.description	该成员对此外部联系人的描述
	follow_user.createtime	该成员添加此外部联系人的时间
	follow_user.tags.group_name	该成员添加此外部联系人所打标签的分组名称（标签功能需要企业微信升级到2.7.5及以上版本）
	follow_user.tags.tag_name	该成员添加此外部联系人所打标签名称
	follow_user.tags.type	该成员添加此外部联系人所打标签类型, 1-企业设置，2-用户自定义，3-规则组标签（仅系统应用返回）
	follow_user.tags.tag_id	该成员添加此外部联系人所打企业标签的id，用户自定义类型标签（type=2）不返回
	follow_user.remark_corp_name	该成员对此客户备注的企业名称
	follow_user.remark_mobiles	该成员对此客户备注的手机号码，代开发自建应用需要管理员授权才可以获取，第三方不可获取，上游企业不可获取下游企业客户该字段
	follow_user.add_way	该成员添加此客户的来源，具体含义详见来源定义
	follow_user.oper_userid	发起添加的userid，如果成员主动添加，为成员的userid；如果是客户主动添加，则为客户的外部联系人userid；如果是内部成员共享/管理员分配，则为对应的成员/管理员userid
	follow_user.state	企业自定义的state参数，用于区分客户具体是通过哪个「联系我」添加，由企业通过创建「联系我」方式指定
	next_cursor	分页的cursor，当跟进人多于500人时返回

注1：如果是微信用户，则返回其微信昵称。如果是企业微信联系人，则返回其设置对外展示的别名或实名

=head3 来源定义

add_way表示添加客户的来源，有固定的值，而state表示此客户的渠道，可以由企业进行自定义的配置，请注意二者的不同。

	值	含义
	0	未知来源
	1	扫描二维码
	2	搜索手机号
	3	名片分享
	4	群聊
	5	手机通讯录
	6	微信联系人
	8	安装第三方应用时自动添加的客服人员
	9	搜索邮箱
	10	视频号主页添加
	201	内部成员共享
	202	管理员/负责人分配

=cut

sub get {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $userid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get?access_token=$access_token&userid=$userid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 remark(access_token, hash);

修改客户备注信息

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92115>

=head3 请求说明：

将指定的企业成员和客户之前的临时会话断开，断开前会自动下发已配置的结束语。

=head4 请求包结构体为：

	{
	   "userid":"zhangsan",
	   "external_userid":"woAJ2GCAAAd1asdasdjO4wKmE8Aabj9AAA",
	   "remark":"备注信息",
	   "description":"描述信息",
	   "remark_company":"腾讯科技",
	   "remark_mobiles":[
			"13800000001",
			"13800000002"
	   ],
	   "remark_pic_mediaid":"MEDIAID"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	userid	是	企业成员的userid
	external_userid	是	外部联系人userid
	remark	否	此用户对外部联系人的备注，最多20个字符
	description	否	此用户对外部联系人的描述，最多150个字符
	remark_company	否	此用户对外部联系人备注的所属公司名称，最多20个字符
	remark_mobiles	否	此用户对外部联系人备注的手机号
	remark_pic_mediaid	否	备注图片的mediaid

remark_company只在此外部联系人为微信用户时有效。
remark，description，remark_company，remark_mobiles和remark_pic_mediaid不可同时为空。
如果填写了remark_mobiles，将会覆盖旧的备注手机号。
如果要清除所有备注手机号,请在remark_mobiles填写一个空字符串("")。
remark_pic_mediaid可以通过素材管理接口获得。

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需具有“企业客户权限->客户基础信息”权限

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub remark {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/remark?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_corp_tag_list(access_token, hash);

获取企业标签库

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92117#获取企业标签库>

=head3 请求说明：

企业可通过此接口获取企业客户标签详情。

=head4 请求包结构体为：

	{
		"tag_id": 
		[
			"etXXXXXXXXXX",
			"etYYYYYYYYYY"
		],
		"group_id":
		[
			"etZZZZZZZZZZZZZ",
			"etYYYYYYYYYYYYY"
		]
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	tag_id	否	要查询的标签id
	group_id	否	要查询的标签组id，返回该标签组以及其下的所有标签信息

若tag_id和group_id均为空，则返回所有标签。
同时传递tag_id和group_id时，忽略tag_id，仅以group_id作为过滤条件。

=head3 权限说明

对于获取企业标签库接口，企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方可读写企业标签，但需有企业客户权限。特别的，添加/编辑/删除客户标签，需具有“企业客户权限->客户联系->管理企业客户标签”权限
自建/第三方应用仅能编辑和删除本应用创建的标签，使用“客户联系”所获取的accesstoken进行调用则可编辑/删除所有的标签和标签组。

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"tag_group": [{
			"group_id": "TAG_GROUPID1",
			"group_name": "GOURP_NAME",
			"create_time": 1557838797,
			"order": 1,
			"deleted": false,
			"tag": [{
					"id": "TAG_ID1",
					"name": "NAME1",
					"create_time": 1557838797,
					"order": 1,
					"deleted": false
				},
				{
					"id": "TAG_ID2",
					"name": "NAME2",
					"create_time": 1557838797,
					"order": 2,
					"deleted": true
				}
			]
		}]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	tag_group	标签组列表
	tag_group.group_id	标签组id
	tag_group.group_name	标签组名称
	tag_group.create_time	标签组创建时间
	tag_group.order	标签组排序的次序值，order值大的排序靠前。有效的值范围是[0, 2^32)
	tag_group.deleted	标签组是否已经被删除，只在指定tag_id进行查询时返回
	tag_group.tag	标签组内的标签列表
	tag_group.tag.id	标签id
	tag_group.tag.name	标签名称
	tag_group.tag.create_time	标签创建时间
	tag_group.tag.order	标签排序的次序值，order值大的排序靠前。有效的值范围是[0, 2^32)
	tag_group.tag.deleted	标签是否已经被删除，只在指定tag_id/group_id进行查询时返回

=cut

sub get_corp_tag_list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_corp_tag_list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 add_corp_tag(access_token, hash);

添加企业客户标签

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92117#添加企业客户标签>

=head3 请求说明：

企业可通过此接口向客户标签库中添加新的标签组和标签，每个企业最多可配置3000个企业标签。

=head4 请求包结构体为：

	{
		"group_id": "GROUP_ID",
		"group_name": "GROUP_NAME",
		"order": 1,
		"tag": [{
				"name": "TAG_NAME_1",
				"order": 1
			},
			{
				"name": "TAG_NAME_2",
				"order": 2
			}
		],
		 "agentid" : 1000014
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	group_id	否	标签组id
	group_name	否	标签组名称，最长为30个字符
	order	否	标签组次序值。order值大的排序靠前。有效的值范围是[0, 2^32)
	tag.name	是	添加的标签名称，最长为30个字符
	tag.order	否	标签次序值。order值大的排序靠前。有效的值范围是[0, 2^32)
	agentid	否	授权方安装的应用agentid。仅旧的第三方多应用套件需要填此参数

注意:
如果要向指定的标签组下添加标签，需要填写group_id参数；如果要创建一个全新的标签组以及标签，则需要通过group_name参数指定新标签组名称，如果填写的groupname已经存在，则会在此标签组下新建标签。
如果填写了group_id参数，则group_name和标签组的order参数会被忽略。
不支持创建空标签组。
标签组内的标签不可同名，如果传入多个同名标签，则只会创建一个。

=head3 权限说明

对于获取企业标签库接口，企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方可读写企业标签，但需有企业客户权限。特别的，添加/编辑/删除客户标签，需具有“企业客户权限->客户联系->管理企业客户标签”权限
自建/第三方应用仅能编辑和删除本应用创建的标签，使用“客户联系”所获取的accesstoken进行调用则可编辑/删除所有的标签和标签组。

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"tag_group": {
			"group_id": "TAG_GROUPID1",
			"group_name": "GOURP_NAME",
			"create_time": 1557838797,
			"order": 1,
			"tag": [{
					"id": "TAG_ID1",
					"name": "NAME1",
					"create_time": 1557838797,
					"order": 1
				},
				{
					"id": "TAG_ID2",
					"name": "NAME2",
					"create_time": 1557838797,
					"order": 2
				}
			]
		}
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	tag_group.group_id	标签组id
	tag_group.group_name	标签组名称
	tag_group.create_time	标签组创建时间
	tag_group.order	标签组次序值。order值大的排序靠前。有效的值范围是[0, 2^32)
	tag_group.tag	标签组内的标签列表
	tag_group.tag.id	新建标签id
	tag_group.tag.name	新建标签名称
	tag_group.tag.create_time	标签创建时间
	tag_group.tag.order	标签次序值。order值大的排序靠前。有效的值范围是[0, 2^32)

=cut

sub add_corp_tag {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/add_corp_tag?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 edit_corp_tag(access_token, hash);

编辑企业客户标签

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92117#编辑企业客户标签>

=head3 请求说明：

企业可通过此接口编辑客户标签/标签组的名称或次序值。

=head4 请求包结构体为：

	{
		"id": "TAG_ID",
		"name": "NEW_TAG_NAME",
		"order": 1,
		"agentid" : 1000014
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	id	是	标签或标签组的id
	name	否	新的标签或标签组名称，最长为30个字符
	order	否	标签/标签组的次序值。order值大的排序靠前。有效的值范围是[0, 2^32)
	agentid	否	授权方安装的应用agentid。仅旧的第三方多应用套件需要填此参数

注意:修改后的标签组不能和已有的标签组重名，标签也不能和同一标签组下的其他标签重名。

=head3 权限说明

对于获取企业标签库接口，企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方可读写企业标签，但需有企业客户权限。特别的，添加/编辑/删除客户标签，需具有“企业客户权限->客户联系->管理企业客户标签”权限
自建/第三方应用仅能编辑和删除本应用创建的标签，使用“客户联系”所获取的accesstoken进行调用则可编辑/删除所有的标签和标签组。

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub edit_corp_tag {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/edit_corp_tag?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del_corp_tag(access_token, hash);

删除企业客户标签

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92117#删除企业客户标签>

=head3 请求说明：

企业可通过此接口删除客户标签库中的标签，或删除整个标签组。

=head4 请求包结构体为：

	{
		"tag_id": [
			"TAG_ID_1",
			"TAG_ID_2"
		],
		"group_id": [
			"GROUP_ID_1",
			"GROUP_ID_2"
		],
		"agentid" : 1000014
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	tag_id	否	标签的id列表
	group_id	否	标签组的id列表
	agentid	否	授权方安装的应用agentid。仅旧的第三方多应用套件需要填此参数

tag_id和group_id不可同时为空。
如果一个标签组下所有的标签均被删除，则标签组会被自动删除。

=head3 权限说明

对于获取企业标签库接口，企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方可读写企业标签，但需有企业客户权限。特别的，添加/编辑/删除客户标签，需具有“企业客户权限->客户联系->管理企业客户标签”权限
自建/第三方应用仅能编辑和删除本应用创建的标签，使用“客户联系”所获取的accesstoken进行调用则可编辑/删除所有的标签和标签组。

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub del_corp_tag {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/del_corp_tag?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_strategy_tag_list(access_token, hash);

获取指定规则组下的企业客户标签

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94882#获取指定规则组下的企业客户标签>

=head3 请求说明：

企业可通过此接口获取某个规则组内的企业客户标签详情。

=head4 请求包结构体为：

	{
		"strategy_id":1,
		"tag_id":
		[
			"etXXXXXXXXXX",
			"etYYYYYYYYYY"
		],
		"group_id":
		[
			"etZZZZZZZZZZZZZ",
			"etYYYYYYYYYYYYY"
		]
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	strategy_id	否	规则组id
	tag_id	否	要查询的标签id
	group_id	否	要查询的标签组id，返回该标签组以及其下的所有标签信息

若tag_id和group_id均为空，则返回所有标签。
同时传递tag_id和group_id时，忽略tag_id，仅以group_id作为过滤条件。

=head3 权限说明

仅可使用“客户联系”secret获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"tag_group": [{
			"group_id": "TAG_GROUPID1",
			"group_name": "GOURP_NAME",
			"create_time": 1557838797,
			"order": 1,
			"strategy_id":1,
			"tag": [{
					"id": "TAG_ID1",
					"name": "NAME1",
					"create_time": 1557838797,
					"order": 1
				},
				{
					"id": "TAG_ID2",
					"name": "NAME2",
					"create_time": 1557838797,
					"order": 2
				}
			]
		}]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	tag_group	标签组列表
	tag_group.group_id	标签组id
	tag_group.group_name	标签组名称
	tag_group.create_time	标签组创建时间
	tag_group.order	标签组排序的次序值，order值大的排序靠前。有效的值范围是[0, 2^32)
	tag_group.strategy_id	标签组所属的规则组id
	tag_group.tag	标签组内的标签列表
	tag_group.tag.id	标签id
	tag_group.tag.name	标签名称
	tag_group.tag.create_time	标签创建时间
	tag_group.tag.order	标签排序的次序值，order值大的排序靠前。有效的值范围是[0, 2^32)

=cut

sub get_strategy_tag_list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_strategy_tag_list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 add_strategy_tag(access_token, hash);

为指定规则组创建企业客户标签

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94882#为指定规则组创建企业客户标签>

=head3 请求说明：

企业可通过此接口向规则组中添加新的标签组和标签，每个企业的企业标签和规则组标签合计最多可配置3000个。注意，仅可在一级规则组下添加标签。

=head4 请求包结构体为：

	{
		"strategy_id":1,
		"group_id": "GROUP_ID",
		"group_name": "GROUP_NAME",
		"order": 1,
		"tag": [{
				"name": "TAG_NAME_1",
				"order": 1
			},
			{
				"name": "TAG_NAME_2",
				"order": 2
			}
		]
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	strategy_id	是	规则组id
	group_id	否	标签组id
	group_name	否	标签组名称，最长为30个字符
	order	否	标签组次序值。order值大的排序靠前。有效的值范围是[0, 2^32)
	tag.name	是	添加的标签名称，最长为30个字符
	tag.order	否	标签次序值。order值大的排序靠前。有效的值范围是[0, 2^32)

注意:
如果填写了group_id参数，则group_name和标签组的order参数会被忽略。
如果填写的group_name和此规则组下的其他标签组同名，则会将相关标签加入已存在的同名标签组下
不支持创建空标签组。
标签组内的标签不可同名，如果传入多个同名标签，则只会创建一个。

=head3 权限说明

仅可使用“客户联系”secret获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"tag_group": {
			"group_id": "TAG_GROUPID1",
			"group_name": "GOURP_NAME",
			"create_time": 1557838797,
			"order": 1,
			"tag": [{
					"id": "TAG_ID1",
					"name": "NAME1",
					"create_time": 1557838797,
					"order": 1
				},
				{
					"id": "TAG_ID2",
					"name": "NAME2",
					"create_time": 1557838797,
					"order": 2
				}
			]
		}
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	tag_group.group_id	标签组id
	tag_group.group_name	标签组名称
	tag_group.create_time	标签组创建时间
	tag_group.order	标签组次序值。order值大的排序靠前。有效的值范围是[0, 2^32)
	tag_group.tag	标签组内的标签列表
	tag_group.tag.id	新建标签id
	tag_group.tag.name	新建标签名称
	tag_group.tag.create_time	标签创建时间
	tag_group.tag.order	标签次序值。order值大的排序靠前。有效的值范围是[0, 2^32)

=cut

sub add_strategy_tag {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/add_strategy_tag?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 edit_strategy_tag(access_token, hash);

编辑指定规则组下的企业客户标签

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94882#编辑指定规则组下的企业客户标签>

=head3 请求说明：

企业可通过此接口编辑指定规则组下的客户标签/标签组的名称或次序值，但不可重新指定标签/标签组所属规则组。

=head4 请求包结构体为：

	{
		"id": "TAG_ID",
		"name": "NEW_TAG_NAME",
		"order": 1
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	id	是	标签或标签组的id
	name	否	新的标签或标签组名称，最长为30个字符
	order	否	标签/标签组的次序值。order值大的排序靠前。有效的值范围是[0, 2^32)

注意:修改后的标签组不能和已有的标签组重名，标签也不能和同一标签组下的其他标签重名。

=head3 权限说明

仅可使用“客户联系”secret获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub edit_strategy_tag {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/edit_strategy_tag?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del_strategy_tag(access_token, hash);

删除指定规则组下的企业客户标签

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94882#删除指定规则组下的企业客户标签>

=head3 请求说明：

企业可通过此接口删除某个规则组下的标签，或删除整个标签组。

=head4 请求包结构体为：

	{
		"tag_id": [
			"TAG_ID_1",
			"TAG_ID_2"
		],
		"group_id": [
			"GROUP_ID_1",
			"GROUP_ID_2"
		],
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	tag_id	否	标签的id列表
	group_id	否	标签组的id列表

tag_id和group_id不可同时为空。
如果一个标签组下所有的标签均被删除，则标签组会被自动删除。

=head3 权限说明

仅可使用“客户联系”secret获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub del_strategy_tag {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/del_strategy_tag?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 mark_tag(access_token, hash);

编辑客户企业标签

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92118>

=head3 请求说明：

企业可通过此接口为指定成员的客户添加上由企业统一配置的标签。

=head4 请求包结构体为：

	{
		"userid":"zhangsan",
		"external_userid":"woAJ2GCAAAd1NPGHKSD4wKmE8Aabj9AAA",
		"add_tag":["TAGID1","TAGID2"],
		"remove_tag":["TAGID3","TAGID4"]
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	userid	是	添加外部联系人的userid
	external_userid	是	外部联系人userid
	add_tag	否	要标记的标签列表
	remove_tag	否	要移除的标签列表

请确保external_userid是userid的外部联系人。
add_tag和remove_tag不可同时为空。
同一个标签组下现已支持多个标签

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需具有“企业客户权限->客户基础信息”权限

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub mark_tag {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/mark_tag?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 transfer_customer(access_token, hash);

分配在职成员的客户

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92125>

=head3 请求说明：

企业可通过此接口，转接在职成员的客户给其他成员。

=head4 请求包结构体为：

	{
	   "handover_userid": "zhangsan",
	   "takeover_userid": "lisi",
	   "external_userid":
	   [
		"woAJ2GCAAAXtWyujaWJHDDGi0mACAAAA",
		"woAJ2GCAAAXtWyujaWJHDDGi0mACBBBB"
		],
	   "transfer_success_msg":"您好，您的服务已升级，后续将由我的同事李四@腾讯接替我的工作，继续为您服务。"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	handover_userid	是	原跟进成员的userid
	takeover_userid	是	接替成员的userid
	external_userid	是	客户的external_userid列表，每次最多分配100个客户
	transfer_success_msg	否	转移成功后发给客户的消息，最多200个字符，不填则使用默认文案

external_userid必须是handover_userid的客户（即配置了客户联系功能的成员所添加的联系人）。
为保障客户服务体验，90个自然日内，在职成员的每位客户仅可被转接2次。

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需拥有“企业客户权限->客户联系->在职继承”权限
接替成员必须在此第三方应用或自建应用的可见范围内。
接替成员需要配置了客户联系功能。
接替成员需要在企业微信激活且已经过实名认证。

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "customer":
		[
			{
				"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACAAAA",
				"errcode":40096
			},
			{
				"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACBBBB",
				"errcode":0
			}
		]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	customer.external_userid	客户的external_userid
	customer.errcode	对此客户进行分配的结果, 具体可参考全局错误码, 0表示成功发起接替,待24小时后自动接替,并不代表最终接替成功

原接口分配在职或离职成员的客户后续将不再更新维护，请使用新接口

=cut

sub transfer_customer {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/transfer_customer?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 transfer_result(access_token, hash);

查询客户接替状态

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94088>

=head3 请求说明：

企业和第三方可通过此接口查询在职成员的客户转接情况。

=head4 请求包结构体为：

	{
	   "handover_userid": "zhangsan",
	   "takeover_userid": "lisi",
	   "cursor":"CURSOR"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	handover_userid	是	原添加成员的userid
	takeover_userid	是	接替成员的userid
	cursor	否	分页查询的cursor，每个分页返回的数据不会超过1000条；不填或为空表示获取第一个分页；

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需拥有“企业客户权限->客户联系->在职继承”权限
接替成员必须在此第三方应用或自建应用的可见范围内。

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "customer":
	  [
	  {
		"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACCCC",
		"status":1,
		"takeover_time":1588262400
	  },
	  {
		"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACBBBB",
		"status":2,
		"takeover_time":1588482400
	  },
	  {
		"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACAAAA",
		"status":3,
		"takeover_time":0
	  }
	  ],
	  "next_cursor":"NEXT_CURSOR"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	customer.external_userid	转接客户的外部联系人userid
	customer.status	接替状态， 1-接替完毕 2-等待接替 3-客户拒绝 4-接替成员客户达到上限 5-无接替记录
	customer.takeover_time	接替客户的时间，如果是等待接替状态，则为未来的自动接替时间
	next_cursor	下个分页的起始cursor

原接口查询客户接替结果后续将不再更新维护，请使用新接口

=cut

sub transfer_result {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/transfer_result?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_unassigned_list(access_token, hash);

获取待分配的离职成员列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92124>

=head3 请求说明：

企业和第三方可通过此接口，获取所有离职成员的客户列表，并可进一步调用分配离职成员的客户接口将这些客户重新分配给其他企业成员。

=head4 请求包结构体为：

	{
	  "page_id":0,
	  "cursor":"",
	  "page_size":100
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	page_id	否	分页查询，要查询页号，从0开始
	page_size	否	每次返回的最大记录数，默认为1000，最大值为1000
	cursor	否	分页查询游标，字符串类型，适用于数据量较大的情况，如果使用该参数则无需填写page_id，该参数由上一次调用返回

注意:
当page_id为1，page_size为100时，表示取第101到第200条记录。
page_id和page_size参数仅适用于记录数小于五万条的情况,即 page_id*page_size < 50000；
如果记录数大于五万，则需要使用cursor参数。

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需拥有“企业客户权限->客户联系->分配离职成员的客户”权限

=head3 RETURN 返回结果

    {
	   "errcode":0,
	   "errmsg":"ok",
	   "info":[
	   {
			"handover_userid":"zhangsan",
			"external_userid":"woAJ2GCAAAd4uL12hdfsdasassdDmAAAAA",
			"dimission_time":1550838571
	   },
	   {
			"handover_userid":"lisi",
			"external_userid":"wmAJ2GCAAAzLTI123ghsdfoGZNqqAAAA",
			"dimission_time":1550661468
		}
	 ],
	 "is_last":false,
	 "next_cursor":"aSfwejksvhToiMMfFeIGZZ"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	info.handover_userid	离职成员的userid
	info.external_userid	外部联系人userid
	info.dimission_time	成员离职时间
	is_last	是否是最后一条记录
	next_cursor	分页查询游标,已经查完则返回空("")，使用page_id作为查询参数时不返回

=cut

sub get_unassigned_list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_unassigned_list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 opengid_to_chatid(access_token, hash);

客户群opengid转换

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94822>

=head3 请求说明：

用户在微信里的客户群里打开小程序时，某些场景下可以获取到群的opengid，如果该群是企业微信的客户群，则企业或第三方可以调用此接口将一个opengid转换为客户群chat_id

=head4 请求包结构体为：

	{
	  "opengid":"oAAAAAAA"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	opengid	是	小程序在微信获取到的群ID，参见wx.getGroupEnterInfo

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“企业客户权限->客户基础信息”权限
对于第三方/自建应用，群主必须在应用的可见范围
仅支持企业服务人员创建的客户群
仅可转换出自己企业下的客户群chat_id

=head3 RETURN 返回结果

    ｛
	 "errcode":0,
	 "errmsg":"ok",
	 "chat_id":"ooAAAAAAAAAAA"
	｝

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	chat_id	客户群ID，可以用来调用获取客户群详情

=cut

sub opengid_to_chatid {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/opengid_to_chatid?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 add_moment_task(access_token, hash);

企业发表内容到客户的朋友圈-创建发表任务

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95094#创建发表任务>

=head3 请求说明：

企业和第三方应用可通过该接口创建客户朋友圈的发表任务。

=head4 请求包结构体为：

	{
		"text": {
			"content": "文本消息内容"
		},
		"attachments": [
			{
				"msgtype": "image",
				"image": {
					"media_id": "MEDIA_ID"
				}
			},
			{
				"msgtype": "video",
				"video": {
					"media_id": "MEDIA_ID"
				}
			},
			{
				"msgtype": "link",
				"link": {
					"title": "消息标题",
					"url": "https://example.link.com/path",
					"media_id": "MEDIA_ID"
				}
			}
		],
		"visible_range":{
			"sender_list":{
				"user_list":["zhangshan","lisi"],
				"department_list":[2,3]
			},
			"external_contact_list":{
				"tag_list":[ "etXXXXXXXXXX", "etYYYYYYYYYY"]
			}
		}
	}

=head4 参数说明：

    参数	必须	说明
    access_token		调用接口凭证
	visible_range	否	指定的发表范围；若未指定，则表示执行者为应用可见范围内所有成员
	sender_list	否	发表任务的执行者列表，详见下文的“可见范围说明”
	sender_list.user_list	否	发表任务的执行者用户列表，最多支持10万个
	sender_list.department_list	否	发表任务的执行者部门列表
	external_contact_list	否	可见到该朋友圈的客户列表，详见下文的“可见范围说明”
	external_contact_list.tag_list	否	可见到该朋友圈的客户标签列表
	text	否	文本消息
	text.content	否	消息文本内容，不能与附件同时为空，最多支持传入2000个字符，若超出长度报错'invalid text size'
	attachments	否	附件，不能与text.content同时为空，最多支持9个图片类型，或者1个视频，或者1个链接。类型只能三选一，若传了不同类型，报错'invalid attachments msgtype'
	msgtype	是	附件类型，可选image、link或者video
	image	否	图片消息附件。普通图片：建议不超过 1440 x 1080。图片不超过10M。最多支持传入9个；超过9个报错'invalid attachments size'
	image.media_id	是	图片的素材id。可通过上传附件资源接口获得
	link	否	图文消息附件。只支持1个；若超过1个报错'invalid attachments size'
	link.title	否	图文消息标题，最多64个字节
	link.url	是	图文消息链接
	link.media_id	是	图片链接封面，普通图片：建议不超过 1440 x 1080，可通过上传附件资源接口获得
	video	否	视频消息附件，建议不超过 1280 x 720，帧率 30 FPS，视频码率 1.67 Mbps，最长不超过30S，最大不超过10MB。只支持1个；若超过1个报错'invalid attachments size'
	video.media_id	是	视频的素材id，未填写报错"invalid msg"。可通过上传附件资源接口获得

=head3 可见范围说明

visible_range，分以下几种情况：

若只指定sender_list，则可见的客户范围为该部分执行者的客户，目前执行者支持传userid与部门id列表，注意不在应用可见范围内的执行者会被忽略。
若只指定external_contact_list，即指定了可见该朋友圈的目标客户，此时会将该发表任务推给这些目标客户的应用可见范围内的跟进人。
若同时指定sender_list以及external_contact_list，会将该发表任务推送给sender_list指定的且在应用可见范围内的执行者，执行者发表后仅external_contact_list指定的客户可见。
若未指定visible_range，则可见客户的范围为该应用可见范围内执行者的客户，执行者为应用可见范围内所有成员。
注：若指定external_contact_list列表，则该条朋友圈为部分可见；否则为公开

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
自建应用调用，只会返回应用可见范围内用户的发送情况。
第三方应用或代开发自建应用调用需要企业授权客户朋友圈下发表到成员客户的朋友圈的权限
企业每分钟创建朋友圈的频率：10条/分钟

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok",
		"jobid":"xxxx"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	jobid	异步任务id，最大长度为64字节，24小时有效；可使用获取发表朋友圈任务结果查询任务状态

=cut

sub add_moment_task {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/add_moment_task?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_moment_task_result(access_token, hash);

企业发表内容到客户的朋友圈-获取任务创建结果

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95094#获取任务创建结果>

=head3 请求说明：

由于发表任务的创建是异步执行的，应用需要再调用该接口以获取创建的结果。

=head4 参数说明：

    参数	必须	说明
    access_token		调用接口凭证
	jobid	是	异步任务id，最大长度为64字节，由创建发表内容到客户朋友圈任务接口获取

=head3 权限说明

只能查询已经提交过的历史任务。

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"status": 1,
		"type": "add_moment_task",
		"result": {
			"errcode":0,
			"errmsg":"ok"
			"moment_id":"xxxx",
			"invalid_sender_list":{
				"user_list":["zhangshan","lisi"],
				"department_list":[2,3]
			},
			"invalid_external_contact_list":{
				"tag_list":["xxx"]
			}
		}
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	status	任务状态，整型，1表示开始创建任务，2表示正在创建任务中，3表示创建任务已完成
	type	操作类型，字节串，此处固定为add_moment_task
	result	详细的处理结果。当任务完成后此字段有效
	result.errcode	返回码
	result.errmsg	对返回码的文本描述内容
	result.moment_id	朋友圈id，可通过获取客户朋友圈企业发表的列表接口获取朋友圈企业发表的列表
	result.invalid_sender_list	不合法的执行者列表，包括不存在的id以及不在应用可见范围内的部门或者成员

=cut

sub get_moment_task_result {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $jobid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_moment_task_result?access_token=$access_token&jobid=$jobid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_moment_list(access_token, hash);

获取客户朋友圈全部的发表记录-获取企业全部的发表列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93333#获取企业全部的发表列表>

=head3 请求说明：

企业和第三方应用可通过该接口获取企业全部的发表内容。企业和第三方应用可通过该接口创建客户朋友圈的发表任务。

=head4 请求包结构体为：

	{
	   "start_time":1605000000,
	   "end_time":1605172726,
	   "creator":"zhangsan",
	   "filter_type":1,
	   "cursor":"CURSOR",
	   "limit":10
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	start_time	是	朋友圈记录开始时间。Unix时间戳
	end_time	是	朋友圈记录结束时间。Unix时间戳
	creator	否	朋友圈创建人的userid
	filter_type	否	朋友圈类型。0：企业发表 1：个人发表 2：所有，包括个人创建以及企业创建，默认情况下为所有类型
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用可不填
	limit	否	返回的最大记录数，整型，最大值20，默认值20，超过最大值时取默认值

=head3 补充说明:

朋友圈记录的起止时间间隔不能超过30天
在朋友圈发表列表中，按时间只能取到(start_time, end_time)范围内的数据
web管理端会展示企业成员所有已经发表的朋友圈（包括已经删除朋友圈），而API接口将不会返回已经删除的朋友圈记录

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
自建应用调用，只会返回应用可见范围内用户的发送情况。
第三方应用调用需要企业授权客户朋友圈下获取企业全部的发表记录的权限

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok",
		"next_cursor":"CURSOR",
		"moment_list":[
			{
				"moment_id":"momxxx",
				"creator":"xxxx",
				"create_time":"xxxx",
				"create_type":1,
				"visible_type":1,
				"text":{
					"content":"test"
				},
				"image":[
						{"media_id":"WWCISP_xxxxx"}
				],
				"video":{
					"media_id":"WWCISP_xxxxx",
					"thumb_media_id":"WWCISP_xxxxx"
				},
				"link":{
					"title":"腾讯网-QQ.COM",
					"url":"https://www.qq.com"
				},
				"location":{
					"latitude":"23.10647",
					"longitude":"113.32446",
					"name":"广州市 · 广州塔"
				}
			}
		]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	next_cursor	分页游标，下次请求时填写以获取之后分页的记录，如果已经没有更多的数据则返回空
	moment_list	朋友圈列表
	moment_list.moment_id	朋友圈id
	moment_list.creator	朋友圈创建者userid，企业发表内容到客户的朋友圈接口创建的朋友圈不再返回该字段
	moment_list.create_time	创建时间
	moment_list.create_type	朋友圈创建来源。0：企业 1：个人
	moment_list.visible_type	可见范围类型。0：部分可见 1：公开
	moment_list.text.content	文本消息结构
	moment_list.image.media_id	图片的media_id列表，可以通过获取临时素材下载资源
	moment_list.video.media_id	视频media_id，可以通过获取临时素材下载资源
	moment_list.video.thumb_media_id	视频封面media_id，可以通过获取临时素材下载资源
	moment_list.link.title	网页链接标题
	moment_list.link.url	网页链接url
	moment_list.location.latitude	地理位置纬度
	moment_list.location.longitude	地理位置经度
	moment_list.location.name	地理位置名称

=cut

sub get_moment_list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_moment_list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_moment_task(access_token, hash);

获取客户朋友圈全部的发表记录-获取客户朋友圈企业发表的列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93333#获取客户朋友圈企业发表的列表>

=head3 请求说明：

企业和第三方应用可通过该接口获取企业发表的朋友圈成员执行情况

=head4 请求包结构体为：

	{
	   "moment_id":"momxxx",
	   "cursor":"CURSOR",
	   "limit":10
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	moment_id	是	朋友圈id,仅支持企业发表的朋友圈id
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用可不填
	limit	否	返回的最大记录数，整型，最大值1000，默认值500，超过最大值时取默认值

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
自建应用调用，只会返回应用可见范围内用户的发送情况。
第三方应用调用需要企业授权客户朋友圈下获取企业全部的发表记录的权限

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok",
		"next_cursor":"CURSOR",
		"task_list":[
			{
				"userid":"zhangsan",
				"publish_status":1
			}
		]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	next_cursor	分页游标，再下次请求时填写以获取之后分页的记录，如果已经没有更多的数据则返回空
	task_list	发表任务列表
	task_list.userid	发表成员用户userid
	task_list.publish_status	成员发表状态。0:未发表 1：已发表

=cut

sub get_moment_task {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_moment_task?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_moment_customer_list(access_token, hash);

获取客户朋友圈全部的发表记录-获取客户朋友圈发表时选择的可见范围

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93333#获取客户朋友圈发表时选择的可见范围>

=head3 请求说明：

企业和第三方应用可通过该接口获取客户朋友圈创建时，选择的客户可见范围

=head4 请求包结构体为：

	{
	   "moment_id":"momxxx",
	   "userid":"xxx",
	   "cursor":"CURSOR",
	   "limit":10
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	moment_id	是	朋友圈id
	userid	是	企业发表成员userid，如果是企业创建的朋友圈，可以通过获取客户朋友圈企业发表的列表获取已发表成员userid，如果是个人创建的朋友圈，创建人userid就是企业发表成员userid
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用可不填
	limit	否	返回的最大记录数，整型，最大值1000，默认值500，超过最大值时取默认值

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
自建应用调用，只会返回应用可见范围内用户的发送情况。
第三方应用调用需要企业授权客户朋友圈下获取企业全部的发表记录的权限

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok",
		"next_cursor":"CURSOR",
		"customer_list":[
			{
				"userid":"xxx",
				"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACCCC  "
			}
		]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	next_cursor	分页游标，再下次请求时填写以获取之后分页的记录，如果已经没有更多的数据则返回空
	customer_list	成员可见客户列表
	customer_list.userid	发表成员用户userid
	customer_list.external_userid	发送成功的外部联系人userid

=cut

sub get_moment_customer_list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_moment_customer_list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_moment_send_result(access_token, hash);

获取客户朋友圈全部的发表记录-获取客户朋友圈发表后的可见客户列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93333#获取客户朋友圈发表后的可见客户列表>

=head3 请求说明：

企业和第三方应用可通过该接口获取客户朋友圈发表后，可在微信朋友圈中查看的客户列表

=head4 请求包结构体为：

	{
	   "moment_id":"momxxx",
	   "userid":"xxx",
	   "cursor":"CURSOR",
	   "limit":100
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	moment_id	是	朋友圈id
	userid	是	企业发表成员userid，如果是企业创建的朋友圈，可以通过获取客户朋友圈企业发表的列表获取已发表成员userid，如果是个人创建的朋友圈，创建人userid就是企业发表成员userid
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用可不填
	limit	否	返回的最大记录数，整型，最大值5000，默认值3000，超过最大值时取默认值

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
自建应用调用，只会返回应用可见范围内用户的发送情况。
第三方应用调用需要企业授权客户朋友圈下获取企业全部的发表记录的权限

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok",
		"next_cursor":"CURSOR",
		"customer_list":[
			{
				"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACCCC"
			}
		]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	next_cursor	分页游标，再下次请求时填写以获取之后分页的记录，如果已经没有更多的数据则返回空
	customer_list	成员发送成功客户列表
	customer_list.external_userid	成员发送成功的外部联系人userid

=cut

sub get_moment_send_result {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_moment_send_result?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_moment_comments(access_token, hash);

获取客户朋友圈全部的发表记录-获取客户朋友圈的互动数据

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93333#获取客户朋友圈的互动数据>

=head3 请求说明：

企业和第三方应用可通过此接口获取客户朋友圈的互动数据。

=head4 请求包结构体为：

	{
	   "moment_id":"momxxx",
	   "userid":"xxx"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	moment_id	是	朋友圈id
	userid	是	企业发表成员userid，如果是企业创建的朋友圈，可以通过获取客户朋友圈企业发表的列表获取已发表成员userid，如果是个人创建的朋友圈，创建人userid就是企业发表成员userid

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
自建应用调用，只会返回应用可见范围内用户的发送情况。
第三方应用调用需要企业授权客户朋友圈下获取企业全部的发表记录的权限

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok",
		"comment_list":[
			{
				"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACAAAA ",
				"create_time":1605172726
			},
			{
				"userid":"zhangshan ",
				"create_time":1605172729
			}
		],
		"like_list":[
			{
				"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACBBBB ",
				"create_time":1605172726
			},
			{
				"userid":"zhangshan ",
				"create_time":1605172720
			}
		]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	comment_list	评论列表
	comment_list.external_userid	评论的外部联系人userid
	comment_list.userid	评论的企业成员userid，userid与external_userid不会同时出现
	comment_list.create_time	评论时间
	like_list	点赞列表
	like_list.external_userid	点赞的外部联系人userid
	like_list.userid	点赞的企业成员userid，userid与external_userid不会同时出现
	like_list.create_time	点赞时间

=cut

sub get_moment_comments {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_moment_comments?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 add_msg_template(access_token, hash);

创建企业群发

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92135>

=head3 请求说明：

企业跟第三方应用可通过此接口添加企业群发消息的任务并通知成员发送给相关客户或客户群。（注：企业微信终端需升级到2.7.5版本及以上）
注意：调用该接口并不会直接发送消息给客户/客户群，需要成员确认后才会执行发送（客服人员的企业微信需要升级到2.7.5及以上版本）
旧接口创建企业群发已经废弃，接口升级后支持发送视频文件，并且支持最多同时发送9个附件。
每位客户/每个客户群每天可接收1条群发消息，可以是企业统一创建发送的，也可以是成员自己创建发送的；超过接收上限的客户/客户群将无法再收到群发消息。

=head4 请求包结构体为：

	{
		"chat_type": "single",
		"external_userid": [
			"woAJ2GCAAAXtWyujaWJHDDGi0mACAAAA",
			"wmqfasd1e1927831123109rBAAAA"
		],
		"sender": "zhangsan",
		"text": {
			"content": "文本消息内容"
		},
		"attachments": [{
			"msgtype": "image",
			"image": {
				"media_id": "MEDIA_ID",
				"pic_url": "http://p.qpic.cn/pic_wework/3474110808/7a6344sdadfwehe42060/0"
			}
		}, {
			"msgtype": "link",
			"link": {
				"title": "消息标题",
				"picurl": "https://example.pic.com/path",
				"desc": "消息描述",
				"url": "https://example.link.com/path"
			}
		}, {
			"msgtype": "miniprogram",
			"miniprogram": {
				"title": "消息标题",
				"pic_media_id": "MEDIA_ID",
				"appid": "wx8bd80126147dfAAA",
				"page": "/path/index.html"
			}
		}, {
			"msgtype": "video",
			"video": {
				"media_id": "MEDIA_ID"
			}
		}, {
			"msgtype": "file",
			"file": {
				"media_id": "MEDIA_ID"
			}
		} ]
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	chat_type	否	群发任务的类型，默认为single，表示发送给客户，group表示发送给客户群
	external_userid	否	客户的外部联系人id列表，仅在chat_type为single时有效，不可与sender同时为空，最多可传入1万个客户
	sender	否	发送企业群发消息的成员userid，当类型为发送给客户群时必填
	text.content	否	消息文本内容，最多4000个字节
	attachments	否	附件，最多支持添加9个附件
	attachments.msgtype	是	附件类型，可选image、link、miniprogram或者video
	image.media_id	否	图片的media_id，可以通过素材管理接口获得
	image.pic_url	否	图片的链接，仅可使用上传图片接口得到的链接
	link.title	是	图文消息标题，最长128个字节
	link.picurl	否	图文消息封面的url，最长2048个字节
	link.desc	否	图文消息的描述，最多512个字节
	link.url	是	图文消息的链接，最长2048个字节
	miniprogram.title	是	小程序消息标题，最多64个字节
	miniprogram.pic_media_id	是	小程序消息封面的mediaid，封面图建议尺寸为520*416
	miniprogram.appid	是	小程序appid（可以在微信公众平台上查询），必须是关联到企业的小程序应用
	miniprogram.page	是	小程序page路径
	video.media_id	是	视频的media_id，可以通过素材管理接口获得
	file.media_id	是	文件的media_id，可以通过素材管理接口获得

* text和attachments不能同时为空
attachments中每个附件信息必须与msgtype一致，例如，msgtype指定为image，则需要填写image.pic_url或者image.media_id，否则会报错。
media_id和pic_url只需填写一个，两者同时填写时使用media_id，二者不可同时为空

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
自建应用只能给应用可见范围内的成员进行推送。
第三方应用需具有“企业客户权限->客户联系->群发消息给客户和客户群”权限。
当只提供sender参数时，相当于选取了这个成员所有的客户。
注意：2019-8-1之后，取消了 “无法向未回复消息的客户发送企业群发消息” 的限制。

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"fail_list":["wmqfasd1e1927831123109rBAAAA"],
		"msgid":"msgGCAAAXtWyujaWJHDDGi0mAAAA"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	fail_list	无效或无法发送的external_userid列表
	msgid	企业群发消息的id，可用于获取群发消息发送结果

=cut

sub add_msg_template {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/add_msg_template?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_groupmsg_list_v2(access_token, hash);

获取企业的全部群发记录-获取群发记录列表

企业跟第三方应用可通过该接口获取群发给客户的消息和群发到客户群的消息

群发助手和客户群群发有以下两种类型
企业发表
管理员或者业务负责人创建内容，成员确认后，即可发送给客户或者客户群
个人发表
成员自己创建的内容，可直接发送给客户或客户群

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93338#获取群发记录列表>

=head3 请求说明：

企业和第三方应用可通过此接口获取企业与成员的群发记录。

=head4 请求包结构体为：

	{
	   "chat_type":"single",
	   "start_time":1605171726,
	   "end_time":1605172726,
	   "creator":"zhangshan",
	   "filter_type":1,
	   "limit":50,
	   "cursor":"CURSOR"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	chat_type	是	群发任务的类型，默认为single，表示发送给客户，group表示发送给客户群
	start_time	是	群发任务记录开始时间
	end_time	是	群发任务记录结束时间
	creator	否	群发任务创建人企业账号id
	filter_type	否	创建人类型。0：企业发表 1：个人发表 2：所有，包括个人创建以及企业创建，默认情况下为所有类型
	limit	否	返回的最大记录数，整型，最大值100，默认值50，超过最大值时取默认值
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用可不填

=head4 补充说明:

群发任务记录的起止时间间隔不能超过1个月
3.1.6版本之前不支持多附件，请参考获取群发记录列表接口获取群发记录列表

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
自建应用调用，只会返回应用可见范围内用户的发送情况。
第三方应用调用需要企业授权客户联系下群发消息给客户和客户群的权限

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok",
		"next_cursor":"CURSOR",
		"group_msg_list":[
			{
				"msgid":"msgGCAAAXtWyujaWJHDDGi0mAAAA",
				"creator":"xxxx",
				"create_time":"xxxx",
				"create_type":1,
				"text": {
					"content":"文本消息内容"
				},
				"attachments": [
					{
						"msgtype": "image",
						"image": {
							"media_id": "MEDIA_ID",
							"pic_url": "http://p.qpic.cn/pic_wework/3474110808/7a6344sdadfwehe42060/0"
						}
					}, 
					{
						"msgtype": "link",
						"link": {
							"title": "消息标题",
							"picurl": "https://example.pic.com/path",
							"desc": "消息描述",
							"url": "https://example.link.com/path"
						}
					}, 
					{
						"msgtype": "miniprogram",
						"miniprogram": {
							"title": "消息标题",
							"pic_media_id": "MEDIA_ID",
							"appid": "wx8bd80126147dfAAA",
							"page": "/path/index.html"
						}
					},
					{
						"msgtype": "video",
						"video": {
							"media_id": "MEDIA_ID"
						}
					},
					{
						"msgtype": "file",
						"file": {
							"media_id": "MEDIA_ID"
						}
					}
				]
			}
		]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	next_cursor	分页游标，再下次请求时填写以获取之后分页的记录，如果已经没有更多的数据则返回空
	group_msg_list	群发记录列表
	group_msg_list.msgid	企业群发消息的id，可用于获取企业群发成员执行结果
	group_msg_list.creator	群发消息创建者userid，API接口创建的群发消息不返回该字段
	group_msg_list.create_time	创建时间
	group_msg_list.create_type	群发消息创建来源。0：企业 1：个人
	group_msg_list.text.content	消息文本内容，最多4000个字节
	group_msg_list.attachments.msgtype	值必须是image
	group_msg_list.attachments.image.media_id	图片的media_id，可以通过获取临时素材下载资源
	group_msg_list.attachments.image.pic_url	图片的url，与图片的media_id不能共存优先吐出media_id
	group_msg_list.attachments.msgtype	值必须是link
	group_msg_list.attachments.link.title	图文消息标题
	group_msg_list.attachments.link.picurl	图文消息封面的url
	group_msg_list.attachments.link.desc	图文消息的描述，最多512个字节
	group_msg_list.attachments.link.url	图文消息的链接
	group_msg_list.attachments.msgtype	值必须是miniprogram
	group_msg_list.attachments.miniprogram.title	小程序消息标题，最多64个字节
	group_msg_list.attachments.miniprogram.appid	小程序appid，必须是关联到企业的小程序应用
	group_msg_list.attachments.miniprogram.page	小程序page路径
	group_msg_list.attachments.msgtype	值必须是video
	group_msg_list.attachments.video.media_id	视频的media_id，可以通过获取临时素材下载资源
	group_msg_list.attachments.msgtype	值必须是file
	group_msg_list.attachments.file.media_id	文件的media_id，可以通过获取临时素材下载资源

=cut

sub get_groupmsg_list_v2 {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_groupmsg_list_v2?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_groupmsg_task(access_token, hash);

获取企业的全部群发记录-获取群发成员发送任务列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93338#获取群发成员发送任务列表>

=head3 请求说明：

=head4 请求包结构体为：

	{
		"msgid": "msgGCAAAXtWyujaWJHDDGi0mACAAAA",
		"limit":50,
		"cursor":"CURSOR"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	msgid	是	群发消息的id，通过获取群发记录列表接口返回
	limit	否	返回的最大记录数，整型，最大值1000，默认值500，超过最大值时取默认值
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用可不填

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
自建应用调用，只会返回应用可见范围内用户的发送情况。
第三方应用调用需要企业授权客户联系下群发消息给客户和客户群的权限

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"next_cursor":"CURSOR",
		"task_list": [
			{
				"userid": "zhangsan",
				"status": 1,
				"send_time": 1552536375
			}
		]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	next_cursor	分页游标，再下次请求时填写以获取之后分页的记录，如果已经没有更多的数据则返回空
	task_list	群发成员发送任务列表
	task_list.userid	企业服务人员的userid
	task_list.status	发送状态：0-未发送 2-已发送
	task_list.send_time	发送时间，未发送时不返回

2020-11-17日之前创建的消息无发送任务列表，请通过获取企业群发成员执行结果接口获取群发结果

=cut

sub get_groupmsg_task {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_groupmsg_task?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_groupmsg_send_result(access_token, hash);

获取企业的全部群发记录-获取企业群发成员执行结果

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93338#获取企业群发成员执行结果>

=head3 请求说明：

=head4 请求包结构体为：

	{
		"msgid": "msgGCAAAXtWyujaWJHDDGi0mACAAAA",
		"userid":"zhangsan ",
		"limit":50,
		"cursor":"CURSOR"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证	 
	msgid	是	群发消息的id，通过获取群发记录列表接口返回	 
	userid	是	发送成员userid，通过[获取群发成员发送任务列表](#获取群发成员发送任务列表 )接口返回	
	limit	否	返回的最大记录数，整型，最大值1000，默认值500，超过最大值时取默认值	 
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用可不填

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
自建应用调用，只会返回应用可见范围内用户的发送情况。
第三方应用调用需要企业授权客户联系下群发消息给客户和客户群的权限

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"next_cursor":"CURSOR",
		"send_list": [
			{
				"external_userid": "wmqfasd1e19278asdasAAAA",
				"chat_id":"wrOgQhDgAAMYQiS5ol9G7gK9JVAAAA",
				"userid": "zhangsan",
				"status": 1,
				"send_time": 1552536375
			}
		]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	next_cursor	分页游标，再下次请求时填写以获取之后分页的记录，如果已经没有更多的数据则返回空
	send_list	群成员发送结果列表
	send_list.external_userid	外部联系人userid，群发消息到企业的客户群不返回该字段
	send_list.chat_id	外部客户群id，群发消息到客户不返回该字段
	send_list.userid	企业服务人员的userid
	send_list.status	发送状态：0-未发送 1-已发送 2-因客户不是好友导致发送失败 3-因客户已经收到其他群发消息导致发送失败
	send_list.send_time	发送时间，发送状态为1时返回

若为客户群群发，由于用户还未选择群，所以不返回未发送记录，只返回已发送记录
2020-11-17日之前创建的消息请通过获取企业群发成员执行结果接口获取群发结果

=cut

sub get_groupmsg_send_result {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_groupmsg_send_result?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 send_welcome_msg(access_token, hash);

发送新客户欢迎语

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92137>

=head3 请求说明：

企业微信在向企业推送添加外部联系人事件时，会额外返回一个welcome_code，企业以此为凭据调用接口，即可通过成员向新添加的客户发送个性化的欢迎语。
为了保证用户体验以及避免滥用，企业仅可在收到相关事件后20秒内调用，且只可调用一次。
如果企业已经在管理端为相关成员配置了可用的欢迎语，则推送添加外部联系人事件时不会返回welcome_code。
每次添加新客户时可能有多个企业自建应用/第三方应用收到带有welcome_code的回调事件，但仅有最先调用的可以发送成功。后续调用将返回41051（externaluser has started chatting）错误，请用户根据实际使用需求，合理设置应用可见范围，避免冲突。
旧接口发送新客户欢迎语已经废弃，接口升级后支持发送视频文件，并且最多支持同时发送9个附件

=head4 请求包结构体为：

	{
		"welcome_code": "CALLBACK_CODE",
		"text": {
			"content": "文本消息内容"
		},
		"attachments": [{
			"msgtype": "image",
			"image": {
				"media_id": "MEDIA_ID",
				"pic_url": "http://p.qpic.cn/pic_wework/3474110808/7a6344sdadfwehe42060/0"
			}
		}, {
			"msgtype": "link",
			"link": {
				"title": "消息标题",
				"picurl": "https://example.pic.com/path",
				"desc": "消息描述",
				"url": "https://example.link.com/path"
			}
		}, {
			"msgtype": "miniprogram",
			"miniprogram": {
				"title": "消息标题",
				"pic_media_id": "MEDIA_ID",
				"appid": "wx8bd80126147dfAAA",
				"page": "/path/index.html"
			}
		}, {
			"msgtype": "video",
			"video": {
				"media_id": "MEDIA_ID"
			}
		},{
			"msgtype":"file",
			"file":
			{
				"media_id":"MEDIA_ID"
			}
		}]
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	welcome_code	是	通过添加外部联系人事件推送给企业的发送欢迎语的凭证，有效期为20秒
	text.content	否	消息文本内容,最长为4000字节
	attachments	否	附件，最多可添加9个附件
	attachments.msgtype	是	附件类型，可选image、link、miniprogram或者video
	image.media_id	否	图片的media_id，可以通过素材管理接口获得
	image.pic_url	否	图片的链接，仅可使用上传图片接口得到的链接
	link.title	是	图文消息标题，最长为128字节
	link.picurl	否	图文消息封面的url
	link.desc	否	图文消息的描述，最长为512字节
	link.url	是	图文消息的链接
	miniprogram.title	是	小程序消息标题，最长为64字节
	miniprogram.pic_media_id	是	小程序消息封面的mediaid，封面图建议尺寸为520*416
	miniprogram.appid	是	小程序appid，必须是关联到企业的小程序应用
	miniprogram.page	是	小程序page路径
	video.media_id	是	视频的media_id，可以通过素材管理接口获得
	file.media_id	是	文件的media_id, 可以通过素材管理接口获得

* text和attachments不能同时为空；
text与附件信息可以同时发送，此时将会以多条消息的形式触达客户
attachments中每个附件信息必须与msgtype一致，例如，msgtype指定为image，则需要填写image.pic_url或者image.media_id，否则会报错。
media_id和pic_url只需填写一个，两者同时填写时使用media_id，二者不可同时为空。

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需要拥有“企业客户权限->客户联系->给客户发送欢迎语”权限
企业成员需在应用的可见范围内

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub send_welcome_msg {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/send_welcome_msg?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_user_behavior_data(access_token, hash);

获取「联系客户统计」数据

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92132>

=head3 请求说明：

企业可通过此接口获取成员联系客户的数据，包括发起申请数、新增客户数、聊天数、发送消息数和删除/拉黑成员的客户数等指标。

=head4 请求包结构体为：

	{
		"userid": [
			"zhangsan",
			"lisi"
		],
		"partyid":
		[
			1001,
			1002
		],
		"start_time":1536508800,
		"end_time":1536595200
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	userid	否	成员ID列表，最多100个
	partyid	否	部门ID列表，最多100个
	start_time	是	数据起始时间
	end_time	是	数据结束时间

userid和partyid不可同时为空;
此接口提供的数据以天为维度，查询的时间范围为[start_time,end_time]，即前后均为闭区间，支持的最大查询跨度为30天；
用户最多可获取最近180天内的数据；
当传入的时间不为0点时间戳时，会向下取整，如传入1554296400(Wed Apr 3 21:00:00 CST 2019)会被自动转换为1554220800（Wed Apr 3 00:00:00 CST 2019）;
如传入多个userid，则表示获取这些成员总体的联系客户数据。

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用使用，需具有“企业客户权限->客户联系->获取成员联系客户的数据统计”权限。
第三方/自建应用调用时传入的userid和partyid要在应用的可见范围内;

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"behavior_data":
		[
			{
			"stat_time":1536508800,
			"chat_cnt":100,
			"message_cnt":80,
			"reply_percentage":60.25,
			"avg_reply_time":1,
			"negative_feedback_cnt":0,
			"new_apply_cnt":6,
			"new_contact_cnt":5
			},
			{
			"stat_time":1536595200,
			"chat_cnt":20,
			"message_cnt":40,
			"reply_percentage":100,
			"avg_reply_time":1,
			"negative_feedback_cnt":0,
			"new_apply_cnt":6,
			"new_contact_cnt":5
			}
		]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	behavior_data.stat_time	数据日期，为当日0点的时间戳
	behavior_data.new_apply_cnt	发起申请数，成员通过「搜索手机号」、「扫一扫」、「从微信好友中添加」、「从群聊中添加」、「添加共享、分配给我的客户」、「添加单向、双向删除好友关系的好友」、「从新的联系人推荐中添加」等渠道主动向客户发起的好友申请数量。
	behavior_data.new_contact_cnt	新增客户数，成员新添加的客户数量。
	behavior_data.chat_cnt	聊天总数， 成员有主动发送过消息的单聊总数。
	behavior_data.message_cnt	发送消息数，成员在单聊中发送的消息总数。
	behavior_data.reply_percentage	已回复聊天占比，浮点型，客户主动发起聊天后，成员在一个自然日内有回复过消息的聊天数/客户主动发起的聊天数比例，不包括群聊，仅在确有聊天时返回。
	behavior_data.avg_reply_time	平均首次回复时长，单位为分钟，即客户主动发起聊天后，成员在一个自然日内首次回复的时长间隔为首次回复时长，所有聊天的首次回复总时长/已回复的聊天总数即为平均首次回复时长，不包括群聊，仅在确有聊天时返回。
	behavior_data.negative_feedback_cnt	删除/拉黑成员的客户数，即将成员删除或加入黑名单的客户数。

=cut

sub get_user_behavior_data {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_user_behavior_data?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 add_product_album(access_token, hash);

管理商品图册-创建商品图册

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95096#创建商品图册>

=head3 请求说明：

企业和第三方应用可以通过此接口增加商品

=head4 请求包结构体为：

	{
		"description":"世界上最好的商品",
		"price":30000,
		"product_sn":"xxxxxxxx",
		"attachments":[
			{
				"type": "image",
				"image": {
					"media_id": "MEDIA_ID"
				}
			}
		]
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	description	是	商品的名称、特色等;不超过300个字
	price	是	商品的价格，单位为分；最大不超过5万元
	product_sn	否	商品编码；不超过128个字节；只能输入数字和字母
	attachments	是	附件类型，仅支持image，最多不超过9个附件
	image.media_id	否	图片的media_id，仅支持通过上传附件资源接口获得的资源

=head3 权限说明

允许使用“客户联系”secret调用
允许自建应用：使用配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
允许第三方应用：第三方应用需授权企业客户权限下管理商品图册的权限
第三方应用必须在服务商管理端申请“企业客户权限->客户联系->管理商品图册”权限。
允许代开发自建应用：应用需授权企业客户权限下管理商品图册的权限
应用需授权“企业客户权限->客户联系->管理商品图册”权限。

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok",
		"product_id" : "xxxxxxxxxx"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	product_id	商品id

=cut

sub add_product_album {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/add_product_album?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_product_album(access_token, hash);

管理商品图册-获取商品图册

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95096#获取商品图册>

=head3 请求说明：

企业和第三方应用可以通过此接口获取商品信息

=head4 请求包结构体为：

	{
		"product_id" : "xxxxxxxxxx"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
    product_id	是		商品id

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用或代开发自建应用调用需要企业授权客户联系下管理商品图册的权限
可获取企业内所有企业级的商品图册

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok",
		"product": {
				"product_id" : "xxxxxxxxxx",
				"description":"世界上最好的商品",
				"price":30000,
				"create_time":1600000000,
				"product_sn":"xxxxxxxx",
				"attachments":[
					{
						"type": "image",
						"image": {
							"media_id": "MEDIA_ID"
						}
					}
				]
		}
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	product	商品详情
	product_id	商品id
	product_sn	商品编码
	description	商品的名称、特色等
	price	商品的价格，单位为分
	create_time	商品图册创建时间
	attachments	附件类型
	attachments.type	附件类型，目前仅支持image
	image.media_id	图片的media_id，可以通过获取临时素材下载资源
	
=cut

sub get_product_album {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_product_album?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_product_album_list(access_token, hash);

管理商品图册-获取商品图册列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95096#获取商品图册列表>

=head3 请求说明：

企业和第三方应用可以通过此接口导出商品

=head4 请求包结构体为：

	{
	   "limit":50,
	   "cursor":"CURSOR"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	limit	否	返回的最大记录数，整型，最大值100，默认值50，超过最大值时取默认值
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用可不填

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
自建应用调用，只会返回应用可见范围内用户的情况。
第三方应用或代开发自建应用调用需要企业授权客户联系下管理商品图册的权限

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok",
		"next_cursor":"CURSOR",
		"product_list":[
			{
				"product_id" : "xxxxxxxxxx",
				"description":"世界上最好的商品",
				"price":30000,
				"product_sn":"xxxxxxxx",
				"attachments":[
					{
						"type": "image",
						"image": {
							"media_id": "MEDIA_ID"
						}
					}
				]
			}
		]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	next_cursor	用于分页查询的游标，字符串类型，用于下一次调用
	product_list	商品列表
	product_list.product_id	商品id
	product_list.product_sn	商品编码
	product_list.description	商品的名称、特色等
	product_list.price	商品的价格，单位为分
	product_list.attachments	附件类型
	product_list.attachments.type	附件类型，目前仅支持image
	product_list.image.media_id	图片的media_id，可以通过获取临时素材下载资源
	
=cut

sub get_product_album_list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_product_album_list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update_product_album(access_token, hash);

管理商品图册-编辑商品图册

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95096#编辑商品图册>

=head3 请求说明：

企业和第三方应用可以通过此接口修改商品信息

=head4 请求包结构体为：

	{
		"product_id" : "xxxxxxxxxx",
		"description":"世界上最好的商品",
		"price":30000,
		"product_sn":"xxxxxx",
		"attachments":[
			{
				"type": "image",
				"image": {
					"media_id": "MEDIA_ID"
				}
			}
		]
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	product_id	是	商品id
	description	是	商品的名称、特色等;不超过300个字
	price	是	商品的价格，单位为分；最大不超过5万元
	product_sn	否	商品编码；不超过128个字节；只能输入数字和字母
	attachments	否	附件类型，仅支持image
	attachments.type	附件类型，目前仅支持image	 
	image.media_id	否	图片的media_id，仅支持通过上传附件资源接口的资源

注：除product_id外，需要更新的字段才填，不需更新的字段可不填。

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用或代开发自建应用调用需要企业授权客户联系下管理商品图册的权限
应用只修改应用自己创建的商品图册；客户联系系统应用可修改所有商品图册

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	
=cut

sub update_product_album {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/update_product_album?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete_product_album(access_token, hash);

管理商品图册-删除商品图册

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95096#删除商品图册>

=head3 请求说明：

企业和第三方应用可以通过此接口删除商品信息

=head4 请求包结构体为：

	{
		"product_id" : "xxxxxxxxxx"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	product_id	是	商品id

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用或代开发自建应用调用需要企业授权客户联系下管理商品图册的权限
应用只可删除应用自己创建的商品图册；客户联系系统应用可删除所有商品图册

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	
=cut

sub delete_product_album {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/delete_product_album?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 add_intercept_rule(access_token, hash);

管理聊天敏感词-新建敏感词规则

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95097#新建敏感词规则>

=head3 请求说明：

企业和第三方应用可以通过此接口新建敏感词规则

=head4 请求包结构体为：

	{
		"rule_name":"rulename",
		"word_list":[
		  "敏感词1","敏感词2"
		],
		"semantics_list":[1,2,3],
		"intercept_type":1,
		"applicable_range":{
			"user_list":["zhangshan"],
			"department_list":[2,3]
		}
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	rule_name	是	规则名称，长度1~20个utf8字符
	word_list	是	敏感词列表，敏感词长度1~32个utf8字符，列表大小不能超过300个
	semantics_list	否	额外的拦截语义规则，1：手机号、2：邮箱地:、3：红包
	intercept_type	是	拦截方式，1:警告并拦截发送；2:仅发警告
	applicable_range	是	敏感词适用范围，userid与department不能同时为不填
	applicable_range.user_list	否	可使用的userid列表。必须为应用可见范围内的成员；最多支持传1000个节点
	applicable_range.department_list	否	可使用的部门列表，必须为应用可见范围内的部门；最多支持传1000个节点

注：企业敏感词规则条数上限为100个。

=head3 权限说明

允许使用“客户联系”secret调用
允许自建应用：使用配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
允许第三方应用：第三方应用需授权企业客户权限下管理敏感词的权限
第三方应用必须在服务商管理端申请“企业客户权限->客户联系->管理敏感词”权限。
允许代开发自建应用：应用需授权企业客户权限下管理敏感词的权限
应用必须授权“企业客户权限->客户联系->管理敏感词”权限。

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok",
		"rule_id" : "xxx"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	rule_id	规则id
	
=cut

sub add_intercept_rule {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/add_intercept_rule?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_intercept_rule_list(access_token, hash);

管理聊天敏感词-获取敏感词规则列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95097#获取敏感词规则列表>

=head3 请求说明：

企业和第三方应用可以通过此接口获取敏感词规则列表

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用或者代开发自建应用调用需要企业授权客户联系下管理敏感词的权限
可获取企业所有敏感词规则

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok",
		"rule_list":[
			{
				"rule_id":"xxxx",
				"rule_name":"rulename",
				"create_time":1600000000
			}
		]
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	rule_id	规则id
	rule_name	规则名称，长度上限20个字符
	create_time	创建时间
	
=cut

sub get_intercept_rule_list {
    if ( @_ && $_[0] ) {
        my $access_token = $_[0];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_intercept_rule_list?access_token=$access_token");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_intercept_rule(access_token, hash);

管理聊天敏感词-获取敏感词规则详情

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95097#获取敏感词规则详情>

=head3 请求说明：

企业和第三方应用可以通过此接口获取敏感词规则详情

=head4 请求包结构体为：

	{
		"rule_id":"xxx"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	rule_id	是	规则id

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用或者代开发自建应用调用需要企业授权客户联系下管理敏感词的权限
使用范围只返回应用可见范围内的成员跟部门

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok",
		"rule":{
			"rule_id":1,
			"rule_name":"rulename",
			"word_list":[
			 "敏感词1","敏感词2"
			],
			"extra_rule":{
				"semantics_list":[1,2,3],
			},
			"intercept_type":1,
			"applicable_range":{
				"user_list":["zhangshan"],
				"department_list":[2,3]
			}
		}

	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	rule_id	规则id
	rule_name	规则名称，长度上限20个字符
	word_list	敏感词列表，敏感词不能超过30个字符，列表大小不能超过300个
	extra_rule	额外的规则
	semantics_list	额外的拦截语义规则，1：手机号、2：邮箱地:、3：红包
	intercept_type	拦截方式，1:警告并拦截发送；2:仅发警告
	applicable_range	敏感词适用范围
	applicable_range.user_list	可使用的userid列表，只返回应用可见范围内的用户
	applicable_range.department_list	可使用的部门列表，只返回应用可见范围内的部门
	create_time	创建时间
	
=cut

sub get_intercept_rule {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_intercept_rule?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update_intercept_rule(access_token, hash);

管理聊天敏感词-修改敏感词规则

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95097#修改敏感词规则>

=head3 请求说明：

企业和第三方应用可以通过此接口修改敏感词规则

=head4 请求包结构体为：

	{
		"rule_id":"xxxx",
		"rule_name":"rulename",
		"word_list":[
		  "敏感词1","敏感词2"
		],
		"extra_rule":{
				"semantics_list":[1,2,3],
		},
		"intercept_type":1,
		"add_applicable_range":{
			"user_list":["zhangshan"],
			"department_list":[2,3]
		},
		"remove_applicable_range":{
			"user_list":["zhangshan"],
			"department_list":[2,3]
		}
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	rule_id	是	规则id
	rule_name	否	规则名称，长度1~20个utf8字符
	word_list	否	敏感词列表，敏感词长度1~32个utf8字符，列表大小不能超过300个；若为空忽略该字段
	extra_rule	否	额外的规则
	semantics_list	否	额外的拦截语义规则，1：手机号、2：邮箱地:、3：红包；若为空表示清楚所有的语义规则
	intercept_type	否	拦截方式，1:警告并拦截发送；2:仅发警告
	add_applicable_range	否	需要新增的使用范围
	add_applicable_range.user_list	否	可使用的userid列表，必须为应用可见范围内的成员；每次最多支持传1000个节点；该规则最多可包含的userid总数上限为10000个。若超过建议设置部门id
	add_applicable_range.department_list	否	可使用的部门列表，必须为应用可见范围内的部门；最多支持传1000个节点
	remove_applicable_range	否	需要删除的使用范围
	remove_applicable_range.user_list	否	可使用的userid列表，必须为应用可见范围内的成员；最多支持传1000个节点
	remove_applicable_range.department_list	否	可使用的部门列表，必须为应用可见范围内的部门；最多支持传1000个节点

注：除rule_id外，需要更新的字段才填，不需更新的字段可不填。

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用或者代开发自建应用调用需要企业授权客户联系下管理敏感词的权限
应用只可修改应用自己创建的敏感词规则；客户联系系统应用可修改所有规则

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	
=cut

sub update_intercept_rule {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/update_intercept_rule?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del_intercept_rule(access_token, hash);

管理聊天敏感词-删除敏感词规则

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95097#删除敏感词规则>

=head3 请求说明：

企业和第三方应用可以通过此接口修改敏感词规则

=head4 请求包结构体为：

	{
		"rule_id":"xxx"
	}

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
	rule_id	是	规则id

=head3 权限说明

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用或者代开发自建应用调用需要企业授权客户联系下管理敏感词的权限
应用只可删除应用自己创建的敏感词规则；客户联系系统应用可删除所有规则

=head3 RETURN 返回结果

    {
		"errcode":0,
		"errmsg":"ok"
	}

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	
=cut

sub del_intercept_rule {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/del_intercept_rule?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
