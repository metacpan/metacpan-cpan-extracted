package QQ::weixin::work::user;

=encoding utf8

=head1 Name

QQ::weixin::work::user

=head1 DESCRIPTION

通讯录管理->成员管理

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.06';
our @EXPORT = qw/ create get update delete batchdelete
                  simplelist list convert_to_openid convert_to_userid authsucc
                  get_active_stat getuserid
                  getuserinfo get_mobile_hashcode /;

=head1 FUNCTION

=head2 create(access_token, hash);

创建成员

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90195>

=head3 请求说明：

=head4 请求包结构体为：

    {
      "userid": "zhangsan",
      "name": "张三",
      "alias": "jackzhang",
      "mobile": "13800000000",
      "department": [1, 2],
      "order":[10,40],
      "position": "产品经理",
      "gender": "1",
      "email": "zhangsan@gzdev.com",
      "is_leader_in_dept": [1, 0],
      "enable":1,
      "avatar_mediaid": "2-G6nrLmr5EC3MNb_-zL1dDdzkd0p7cNliYu9V5w7o8K0",
      "telephone": "020-123456",
      "address": "广州市海珠区新港中路",
      "extattr": {
        "attrs": [
            {
                "type": 0,
                "name": "文本名称",
                "text": {
                    "value": "文本"
                }
            },
            {
                "type": 1,
                "name": "网页名称",
                "web": {
                    "url": "http://www.test.com",
                    "title": "标题"
                }
            }
        ]
      },
      "to_invite": true,
      "external_position": "高级产品经理",
      "external_profile": {
        "external_corp_name": "企业简称",
        "external_attr": [
            {
                "type": 0,
                "name": "文本名称",
                "text": {
                    "value": "文本"
                }
            },
            {
                "type": 1,
                "name": "网页名称",
                "web": {
                    "url": "http://www.test.com",
                    "title": "标题"
                }
            },
            {
                "type": 2,
                "name": "测试app",
                "miniprogram": {
                    "appid": "wx8bd8012614784fake",
                    "pagepath": "/index",
                    "title": "my miniprogram"
                }
            }
        ]
      }
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证。获取方法查看“获取access_token”
	userid	是	成员UserID。对应管理端的帐号，企业内必须唯一。长度为1~64个字节。只能由数字、字母和“_-@.”四种字符组成，且第一个字符必须是数字或字母。系统进行唯一性检查时会忽略大小写。
	name	是	成员名称。长度为1~64个utf8字符
	alias	否	成员别名。长度1~64个utf8字符
	mobile	否	手机号码。企业内必须唯一，mobile/email二者不能同时为空
	department	是	成员所属部门id列表，不超过100个
	order	否	部门内的排序值，默认为0，成员次序以创建时间从小到大排列。个数必须和参数department的个数一致，数值越大排序越前面。有效的值范围是[0, 2^32)
	position	否	职务信息。长度为0~128个字符
	gender	否	性别。1表示男性，2表示女性
	email	否	邮箱。长度6~64个字节，且为有效的email格式。企业内必须唯一，mobile/email二者不能同时为空
	biz_mail	否	企业邮箱。仅对开通企业邮箱的企业有效。长度6~64个字节，且为有效的企业邮箱格式。企业内必须唯一。未填写则系统会为用户生成默认企业邮箱（可修改一次）
	telephone	否	座机。32字节以内，由纯数字、“-”、“+”或“,”组成。
	is_leader_in_dept	否	个数必须和参数department的个数一致，表示在所在的部门内是否为部门负责人。1表示为部门负责人，0表示非部门负责人。在审批(自建、第三方)等应用里可以用来标识上级审批人
	direct_leader	否	直属上级UserID，设置范围为企业内成员，可以设置最多5个上级
	avatar_mediaid	否	成员头像的mediaid，通过素材管理接口上传图片获得的mediaid
	enable	否	启用/禁用成员。1表示启用成员，0表示禁用成员
	extattr	否	自定义字段。自定义字段需要先在WEB管理端添加，见扩展属性添加方法，否则忽略未知属性的赋值。
	extattr.type	是	属性类型: 0-文本 1-网页 2-小程序
	extattr.name	是	属性名称： 需要先确保在管理端有创建该属性，否则会忽略
	extattr.text	否	文本类型的属性
	extattr.text.value	是	文本属性内容，长度限制64个UTF8字符
	extattr.web	否	网页类型的属性，url和title字段要么同时为空表示清除该属性，要么同时不为空
	extattr.web.url	是	网页的url,必须包含http或者https头
	extattr.web.title	是	网页的展示标题,长度限制12个UTF8字符
	to_invite	否	是否邀请该成员使用企业微信（将通过微信服务通知或短信或邮件下发邀请，每天自动下发一次，最多持续3个工作日），默认值为true。
	external_profile	否	成员对外属性，字段详情见对外属性
	external_position	否	对外职务，如果设置了该值，则以此作为对外展示的职务，否则以position来展示。长度12个汉字内
	nickname	否	视频号名字（设置后，成员将对外展示该视频号）。须从企业绑定到企业微信的视频号中选择，可在“我的企业”页中查看绑定的视频号
	address	否	地址。长度最大128个字符
	main_department	否	主部门

=head3 权限说明

仅通讯录同步助手或第三方通讯录应用可调用。

注意，每个部门下的部门、成员总数不能超过3万个。建议保证创建department对应的部门和创建成员是串行化处理。

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "created"
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

=cut

sub create {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/user/create?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token, userid);

读取成员

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90196>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	        是	成员UserID。对应管理端的帐号，企业内必须唯一。不区分大小写，长度为1~64个字节

=head3 权限说明

应用须拥有指定成员的查看权限。

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"userid": "zhangsan",
		"name": "张三",
		"department": [1, 2],
		"order": [1, 2],
		"position": "后台工程师",
		"mobile": "13800000000",
		"gender": "1",
		"email": "zhangsan@gzdev.com",
		"biz_mail":"zhangsan@qyycs2.wecom.work",
		"is_leader_in_dept": [1, 0],
		"direct_leader":["lisi","wangwu"],
		"avatar": "http://wx.qlogo.cn/mmopen/ajNVdqHZLLA3WJ6DSZUfiakYe37PKnQhBIeOQBO4czqrnZDS79FH5Wm5m4X69TBicnHFlhiafvDwklOpZeXYQQ2icg/0",
		"thumb_avatar": "http://wx.qlogo.cn/mmopen/ajNVdqHZLLA3WJ6DSZUfiakYe37PKnQhBIeOQBO4czqrnZDS79FH5Wm5m4X69TBicnHFlhiafvDwklOpZeXYQQ2icg/100",
		"telephone": "020-123456",
		"alias": "jackzhang",
		"address": "广州市海珠区新港中路",
		"open_userid": "xxxxxx",
		"main_department": 1,
		"extattr": {
			"attrs": [
				{
					"type": 0,
					"name": "文本名称",
					"text": {
						"value": "文本"
					}
				},
				{
					"type": 1,
					"name": "网页名称",
					"web": {
						"url": "http://www.test.com",
						"title": "标题"
					}
				}
			]
		},
		"status": 1,
		"qr_code": "https://open.work.weixin.qq.com/wwopen/userQRCode?vcode=xxx",
		"external_position": "产品经理",
		"external_profile": {
			"external_corp_name": "企业简称",
			"wechat_channels": {
				"nickname": "视频号名称",
				"status": 1
			},
			"external_attr": [{
					"type": 0,
					"name": "文本名称",
					"text": {
						"value": "文本"
					}
				},
				{
					"type": 1,
					"name": "网页名称",
					"web": {
						"url": "http://www.test.com",
						"title": "标题"
					}
				},
				{
					"type": 2,
					"name": "测试app",
					"miniprogram": {
						"appid": "wx8bd80126147dFAKE",
						"pagepath": "/index",
						"title": "my miniprogram"
					}
				}
			]
		}
	}


