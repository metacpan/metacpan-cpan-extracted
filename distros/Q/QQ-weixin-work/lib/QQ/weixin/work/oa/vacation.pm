package QQ::weixin::work::oa::vacation;

=encoding utf8

=head1 Name

QQ::weixin::work::oa::vacation

=head1 DESCRIPTION

审批

=cut

use strict;
use base qw(QQ::weixin::work::oa);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ getcorpconf getuservacationquota setoneuserquota /;

=head1 FUNCTION

=head2 getcorpconf(access_token, size_type);

获取企业假期管理配置
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93375>

=head3 请求说明：

通过本接口可以获取可见范围内员工的“假期管理”配置，包括：各个假期的id、名称、请假单位、时长计算方式、发放规则等。

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证

=head4 权限说明：

	应用类型	权限要求
	自建应用	配置到「审批 - 可调用接口的应用」中
	代开发应用	具有「审批」权限
	第三方应用	具有「审批」权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"lists": [
			{
				"id": 1,
				"name": "年假",
				"time_attr": 0,
				"duration_type": 0,
				"quota_attr": {
					"type": 1,
					"autoreset_time": 1641010352,
					"autoreset_duration": 432000,
					"quota_rule_type": 1,
					"quota_rules": {
					  "list": [
						{
						  "quota": 432000,
						  "begin": 0,
						  "end": 1
						},
						{
						  "quota": 518400,
						  "begin": 1,
						  "end": 2
						},
						{
						  "quota": 604800,
						  "begin": 2,
						  "end": 0
						}
					  ],
					  "based_on_actual_work_time": true
					},
					"at_entry_date": true,
					"auto_reset_month_day": 0
				  },
				"perday_duration": 86400
				"is_newovertime": 0,
				"enter_comp_time_limit": 0,
				"expire_rule": {
					"type": 2,
					"duration": 2,
					"date": {
					  "month": 0,
					  "day": 0
					},
					"extern_duration_enable": false,
					"extern_duration": {
					  "month": 0,
					  "day": 0
					}
				}
			}
		]
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码，详情见错误码说明
	errmsg	string	错误码对应的错误信息提示
	lists	obj[]	假期列表
	lists.id	uint32	假期id
	lists.name	string	假期名称
	lists.time_attr	uint32	假期时间刻度：0-按天请假；1-按小时请假
	lists.duration_type	uint32	时长计算类型：0-自然日；1-工作日
	lists.quota_attr	obj	假期发放相关配置
	lists.quota_attr.type	uint32	假期发放类型：0-不限额；1-自动按年发放；2-手动发放；3-自动按月发放
	lists.quota_attr.autoreset_time	uint32	自动发放时间戳，若假期发放为自动发放，此参数代表自动发放日期。注：返回时间戳的年份是无意义的，请只使用返回时间的月和日；若at_entry_date为true，该字段则无效，假期发放时间为员工入职时间
	lists.quota_attr.autoreset_duration	uint32	自动发放时长，单位为秒。注：只有自动按年发放和自动按月发放时有效，若选择了按照工龄和司龄发放，该字段无效，发放时长请使用区间中的quota
	lists.quota_attr.quota_rule_type	uint32	额度计算类型，自动按年发放时有效，0-固定额度；1-按工龄计算；2-按司龄计算
	lists.quota_attr.quota_rules	obj	额度计算规则，自动按年发放时有效
	lists.quota_attr.quota_rules.list	obj[]	额度计算规则区间，只有在选择了按照工龄计算或者按照司龄计算时有效
	lists.quota_attr.quota_rules.list.quota	uint32	区间发放时长，单位为s
	lists.quota_attr.quota_rules.list.begin	uint32	区间开始点，单位为年
	lists.quota_attr.quota_rules.list.end	uint32	区间结束点，无穷大则为0，单位为年
	lists.quota_attr.quota_rules.list.based_on_actual_work_time	bool	是否根据实际入职时间计算假期，选择后会根据员工在今年的实际工作时间发放假期
	lists.quota_attr.at_entry_date	bool	是否按照入职日期发放假期，只有在自动按年发放类型有效，选择后发放假期的时间会成为员工入职的日期
	lists.quota_attr.auto_reset_month_day	uint32	自动按月发放的发放时间，只有自动按月发放类型有效
	lists.perday_duration	uint32	单位换算值，即1天对应的秒数，可将此值除以3600得到一天对应的小时。
	lists.is_newovertime	uint32	是否关联加班调休，0-不关联，1-关联，关联后改假期类型变为调休假
	lists.enter_comp_time_limit	uint32	入职时间大于n个月可用该假期，单位为月
	lists.expire_rule	obj	假期过期规则
	lists.expire_rule.type	uint32	过期规则类型，1-按固定时间过期，2-从发放日按年过期，3-从发放日按月过期，4-不过期
	lists.expire_rule.duration	uint64	有效期，按年过期为年，按月过期为月，只有在以上两种情况时有效
	lists.expire_rule.date	obj	失效日期，只有按固定时间过期时有效
	lists.expire_rule.date.month	uint32	失效日期所在月份
	lists.expire_rule.date.day	uint32	失效日期所在日
	lists.expire_rule.extern_duration_enable	bool	是否允许延长有效期
	lists.expire_rule.extern_duration	obj	延长有效期的具体时间，只有在extern_duration_enable为true时有效
	lists.expire_rule.extern_duration.month	uint32	延长月数
	lists.expire_rule.extern_duration.day	uint32	延长天数

