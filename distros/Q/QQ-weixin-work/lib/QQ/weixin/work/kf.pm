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

our $VERSION = '0.06';
our @EXPORT = qw/ add_contact_way
				sync_msg send_msg send_msg_on_event /;

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

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微信客服->获取基础信息”权限

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

读取消息

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94670#读取消息>

=head3 请求说明：

微信客户发送的消息、接待人员在企业微信回复的消息、发送消息接口发送失败事件（如被用户拒收）、客户点击菜单消息的回复消息，可以通过该接口获取具体的消息内容和事件。不支持读取通过发送消息接口发送的消息。
支持的消息类型：文本、图片、语音、视频、文件、位置、链接、名片、小程序、菜单、事件。

接口定义

=head4 请求包结构体为：

    {
		"cursor": "4gw7MepFLfgF2VC5npN",
		"token": "ENCApHxnGDNAVNY4AaSJKj4Tb5mwsEMzxhFmHVGcra996NR",
		"limit": 1000,
		"voice_format": 0
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

=head3 权限说明

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微信客服权限->管理帐号、分配会话和收发消息”权限

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

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微信客服权限->管理帐号、分配会话和收发消息”权限

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

企业需要使用“微信客服”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微信客服权限->管理帐号、分配会话和收发消息”权限

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


1;
__END__