=head4 RETURN 参数说明

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	userid	成员UserID。对应管理端的帐号，企业内必须唯一。不区分大小写，长度为1~64个字节
	name	成员名称；第三方不可获取，调用时返回userid以代替name；代开发自建应用需要管理员授权才返回；对于非第三方创建的成员，第三方通讯录应用也不可获取；未返回name的情况需要通过通讯录展示组件来展示名字
	mobile	手机号码，代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	department	成员所属部门id列表，仅返回该应用有查看权限的部门id；成员授权模式下，固定返回根部门id，即固定为1。对授权了“组织架构信息”权限的第三方应用，返回成员所属的全部部门id
	order	部门内的排序值，默认为0。数量必须和department一致，数值越大排序越前面。值范围是0, 2^32)。[成员授权模式下不返回该字段
	position	职务信息；代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	gender	性别。0表示未定义，1表示男性，2表示女性。第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段。注：不可获取指返回值0
	email	邮箱，代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	biz_mail	企业邮箱，代开发自建应用不返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	is_leader_in_dept	表示在所在的部门内是否为部门负责人，数量与department一致；第三方通讯录应用或者授权了“组织架构信息-应用可获取企业的部门组织架构信息-部门负责人”权限的第三方应用可获取；对于非第三方创建的成员，第三方通讯录应用不可获取；上游企业不可获取下游企业成员该字段
	direct_leader	直属上级UserID，返回在应用可见范围内的直属上级列表，最多有五个直属上级；第三方通讯录应用或者授权了“组织架构信息-应用可获取可见范围内成员组织架构信息-直属上级”权限的第三方应用可获取；对于非第三方创建的成员，第三方通讯录应用不可获取；上游企业不可获取下游企业成员该字段
	avatar	头像url。 第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	thumb_avatar	头像缩略图url。第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	telephone	座机。代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	alias	别名；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	extattr	扩展属性，代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	status	激活状态: 1=已激活，2=已禁用，4=未激活，5=退出企业。
	已激活代表已激活企业微信或已关注微信插件（原企业号）。未激活代表既未激活企业微信又未关注微信插件（原企业号）。
	qr_code	员工个人二维码，扫描可添加为外部联系人(注意返回的是一个url，可在浏览器上打开该url以展示二维码)；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	external_profile	成员对外属性，字段详情见对外属性；代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	external_position	对外职务，如果设置了该值，则以此作为对外展示的职务，否则以position来展示。代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	address	地址。代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	open_userid	全局唯一。对于同一个服务商，不同应用获取到企业内同一个成员的open_userid是相同的，最多64个字节。仅第三方应用可获取
	main_department	主部门，仅当应用对主部门有查看权限时返回。

=cut

sub get {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $userid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/user/get?access_token=$access_token&userid=$userid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update(access_token, hash);

更新成员

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90197>

=head3 请求说明：

=head4 请求包体:

    {
      "userid": "zhangsan",
      "name": "李四",
      "department": [1],
      "order": [10],
      "position": "后台工程师",
      "mobile": "13800000000",
      "gender": "1",
      "email": "zhangsan@gzdev.com",
      "is_leader_in_dept": [1],
      "enable": 1,
      "avatar_mediaid": "2-G6nrLmr5EC3MNb_-zL1dDdzkd0p7cNliYu9V5w7o8K0",
      "telephone": "020-123456",
      "alias": "jackzhang",
      "address": "广州市海珠区新港中路",
      "extattr": {
        "attrs": [
            {
                "type": 0,
                "name": "文本名称",
                "text": {
                    "value": "文本"
                }
            },
            {
                "type": 1,
                "name": "网页名称",
                "web": {
                    "url": "http://www.test.com",
                    "title": "标题"
                }
            }
        ]
      },
      "external_position": "工程师",
      "external_profile": {
        "external_corp_name": "企业简称",
        "external_attr": [
            {
                "type": 0,
                "name": "文本名称",
                "text": {
                    "value": "文本"
                }
            },
            {
                "type": 1,
                "name": "网页名称",
                "web": {
                    "url": "http://www.test.com",
                    "title": "标题"
                }
            },
            {
                "type": 2,
                "name": "测试app",
                "miniprogram": {
                    "appid": "wx8bd80126147dFAKE",
                    "pagepath": "/index",
                    "title": "my miniprogram"
                }
            }
        ]
      }
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
	userid	是	成员UserID。对应管理端的帐号，企业内必须唯一。不区分大小写，长度为1~64个字节
	name	否	成员名称。长度为1~64个utf8字符
	alias	否	别名。长度为1-64个utf8字符
	mobile	否	手机号码。企业内必须唯一。若成员已激活企业微信，则需成员自行修改（此情况下该参数被忽略，但不会报错）
	department	否	成员所属部门id列表，不超过100个
	order	否	部门内的排序值，默认为0。当有传入department时有效。数量必须和department一致，数值越大排序越前面。有效的值范围是[0, 2^32)
	position	否	职务信息。长度为0~128个字符
	gender	否	性别。1表示男性，2表示女性
	email	否	邮箱。长度不超过64个字节，且为有效的email格式。企业内必须唯一。
	biz_mail	否	邮箱。企业邮箱。仅对开通企业邮箱的企业有效。长度6~64个字节，且为有效的企业邮箱格式。企业内必须唯一
	telephone	否	座机。由1-32位的纯数字、“-”、“+”或“,”组成
	is_leader_in_dept	否	部门负责人字段，个数必须和department一致，表示在所在的部门内是否为负责人。
	direct_leader	否	直属上级，可以设置企业范围内成员为直属上级，最多设置5个
	avatar_mediaid	否	成员头像的mediaid，通过素材管理接口上传图片获得的mediaid
	enable	否	启用/禁用成员。1表示启用成员，0表示禁用成员
	extattr	否	自定义字段。自定义字段需要先在WEB管理端添加，见扩展属性添加方法，否则忽略未知属性的赋值。
	extattr.type	是	属性类型: 0-文本 1-网页 2-小程序
	extattr.name	是	属性名称： 需要先确保在管理端有创建该属性，否则会忽略
	extattr.text	否	文本类型的属性
	extattr.text.value	是	文本属性内容,长度限制64个UTF8字符
	extattr.web	否	网页类型的属性，url和title字段要么同时为空表示清除该属性，要么同时不为空
	extattr.web.url	是	网页的url,必须包含http或者https头
	extattr.web.title	是	网页的展示标题,长度限制12个UTF8字符
	external_profile	否	成员对外属性，字段详情见对外属性
	external_position	否	对外职务，如果设置了该值，则以此作为对外展示的职务，否则以position来展示。不超过12个汉字
	nickname	否	视频号名字（设置后，成员将对外展示该视频号）。须从企业绑定到企业微信的视频号中选择，可在“我的企业”页中查看绑定的视频号
	address	否	地址。长度最大128个字符
	main_department	否	主部门

    特别地，如果userid由系统自动生成，则仅允许修改一次。新值可由new_userid字段指定。
    如果创建时『企业邮箱』为系统默认分配的，则仅允许修改一次，若创建时填入了合规的『企业邮箱』，则无法修改

=head3 权限说明

仅通讯录同步助手或第三方通讯录应用可调用。

注意，每个部门下的部门、成员总数不能超过3万个。

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "updated"
    }

=head3 RETURN 参数说明

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

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/user/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete(access_token, userid);

删除成员

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90198>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	        是	成员UserID。成员UserID。对应管理端的帐号

=head3 权限说明

仅通讯录同步助手或第三方通讯录应用可调用。
若是绑定了腾讯企业邮，则会同时删除邮箱帐号。

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "deleted"
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

=cut

sub delete {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $userid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/user/delete?access_token=$access_token&userid=$userid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 batchdelete(access_token, hash);

批量删除成员

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90199>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"useridlist": ["zhangsan", "lisi"]
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    useridlist	  是	成员UserID列表。对应管理端的帐号。最多支持200个。若存在无效UserID，直接返回错误

=head3 权限说明

    仅通讯录同步助手或第三方通讯录应用可调用。

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "deleted"
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

=cut

sub batchdelete {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/user/batchdelete?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 simplelist(access_token, department_id, fetch_child);

获取部门成员

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90200>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    department_id	是	获取的部门id
    fetch_child	否	是否递归获取子部门下面的成员：1-递归获取，0-只获取本部门

=head3 权限说明

应用须拥有指定部门的查看权限。

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
    	"userlist": [
          {
             "userid": "zhangsan",
             "name": "张三",
             "department": [1, 2],
			 "open_userid": "xxxxxx"
          }
      ]
    }

=head4 RETURN 参数说明

    参数	        说明
    errcode	    返回码
    errmsg	    对返回码的文本描述内容
    userlist	成员列表
    userid	    成员UserID。对应管理端的帐号
    name	     成员名称，此字段从2019年12月30日起，对新创建第三方应用不再返回，2020年6月30日起，对所有历史第三方应用不再返回，后续第三方仅通讯录应用可获取，第三方页面需要通过通讯录展示组件来展示名字
    department	成员所属部门列表。列表项为部门ID，32位整型
    open_userid	全局唯一。对于同一个服务商，不同应用获取到企业内同一个成员的open_userid是相同的，最多64个字节。仅第三方应用可获取

=cut

sub simplelist {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $department_id = $_[1];
        my $fetch_child = $_[2] || 0;
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/user/simplelist?access_token=$access_token&department_id=$department_id&fetch_child=$fetch_child");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token, department_id, fetch_child);

获取部门成员详情

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90201>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    department_id	是	获取的部门id
    fetch_child	    否	1/0：是否递归获取子部门下面的成员

=head3 权限说明

应用须拥有指定部门的查看权限。

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok",
        "userlist": [
            {
              "userid": "zhangsan",
              "name": "李四",
              "department": [1, 2],
              "order": [1, 2],
              "position": "后台工程师",
              "mobile": "13800000000",
              "gender": "1",
              "email": "zhangsan@gzdev.com",
              "is_leader_in_dept": [1, 0],
              "avatar": "http://wx.qlogo.cn/mmopen/ajNVdqHZLLA3WJ6DSZUfiakYe37PKnQhBIeOQBO4czqrnZDS79FH5Wm5m4X69TBicnHFlhiafvDwklOpZeXYQQ2icg/0",
              "thumb_avatar": "http://wx.qlogo.cn/mmopen/ajNVdqHZLLA3WJ6DSZUfiakYe37PKnQhBIeOQBO4czqrnZDS79FH5Wm5m4X69TBicnHFlhiafvDwklOpZeXYQQ2icg/100",
              "telephone": "020-123456",
              "enable": 1,
              "alias": "jackzhang",
              "status": 1,
              "address": "广州市海珠区新港中路",
              "hide_mobile" : 0,
              "english_name" : "jacky",
              "extattr": {
                "attrs": [
                    {
                        "type": 0,
                        "name": "文本名称",
                        "text": {
                            "value": "文本"
                        }
                    },
                    {
                        "type": 1,
                        "name": "网页名称",
                        "web": {
                            "url": "http://www.test.com",
                            "title": "标题"
                        }
                    }
                ]
              },
              "qr_code": "https://open.work.weixin.qq.com/wwopen/userQRCode?vcode=xxx",
              "external_position": "产品经理",
              "external_profile": {
                "external_corp_name": "企业简称",
                "external_attr": [{
                        "type": 0,
                        "name": "文本名称",
                        "text": {
                            "value": "文本"
                        }
                    },
                    {
                        "type": 1,
                        "name": "网页名称",
                        "web": {
                            "url": "http://www.test.com",
                            "title": "标题"
                        }
                    },
                    {
                        "type": 2,
                        "name": "测试app",
                        "miniprogram": {
                            "appid": "wx8bd80126147dFAKE",
                            "pagepath": "/index",
                            "title": "miniprogram"
                        }
                    }
                ]
              }
            }
        ]
    }

=head4 RETURN 参数说明

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	userlist	成员列表
	userid	成员UserID。对应管理端的帐号
	name	成员名称；第三方不可获取，调用时返回userid以代替name；代开发自建应用需要管理员授权才返回；对于非第三方创建的成员，第三方通讯录应用也不可获取；未返回名称的情况需要通过通讯录展示组件来展示名字
	mobile	手机号码，代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	department	成员所属部门id列表，仅返回该应用有查看权限的部门id。对授权了“组织架构信息”的第三方应用，返回成员所属的全部部门id列表
	order	部门内的排序值，默认为0。数量必须和department一致，数值越大排序越前面。值范围是[0, 2^32)
	position	职务信息；代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	gender	性别。0表示未定义，1表示男性，2表示女性。第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段。注：不可获取指返回值为0
	email	邮箱，代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	biz_mail	企业邮箱，代开发自建应用不返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	is_leader_in_dept	表示在所在的部门内是否为部门负责人。0-否；1-是。是一个列表，数量必须与department一致。第三方通讯录应用或者授权了“组织架构信息-应用可获取企业的部门组织架构信息-部门负责人”权限的第三方应用可获取；对于非第三方创建的成员，第三方通讯录应用不可获取；上游企业不可获取下游企业成员该字段
	direct_leader	直属上级UserID，返回在应用可见范围内的直属上级列表，最多有五个直属上级；第三方通讯录应用或者授权了“组织架构信息-应用可获取可见范围内成员组织架构信息-直属上级”权限的第三方应用可获取；对于非第三方创建的成员，第三方通讯录应用不可获取；上游企业不可获取下游企业成员该字段
	avatar	头像url。 第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	thumb_avatar	头像缩略图url。第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	telephone	座机。代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	alias	别名；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	extattr	扩展属性，代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	status	激活状态: 1=已激活，2=已禁用，4=未激活，5=退出企业。
	已激活代表已激活企业微信或已关注微信插件（原企业号）。未激活代表既未激活企业微信又未关注微信插件（原企业号）。
	qr_code	员工个人二维码，扫描可添加为外部联系人(注意返回的是一个url，可在浏览器上打开该url以展示二维码)；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	external_profile	成员对外属性，字段详情见对外属性；代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	external_position	对外职务，如果设置了该值，则以此作为对外展示的职务，否则以position来展示。代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	address	地址。代开发自建应用需要管理员授权才返回；第三方仅通讯录应用可获取；对于非第三方创建的成员，第三方通讯录应用也不可获取；上游企业不可获取下游企业成员该字段
	open_userid	全局唯一。对于同一个服务商，不同应用获取到企业内同一个成员的open_userid是相同的，最多64个字节。仅第三方应用可获取
	main_department	主部门，仅当应用对主部门有查看权限时返回。

=cut

sub list {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $department_id = $_[1];
        my $fetch_child = $_[2] || 0;
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/user/list?access_token=$access_token&department_id=$department_id&fetch_child=$fetch_child");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 convert_to_openid(access_token, hash);

userid与openid互换: userid转openid

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90202>

=head3 请求说明：

该接口使用场景为企业支付，在使用企业红包和向员工付款时，需要自行将企业微信的userid转成openid。

注：需要成员使用微信登录企业微信或者关注微工作台（原企业号）才能转成openid;

如果是外部联系人，请使用外部联系人openid转换转换openid

=head4 请求包结构体为：

    {
    	"userid": "zhangsan"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	是	企业内的成员id

=head3 权限说明

    成员必须处于应用的可见范围内

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok",
        "openid": "oDjGHs-1yCnGrRovBj2yHij5JAAA"
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    openid	企业微信成员userid对应的openid

=cut

sub convert_to_openid {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/user/convert_to_openid?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 convert_to_userid(access_token, hash);

userid与openid互换: openid转userid

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90202>

=head3 请求说明：

该接口主要应用于使用企业支付之后的结果查询。

开发者需要知道某个结果事件的openid对应企业微信内成员的信息时，可以通过调用该接口进行转换查询。

=head4 请求包结构体为：

    {
    	"openid": "oDjGHs-1yCnGrRovBj2yHij5JAAA"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    openid	是	在使用企业支付之后，返回结果的openid

=head3 权限说明

    管理组需对openid对应的企业微信成员有查看权限。

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok",
        "userid": "zhangsan"
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    userid	该openid在企业微信对应的成员userid

=cut

sub convert_to_userid {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/user/convert_to_userid?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 authsucc(access_token, userid);

二次验证

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90203>

=head3 请求说明：

此接口可以满足安全性要求高的企业进行成员加入验证。开启二次验证后，用户加入企业时需要跳转企业自定义的页面进行验证。

企业在开启二次验证时，必须在管理端填写企业二次验证页面的url。

当成员登录企业微信或关注微工作台（原企业号）加入企业时，会自动跳转到企业的验证页面。在跳转到企业的验证页面时，会带上如下参数：code=CODE。

企业收到code后，使用“通讯录同步助手”调用接口“根据code获取成员信息”获取成员的userid。然后在验证成员信息成功后，调用如下接口即可让成员成功加入企业。

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	        是	成员UserID。对应管理端的帐号

=head3 权限说明

=head3 RETURN 返回结果

    {
      "errcode": 0,
      "errmsg": "ok"
    }

=head4 RETURN 参数说明

    参数	        说明
    errcode	    返回码
    errmsg	    对返回码的文本描述内容

=cut

sub authsucc {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $userid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/user/authsucc?access_token=$access_token&userid=$userid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_active_stat(access_token, hash);

获取企业活跃成员数

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92714>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"date": "2020-03-27"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证。获取方法查看“获取access_token”
	date	是	具体某天的活跃人数，最长支持获取30天前数据

=head3 权限说明

    仅通讯录同步助手可调用。

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"active_cnt": 100
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    active_cnt	活跃成员数

=cut

sub get_active_stat {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/user/get_active_stat?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getuserid(access_token, hash);

手机号获取userid

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95402>

=head3 请求说明：

通过手机号获取其所对应的userid。

=head4 请求包结构体为：

    {
    	"mobile": "13430388888"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证，授权企业的token（通过获取企业凭证获取）或上游获取的下游企业的token（通过获取下级/下游企业的access_token）
	mobile	是	手机号码。长度为5~32个字节

=head3 权限说明

    应用须拥有指定成员的查看权限。

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"userid": "zhangsan"
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    userid	成员UserID。对应管理端的帐号，企业内必须唯一。不区分大小写，长度为1~64个字节

=head3 更多说明

    请确保手机号的正确性，若出错的次数较多，会导致1天不可调用。

=cut

sub getuserid {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/user/getuserid?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getuserinfo(access_token, code);

获取访问用户身份

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/91023>

=head3 请求说明：

该接口用于根据code获取成员信息

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    code	是	通过成员授权获取到的code，最大为512字节。每次成员授权带上的code将不一样，code只能使用一次，5分钟未被使用自动过期。

=head3 权限说明

跳转的域名须完全匹配access_token对应应用的可信域名，否则会返回50001错误。

=head3 RETURN 返回结果a

    {
      "errcode": 0,
      "errmsg": "ok",
      "UserId":"USERID",
      "DeviceId":"DEVICEID"
    }

=head4 RETURN 参数说明a

    参数	        说明
    errcode	    返回码
    errmsg	    对返回码的文本描述内容
    UserId	成员UserID。若需要获得用户详情信息，可调用通讯录接口：读取成员
    DeviceId	手机设备号(由企业微信在安装时随机生成，删除重装会改变，升级不受影响)

=head3 RETURN 返回结果b

        {
          "errcode": 0,
          "errmsg": "ok",
          "OpenId":"OPENID",
          "DeviceId":"DEVICEID"
        }

=head4 RETURN 参数说明b

        参数	        说明
        errcode	    返回码
        errmsg	    对返回码的文本描述内容
        OpenId	非企业成员的标识，对当前企业唯一
        DeviceId	手机设备号(由企业微信在安装时随机生成，删除重装会改变，升级不受影响)

=cut

sub getuserinfo {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $code = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/user/getuserinfo?access_token=$access_token&code=$code");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_mobile_hashcode(access_token, hash);

获取手机号随机串

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/91735>

=head3 请求说明：

支持企业获取手机号随机串，该随机串可直接在企业微信终端搜索手机号对应的微信用户。

=head4 请求包结构体为：

    {
      "mobile" : "+8613800000000",
      "state": "123456"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    mobile	是	手机号
    state	否	企业自定义的state参数，用于区分不同的添加渠道，在调用“获取外部联系人详情”时会返回该参数值

=head3 权限说明

    仅限自建应用调用。

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok",
        "hashcode": "1abcd2xaba3dxab4sdxa"
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    hashcode	手机号对应的随机串，20个字节，30分钟内有效

=cut

sub get_mobile_hashcode {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/user/get_mobile_hashcode?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
