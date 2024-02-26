package QQ::weixin::work::oa::calendar;

=encoding utf8

=head1 Name

QQ::weixin::work::oa::calendar

=head1 DESCRIPTION

日历

=cut

use strict;
use base qw(QQ::weixin::work::oa);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ add update get del /;

=head1 FUNCTION

=head2 add(access_token, hash);

创建日历
最后更新：2023/04/23

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93647>

=head3 请求说明：

该接口用于通过应用在企业内创建一个日历。

=head4 请求包结构体为：

	{
		"calendar": {
			"admins":[
					"admin1",
					"admin2"
			],
			"set_as_default": 1,
			"summary": "test_summary",
			"color": "#FF3030",
			"description": "test_describe",
			"shares": [{
					"userid": "userid2",
					"permission": 1
				},
				{
					"userid": "userid3",
					"permission": 3
				}
			],
			"is_public": 1,
			"public_range": {
				"userids": ["abel", "jack"],
				"partyids": [1232, 34353]
			},
			"is_corp_calendar": 1
		},
		"agentid": 1000014
	}

=head4 参数说明：

	参数	是否必须	说明
	calendar	是	日历信息
	admins	否	日历的管理员userid列表，管理员必须在通知范围成员的列表中。最多指定3人
	set_as_default	否	是否将该日历设置为access_token所对应应用的默认日历。
	0-否；1-是。默认为0，即不设为默认日历
	第三方应用不支持使用该参数
	summary	是	日历标题。1 ~ 128 字符
	color	是	日历在终端上显示的颜色，RGB颜色编码16进制表示，例如："#0000FF" 表示纯蓝色
	description	否	日历描述。0 ~ 512 字符
	is_public	否	是否公共日历。0-否；1-是。注意：每个人最多可创建或订阅100个公共日历。该属性不可更新
	public_range	否	公开范围。仅当是公共日历时有效
	public_range.userids	否	公开的成员列表范围 。最多指定1000个成员
	public_range.partyids	否	公开的部门列表范围 。最多指定100个部门
	is_corp_calendar	否	是否全员日历。0-否；1-是。注意：
	1. 每个企业最多可创建20个全员日历
	2. 全员日历也是公共日历的一种，需要指定public_range
	3. 全员日历不支持指定颜色、默认日历、只读权限
	4. 该属性不可更新
	shares	否	日历通知范围成员列表。最多2000人
	shares.userid	是	日历通知范围成员的id
	shares.permission	否	日历通知范围成员权限（不填则默认为「可查看」）。
	1：可查看
	3：仅查看闲忙状态
	agentid	否	授权方安装的应用agentid。仅旧的第三方多应用套件需要填此参数

=head3 权限说明

=head3 RETURN 返回结果

	{ 
		"errcode": 0,
		"errmsg" : "ok",
		"cal_id":"wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA",
		"fail_result": {
			"shares":[{
				"errcode": 40001,
				"errmsg": "not found",
				"userid": "userid3"
			}]
		}
	}

=head3 RETURN 参数说明

	参数		说明
	errcode	错误码
	errmsg	错误码说明
	cal_id	日历ID
	fail_result	无效的输入内容
	fail_result.shares	无效的日历通知范围成员列表
	shares.errcode	错误码
	shares.errmsg	错误码说明
	shares.userid	日历通知范围成员的id

=cut

