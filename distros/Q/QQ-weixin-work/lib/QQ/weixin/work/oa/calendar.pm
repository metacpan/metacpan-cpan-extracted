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

our $VERSION = '0.06';
our @EXPORT = qw/ add update get del /;

=head1 FUNCTION

=head2 add(access_token, hash);

创建日历

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93647#创建日历>

=head3 请求说明：

=head4 请求包结构体为：

    {
		"calendar" : {
			"organizer" : "userid1",
			"readonly" : 1,
			"set_as_default" : 1,
			"summary" : "test_summary",
			"color" : "#FF3030",
			"description" : "test_describe",
			"shares" : [
				{
					"userid" : "userid2"
				},
				{
					"userid" : "userid3",
					"readonly" : 1
				}
			]
		},
		"agentid" : 1000014
	}

=head4 参数说明：

    参数	是否必须	说明
	calendar	是	日历信息
	organizer	是	指定的组织者userid。注意该字段指定后不可更新
	readonly	否	日历组织者对日历是否只读权限（即不可编辑日历，不可在日历上添加日程，仅可作为组织者删除日历）。
					0-否；1-是。默认为1，即只读
	set_as_default	否	是否将该日历设置为组织者的默认日历。
						0-否；1-是。默认为0，即不设为默认日历
						第三方应用不支持使用该参数
	summary	是	日历标题。1 ~ 128 字符
	color	是	日历在终端上显示的颜色，RGB颜色编码16进制表示，例如："#0000FF" 表示纯蓝色
	description	否	日历描述。0 ~ 512 字符
	shares	否	日历共享成员列表。最多2000人
	shares.userid	是	日历共享成员的id
	shares.readonly	否	共享成员对日历是否只读权限（即不可编辑日历，不可在日历上添加日程，仅可以退出日历）。
						0-否；1-是。默认为1，即只读
	agentid	否	授权方安装的应用agentid。仅旧的第三方多应用套件需要填此参数

=head3 权限说明

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "ok",
       "cal_id":"wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA"
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    cal_id	日历ID

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

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93647#更新日历>

=head3 请求说明：

该接口用于修改指定日历的信息。

注意，更新操作是覆盖式，而不是增量式
企业微信需要更新到3.0.2及以上版本

=head4 请求包体:

    {
		"calendar" : {
			"cal_id":"wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA",
			"readonly" : 1,
			"summary" : "test_summary",
			"color" : "#FF3030",
			"description" : "test_describe_1",
			"shares" : [
				{
					"userid" : "userid1"
				},
				{
					"userid" : "userid2",
					"readonly" : 1
				}
			]
		}
	}

=head4 参数说明：

    参数	是否必须	说明
	calendar	是	日历信息
	cal_id	是	日历ID
	readonly	否	日历组织者对日历是否只读权限（即不可编辑日历，不可在日历上添加日程，仅可作为组织者删除日历）。
					0-否；1-是。默认为1，即只读
	summary	是	日历标题。1 ~ 128 字符
	color	是	日历颜色，RGB颜色编码16进制表示，例如："#0000FF" 表示纯蓝色
	description	否	日历描述。0 ~ 512 字符
	shares	否	日历共享成员列表。最多2000人
	shares.userid	是	日历共享成员的id
	shares.readonly	否	共享成员对日历是否只读权限（即不可编辑日历，不可在日历上添加日程，仅可以退出日历）。
						0-否；1-是。默认为1，即只读

=head3 权限说明

注意, 不可更新组织者。

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

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93647#获取日历详情>

=head3 请求说明：

该接口用于获取应用在企业内创建的日历信息。

注: 企业微信需要更新到3.0.2及以上版本

=head4 请求包结构体为：

    {
    	"cal_id_list": ["wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA"]
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    cal_id_list	是	日历ID列表。一次最多可获取1000条

=head3 权限说明

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"calendar_list": [{
			"cal_id": "wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA",
			"organizer": "userid1",
			"readonly": 1,
			"summary": "test_summary",
			"color": "#FF3030",
			"description": "test_describe_1",
			"shares": [
				{
					"userid": "userid2"
				},
				{
					"userid": "userid1",
					"readonly" : 1
				}
			]
		}]
	}

=head3 RETURN 参数说明

    参数	    说明
    errcode	错误码
	errmsg	错误码说明
	calendar_list	日历列表
	cal_id	日历ID
	organizer	指定的组织者userid
	readonly	日历组织者对日历是否只读权限。0-否；1-是；
	summary	日历标题。1 ~ 128 字符
	color	日历颜色，RGB颜色编码16进制表示，例如："#0000FF" 表示纯蓝色
	description	日历描述。0 ~ 512 字符
	shares	日历共享成员列表。最多2000人
	shares.userid	日历共享成员的id
	shares.readonly	共享成员对日历是否只读权限。0-否；1-是；

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

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93647#删除日历>

=head3 请求说明：

该接口用于删除指定日历。

注: 企业微信需要更新到3.0.2及以上版本

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
