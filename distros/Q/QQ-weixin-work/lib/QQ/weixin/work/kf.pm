package QQ::weixin::work::kf;

=encoding utf8

=head1 Name

QQ::weixin::work::kf

=head1 DESCRIPTION

微信客服

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ add_contact_way
				sync_msg send_msg send_msg_on_event
				get_corp_statistic get_servicer_statistic /;

=head1 FUNCTION

=head2 add_contact_way(access_token, hash);

获取客服帐号链接

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94665>

=head3 请求说明：

企业可通过此接口获取带有不同参数的客服链接，不同客服帐号对应不同的客服链接。获取后，企业可将链接嵌入到网页等场景中，微信用户点击链接即可向对应的客服帐号发起咨询。企业可依据参数来识别用户的咨询来源等。

=head4 请求包结构体为：

    {
		"open_kfid": "OPEN_KFID",
		"scene": "12345"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	open_kfid	是	string	客服帐号ID
	scene	否	string	场景值，字符串类型，由开发者自定义。
						不多于32字节
						字符串取值范围(正则表达式)：[0-9a-zA-Z_-]*

1. 若scene非空，返回的客服链接开发者可拼接scene_param=SCENE_PARAM参数使用，用户进入会话事件会将SCENE_PARAM原样返回。其中SCENE_PARAM需要urlencode，且长度不能超过128字节。
如 https://work.weixin.qq.com/kf/kfcbf8f8d07ac7215f?enc_scene=ENCGFSDF567DF&scene_param=a%3D1%26b%3D2
2. 历史调用接口返回的客服链接（包含encScene=XXX参数），不支持scene_param参数。
3. 返回的客服链接，不能修改或复制参数到其他链接使用。否则进入会话事件参数校验不通过，导致无法回调。

=head3 权限说明

调用的应用需要满足如下的权限

	应用类型	权限要求
	自建应用	配置到「 微信客服- 可调用接口的应用」中
	第三方应用	具有“微信客服->获取基础信息”权限
	代开发自建应用	具有“微信客服->获取基础信息”权限
	微信客服组件应用	具有“管理接入的微信客服->获取企业授权接入的客服账号->客服账号信息与链接”权限，仅可获取企业已授权的客服账号链接

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "url":"https://work.weixin.qq.com/kf/kfcbf8f8d07ac7215f?enc_scene=ENCGFSDF567DF"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int32	返回码
	errmsg	string	对返回码的文本描述内容
	url	string	客服链接，开发者可将该链接嵌入到H5页面中，用户点击链接即可向对应的微信客服帐号发起咨询。开发者也可根据该url自行生成需要的二维码图片

=cut

sub add_contact_way {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/add_contact_way?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 sync_msg(access_token, hash);

接收消息和事件
最后更新：2024/01/31
读取消息

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94670#读取消息>

=head3 请求说明：

微信客户发送的消息、接待人员在企业微信回复的消息、发送消息接口发送失败事件（如被用户拒收）、客户点击菜单消息的回复消息，可以通过该接口获取最近3天内具体的消息内容和事件。不支持读取通过发送消息接口发送的消息。
支持的消息类型：文本、图片、语音、视频、文件、位置、链接、名片、小程序、菜单、事件。

图片、语音、视频、文件消息的媒体文件有如下大小限制，超出会获取到文本提示消息：

图片：2MB
语音：2MB
视频：10MB
文件：20MB

接口定义

=head4 请求包结构体为：

	{
		"cursor": "4gw7MepFLfgF2VC5npN",
		"token": "ENCApHxnGDNAVNY4AaSJKj4Tb5mwsEMzxhFmHVGcra996NR",
		"limit": 1000,
		"voice_format": 0,
		"open_kfid": "wkxxxxxx"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	cursor	否	string	上一次调用时返回的next_cursor，第一次拉取可以不填。
						不多于64字节
	token	否	string	回调事件返回的token字段，10分钟内有效；可不填，如果不填接口有严格的频率限制。
						不多于128字节
	limit	否	uint32	期望请求的数据量，默认值和最大值都为1000。
						注意：可能会出现返回条数少于limit的情况，需结合返回的has_more字段判断是否继续请求。
	voice_format	否	uint32	语音消息类型，0-Amr 1-Silk，默认0。可通过该参数控制返回的语音格式
	open_kfid	是	string	指定拉取某个客服账号的消息

=head3 权限说明

调用的应用需要满足如下的权限

	应用类型	权限要求
	自建应用	配置到「 微信客服- 可调用接口的应用」中
	第三方应用	具有“微信客服->管理账号、分配会话和收发消息”权限
	代开发自建应用	具有“微信客服->管理账号、分配会话和收发消息”权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

只能通过API管理企业指定的客服账号。企业可在管理后台“微信客服-通过API管理微信客服账号”处设置对应的客服账号通过API来管理。
操作的客服账号对应的接待人员应在应用的可见范围内

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"next_cursor": "4gw7MepFLfgF2VC5npN",
		"has_more": 1,
		"msg_list": [
			{
				"msgid": "from_msgid_4622416642169452483",
				"open_kfid": "wkAJ2GCAAASSm4_FhToWMFea0xAFfd3Q",
				"external_userid": "wmAJ2GCAAAme1XQRC-NI-q0_ZM9ukoAw",
				"send_time": 1615478585,
				"origin": 3,
				"servicer_userid": "Zhangsan",
				"msgtype": "MSG_TYPE"
			}
		]
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	next_cursor	string	下次调用带上该值，则从当前的位置继续往后拉，以实现增量拉取。
						强烈建议对改该字段入库保存，每次请求读取带上，请求结束后更新。避免因意外丢，导致必须从头开始拉取，引起消息延迟。
	has_more	uint32	是否还有更多数据。0-否；1-是。
						不能通过判断msg_list是否空来停止拉取，可能会出现has_more为1，而msg_list为空的情况
	msg_list	obj[]	消息列表
	msg_list.msgid	string	消息ID
	msg_list.open_kfid	string	客服帐号ID（msgtype为event，该字段不返回）
	msg_list.external_userid	string	客户UserID（msgtype为event，该字段不返回）
	msg_list.send_time	uint64	消息发送时间
	msg_list.origin	uint32	消息来源。3-微信客户发送的消息 4-系统推送的事件消息 5-接待人员在企业微信客户端发送的消息
	msg_list.servicer_userid	string	从企业微信给客户发消息的接待人员userid（msgtype为event，该字段不返回）
	msg_list.msgtype	string	对不同的msgtype，有相应的结构描述，下面进一步说明

=cut

sub sync_msg {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/sync_msg?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 send_msg(access_token, hash);

微信客服-会话分配与消息收发-发送消息
最后更新：2023/12/19

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94677>

=head3 请求说明：

当微信客户处于“新接入待处理”或“由智能助手接待”状态下，可调用该接口给用户发送消息。
注意仅当微信客户在主动发送消息给客服后的48小时内，企业可发送消息给客户，最多可发送5条消息；若用户继续发送消息，企业可再次下发消息。
支持发送消息类型：文本、图片、语音、视频、文件、图文、小程序、菜单消息、地理位置。
目前该接口允许下发消息条数和下发时限如下：

	用户动作	允许下发条数限制	下发时限
	用户发送消息	5条	48 小时

=head4 请求包结构体为：

    

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	string	调用接口凭证

=head3 权限说明

调用的应用需要满足如下的权限

	应用类型	权限要求
	自建应用	配置到「 微信客服- 可调用接口的应用」中
	第三方应用	具有“微信客服->管理账号、分配会话和收发消息”权限
	代开发自建应用	具有“微信客服->管理账号、分配会话和收发消息”权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

只能通过API管理企业指定的客服账号。企业可在管理后台“微信客服-通过API管理微信客服账号”处设置对应的客服账号通过API来管理。
操作的客服账号对应的接待人员应在应用的可见范围内

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"msgid": "MSG_ID"
	}
	
注意：接口返回成功，不代表消息最终发送成功，还需要关注消息发送失败事件的回调事件。

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	msgid	string	消息ID。如果请求参数指定了msgid，则原样返回，否则系统自动生成并返回。若指定msgid，开发者需确保客服账号内唯一，否则接口返回错误。
					不多于32字节
					字符串取值范围(正则表达式)：[0-9a-zA-Z_-]*

=cut

sub send_msg {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/send_msg?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 send_msg_on_event(access_token, hash);

微信客服-会话分配与消息收发-发送欢迎语等事件响应消息
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95122>

=head3 请求说明：

当特定的事件回调消息包含code字段，或通过接口变更到特定的会话状态，会返回code字段。
开发者可以此code为凭证，调用该接口给用户发送相应事件场景下的消息，如客服欢迎语、客服提示语和会话结束语等。
除"用户进入会话事件"以外，响应消息仅支持会话处于获取该code的会话状态时发送，如将会话转入待接入池时获得的code仅能在会话状态为”待接入池排队中“时发送。

目前支持的事件场景和相关约束如下：

	事件场景	允许下发条数	code有效期	支持的消息类型	获取code途径
	用户进入会话，用于发送客服欢迎语	1条	20秒	文本、菜单	事件回调
	进入接待池，用于发送排队提示语等	1条	48小时	文本	转接会话接口
	从接待池接入会话，用于发送非工作时间的提示语或超时未回复的提示语等	1条	48小时	文本	事件回调、转接会话接口
	结束会话，用于发送结束会话提示语或满意度评价等	1条	20秒	文本、菜单	事件回调、转接会话接口

=head4 请求包结构体为：

    {
		"code": "CODE",
		"msgid": "MSG_ID",
		"msgtype": "MSG_TYPE"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	code	是	string	事件响应消息对应的code。通过事件回调下发，仅可使用一次。
	msgid	否	string	消息ID。如果请求参数指定了msgid，则原样返回，否则系统自动生成并返回。
						不多于32字节
						字符串取值范围(正则表达式)：[0-9a-zA-Z_-]*
	msgtype	是	string	消息类型。对不同的msgtype，有相应的结构描述，详见消息类型

「进入会话事件」响应消息：
如果满足通过API下发欢迎语条件（条件为：用户在过去48小时里未收过欢迎语，且未向客服发过消息），则用户进入会话事件会额外返回一个welcome_code，开发者以此为凭据调用接口（填到该接口code参数），即可向客户发送客服欢迎语。

=head3 权限说明

调用的应用需要满足如下的权限

	应用类型	权限要求
	自建应用	配置到「 微信客服- 可调用接口的应用」中
	第三方应用	具有“微信客服->管理账号、分配会话和收发消息”权限
	代开发自建应用	具有“微信客服->管理账号、分配会话和收发消息”权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

只能通过API管理企业指定的客服账号。企业可在管理后台“微信客服-通过API管理微信客服账号”处设置对应的客服账号通过API来管理。
操作的客服账号对应的接待人员应在应用的可见范围内

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"msgid": "MSG_ID"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	msgid	string	消息ID

=cut

sub send_msg_on_event {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/send_msg_on_event?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_corp_statistic(access_token, hash);

获取「客户数据统计」企业汇总数据
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95489>

=head3 请求说明：

通过此接口，可以获取咨询会话数、咨询客户数等企业汇总统计数据

=head4 请求包结构体为：

	{
		"open_kfid": "OPEN_KFID",
		"start_time": 1645545600,
		"end_time": 1645632000
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	open_kfid	是	string	客服账号ID
	start_time	是	uint32	起始日期的时间戳，填这一天的0时0分0秒（否则系统自动处理为当天的0分0秒）。取值范围：昨天至前180天
	end_time	是	uint32	结束日期的时间戳，填这一天的0时0分0秒（否则系统自动处理为当天的0分0秒）。取值范围：昨天至前180天

查询时间区间[start_time, end_time]为闭区间，最大查询跨度为31天，用户最多可获取最近180天内的数据。当天的数据需要等到第二天才能获取，建议在第二天早上六点以后再调用此接口获取前一天的数据
当传入的时间不为0点时，会向下取整，如传入1554296400(Wed Apr 3 21:00:00 CST 2019)会被自动转换为1554220800（Wed Apr 3 00:00:00 CST 2019）;
开启API或授权第三方应用管理会话，没有2022年3月11日以前的统计数据

=head3 权限说明

调用的应用需要满足如下的权限

	应用类型	权限要求
	自建应用	配置到「 微信客服- 可调用接口的应用」中
	第三方应用	具有“微信客服->服务工具->获取客服数据统计”权限
	代开发自建应用	具有“微信客服->服务工具->获取客服数据统计”权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

操作的客服账号对应的接待人员应在应用的可见范围内

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"statistic_list" : [
				{
					"stat_time" : 1645545600,
					"statistic" : {
						"session_cnt" : 2,
						"customer_cnt" : 1,
						"customer_msg_cnt" : 6,
						"upgrade_service_customer_cnt" : 0,
						"ai_session_reply_cnt" : 1,
						"ai_transfer_rate" : 1,
						"ai_knowledge_hit_rate" : 0,
						"msg_rejected_customer_cnt" : 1
					},
				},
				 {
					 "stat_time" : 1645632000,
					 "statistic" : {
						 ...
					 }
				}
			]
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	statistic_list	obj	统计数据列表
	statistic_list.stat_time	uint32	数据统计日期，为当日0点的时间戳
	statistic_list.statistic	obj	一天的统计数据。若当天未产生任何下列统计数据或统计数据还未计算完成则不会返回此项
	statistic_list.statistic.session_cnt	uint64	咨询会话数。客户发过消息并分配给接待人员或智能助手的客服会话数，转接不会产生新的会话
	statistic_list.statistic.customer_cnt	uint64	咨询客户数。在会话中发送过消息的客户数量，若客户多次咨询只计算一个客户
	statistic_list.statistic.customer_msg_cnt	uint64	咨询消息总数。客户在会话中发送的消息的数量
	statistic_list.statistic.upgrade_service_customer_cnt	uint64	升级服务客户数。通过「升级服务」功能成功添加专员或加入客户群的客户数，若同一个客户添加多个专员或客户群，只计算一个客户。在2022年3月10日以后才会有对应统计数据
	statistic_list.statistic.ai_session_reply_cnt	uint64	智能回复会话数。客户发过消息并分配给智能助手的咨询会话数。通过API发消息或者开启智能回复功能会将客户分配给智能助手
	statistic_list.statistic.ai_transfer_rate	float	转人工率。一个自然日内，客户给智能助手发消息的会话中，转人工的会话的占比。
	statistic_list.statistic.ai_knowledge_hit_rate	float	知识命中率。一个自然日内，客户给智能助手发送的消息中，命中知识库的占比。只有在开启了智能回复原生功能并配置了知识库的情况下，才会产生该项统计数据。当api托管了会话分配，智能回复原生功能失效。若不返回，代表没有向配置知识库的智能接待助手发送消息，该项无法计算
	statistic_list.statistic.msg_rejected_customer_cnt	uint64	被拒收消息的客户数。被接待人员设置了“不再接收消息”的客户数

=cut

sub get_corp_statistic {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/get_corp_statistic?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_servicer_statistic(access_token, hash);

获取「客户数据统计」接待人员明细数据
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95490>

=head3 请求说明：

通过此接口，可获取接入人工会话数、咨询会话数等与接待人员相关的统计信息

=head4 请求包结构体为：

	{
		"open_kfid": "OPEN_KFID",
		"servicer_userid":"zhangsan",
		"start_time": 1645545600,
		"end_time": 1645632000
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	open_kfid	是	string	客服账号ID
	servicer_userid	否	string	接待人员的userid。第三方应用为密文userid，即open_userid
	start_time	是	uint32	起始日期的时间戳，填当天的0时0分0秒（否则系统自动处理为当天的0分0秒）。取值范围：昨天至前180天
	end_time	是	uint32	结束日期的时间戳，填当天的0时0分0秒（否则系统自动处理为当天的0分0秒）。取值范围：昨天至前180天

servicer_userid为非必填参数:
1. 不指定servicer_userid，返回客服账号维度汇总数据；
2. 指定servicer_userid，返回该接待人员在此客服账号下的数据。
查询时间区间[start_time, end_time]为闭区间，最大查询跨度为31天，用户最多可获取最近180天内的数据。当天的数据需要等到第二天才能获取，建议在第二天早上六点以后再调用此接口获取前一天的数据
当传入的时间不为0点时，会向下取整，如传入1554296400(Wed Apr 3 21:00:00 CST 2019)会被自动转换为1554220800（Wed Apr 3 00:00:00 CST 2019）;
开启API或授权第三方应用管理会话，没有2022年3月11日以前的统计数据

=head3 权限说明

调用的应用需要满足如下的权限

	应用类型	权限要求
	自建应用	配置到「 微信客服- 可调用接口的应用」中
	第三方应用	具有“微信客服->服务工具->获取客服数据统计”权限
	代开发自建应用	具有“微信客服->服务工具->获取客服数据统计”权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

操作的客服账号对应的接待人员应在应用的可见范围内

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"statistic_list" : [
				{
					"stat_time" : 1645545600,
					"statistic" : {
						"session_cnt" : 1,
						"customer_cnt" : 1,
						"customer_msg_cnt" : 1,
						"reply_rate" : 1,
						"first_reply_average_sec" : 17,
						"satisfaction_investgate_cnt" : 1,
						"satisfaction_participation_rate" : 1,
						"satisfied_rate" : 1,
						"middling_rate" : 0,
						"dissatisfied_rate" : 0,
						"upgrade_service_customer_cnt" : 0,
						"upgrade_service_member_invite_cnt" : 0,
						"upgrade_service_member_customer_cnt" : 0,
						"upgrade_service_groupchat_invite_cnt" : 0,
						"upgrade_service_groupchat_customer_cnt" : 0,
						"msg_rejected_customer_cnt" : 1
					}
				},
				{
					 "stat_time" : 1645632000,
					 "statistic" : {
						...
					 }
				}
			]
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	statistic_list	obj	统计数据列表
	statistic_list.stat_time	uint32	数据统计日期，为当日0点的时间戳
	statistic_list.statistic	obj	一天的统计数据。若当天未产生任何下列统计数据或统计数据还未计算完成则不会返回此项
	statistic_list.statistic.session_cnt	uint64	接入人工会话数。客户发过消息并分配给接待人员的咨询会话数
	statistic_list.statistic.customer_cnt	uint64	咨询客户数。在会话中发送过消息且接入了人工会话的客户数量，若客户多次咨询只计算一个客户
	statistic_list.statistic.customer_msg_cnt	uint64	咨询消息总数。客户在会话中发送的消息的数量
	statistic_list.statistic.reply_rate	float	人工回复率。一个自然日内，客户给接待人员发消息的会话中，接待人员回复了的会话的占比。若数据项不返回，代表没有给接待人员发送消息的客户，此项无法计算。
	statistic_list.statistic.first_reply_average_sec	float	平均首次响应时长，单位：秒。一个自然日内，客户给接待人员发送的第一条消息至接待人员回复之间的时长，为首次响应时长。所有的首次回复总时长/已回复的咨询会话数，即为平均首次响应时长 。若数据项不返回，代表没有给接待人员发送消息的客户，此项无法计算
	statistic_list.statistic.satisfaction_investgate_cnt	uint64	满意度评价发送数。当api托管了会话分配，满意度原生功能失效，满意度评价发送数为0
	statistic_list.statistic.satisfaction_participation_rate	float	满意度参评率 。当api托管了会话分配，满意度原生功能失效。若数据项不返回，代表没有发送满意度评价，此项无法计算
	statistic_list.statistic.satisfied_rate	float	“满意”评价占比 。在客户参评的满意度评价中，评价是“满意”的占比。当api托管了会话分配，满意度原生功能失效。若数据项不返回，代表没有客户参评的满意度评价，此项无法计算
	statistic_list.statistic.middling_rate	float	“一般”评价占比 。在客户参评的满意度评价中，评价是“一般”的占比。当api托管了会话分配，满意度原生功能失效。若数据项不返回，代表没有客户参评的满意度评价，此项无法计算
	statistic_list.statistic.dissatisfied_rate	float	“不满意”评价占比。在客户参评的满意度评价中，评价是“不满意”的占比。当api托管了会话分配，满意度原生功能失效。若数据项不返回，代表没有客户参评的满意度评价，此项无法计算
	statistic_list.statistic.upgrade_service_customer_cnt	uint64	升级服务客户数。通过「升级服务」功能成功添加专员或加入客户群的客户数，若同一个客户添加多个专员或客户群，只计算一个客户。在2022年3月10日以后才会有对应统计数据
	statistic_list.statistic.upgrade_service_member_invite_cnt	uint64	专员服务邀请数。接待人员通过「升级服务-专员服务」向客户发送服务专员名片的次数。在2022年3月10日以后才会有对应统计数据
	statistic_list.statistic.upgrade_service_member_customer_cnt	uint64	添加专员的客户数 。客户成功添加专员为好友的数量，若同一个客户添加多个专员，则计算多个客户数。在2022年3月10日以后才会有对应统计数据
	statistic_list.statistic.upgrade_service_groupchat_invite_cnt	uint64	客户群服务邀请数。接待人员通过「升级服务-客户群服务」向客户发送客户群二维码的次数。在2022年3月10日以后才会有对应统计数据
	statistic_list.statistic.upgrade_service_groupchat_customer_cnt	uint64	加入客户群的客户数。客户成功加入客户群的数量，若同一个客户加多个客户群，则计算多个客户数。在2022年3月10日以后才会有对应统计数据
	statistic_list.statistic.msg_rejected_customer_cnt	uint64	被拒收消息的客户数。被接待人员设置了“不再接收消息”的客户数

=cut

sub get_servicer_statistic {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/get_servicer_statistic?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