接口频率限制 600次/分钟

=head4 错误说明：

	错误码	说明
	301062	没有假勤权限
	301063	参数错误
	301064	内部错误

=cut

sub getcorpconf {
    if ( @_ && $_[0] ) {
        my $access_token = $_[0];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/oa/vacation/getcorpconf?access_token=$access_token");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getuservacationquota(access_token, hash);

获取成员假期余额
最后更新：2023/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93376>

=head3 请求说明：

通过本接口可获取应用可见范围内各个员工的假期余额数据。

=head4 请求包结构体为：

	{
		"userid": "ZhangSan"
	}

=head4 参数说明：

	参数		必须		类型		说明
	access_token	是	string	调用接口凭证。必须使用第三方应用accesstoken获取，获取方式参考：文档-获取access_token
	userid	是	string	需要获取假期余额的成员的userid

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「审批 - 可调用接口的应用」中
	代开发应用	具有「审批」权限
	第三方应用	具有「审批」权限

1.第三方应用可以获取第三方应用添加的模板详情。
2.自建应用的Secret可获取企业自建模板的模板详情。
3.接口调用频率限制为600次/分钟。
注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"lists": [
			{
				"id": 1,
				"assignduration": 0,
				"usedduration": 0,
				"leftduration": 604800,
				"vacationname": "年假",
				"real_assignduration": 0
			},
			{
				"id": 2,
				"assignduration": 1296000,
				"usedduration": 0,
				"leftduration": 1296000,
				"vacationname": "事假",
				"real_assignduration": 1296000
			},
			{
				"id": 3,
				"assignduration": 1296000,
				"usedduration": 0,
				"leftduration": 1296000,
				"vacationname": "病假",
				"real_assignduration": 86400
			}
		]
	}

=head3 RETURN 参数说明

	参数		类型		说明
	errcode	int32	错误码，详情见错误码说明
	errmsg	string	错误码对应的错误信息提示
	lists	obj[]	假期列表
	lists.id	int32	假期id
	lists.assignduration	uint32	发放时长，单位为秒
	lists.usedduration	uint32	使用时长，单位为秒
	lists.leftduration	uint32	剩余时长，单位为秒
	lists.vacationname	string	假期名称
	lists.real_assignduration	uint32	假期的实际发放时长，通常在设置了按照实际工作时间发放假期后进行计算

接口频率限制 600次/分钟
注：余额的时长单位都为秒，如果假期时间刻度为“按天”，需要除以86400，得到真实假期余额天数；如果假期时间刻度为“按小时”，需要除以3600得到真实假期余额小时数。

=head3 错误说明：

	错误码	说明
	301062	没有假勤权限
	301063	参数错误
	301064	内部错误

=cut

sub getuservacationquota {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/vacation/getuservacationquota?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 setoneuserquota(access_token, hash);

修改成员假期余额
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93377>

=head3 请求说明：

通过本接口可以修改可见范围内员工的“假期余额”。

=head4 请求包结构体为：

	{
		"userid": "ZhangSan",
		"vacation_id": 1,
		"leftduration": 604800,
		"time_attr": 1,
		"remarks": "PLACE_HOLDER"
	}

=head4 参数说明：

	参数		必须		类型		说明
	access_token	是	string	调用接口凭证
	userid	是	string	需要修改假期余额的成员的userid
	vacation_id	是	uint32	假期id
	leftduration	是	uint32	设置的假期余额,单位为秒
								不能大于1000天或24000小时，当假期时间刻度为按小时请假时，必须为360整倍数，即0.1小时整倍数，按天请假时，必须为8640整倍数，即0.1天整倍数
	time_attr	是	uint32	假期时间刻度：0-按天请假；1-按小时请假
							主要用于校验，必须等于企业假期管理配置中设置的假期时间刻度类型
	remarks	否	string	修改备注，用于显示在假期余额的修改记录当中，可对修改行为作说明，不超过200字符

注：余额的时长单位都为秒，如果假期时间刻度为“按天”，需要除以86400，得到真实假期余额天数；如果假期时间刻度为“按小时”，需要除以3600得到真实假期余额小时数。

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「审批 - 可调用接口的应用」中
	代开发应用	具有「审批」权限
	第三方应用	具有「审批」权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok"
	}

=head3 RETURN 参数说明

	参数		类型		说明
	errcode	int32	返回码
	errmsg	string	错误码描述

接口频率限制 600次/分钟

=head3 错误说明：

	错误码	说明
	301062	没有假勤权限
	301063	参数错误
	301064	内部错误
	301098	成员不在假期的适用范围内

=cut

sub setoneuserquota {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/vacation/setoneuserquota?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
