package QQ::weixin::work::living;

=encoding utf8

=head1 Name

QQ::weixin::work::living

=head1 DESCRIPTION

直播

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.06';
our @EXPORT = qw/ create modify cancel delete_replay_data get_living_code
				get_user_all_livingid get_living_info get_watch_stat get_living_share_info /;

=head1 FUNCTION

=head2 create(access_token, hash);

创建预约直播

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93637>

=head3 请求说明：

=head4 请求包结构体为：

    {
	   "anchor_userid": "zhangsan",
	   "theme": "theme",
	   "living_start": 1600000000,
	   "living_duration": 3600,
	   "description": "test description",
	   "type": 4,
	   "agentid" : 1000014,
	   "remind_time": 60,
	   "activity_cover_mediaid": "MEDIA_ID",
	   "activity_share_mediaid": "MEDIA_ID",
	   "activity_detail":
	   {
		   "description": "活动描述，非活动类型的直播不用传",
		   "image_list": [
				"MEDIA_ID_1",
				"MEDIA_ID_2"
		   ]
	   }
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证。获取方法查看“获取access_token”
	anchor_userid	是	直播发起者的userid
	theme	是	直播的标题，最多支持60个字节
	living_start	是	直播开始时间的unix时间戳
	living_duration	是	直播持续时长
	type	否	直播的类型，0：通用直播，1：小班课，2：大班课，3：企业培训，4：活动直播，默认 0。其中大班课和小班课仅k12学校和IT行业类型能够发起
	description	否	直播的简介，最多支持300个字节，仅对“通用直播”、“小班课”、“大班课”和“企业培训”生效，“活动直播”简介通过activity_detail.description控制
	agentid	否	授权方安装的应用agentid。仅旧的第三方多应用套件需要填此参数
	remind_time	否	指定直播开始前多久提醒用户，相对于living_start前的秒数，默认为0
	activity_cover_mediaid	否	活动直播特定参数，直播间封面图的mediaId
	activity_share_mediaid	否	活动直播特定参数，直播分享卡片图的mediaId
	activity_detail	否	活动直播特定参数，活动直播详情信息
	activity_detail.description	否	活动直播特定参数，活动直播简介
	activity_detail.image_list	否	活动直播特定参数，活动直播附图的mediaId列表，最多支持传5张，超过五张取前五张

=head4 权限说明：

发起人必须在应用可见范围内，「上课直播/直播」应用默认全员可见
系统应用「上课直播/直播」默认可使用直播接口
自建应用需要配置在“可调用接口的应用”里
第三方服务商创建应用的时候，需要开启“直播接口权限”

=head3 RETURN 返回结果：

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "livingid": "XXXXXXXXX"
	}

=head4 RETURN 参数说明：

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	livingid	直播id，通过此id可调用“进入直播”接口(包括小程序接口和JS-SDK接口)，以实现主播到点后的开播操作，以及观众进入直播详情预约和观看直播

=cut