sub add {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/calendar/add?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update(access_token, hash);

更新日历
最后更新：2023/08/31

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97716>

=head3 请求说明：

该接口用于修改指定日历的信息。

注意，更新操作是覆盖式，而不是增量式

=head4 请求包体:

	{
		"skip_public_range" : 0,
		"calendar": {
			"cal_id": "wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA",
			"admins":[
					"admin1",
					"admin2"
			],
			"summary": "test_summary",
			"color": "#FF3030",
			"description": "test_describe_1",
			"shares": [{
					"userid": "userid1",
					"permission": 1
				},
				{
					"userid": "userid2",
					"permission": 3
				}
			],
			"public_range": {
				"userids": ["abel", "jack"],
				"partyids": [1232, 34353]
			}
		}
	}

=head4 参数说明：

	参数		是否必须		说明
	skip_public_range	否	是否不更新可订阅范围。0-否；1-是。默认会为0，会更新可订阅范围
	calendar	是	日历信息
	cal_id	是	日历ID
	admins	否	日历的管理员userid列表。最多指定3人
	summary	是	日历标题。1 ~ 128 字符
	color	是	日历颜色，RGB颜色编码16进制表示，例如："#0000FF" 表示纯蓝色
	description	否	日历描述。0 ~ 512 字符
	public_range	否	公开范围。仅当是公共日历时有效
	public_range.userids	否	公开的成员列表范围 。最多指定1000个成员
	public_range.partyids	否	公开的部门列表范围 。最多指定100个部门
	shares	否	日历通知范围成员列表。最多2000人
	shares.userid	是	日历通知范围成员的id
	shares.permission	否	日历通知范围成员权限（不填则默认为「可查看」）。
							1：可查看
							3：仅查看闲忙状态

=head3 权限说明

注意, 不可更新组织者。

=head3 RETURN 返回结果

	{ 
		"errcode": 0,
		"errmsg" : "ok",
		"fail_result": {
			"shares":[{
				"errcode": 40001,
				"errmsg": "not found",
				"userid": "userid3"
			}]
		}
	}

=head3 RETURN 参数说明

	参数		说明
	errcode	错误码
	errmsg	错误码说明
	fail_result	无效的输入内容
	fail_result.shares	无效的日历通知范围成员列表
	shares.errcode	错误码
	shares.errmsg	错误码说明
	shares.userid	日历通知范围成员的id

=cut

sub update {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/calendar/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token, hash);

获取日历详情
最后更新：2023/04/11

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97717>

=head3 请求说明：

该接口用于获取应用在企业内创建的日历信息。

=head4 请求包结构体为：

    {
    	"cal_id_list": ["wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA"]
    }

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    cal_id_list	是	日历ID列表，调用创建日历接口后获得。一次最多可获取1000条

=head3 权限说明

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"calendar_list": [{
			"cal_id": "wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA",
			"adminis":[
					"admin1",
					"admin2",
			],
			"summary": "test_summary",
			"color": "#FF3030",
			"description": "test_describe_1",
			"shares": [{
					"userid": "userid2",
					"permission": 1
				},
				{
					"userid": "userid1",
					"permission": 3
				}
			],
			"is_public": 1,
			"public_range": {
				"userids": ["abel", "jack"],
				"partyids": [1232, 34353]
			},
			"is_corp_calendar": 1
		}]
	}

=head3 RETURN 参数说明

	参数	    说明
    errcode	错误码
	errmsg	错误码说明
	calendar_list	日历列表
	cal_id	日历ID
	admins	日历的管理员userid列表
	summary	日历标题。1 ~ 128 字符
	color	日历颜色，RGB颜色编码16进制表示，例如："#0000FF" 表示纯蓝色
	description	日历描述。0 ~ 512 字符
	is_public	是否公共日历。0-否；1-是
	public_range	公开范围。仅当是公共日历时有效
	public_range.userids	公开的成员列表范围
	public_range.partyids	公开的部门列表范围
	is_corp_calendar	是否全员日历。0-否；1-是
	shares	日历通知范围成员列表。最多2000人
	shares.userid	日历通知范围成员的id
	shares.permission	日历通知范围成员权限。
						1：可查看
						3：仅查看闲忙状态

=cut

sub get {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/calendar/get?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del(access_token, hash);

删除日历
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97718>

=head3 请求说明：

该接口用于删除指定日历。

=head4 请求包体：

    {
    	"cal_id":"wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA"
    }

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    cal_id	是	日历ID

=head3 权限说明

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok"
    }

=head3 RETURN 参数说明

	参数	    说明
    errcode	错误码
	errmsg	错误码说明

=cut

sub del {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/calendar/del?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
