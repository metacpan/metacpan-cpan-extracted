package QQ::weixin::work::security::trustdevice;

=encoding utf8

=head1 Name

QQ::weixin::work::security::trustdevice

=head1 DESCRIPTION

设备管理
最后更新：2023/12/01

=cut

use strict;
use base qw(QQ::weixin::work::security);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ import list get_by_user delete approve reject /;

=head1 FUNCTION

=head2 import(access_token, hash);

导入可信企业设备

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98920>

=head3 请求说明：

启用了 “设备管理”的企业可以通过相关接口导入可信企业设备，获取/删除可信企业设备、可信个人设备、未知设备，并对未知设备的归属申请进行确认或驳回。

=head4 请求包结构体为：

	{
		"device_list":
		[
			{
				"system":"Windows",
				"mac_addr":
				[
					"50:81:40:29:33:CA",
					"36:27:51:DF:6E:80"
				],
				"motherboard_uuid":"MB_UUID",
				"harddisk_uuid":
				[
					"HD_UUID1",
					"HD_UUID2"
				],
				"domain":"WINDOWS_DOMAIN",
				"pc_name":"PC_001",
			},
			{
				"system":"Mac",
				"seq_no":"SEQ_NO",
				"mac_addr":
				[
					"81:40:50:29:33:DB"
				]
			}
		]
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    device_list.system	string	是	设备的类型，Windows或Mac
	device_list.mac_addr	string	是	设备MAC地址，当system为Windows时必填，Mac选填，每个设备最多100个
	device_list.motherboard_uuid	string	否	主板UUID，当system为Windows可选填此参数
	device_list.harddisk_uuid	string	否	硬盘序列号，当system为Windows时可选填此参数，每个设备最多100个
	device_list.domain	string	否	Windows域名，当system为Windows时可选填此参数
	device_list.pc_name	string	否	Windows计算机名，当system为Windows时可选填此参数
	device_list.seq_no	string	是	Mac序列号，当system为Mac时必填

=head4 权限说明

调用设备管理相关接口的应用需要满足如下的权限：

应用类型	权限要求
自建应用	配置到「安全与管理 - 设备管理 - 可调用接口的应用」中
代开发应用	暂不支持
第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head4 调用说明

每次调用最多导入100条可信企业设备记录

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"result":
		[
			{
			   "device_index":1,
			   "device_code":"49nNtYq",
				"status":1
			},
			{
				"device_index":2,
				"status":2
			},
			{
				"device_index":3,
				"status":3
			}
		]
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	result.device_index	int32	导入设备记录的标识，对应请求中设备的顺序，从1开始
	result.device_code	string	设备的唯一标识，仅导入成功的记录返回
	result.status	int32	导入结果，1-成功 2-重复导入 3-不支持的设备 4-数据格式错误

=cut

sub import {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/security/trustdevice/import?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token, hash);

获取设备信息

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98920>

=head3 请求说明：

启用了 “设备管理”的企业可以通过相关接口导入可信企业设备，获取/删除可信企业设备、可信个人设备、未知设备，并对未知设备的归属申请进行确认或驳回。

=head4 请求包结构体为：

	{
		"cursor":"CURSOR",
		"limit":100,
		"type":1
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    cursor	string	否	分页cursor,用于获取分页数据
	type	int32	是	查询设备类型，1-可信企业设备 2-未知设备 3-可信个人设备
	limit	int32	否	查询返回的最大记录数，最高不超过100，默认为100

=head4 权限说明

调用设备管理相关接口的应用需要满足如下的权限：

应用类型	权限要求
自建应用	配置到「安全与管理 - 设备管理 - 可调用接口的应用」中
代开发应用	暂不支持
第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head4 调用说明

每次调用最多导入100条可信企业设备记录

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"device_list":
		[
			{
				"device_code":"49nNtYq",
				"system":"Windows",
				"mac_addr":
				[
					"50:81:40:29:33:CA"
				],
				"motherboard_uuid":"MB_UUID",
				"harddisk_uuid":
				[
					"HD_UUID1"
				],
				"domain":"WINDOWS_DOMAIN",
				"pc_name":"PC_001",
				"last_login_time":1681722163,
				"last_login_userid":"lisi",
				"confirm_timestamp":1681722163,
				"confirm_userid":"lisi",
				"approved_userid":"zhangsan",
				"source":3,
				"status":5
			},
			{
				"device_code":"rjDTnOh",
				"system":"Mac",
				"seq_no":"SEQ_NO1",
				"mac_addr":
				[
					"50:81:40:29:33:CA"
				],
				"source":1,
				"status":5
			}
		],
		"next_cursor":"CURSOR"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	device.device_code	string	设备编码
	device_list.system	string	设备的类型，Windows或Mac
	device_list.mac_addr	string	设备MAC地址
	device_list.motherboard_uuid	string	主板UUID
	device_list.harddisk_uuid	string	硬盘UUID
	device_list.domain	string	Windows域
	device_list.pc_name	string	计算机名
	device_list.seq_no	string	Mac序列号
	device_list.last_login_time	int32	设备最后登录时间戳
	device_list.last_login_userid	string	设备最后登录成员userid
	device_list.confirm_timestamp	int32	设备归属/确认时间戳
	device_list.confirm_userid	string	设备归属/确认成员userid
	device_list.approved_userid	string	通过申报的管理员userid
	device_list.source	int32	设备来源 0-未知 1-成员确认 2-管理员导入 3-成员自主申报
	device_list.status	int32	设备状态 1-已导入未登录 2-待邀请 3-待管理员确认为企业设备 4-待管理员确认为个人设备 5-已确认为可信企业设备 6-已确认为可信个人设备
	next_cursor	string	分页游标，再下次请求时填写以获取之后分页的记录，如果已经没有更多的数据则返回空
	
注意，当获取未确认为可信企业设备的记录时，即获取status为2、4、6时，mac地址，序列号，主板UUID等将会返回脱敏数据。

=cut

sub list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/security/trustdevice/list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_by_user(access_token, hash);

获取成员使用设备

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98920>

=head3 请求说明：

启用了 “设备管理”的企业可以通过相关接口导入可信企业设备，获取/删除可信企业设备、可信个人设备、未知设备，并对未知设备的归属申请进行确认或驳回。

=head4 请求包结构体为：

	{
		"last_login_userid":"zhangsan",
		"type":1
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    last_login_userid	string	是	最后登录的成员userid
	type	int32	是	查询设备类型，1-可信企业设备 2-未知设备 3-可信个人设备

=head4 权限说明

调用设备管理相关接口的应用需要满足如下的权限：

应用类型	权限要求
自建应用	配置到「安全与管理 - 设备管理 - 可调用接口的应用」中
代开发应用	暂不支持
第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head4 调用说明

每次调用最多导入100条可信企业设备记录

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"device_list":
		[
			{
				"device_code":"49nNtYq",
				"system":"Windows",
				"mac_addr":
				[
					"50:81:40:29:33:CA"
				],
				"motherboard_uuid":"MB_UUID",
				"harddisk_uuid":
				[
					"HD_UUID1"
				],
				"domain":"WINDOWS_DOMAIN",
				"pc_name":"PC_001",
				"last_login_time":1681722163,
				"last_login_userid":"lisi",
				"confirm_timestamp":1681722163,
				"confirm_userid":"lisi",
				"approved_userid":"zhangsan",
				"source":3,
				"status":5
			},
			{
				"device_code":"rjDTnOh",
				"system":"Mac",
				"seq_no":"SEQ_NO1",
				"mac_addr":
				[
					"50:81:40:29:33:CA"
				],
				"source":1,
				"status":5
			}
		]
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	device_list.device_code	string	设备编码
	device_list.system	string	设备的类型，Windows或Mac
	device_list.mac_addr	string	设备MAC地址
	device_list.motherboard_uuid	string	主板UUID
	device_list.harddisk_uuid	string	硬盘UUID
	device_list.domain	string	windows域
	device_list.pc_name	string	计算机名
	device_list.seq_no	string	Mac序列号
	device_list.last_login_time	int32	设备最后登录时间戳
	device_list.last_login_userid	string	设备最后登录成员userid
	device_list.confirm_timestamp	int32	设备归属/确认时间戳
	device_list.confirm_userid	string	设备归属/确认成员userid
	device_list.approved_userid	string	通过申报的管理员userid
	device_list.source	int32	设备来源 0-未知 1-成员确认 2-管理员导入 3-成员自主申报
	device_list.status	int32	设备状态 1-已导入未登录 2-待邀请 3-待管理员确认为企业设备 4-待管理员确认未个人设备 5-已确认为可信企业设备 6-已确认为可信个人设备
	
注意，当获取未确认为可信企业设备的记录时，即获取status为2、4、6时，mac地址，序列号，主板UUID等将会返回脱敏数据。

=cut

sub get_by_user {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/security/trustdevice/get_by_user?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete(access_token, hash);

删除设备信息

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98920>

=head3 请求说明：

启用了 “设备管理”的企业可以通过相关接口导入可信企业设备，获取/删除可信企业设备、可信个人设备、未知设备，并对未知设备的归属申请进行确认或驳回。

=head4 请求包结构体为：

	{
		"type":1,
		"device_code_list":
		[
			"49nNtYq",
			"rjDTnOh"
		]
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    type	int32	是	删除设备类型，1-可信企业设备 2-未知设备 3-可信个人设备
	device_code_list	string	是	设备编码列表

=head4 权限说明

调用设备管理相关接口的应用需要满足如下的权限：

应用类型	权限要求
自建应用	配置到「安全与管理 - 设备管理 - 可调用接口的应用」中
代开发应用	暂不支持
第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head4 调用说明

每次调用可删除100个设备

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	int32	错误码
	errmsg	string	错误码说明

=cut

sub delete {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/security/trustdevice/delete?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 approve(access_token, hash);

确认为可信设备

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98920>

=head3 请求说明：

启用了 “设备管理”的企业可以通过相关接口导入可信企业设备，获取/删除可信企业设备、可信个人设备、未知设备，并对未知设备的归属申请进行确认或驳回。

=head4 请求包结构体为：

	{
		"device_code_list":
		[
			"49nNtYq",
			"rjDTnOh"
		]
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	应用调用凭证
	device_code_list	string	是	设备编码列表, 仅可确认待管理员通过状态，即status为3或4的设备

=head4 权限说明

调用设备管理相关接口的应用需要满足如下的权限：

应用类型	权限要求
自建应用	配置到「安全与管理 - 设备管理 - 可调用接口的应用」中
代开发应用	暂不支持
第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head4 调用说明

每次调用最多可以确认100个设备

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"success_list":["49nNtYq"],
		"fail_list":["rjDTnOh"]
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	success_list	string	确认成功设备code列表
	fail_list	string	确认失败设备code列表

=cut

sub approve {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/security/trustdevice/approve?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 reject(access_token, hash);

驳回可信设备申请

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98920>

=head3 请求说明：

启用了 “设备管理”的企业可以通过相关接口导入可信企业设备，获取/删除可信企业设备、可信个人设备、未知设备，并对未知设备的归属申请进行确认或驳回。

=head4 请求包结构体为：

	{
		"device_code_list":
		[
			"49nNtYq",
			"rjDTnOh"
		]
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	应用调用凭证
	device_code_list	string	是	设备编码列表，仅可驳回待管理员通过状态，即status为3或4的设备

=head4 权限说明

调用设备管理相关接口的应用需要满足如下的权限：

应用类型	权限要求
自建应用	配置到「安全与管理 - 设备管理 - 可调用接口的应用」中
代开发应用	暂不支持
第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head4 调用说明

每次调用最多可以拒绝100个设备

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"success_list":["49nNtYq"],
		"fail_list":["rjDTnOh"]
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	success_list	string	驳回成功设备code列表
	fail_list	string	驳回失败设备code列表

=cut

sub reject {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/security/trustdevice/reject?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