sub create {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/living/create?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 modify(access_token, hash);

修改预约直播

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93640>

=head3 请求说明：

=head4 请求包结构体为：

    {
	   "livingid": "XXXXXXXXX",
	   "theme": "theme",
	   "living_start": 1600100000,
	   "living_duration": 3600,
	   "description": "test description",
	   "type": 1,
	   "remind_time": 60
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证。获取方法查看“获取access_token”
	livingid	是	直播id，仅允许修改预约状态下的直播id
	theme	否	直播的标题，最多支持60个字节
	living_start	否	直播开始时间的unix时间戳
	living_duration	否	直播持续时长
	type	否	直播的类型，0：通用直播，1：小班课，2：大班课，3：企业培训，4：活动直播。其中大班课和小班课仅k12学校和IT行业类型能够发起
	description	否	直播的简介，最多支持300个字节
	remind_time	否	指定直播开始前多久提醒用户，相对于living_start前的秒数，默认为0

=head4 权限说明：

仅允许修改当前应用创建的直播。

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

sub modify {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/living/modify?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 cancel(access_token, hash);

取消预约直播

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93638>

=head3 请求说明：

=head4 请求包结构体为：

    {
	   "livingid": "XXXXXXXXX"
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证。获取方法查看“获取access_token”
	livingid	是	直播id，仅允许取消预约状态下的直播id

=head4 权限说明：

仅允许取消当前应用创建的直播。

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

sub cancel {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/living/cancel?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete_replay_data(access_token, hash);

删除直播回放

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93874>

=head3 请求说明：

=head4 请求包结构体为：

    {
	   "livingid": "XXXXXXXXX"
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证。获取方法查看“获取access_token”
	livingid	是	直播id

=head4 权限说明：

仅允许取消当前应用创建的直播。

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

sub delete_replay_data {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/living/delete_replay_data?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_living_code(access_token, hash);

获取微信观看直播凭证

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93641#获取微信观看直播凭证>

=head3 请求说明：

通过微信观看直播的凭证，可在微信中H5或小程序页面唤起企业微信直播小程序，并进入对应直播或直播回放。

=head4 请求包结构体为：

    {
		"livingid": "XXXXXXXXX",
		"openid": "abcopenid"
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证。获取方法查看“获取access_token”
	livingid	是	直播id
	openid	是	微信用户的openid

=head4 权限说明：

非直播系统应用仅允许获取当前应用创建的微信观看直播凭证。
直播系统应用可以调用该企业任意直播的微信观看直播凭证。

=head3 RETURN 返回结果：

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "living_code": "abcdef"
	}

=head4 RETURN 参数说明：

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	living_code	微信观看直播凭证，5分钟内可以重复使用，且仅能在微信上使用。开发者获取到该凭证后可以在微信H5页面或小程序进入直播或直播回放页

=cut

sub get_living_code {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/living/get_living_code?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_user_all_livingid(access_token, hash);

获取成员直播ID列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93634>

=head3 请求说明：

通过此接口可以获取指定成员的所有直播ID

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"cursor": "NEXT_KEY",
		"limit": 20
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
	userid	是	企业成员的userid
	cursor	否	上一次调用时返回的next_cursor，第一次拉取可以不填
	limit	否	每次拉取的数据量，默认值和最大值都为100

=head4 权限说明：

「上课直播/直播」应用有获取用户的所有直播
自建应用和第三方应用只能获取本应用创建的直播


=head3 RETURN 返回结果：

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "next_cursor": "next_cursor",
	   "livingid_list":[
			"livingid1",
			"livingid2"
	   ]
	}

=head4 RETURN 参数说明：

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	next_cursor	当前数据最后一个key值，如果下次调用带上该值则从该key值往后拉，用于实现分页拉取，返回空字符串代表已经是最后一页
	livingid_list	直播ID列表

=cut

sub get_user_all_livingid {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/living/get_user_all_livingid?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_living_info(access_token,livingid);

获取直播详情

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93635>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
	livingid	是	直播ID

=head4 权限说明：

「上课直播/直播」应用可获取用户的所有直播
自建应用和第三方应用只能获取本应用创建的直播

=head3 RETURN 返回结果：

	{
	   "errcode": 0,
	   "errmsg": "ok",
	   "living_info":{
			"theme": "直角三角形讲解",
			"living_start": 1586405229,
			"living_duration": 1800,
			"status ": 3,
			"reserve_start": 1586405239,
			"reserve_living_duration": 1600,
			"description": "小学数学精选课程",
			"anchor_userid": "zhangsan",
			"main_department": 1,
			"viewer_num": 100,
			"comment_num": 110,
			"mic_num": 120,
			"open_replay": 1,
			"replay_status": 2,
			"type": 0,
			"push_stream_url": "https://www.qq.test.com",
			"online_count": 1,
			"subscribe_count": 1
		}
	}

=head4 RETURN 参数说明：

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	living_info	直播信息
	living_info.theme	直播主题
	living_info.living_start	直播开始时间戳
	living_info.living_duration	直播时长，单位为秒
	living_info.status	直播的状态，0：预约中，1：直播中，2：已结束，3：已过期，4：已取消
	living_info.reserve_start	直播预约的开始时间戳
	living_info.reserve_living_duration	直播预约时长，单位为秒
	living_info.description	直播的描述，最多支持100个汉字
	living_info.anchor_userid	主播的userid
	living_info.main_department	主播所在主部门id
	living_info.viewer_num	观看直播总人数
	living_info.comment_num	评论数
	living_info.mic_num	连麦发言人数
	living_info.open_replay	是否开启回放，1表示开启，0表示关闭
	living_info.replay_status	open_replay为1时才返回该字段。0表示生成成功，1表示生成中，2表示回放已删除，3表示生成失败
	living_info.type	直播的类型，0：通用直播，1：小班课，2：大班课，3：企业培训，4：活动直播
	living_info.push_stream_url	推流地址，仅直播类型为活动直播并且直播状态是待开播返回该字段
	living_info.online_count	当前在线观看人数
	living_info.subscribe_count	直播预约人数

=cut

sub get_living_info {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $livingid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/living/get_living_info?access_token=$access_token&livingid=$livingid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_watch_stat(access_token, hash);

获取直播观看明细

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93634>

=head3 请求说明：

通过该接口可以获取所有观看直播的人员统计

=head4 请求包结构体为：

    {
		"livingid": "livingid1",
		"next_key": "NEXT_KEY"
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
	livingid	是	直播的id
	next_key	否	上一次调用时返回的next_key，初次调用可以填"0"

=head4 权限说明：

「上课直播/直播」应用有获取用户的所有直播
自建应用和第三方应用只能获取本应用创建的直播


=head3 RETURN 返回结果：

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "ending":1,
	   "next_key": "NEXT_KEY",
	   "stat_info":{
			"users":[
				{
					"userid": "userid",
					"watch_time": 30,
					"is_comment": 1,
					"is_mic": 1
				}
			],
			"external_users":[
				{
					"external_userid": "external_userid1",
					"type": 1,
					"name": "user name",
					"watch_time": 30,
					"is_comment": 1,
					"is_mic": 1
				},
				{
					"external_userid": "external_userid2",
					"type": 2,
					"name": "user_name",
					"watch_time": 30,
					"is_comment": 1,
					"is_mic": 1
				}
			],
	   }
	}

=head4 RETURN 参数说明：

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	ending	是否结束。0：表示还有更多数据，需要继续拉取，1：表示已经拉取完所有数据。注意只能根据该字段判断是否已经拉完数据
	next_key	当前数据最后一个key值，如果下次调用带上该值则从该key值往后拉，用于实现分页拉取
	stat_info	统计信息列表
	stat_info.users	观看直播的企业成员列表
	stat_info.users.userid	企业成员的userid
	stat_info.users.watch_time	观看时长，单位为秒
	stat_info.users.is_comment	是否评论。0-否；1-是
	stat_info.users.is_mic	是否连麦发言。0-否；1-是
	stat_info.users.invitor_userid	邀请人的userid
	stat_info.users.invitor_external_userid	邀请人的external_userid
	stat_info.external_users	观看直播的外部成员列表
	stat_info.external_users.external_userid	外部成员的userid
	stat_info.external_users.type	外部成员类型，1表示该外部成员是微信用户，2表示该外部成员是企业微信用户
	stat_info.external_users.name	外部成员的名称
	stat_info.external_users.watch_time	观看时长，单位为秒
	stat_info.external_users.is_comment	是否评论。0-否；1-是
	stat_info.external_users.is_mic	是否连麦发言。0-否；1-是
	stat_info.external_users.invitor_userid	邀请人的userid，邀请人为企业内部成员时返回（观众首次进入直播时，其使用的直播卡片/二维码所对应的分享人；仅“推广产品”直播支持）
	stat_info.external_users.invitor_external_userid	邀请人的external_userid，邀请人为非企业内部成员时返回（观众首次进入直播时，其使用的直播卡片/二维码所对应的分享人；仅“推广产品”直播支持）

=cut

sub get_watch_stat {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/living/get_watch_stat?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_living_share_info(access_token, hash);

获取跳转小程序商城的直播观众信息

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94442>

=head3 请求说明：

通过此接口，开发者可获取跳转小程序商城的直播间(“推广产品”直播)观众id、邀请人id及对应直播间id，以打通卖货直播的“人货场”信息闭环。

=head4 请求包结构体为：

    {
		"ww_share_code": "CODE"
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
	ww_share_code	是	“推广产品”直播观众跳转小程序商城时会在小程序path中带上ww_share_code=xxxxx参数

=head4 权限说明：

系统应用「直播」默认可使用此接口
自建应用需要配置在“可调用接口的应用”里
第三方服务商创建应用的时候，需要开启“直播接口权限”
跳转的小程序需要与企业有绑定关系


=head3 RETURN 返回结果：

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "livingid": "livingid",
	   "viewer_userid": "viewer_userid",
	   "viewer_external_userid": "viewer_external_userid",
	   "invitor_userid": "invitor_userid",
	   "invitor_external_userid": "invitor_external_userid"
	}

=head4 RETURN 参数说明：

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	livingid	直播id
	viewer_userid	观众的userid，观众为企业内部成员时返回
	viewer_external_userid	观众的external_userid，观众为非企业内部成员时返回
	invitor_userid	邀请人的userid，邀请人为企业内部成员时返回（观众首次进入直播时，其使用的直播卡片/二维码所对应的分享人）
	invitor_external_userid	邀请人的external_userid，邀请人为非企业内部成员时返回 （观众首次进入直播时，其使用的直播卡片/二维码所对应的分享人）

=cut

sub get_living_share_info {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/living/get_living_share_info?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
