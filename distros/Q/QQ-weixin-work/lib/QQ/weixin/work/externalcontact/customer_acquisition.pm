package QQ::weixin::work::externalcontact::customer_acquisition;

=encoding utf8

=head1 Name

QQ::weixin::work::externalcontact::customer_acquisition

=head1 DESCRIPTION

获客链接管理
最后更新：2023/11/13

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97297>

=cut

use strict;
use base qw(QQ::weixin::work::externalcontact);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ list_link get create_link update_link delete_link
				customer
				statistic /;

=head1 FUNCTION

=head2 list_link(access_token, hash);

获取获客链接列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97297#获取获客链接列表>

=head3 请求说明：

企业可通过此接口获取当前仍然有效的获客链接。

=head4 请求包结构体为：

	{
	   "limit":100,
	   "cursor":"CURSOR"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	limit	否	返回的最大记录数，整型，最大值100
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用可不填

=head4 权限说明：

调企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方或代开发应用需具有“企业客户权限->获客助手”权限
不支持客户联系系统应用调用

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"link_id_list":
		[
			"LINK_ID_AAA",
			"LINK_ID_BBB",
			"LINK_ID_CCC"
		],
		"next_cursor":"CURSOR"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	link_id_list	link_id列表
	next_cursor	分页游标，在下次请求时填写以获取之后分页的记录

=cut

sub list_link {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/customer_acquisition/list_link?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token, hash);

获取获客链接详情

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97297#获取获客链接详情>

=head3 请求说明：

企业可通过此接口根据获客链接id获取链接配置详情。

=head4 请求包结构体为：

	{
	   "link_id":"LINK_ID_AAA"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	link_id	是	获客链接id

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方或代开发应用需具有“企业客户权限->获客助手”权限
不支持客户联系系统应用调用

=head3 RETURN 返回结果：

	{
	  "errcode": 0,
	  "errmsg": "ok",
	  "link":
		{
			"link_name":"LINK_NAME",
			"url":"https://work.weixin.qq.com/ca/xxxxxx",
			"create_time":1672502400,
			"skip_verify":true
		},
		"range":
		{
			"user_list":["rocky","sam"],
			"department_list":[1]
		},
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	link.link_name	获客链接的名称
	link.url	获客链接实际的url
	link.create_time	创建时间
	link.skip_verify	是否无需验证，默认为true
	range.user_list	该获客链接使用范围成员列表
	range.department_list	该获客链接使用范围的部门列表

=cut

sub get {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/customer_acquisition/get?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 create_link(access_token, hash);

创建获客链接

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97297#创建获客链接>

=head3 请求说明：

企业可通过此接口创建新的获客链接。

=head4 请求包结构体为：

	{
	   "link_name":"获客链接1号",
	   "range":
	   {
			"user_list":["zhangsan","lisi"],
			"department_list":[2,3]
	   },
	   "skip_verify":true
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	link_name	是	链接名称
	range.user_list	否	此获客链接关联的userid列表，最多500人
	range.department_list	否	此获客链接关联的部门id列表，部门覆盖总人数最多500个
	skip_verify	否	是否无需验证，默认为true
	
range.user_list和range.department_list不可同时为空，range覆盖的总用户数不得超过500人。

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方或代开发应用需具有“企业客户权限->获客助手”权限
不支持客户联系系统应用调用

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"link":{
			"link_id":"LINK_ID",
			"link_name":"获客链接1号",
			"url":"URL",
			"create_time":1667232000
		}
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	link.link_id	获客链接的id
	link.link_name	获客链接名称
	link.url	获客链接
	create_time	获客链接创建时间

如为获取更好的跳转体验，也可将获客链接的url调整为scheme使用，方法如下：
scheme = weixin://biz/ww/profile/{urlencode(LINK_URL?customer_channel=STATE)}

示例，如果创建的获客链接为https://work.weixin.qq.com/ca/caXXXXX，
希望配置的customer_channel参数为WORK，则生成的scheme为:
weixin://biz/ww/profile/https%3A%2F%2Fwork.weixin.qq.com%2Fca%2FcaXXXXX%3Fcustomer_channel%3DWORK

=cut

sub create_link {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/customer_acquisition/create_link?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update_link(access_token, hash);

编辑获客链接

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97297#编辑获客链接>

=head3 请求说明：

企业可通过此接口编辑获客链接，修改获客链接的关联范围或修改获客链接的名称。

=head4 请求包结构体为：

	{
	   "link_id":"LINK_ID",
	   "link_name":"获客链接1号",
	   "range":
	   {
			"user_list":["zhangsan","lisi"],
			"department_list":[2,3]
	   },
	   "skip_verify":true
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	link_id	是	获客链接的id
	link_name	否	更新的链接名称
	range.user_list	否	此获客链接关联的userid列表，最多可关联500个
	range.department_list	否	此获客链接关联的部门id列表，部门覆盖总人数最多500个
	skip_verify	否	是否无需验证，默认为true

range为覆盖更新，覆盖的总人数不能超过500人。

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方或代开发应用需具有“企业客户权限->获客助手”权限
不支持客户联系系统应用调用

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

sub update_link {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/customer_acquisition/update_link?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete_link(access_token, hash);

删除获客链接

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97297#删除获客链接>

=head3 请求说明：

企业可通过此接口删除获客链接，删除后的获客链接将无法继续使用。

=head4 请求包结构体为：

	{
	   "link_id":"LINK_ID"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	link_id	是	获客链接的id

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方或代开发应用需具有“企业客户权限->获客助手”权限
不支持客户联系系统应用调用

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

sub delete_link {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/customer_acquisition/delete_link?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 customer(access_token, hash);

获取由获客链接添加的客户信息
最后更新：2023/10/18

获取获客客户列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97298>

=head3 请求说明：

企业可通过此接口获取到由指定的获客链接添加的客户列表。

=head4 请求包结构体为：

	{
	   "link_id":"LINK_ID",
	   "limit":1000,
	   "cursor":"CURSOR"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	link_id	是	获客链接id
	limit	否	返回的最大记录数，整型，最大值1000
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用可不填

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方或代开发应用需具有“企业客户权限->获客助手”权限
不支持客户联系系统应用调用

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"customer_list":
		[
			{
				"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACAAA",
				"userid":"zhangsan",
				"chat_status":0,
				"state":"CHANNEL_A"
			},
			{	
				"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACAAA",
				"userid":"lisi",
				"chat_status":0,
				"state":"CHANNEL_B"
			},
			{
				"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mBCBBB",
				"userid":"rocky",
				"chat_status":1,
				"state":"CHANNEL_A"
			}
		],
		"next_cursor":"CURSOR"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	customer_list.external_userid	客户external_userid
	customer_list.userid	通过获客链接添加此客户的跟进人userid
	customer_list.chat_status	会话状态，0-客户未发消息 1-客户已发送消息 2-客户发送消息状态未知
	customer_list.state	用于区分客户具体是通过哪个获客链接进行添加，用户可在获客链接后拼接customer_channel=自定义字符串，字符串不超过64字节，超过会被截断。通过点击带有customer_channel参数的链接获取到的客户，调用获客信息接口或获取客户详情接口时，返回的state参数即为链接后拼接自定义字符串
	next_cursor	分页游标，再下次请求时填写以获取之后分页的记录，如果已经没有更多的数据则返回空

=cut

sub customer {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/customer_acquisition/customer?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 statistic(access_token, hash);

获客助手额度管理与使用统计
最后更新：2023/08/08

查询链接使用详情

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97375#查询链接使用详情>

=head3 请求说明：

企业可通过此接口查询指定获客链接在指定时间范围内的访问情况。

=head4 请求包结构体为：

	{
	   "link_id":"caxxxxxxx",
	   "start_time":1688140800,
	   "end_time":1688486400
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	link_id	是	获客链接的id
	start_time	是	统计起始时间戳
	end_time	是	统计结束时间戳

注意：
1.统计范围的最小粒度为日，将自动转换为时间戳所在日进行统计，区间为闭区间。
2.仅可查询最近180天内的使用记录，起始和结束时间相差不可超过30天

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）；
第三方或代开发应用需具有“企业客户权限->获客助手”权限
不支持客户联系系统应用调用

=head3 RETURN 返回结果：

	{
	   "errcode": 0,
	   "errmsg": "ok",
	   "click_link_customer_cnt":1000,
	   "new_customer_cnt":500,
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	click_link_customer_cnt	点击链接客户数
	new_customer_cnt	新增客户数

=cut

sub statistic {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/customer_acquisition/statistic?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
