package QQ::weixin::work::externalcontact::groupchat;

=encoding utf8

=head1 Name

QQ::weixin::work::externalcontact::groupchat

=head1 DESCRIPTION

客户联系->离职继承

=cut

use strict;
use base qw(QQ::weixin::work::externalcontact);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ onjob_transfer transfer list get
				add_join_way get_join_way update_join_way del_join_way
				statistic statistic_group_by_day /;

=head1 FUNCTION

=head2 onjob_transfer(access_token, hash);

分配在职成员的客户群
最后更新：2023/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95703>

=head3 请求说明：

企业可通过此接口，将在职成员为群主的群，分配给另一个客服成员。

=head4 请求包结构体为：

    {
		"chat_id_list" : ["wrOgQhDgAAcwMTB7YmDkbeBsgT_AAAA", "wrOgQhDgAAMYQiS5ol9G7gK9JVQUAAAA"],
		"new_owner" : "zhangsan"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	chat_id_list	是	需要转群主的客户群ID列表。取值范围： 1 ~ 100
	new_owner	是	新群主ID

注意：
继承给的新群主，必须是配置了客户联系功能的成员
继承给的新群主，必须有设置实名
继承给的新群主，必须有激活企业微信
同一个人的群，限制每天最多分配300个给新群主
继承给的新群主和旧的群主，需要在最近一年内至少登陆过一次企业微信

为保障客户服务体验，90个自然日内，在职成员的每个客户群仅可被转接2次。

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需拥有“企业客户权限->客户联系->分配在职成员的客户群”权限
对于第三方/自建应用，群主必须在应用的可见范围。

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"failed_chat_list": [
			{
				"chat_id": "wrOgQhDgAAcwMTB7YmDkbeBsgT_KAAAA",
				"errcode": 90501,
				"errmsg": "chat is not external group chat"
			}
		]
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	failed_chat_list	没能成功继承的群
	failed_chat_list.chat_id	没能成功继承的群ID
	failed_chat_list.errcode	没能成功继承的群，错误码
	failed_chat_list.errmsg	没能成功继承的群，错误描述

=cut

sub onjob_transfer {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/groupchat/onjob_transfer?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 transfer(access_token, hash);

分配离职成员的客户群
最后更新：2023/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92127>

=head3 请求说明：

企业可通过此接口，将已离职成员为群主的群，分配给另一个客服成员。

=head4 请求包结构体为：

    {
		"chat_id_list" : ["wrOgQhDgAAcwMTB7YmDkbeBsgT_AAAA", "wrOgQhDgAAMYQiS5ol9G7gK9JVQUAAAA"],
		"new_owner" : "zhangsan"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	chat_id_list	是	需要转群主的客户群ID列表。取值范围： 1 ~ 100
	new_owner	是	新群主ID

注意：
群主离职了的客户群，才可继承
继承给的新群主，必须是配置了客户联系功能的成员
继承给的新群主，必须有设置实名
继承给的新群主，必须有激活企业微信
同一个人的群，限制每天最多分配300个给新群主
继承给的新群主，需要在最近一年内至少登陆过一次企业微信；旧群主的离职时间不能超过1年且离职前一年内至少登录过一次企业微信

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需拥有“企业客户权限->客户联系->分配离职成员的客户群”权限
对于第三方/自建应用，群主必须在应用的可见范围。

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"failed_chat_list": [
			{
				"chat_id": "wrOgQhDgAAcwMTB7YmDkbeBsgT_KAAAA",
				"errcode": 90500,
				"errmsg": "the owner of this chat is not resigned"
			}
		]
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	failed_chat_list	没能成功继承的群
	failed_chat_list.chat_id	没能成功继承的群ID
	failed_chat_list.errcode	没能成功继承的群，错误码
	failed_chat_list.errmsg	没能成功继承的群，错误描述

=cut

sub transfer {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/groupchat/transfer?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token, hash);

获取客户群列表
最后更新：2023/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92120>

=head3 请求说明：

该接口用于获取配置过客户群管理的客户群列表。

=head4 请求包结构体为：

    {
		"status_filter": 0,
		"owner_filter": {
			"userid_list": ["abel"]
		},
		"cursor" : "r9FqSqsI8fgNbHLHE5QoCP50UIg2cFQbfma3l2QsmwI",
		"limit" : 10
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	status_filter	否	客户群跟进状态过滤。
						0 - 所有列表(即不过滤)
						1 - 离职待继承
						2 - 离职继承中
						3 - 离职继承完成
						默认为0
	owner_filter	否	群主过滤。
						如果不填，表示获取应用可见范围内全部群主的数据（但是不建议这么用，如果可见范围人数超过1000人，为了防止数据包过大，会报错 81017）
	owner_filter.userid_list	否	用户ID列表。最多100个
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用不填
	limit	是	分页，预期请求的数据量，取值范围 1 ~ 1000
	
如果不指定 owner_filter，会拉取应用可见范围内的所有群主的数据，但是不建议这样使用。如果可见范围内人数超过1000人，为了防止数据包过大，会报错 81017。此时，调用方需通过指定 owner_filter 来缩小拉取范围
旧版接口以offset+limit分页，要求offset+limit不能超过50000，该方案将废弃，请改用cursor+limit分页

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需具有“企业客户权限->客户基础信息”权限
对于第三方/自建应用，群主必须在应用的可见范围。

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"group_chat_list": [{
			"chat_id": "wrOgQhDgAAMYQiS5ol9G7gK9JVAAAA",
			"status": 0
		}, {
			"chat_id": "wrOgQhDgAAcwMTB7YmDkbeBsAAAA",
			"status": 0
		}],
		"next_cursor":"tJzlB9tdqfh-g7i_J-ehOz_TWcd7dSKa39_AqCIeMFw"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	group_chat_list	客户群列表
	group_chat_list.chat_id	客户群ID
	group_chat_list.status	客户群跟进状态。
							0 - 跟进人正常
							1 - 跟进人离职
							2 - 离职继承中
							3 - 离职继承完成
	next_cursor	分页游标，下次请求时填写以获取之后分页的记录。如果该字段返回空则表示已没有更多数据

=cut

sub list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/groupchat/list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token, hash);

获取客户群详情
最后更新：2023/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92122>

=head3 请求说明：

通过客户群ID，获取详情。包括群名、群成员列表、群成员入群时间、入群方式。（客户群是由具有客户群使用权限的成员创建的外部群）

需注意的是，如果发生群信息变动，会立即收到群变更事件，但是部分信息是异步处理，可能需要等一段时间调此接口才能得到最新结果

=head4 请求包结构体为：

    {
		"chat_id":"wrOgQhDgAAMYQiS5ol9G7gK9JVAAAA",
		"need_name" : 1
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	chat_id	是	客户群ID
	need_name	否	是否需要返回群成员的名字group_chat.member_list.name。0-不返回；1-返回。默认不返回

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“企业客户权限->客户基础信息”权限
对于第三方/自建应用，群主必须在应用的可见范围。

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"group_chat": {
			"chat_id": "wrOgQhDgAAMYQiS5ol9G7gK9JVAAAA",
			"name": "销售客服群",
			"owner": "ZhuShengBen",
			"create_time": 1572505490,
			"notice": "文明沟通，拒绝脏话",
			"member_list": [{
				"userid": "abel",
				"type": 1,
				"join_time": 1572505491,
				"join_scene": 1,
				"invitor": {
					"userid": "jack"
				},
				"group_nickname": "客服小张",
				"name": "张三丰"
			}, {
				"userid": "wmOgQhDgAAuXFJGwbve4g4iXknfOAAAA",
				"type": 2,
				"unionid": "ozynqsulJFCZ2z1aYeS8h-nuasdAAA",
				"join_time": 1572505491,
				"join_scene": 1,
				"group_nickname": "顾客老王",
				"name": "王语嫣"
			}],
			"admin_list": [{
				"userid": "sam"
			}, {
				"userid": "pony"
			}],
			"member_version": "71217227bbd112ecfe3a49c482195cb4"
		}
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	group_chat	客户群详情
	group_chat.chat_id	客户群ID
	group_chat.name	群名
	group_chat.owner	群主ID
	group_chat.create_time	群的创建时间
	group_chat.notice	群公告
	group_chat.member_list	群成员列表
	group_chat.member_list.userid	群成员id
	group_chat.member_list.type	成员类型。
								1 - 企业成员
								2 - 外部联系人
	group_chat.member_list.unionid	外部联系人在微信开放平台的唯一身份标识（微信unionid），通过此字段企业可将外部联系人与公众号/小程序用户关联起来。仅当群成员类型是微信用户（包括企业成员未添加好友），且企业绑定了微信开发者ID有此字段（查看绑定方法）。第三方不可获取，上游企业不可获取下游企业客户的unionid字段
	group_chat.member_list.join_time	入群时间
	group_chat.member_list.join_scene	入群方式。
										1 - 由群成员邀请入群（直接邀请入群）
										2 - 由群成员邀请入群（通过邀请链接入群）
										3 - 通过扫描群二维码入群
	group_chat.member_list.invitor	邀请者。目前仅当是由本企业内部成员邀请入群时会返回该值
	group_chat.member_list.invitor.userid	邀请者的userid
	group_chat.member_list.group_nickname	在群里的昵称
	group_chat.member_list.name	名字。仅当 need_name = 1 时返回
								如果是微信用户，则返回其在微信中设置的名字
								如果是企业微信联系人，则返回其设置对外展示的别名或实名
	group_chat.admin_list	群管理员列表
	group_chat.admin_list.userid	群管理员userid
	group_chat.member_version	当前群成员版本号。可以配合客户群变更事件减少主动调用本接口的次数

=cut

sub get {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/groupchat/get?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 联系我与客户入群方式

客户群「加入群聊」管理
最后更新：2023/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92229>

=head3 请求说明：

企业可通过接口配置客户群「加入群聊」的方式。配置后，客户通过扫描群二维码或点击小程序上的按钮，即可进入企业的客户群

=head4 权限说明：

调用的应用需要满足如下的权限：

	应用类型	权限要求
	自建应用	配置到「客户联系 - 可调用接口的应用」中
	代开发应用	具有企业客户权限-客户群-配置「加入群聊」二维码权限，且已购买「加入群聊」增值接口
	第三方应用	具有企业客户权限-客户群-配置「加入群聊」二维码权限，且已购买「加入群聊」增值接口

提示
应用仅能获取和管理由本应用创建的「加入群聊」二维码/小程序组件

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head2 add_join_way(access_token, hash);

配置客户群进群方式

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92229#配置客户群进群方式>

=head3 请求说明：

企业可以在管理后台-客户联系中配置「加入群聊」的二维码或者小程序按钮，客户通过扫描二维码或点击小程序上的按钮，即可加入特定的客户群。
企业可通过此接口为具有客户联系功能的成员生成专属的二维码或者小程序按钮。
如果配置的是小程序按钮，需要开发者的小程序接入小程序插件。

通过API添加的配置不会在管理端进行展示，每个企业可通过API最多配置50万个「加入群聊」(与「联系我」共用50万的额度)。

=head4 请求包结构体为：

    {
		"scene": 2,
		"remark": "aa_remark",
		"auto_create_room": 1,
		"room_base_name" : "销售客服群",
		"room_base_id" : 10,
		"chat_id_list": [
			"wrOgQhDgAAH2Yy-CTZ6POca8mlBEdaaa",
			"wrOgQhDgAALPUthpRAKvl7mgiQRwAAA"
		],
		"state" : "klsdup3kj3s1"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	scene	是	场景。
				1 - 群的小程序插件
				2 - 群的二维码插件
	remark	否	联系方式的备注信息，用于助记，超过30个字符将被截断
	auto_create_room	否	当群满了后，是否自动新建群。0-否；1-是。 默认为1
	room_base_name	否	自动建群的群名前缀，当auto_create_room为1时有效。最长40个utf8字符
	room_base_id	否	自动建群的群起始序号，当auto_create_room为1时有效
	chat_id_list	是	使用该配置的客户群ID列表，支持5个。见客户群ID获取方法
	state	否	企业自定义的state参数，用于区分不同的入群渠道。不超过30个UTF-8字符
				如果有设置此参数，在调用获取客户群详情接口时会返回每个群成员对应的该参数值，详见文末附录2

room_base_name 和 room_base_id 两个参数配合，用于指定自动新建群的群名
例如，假如 room_base_name = "销售客服群", room_base_id = 10
那么，自动创建的第一个群，群名为“销售客服群10”；自动创建的第二个群，群名为“销售客服群11”，依次类推

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"config_id": "9ad7fa5cdaa6511298498f979c472aaa"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	config_id	配置id

=cut

sub add_join_way {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/groupchat/add_join_way?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_join_way(access_token, hash);

获取客户群进群方式配置

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92229#获取客户群进群方式配置>

=head3 请求说明：

获取企业配置的群二维码或小程序按钮。

=head4 请求包结构体为：

    {
		"config_id":"9ad7fa5cdaa6511298498f979c472aaa"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	config_id	是	联系方式的配置id

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"join_way": {
			"config_id": "9ad7fa5cdaa6511298498f979c472aaa",
			"scene": 2,
			"remark": "aa_remark",
			"auto_create_room": 1,
			"room_base_name" : "销售客服群",
			"room_base_id" : 10,
			"chat_id_list": ["wrOgQhDgAAH2Yy-CTZ6POca8mlBEdaaa", "wrOgQhDgAALPUthpRAKvl7mgiQRw_aaa"],
			"qr_code": "http://p.qpic.cn/wwhead/nMl9ssowtibVGyrmvBiaibzDtp703nXuzpibnKtbSDBRJTLwS3ic4ECrf3ibLVtIFb0N6wWwy5LVuyvMQ22/0",
			"state" : "klsdup3kj3s1"
		}
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	join_way	配置详情
	config_id	新增联系方式的配置id
	scene	场景。
			1 - 群的小程序插件
			2 - 群的二维码插件
	remark	联系方式的备注信息，用于助记，超过30个字符将被截断
	auto_create_room	当群满了后，是否自动新建群。0-否；1-是。 默认为1
	room_base_name	自动建群的群名前缀，当auto_create_room为1时有效。最长40个utf8字符
	room_base_id	自动建群的群起始序号，当auto_create_room为1时有效
	chat_id_list	使用该配置的客户群ID列表。见客户群ID获取方法
	qr_code	联系二维码的URL，仅在配置为群二维码时返回
	state	企业自定义的state参数，用于区分不同的入群渠道。不超过30个UTF-8字符
			如果有设置此参数，在调用获取客户群详情接口时会返回每个群成员对应的该参数值，详见文末附录2

=cut

sub get_join_way {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/groupchat/get_join_way?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update_join_way(access_token, hash);

更新客户群进群方式配置

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92229#更新客户群进群方式配置>

=head3 请求说明：

更新进群方式配置信息。注意：使用覆盖的方式更新。

=head4 请求包结构体为：

    {
		"config_id": "9ad7fa5cdaa6511298498f979c4722de",
		"scene": 2,
		"remark": "bb_remark",
		"auto_create_room": 1,
		"room_base_name" : "销售客服群",
		"room_base_id" : 10,
		"chat_id_list": ["wrOgQhDgAAH2Yy-CTZ6POca8mlBEdaaa", "wrOgQhDgAALPUthpRAKvl7mgiQRw_aaa"],
		"state" : "klsdup3kj3s1"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	config_id	是	企业联系方式的配置id
	scene	是	场景。
				1 - 群的小程序插件
				2 - 群的二维码插件
	remark	否	联系方式的备注信息，用于助记，超过30个字符将被截断
	auto_create_room	否	当群满了后，是否自动新建群。0-否；1-是。 默认为1
	room_base_name	否	自动建群的群名前缀，当auto_create_room为1时有效。最长40个utf8字符
	room_base_id	否	自动建群的群起始序号，当auto_create_room为1时有效
	chat_id_list	是	使用该配置的客户群ID列表，支持5个。见客户群ID获取方法
	state	否	企业自定义的state参数，用于区分不同的入群渠道。不超过30个UTF-8字符
				如果有设置此参数，在调用获取客户群详情接口时会返回每个群成员对应的该参数值，详见文末附录2

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub update_join_way {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/groupchat/update_join_way?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del_join_way(access_token, hash);

删除客户群进群方式配置

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92229#删除客户群进群方式配置>

=head3 请求说明：

删除一个进群方式配置。

=head4 请求包结构体为：

    {
		"config_id": "42b34949e138eb6e027c123cba77faaa"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	config_id	是	企业联系方式的配置id

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub del_join_way {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/groupchat/del_join_way?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 统计管理

获取「群聊数据统计」数据
最后更新：2023/12/01

=head3 请求说明：

获取指定日期的统计数据。注意，企业微信仅存储180天的数据。

=head2 statistic(access_token, hash);

获取「群聊数据统计」数据-按群主聚合的方式

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92133#按群主聚合的方式>

=head4 请求包结构体为：

    {
		"day_begin_time": 1600272000,
		"day_end_time": 1600444800,
		"owner_filter": {
			"userid_list": ["zhangsan"]
		},
		"order_by": 2,
		"order_asc": 0,
		"offset" : 0,
		"limit" : 1000
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	day_begin_time	是	起始日期的时间戳，填当天的0时0分0秒（否则系统自动处理为当天的0分0秒）。取值范围：昨天至前180天。
	day_end_time	否	结束日期的时间戳，填当天的0时0分0秒（否则系统自动处理为当天的0分0秒）。取值范围：昨天至前180天。
						如果不填，默认同 day_begin_time（即默认取一天的数据）
	owner_filter	是	群主过滤。
						如果不填，表示获取应用可见范围内全部群主的数据（但是不建议这么用，如果可见范围人数超过1000人，为了防止数据包过大，会报错 81017）
	owner_filter.userid_list	是	群主ID列表。最多100个
	order_by	否	排序方式。
					1 - 新增群的数量
					2 - 群总数
					3 - 新增群人数
					4 - 群总人数

此接口查询的时间范围为 [day_begin_time, day_end_time]，前后均为闭区间（即包含day_end_time当天的数据），支持的最大查询跨度为30天；
用户最多可获取最近180天内的数据（超过180天企业微信将不再存储）；
当传入的时间不为0点时，会向下取整，如传入1554296400(Wed Apr 3 21:00:00 CST 2019)会被自动转换为1554220800（Wed Apr 3 00:00:00 CST 2019）;

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用使用，需具有“企业客户权限->客户群->获取客户群的数据统计”权限。
对于第三方/自建应用，群主必须在应用的可见范围。

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"total": 2,
		"next_offset": 2,
		"items": [{
				"owner": "zhangsan",
				"data": {
					"new_chat_cnt": 2,
					"chat_total": 2,
					"chat_has_msg": 0,
					"new_member_cnt": 0,
					"member_total": 6,
					"member_has_msg": 0,
					"msg_total": 0,
					"migrate_trainee_chat_cnt": 3
				}
			},
			{
				"owner": "lisi",
				"data": {
					"new_chat_cnt": 1,
					"chat_total": 3,
					"chat_has_msg": 2,
					"new_member_cnt": 0,
					"member_total": 6,
					"member_has_msg": 0,
					"msg_total": 0,
					"migrate_trainee_chat_cnt": 3
				}
			}
		]
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	total	命中过滤条件的记录总个数
	next_offset	当前分页的下一个offset。当next_offset和total相等时，说明已经取完所有
	items	记录列表。表示某个群主所拥有的客户群的统计数据
	items.owner	群主ID
	items.data	详情
	items.data.new_chat_cnt	新增客户群数量
	items.data.chat_total	截至当天客户群总数量
	items.data.chat_has_msg	截至当天有发过消息的客户群数量
	items.data.new_member_cnt	客户群新增群人数。
	items.data.member_total	截至当天客户群总人数
	items.data.member_has_msg	截至当天有发过消息的群成员数
	items.data.msg_total	截至当天客户群消息总数
	items.data.migrate_trainee_chat_cnt	截至当天新增迁移群数(仅教培行业返回)

=cut

sub statistic {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/groupchat/statistic?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 statistic_group_by_day(access_token, hash);

获取「群聊数据统计」数据-按自然日聚合的方式

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92133#按自然日聚合的方式>

=head3 请求说明：

获取指定日期的统计数据。注意，企业微信仅存储180天的数据。

=head4 请求包结构体为：

    {
		"day_begin_time": 1600272000,
		"day_end_time": 1600358400,
		"owner_filter": {
			"userid_list": ["zhangsan"]
		}
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	day_begin_time	是	起始日期的时间戳，填当天的0时0分0秒（否则系统自动处理为当天的0分0秒）。取值范围：昨天至前180天。
	day_end_time	否	结束日期的时间戳，填当天的0时0分0秒（否则系统自动处理为当天的0分0秒）。取值范围：昨天至前180天。
						如果不填，默认同 day_begin_time（即默认取一天的数据）
	owner_filter	是	群主过滤。
						如果不填，表示获取应用可见范围内全部群主的数据（但是不建议这么用，如果可见范围人数超过1000人，为了防止数据包过大，会报错 81017）
	owner_filter.userid_list	是	群主ID列表。最多100个

此接口查询的时间范围为 [day_begin_time, day_end_time]，前后均为闭区间（即包含day_end_time当天的数据），支持的最大查询跨度为30天；
用户最多可获取最近180天内的数据（超过180天企业微信将不再存储）；
当传入的时间不为0点时，会向下取整，如传入1554296400(Wed Apr 3 21:00:00 CST 2019)会被自动转换为1554220800（Wed Apr 3 00:00:00 CST 2019）;

=head4 权限说明：

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用使用，需具有“企业客户权限->客户群->获取客户群的数据统计”权限。
对于第三方/自建应用，群主必须在应用的可见范围。

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"items": [{
				"stat_time": 1600272000,
				"data": {
					"new_chat_cnt": 2,
					"chat_total": 2,
					"chat_has_msg": 0,
					"new_member_cnt": 0,
					"member_total": 6,
					"member_has_msg": 0,
					"msg_total": 0,
					"migrate_trainee_chat_cnt": 3
				}
			},
			{
				"stat_time": 1600358400,
				"data": {
					"new_chat_cnt": 2,
					"chat_total": 2,
					"chat_has_msg": 0,
					"new_member_cnt": 0,
					"member_total": 6,
					"member_has_msg": 0,
					"msg_total": 0,
					"migrate_trainee_chat_cnt": 3
				}
			}
		]
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	items	记录列表。表示某个自然日客户群的统计数据
	items.stat_time	数据日期，为当日0点的时间戳
	items.data	详情
	items.data.new_chat_cnt	新增客户群数量
	items.data.chat_total	截至当天客户群总数量
	items.data.chat_has_msg	截至当天有发过消息的客户群数量
	items.data.new_member_cnt	客户群新增群人数。
	items.data.member_total	截至当天客户群总人数
	items.data.member_has_msg	截至当天有发过消息的群成员数
	items.data.msg_total	截至当天客户群消息总数
	items.data.migrate_trainee_chat_cnt	截至当天新增迁移群数(仅教培行业返回)

=cut

sub statistic_group_by_day {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/groupchat/statistic_group_by_day?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
