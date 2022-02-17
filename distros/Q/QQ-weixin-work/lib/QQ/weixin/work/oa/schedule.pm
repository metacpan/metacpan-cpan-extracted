package QQ::weixin::work::oa::schedule;

=encoding utf8

=head1 Name

QQ::weixin::work::oa::schedule

=head1 DESCRIPTION

日程

=cut

use strict;
use base qw(QQ::weixin::work::oa);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.06';
our @EXPORT = qw/ add update get del get_by_calendar add_attendees del_attendees /;

=head1 FUNCTION

=head2 add(access_token, hash);

创建日程

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93648#创建日程>

=head3 请求说明：

该接口用于在日历中创建一个日程。

=head4 请求包结构体为：

    {
		"schedule": {
			"organizer": "userid1",
			"start_time": 1571274600,
			"end_time": 1571320210,
			"attendees": [{
				"userid": "userid2"
			}],
			"summary": "需求评审会议",
			"description": "2.0版本需求初步评审",
			"reminders": {
				"is_remind": 1,
				"remind_before_event_secs": 3600,
				"is_repeat": 1,
				"repeat_type": 7,
				"repeat_until": 1606976813,
				"is_custom_repeat": 1,
				"repeat_interval": 1,
				"repeat_day_of_week": [3, 7],
				"repeat_day_of_month": [10, 21],
				"timezone" : 8
			},
			"location": "广州国际媒体港10楼1005会议室",
			"cal_id": "wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA"
		},
		"agentid": 1000014
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	string	调用接口凭证
	schedule	是	obj	日程信息
	schedule.attendees	否	obj[]	日程参与者列表。最多支持2000人
	schedule.attendees.userid	是	string	日程参与者ID
											不多于64字节
	schedule.summary	否	string	日程标题。0 ~ 128 字符。不填会默认显示为“新建事件”
	schedule.description	否	string	日程描述
										不多于512个字符
	schedule.reminders	否	obj	提醒相关信息
	schedule.reminders.is_remind	否	int32	是否需要提醒。0-否；1-是
	schedule.reminders.is_repeat	否	int32	是否重复日程。0-否；1-是
	schedule.reminders.remind_before_event_secs	否	uint32	日程开始（start_time）前多少秒提醒，当is_remind为1时有效。
															例如： 300表示日程开始前5分钟提醒。目前仅支持以下数值：
															0 - 事件开始时
															300 - 事件开始前5分钟
															900 - 事件开始前15分钟
															3600 - 事件开始前1小时
															86400 - 事件开始前1天
	schedule.reminders.repeat_type	否	uint32	重复类型，当is_repeat为1时有效。目前支持如下类型： 
												0 - 每日
												1 - 每周
												2 - 每月
												5 - 每年
												7 - 工作日
	schedule.reminders.repeat_until	否	uint32	重复结束时刻，Unix时间戳。不填或填0表示一直重复
	schedule.reminders.is_custom_repeat	否	uint32	是否自定义重复。0-否；1-是
	schedule.reminders.repeat_interval	否	uint32	重复间隔
													仅当指定为自定义重复时有效
													该字段随repeat_type不同而含义不同
													例如：
													repeat_interval指定为3，repeat_type指定为每周重复，那么每3周重复一次；
													repeat_interval指定为3，repeat_type指定为每月重复，那么每3个月重复一次
	schedule.reminders.repeat_day_of_week	否	uint32[]	每周周几重复
															仅当指定为自定义重复且重复类型为每周时有效
															取值范围：1 ~ 7，分别表示周一至周日
	schedule.reminders.repeat_day_of_month	否	uint32[]	每月哪几天重复
															仅当指定为自定义重复且重复类型为每月时有效
															取值范围：1 ~ 31，分别表示1~31号
	schedule.reminders.timezone	否	uint32	时区。UTC偏移量表示(即偏离零时区的小时数)，东区为正数，西区为负数。
											例如：+8 表示北京时间东八区
											默认为北京时间东八区
											取值范围：-12 ~ +12
	schedule.location	否	string	日程地址
									不多于128个字符
	schedule.organizer	是	string	组织者
									不多于64字节
	schedule.start_time	是	uint32	日程开始时间，Unix时间戳
	schedule.end_time	是	uint32	日程结束时间，Unix时间戳
	schedule.cal_id	否	string	日程所属日历ID。该日历必须是access_token所对应应用所创建的日历。
								注意，这个日历必须是属于组织者(organizer)的日历；
								如果不填，那么插入到组织者的默认日历上。
								第三方应用必须指定cal_id 
								不多于64字节
	schedule.allow_active_join	否	bool	是否允许非参与人主动加入日程，默认为开启。
	agentid	否	uint32	授权方安装的应用agentid。仅旧的第三方多应用套件需要填此参数

=head3 关于自定义重复的说明

is_custom_repeat 如果为0，那么系统会根据 start_time 和 repeat_type 来自动计算下一次重复的时间，例如：

start_time 为本周周三8点整，repeat_type 为每周重复，那么每周三8点整重复；
start_time 为本月3号10点整，repeat_type 为每月重复，那么每月3号10点整重复；
如果 is_custom_repeat 指定为1，那么可以配合 repeat_day_of_week 或 repeat_day_of_month 特别指定周几或几号重复，且可以使用 repeat_interval 指定重复间隔

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "ok",
       "schedule_id":"17c7d2bd9f20d652840f72f59e796AAA"
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	错误码描述
    schedule_id	日程ID

=cut

sub add {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/schedule/add?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update(access_token, hash);

更新日程

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93648#更新日程>

=head3 请求说明：

该接口用于在日历中更新指定的日程。

注意，更新操作是覆盖式，而不是增量式
不可更新组织者和日程所属日历ID

=head4 请求包体:

    {
		"schedule": {
			"organizer": "userid1",
			"schedule_id": "17c7d2bd9f20d652840f72f59e796AAA",
			"start_time": 1571274600,
			"end_time": 1571320210,
			"attendees": [
				{
					"userid": "userid2"
				}
			],
			"summary": "test_summary",
			"description": "test_description",
			"reminders": {
				"is_remind": 1,
				"remind_before_event_secs": 3600,
				"is_repeat": 1,
				"repeat_type": 7,
				"repeat_until": 1606976813,
				"is_custom_repeat": 1,
				"repeat_interval": 1,
				"repeat_day_of_week": [3, 7],
				"repeat_day_of_month": [10, 21],
				"timezone" : 8
			},
			"location": "test_place",
			"skip_attendees ":false
		}
	}

=head4 参数说明：

    参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	schedule	是	obj	日程信息
	schedule.schedule_id	是	string	日程ID。创建日程时返回的ID
	schedule.attendees	否	obj[]	日程参与者列表。最多支持2000人
	schedule.attendees.userid	是	string	日程参与者ID
											不多于64字节
	schedule.summary	否	string	日程标题。0 ~ 128 字符。不填会默认显示为“新建事件”
	schedule.description	否	string	日程描述
										不多于512个字符
	schedule.reminders	否	obj	提醒相关信息
	schedule.reminders.is_remind	否	int32	是否需要提醒。0-否；1-是
	schedule.reminders.is_repeat	否	int32	是否重复日程。0-否；1-是
	schedule.reminders.remind_before_event_secs	否	uint32	日程开始（start_time）前多少秒提醒，当is_remind为1时有效。
															例如： 300表示日程开始前5分钟提醒。目前仅支持以下数值：
															0 - 事件开始时
															300 - 事件开始前5分钟
															900 - 事件开始前15分钟
															3600 - 事件开始前1小时
															86400 - 事件开始前1天
	schedule.reminders.repeat_type	否	uint32	重复类型，当is_repeat为1时有效。目前支持如下类型： 
												0 - 每日
												1 - 每周
												2 - 每月
												5 - 每年
												7 - 工作日
	schedule.reminders.repeat_until	否	uint32	重复结束时刻，Unix时间戳。不填或填0表示一直重复
	schedule.reminders.is_custom_repeat	否	uint32	是否自定义重复。0-否；1-是
	schedule.reminders.repeat_interval	否	uint32	重复间隔
													仅当指定为自定义重复时有效
													该字段随repeat_type不同而含义不同
													例如：
													repeat_interval指定为2，repeat_type指定为每周重复，那么每2周重复一次；
													repeat_interval指定为2，repeat_type指定为每月重复，那么每2月重复一次
	schedule.reminders.repeat_day_of_week	否	uint32[]	每周周几重复
															仅当指定为自定义重复且重复类型为每周时有效
															取值范围：1 ~ 7，分别表示周一至周日
	schedule.reminders.repeat_day_of_month	否	uint32[]	每月哪几天重复
															仅当指定为自定义重复且重复类型为每月时有效
															取值范围：1 ~ 31，分别表示1~31号
	schedule.reminders.timezone	否	uint32	时区。UTC偏移量表示(即偏离零时区的小时数)，东区为正数，西区为负数。
											例如：+8 表示北京时间东八区
											默认为北京时间东八区
											取值范围：-12 ~ +12
	schedule.location	否	string	日程地址
									不多于128个字符
	schedule.organizer	否	string	组织者
									不多于64字节
	schedule.start_time	是	uint32	日程开始时间，Unix时间戳
	schedule.end_time	是	uint32	日程结束时间，Unix时间戳
	schedule.skip_attendees	否	bool	忽略掉attendees参数，只更新其他参数,默认值是false

=head3 权限说明

注意, 更新操作是覆盖式，而不是增量式

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "ok"
    }

=head3 RETURN 参数说明

    参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=cut

sub update {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/schedule/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token, hash);

获取日程

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93648#获取日程详情>

=head3 请求说明：

该接口用于获取指定的日程详情。

=head4 请求包结构体为：

    {
        "schedule_id_list": [
            "17c7d2bd9f20d652840f72f59e796AAA"
        ]
    }

=head4 参数说明：

    参数	            是否必须	说明
    access_token	是	调用接口凭证
    schedule_id_list	是	日程ID列表。一次最多拉取1000条

=head3 权限说明

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"schedule_list": [{
			"schedule_id": "17c7d2bd9f20d652840f72f59e796AAA",
			"organizer": "userid1",
			"attendees": [{
				"userid": "userid2",
				"response_status": 1
			}],
			"summary": "test_summary",
			"description": "test_content",
			"reminders": {
				"is_remind": 1,
				"is_repeat": 1,
				"remind_before_event_secs": 3600,
				"remind_time_diffs": [
					-3600
				],
				"repeat_type": 7,
				"repeat_until": 1606976813,
				"is_custom_repeat": 1,
				"repeat_interval": 1,
				"repeat_day_of_week": [3, 7],
				"repeat_day_of_month": [10, 21],
				"timezone" : 8,
				"exclude_time_list": [
					{
						"start_time": 1571361000
					}
				]
			},
			"location": "test_place",
			"cal_id": "wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA",
			"start_time": 1571274600,
			"end_time": 1571579410,
			"status": 1
		}]
	}

=head3 RETURN 参数说明

    参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	schedule_list	obj[]	日程列表
	schedule_list.schedule_id	string	日程ID
	schedule_list.attendees	obj[]	日程参与者列表。最多支持2000人
	schedule_list.attendees.userid	string	日程参与者ID
	schedule_list.attendees.response_status	uint32	日程参与者的接受状态。
													0 - 未处理
													1 - 待定
													2 - 全部接受
													3 - 仅接受一次
													4 - 拒绝
	schedule_list.summary	string	日程标题
	schedule_list.description	string	日程描述
	schedule_list.reminders	obj	提醒相关信息
	schedule_list.reminders.is_remind	int32	是否需要提醒。0-否；1-是
	schedule_list.reminders.is_repeat	int32	是否重复日程。0-否；1-是
	schedule_list.reminders.remind_before_event_secs	uint32	日程开始（start_time）前多少秒提醒，当is_remind为1时有效。例如： 300表示日程开始前5分钟提醒。目前仅支持以下数值：
																0 - 事件开始时
																300 - 事件开始前5分钟
																900 - 事件开始前15分钟
																3600 - 事件开始前1小时
																86400 - 事件开始前1天
																注意：建议使用 remind_time_diffs 字段，该字段后续将会废弃。
	schedule_list.reminders.remind_time_diffs	int32[]	日程开始（start_time）与提醒时间的差值，当is_remind为1时有效。例如：-300表示日程开始前5分钟提醒。
														特殊情况：企业微信终端设置的“全天”类型的日程，由于start_time是0点时间戳，提醒如果设置了当天9点，则会出现正数32400。
														取值范围：-604800 ~ 86399
	schedule_list.reminders.repeat_type	uint32	重复类型，当is_repeat为1时有效。目前支持如下类型： 
												0 - 每日
												1 - 每周
												2 - 每月
												5 - 每年
												7 - 工作日
	schedule_list.reminders.repeat_until	uint32	重复结束时刻，Unix时间戳。不填或填0表示一直重复
	schedule_list.reminders.is_custom_repeat	uint32	是否自定义重复。0-否；1-是
	schedule_list.reminders.repeat_interval	uint32	重复间隔
													仅当指定为自定义重复时有效
													该字段随repeat_type不同而含义不同
													例如：
													repeat_interval指定为2，repeat_type指定为每周重复，那么每2周重复一次；
													repeat_interval指定为2，repeat_type指定为每月重复，那么每2月重复一次
	schedule_list.reminders.repeat_day_of_week	uint32[]	每周周几重复
															仅当指定为自定义重复且重复类型为每周时有效
															取值范围：1 ~ 7，分别表示周一至周日
	schedule_list.reminders.repeat_day_of_month	uint32[]	每月哪几天重复
															仅当指定为自定义重复且重复类型为每月时有效
															取值范围：1 ~ 31，分别表示1~31号
	schedule_list.reminders.timezone	uint32	时区。UTC偏移量表示(即偏离零时区的小时数)，东区为正数，西区为负数。
												例如：+8 表示北京时间东八区
												默认为北京时间东八区
												取值范围：-12 ~ +12
	schedule_list.reminders.exclude_time_list	obj[]	重复日程不包含的日期列表。对重复日程修改/删除特定一天或多天，则原来的日程将会排除对应的日期。
	schedule_list.reminders.exclude_time_list.start_time	uint32	不包含的日期时间戳。
	schedule_list.location	string	日程地址
									不多于128个字符
	schedule_list.organizer	string	组织者
									不多于64字节
	schedule_list.status	uint32	日程状态。0-正常；1-已取消
	schedule_list.start_time	uint32	日程开始时间，Unix时间戳
	schedule_list.end_time	uint32	日程结束时间，Unix时间戳
	schedule_list.cal_id	string	日程所属日历ID。该日历必须是access_token所对应应用所创建的日历。
									注意，这个日历必须是属于组织者(organizer)的日历；
									如果不填，那么插入到组织者的默认日历上。
									第三方应用必须指定cal_id 
									不多于64字节

注意，被取消的日程也可以拉取详情，调用者需要检查status

=cut

sub get {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/schedule/get?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del(access_token, hash);

取消日程

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93648#取消日程>

=head3 请求说明：

该接口用于取消指定的日程。

=head4 请求包结构体为：

    {
    	"schedule_id":"17c7d2bd9f20d652840f72f59e796AAA"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    schedule_id	是	日程ID

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

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/schedule/del?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_by_calendar(access_token, hash);

获取日历下的日程列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93648#获取日历下的日程列表>

=head3 请求说明：

该接口用于获取指定的日历下的日程列表。
仅可获取应用自己创建的日历下的日程。

=head4 请求包结构体为：

    {
        "cal_id": "wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA",
        "offset" : 100,
        "limit" : 1000
    }

=head4 参数说明：

    参数	            是否必须	说明
    access_token	是	调用接口凭证
    cal_id	是	日历ID
    offset	否	分页，偏移量, 默认为0
    limit	否	分页，预期请求的数据量，默认为500，取值范围 1 ~ 1000

=head3 权限说明

当日程较多时，需要使用参数是offset及limit 分页获取，注意offset是以0为起点，
当获取到的 schedule_list 是空的时候，表示offset已经过大，此时应终止获取。若有新增日程，可在此基础上继续增量获取。

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"schedule_list": [{
			"schedule_id": "17c7d2bd9f20d652840f72f59e796AAA",
			"sequence": 100,
			"attendees": [{
				"userid": "userid1",
				"response_status": 0
			}],
			"summary": "test_summary",
			"description": "test_content",
			"reminders": {
				"is_remind": 1,
				"is_repeat": 1,
				"remind_before_event_secs": 3600,
				"repeat_type": 7,
				"repeat_until": 1606976813,
				"is_custom_repeat": 1,
				"repeat_interval": 1,
				"repeat_day_of_week": [3, 7],
				"repeat_day_of_month": [10, 21],
				"timezone" : 8
			},
			"location": "test_place",
			"start_time": 1571274600,
			"end_time": 1571320210,
			"status": 1,
			"cal_id": "wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA"
		}]
	}

=head3 RETURN 参数说明

    参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	schedule_list	obj[]	日程列表
	schedule_list.schedule_id	string	日程ID
	schedule_list.attendees	obj[]	日程参与者列表。最多支持2000人
	schedule_list.attendees.userid	string	日程参与者ID
	schedule_list.attendees.response_status	uint32	日程参与者的接受状态。
													0 - 未处理
													1 - 待定
													2 - 全部接受
													3 - 仅接受一次
													4 - 拒绝
	schedule_list.summary	string	日程标题
	schedule_list.description	string	日程描述
	schedule_list.reminders	obj	提醒相关信息
	schedule_list.reminders.is_remind	int32	是否需要提醒。0-否；1-是
	schedule_list.reminders.is_repeat	int32	是否重复日程。0-否；1-是
	schedule_list.reminders.remind_before_event_secs	uint32	日程开始（start_time）前多少秒提醒，当is_remind为1时有效。例如： 300表示日程开始前5分钟提醒。目前仅支持以下数值：
																0 - 事件开始时
																300 - 事件开始前5分钟
																900 - 事件开始前15分钟
																3600 - 事件开始前1小时
																86400 - 事件开始前1天
	schedule_list.reminders.repeat_type	uint32	重复类型，当is_repeat为1时有效。目前支持如下类型： 
												0 - 每日
												1 - 每周
												2 - 每月
												5 - 每年
												7 - 工作日
	schedule_list.reminders.repeat_until	uint32	重复结束时刻，Unix时间戳。不填或填0表示一直重复
	schedule_list.reminders.is_custom_repeat	uint32	是否自定义重复。0-否；1-是
	schedule_list.reminders.repeat_interval	uint32	重复间隔
													仅当指定为自定义重复时有效
													该字段随repeat_type不同而含义不同
													例如：
													repeat_interval指定为2，repeat_type指定为每周重复，那么每2周重复一次；
													repeat_interval指定为2，repeat_type指定为每月重复，那么每2月重复一次
	schedule_list.reminders.repeat_day_of_week	uint32[]	每周周几重复
															仅当指定为自定义重复且重复类型为每周时有效
															取值范围：1 ~ 7，分别表示周一至周日
	schedule_list.reminders.repeat_day_of_month	uint32[]	每月哪几天重复
															仅当指定为自定义重复且重复类型为每月时有效
															取值范围：1 ~ 31，分别表示1~31号
	schedule_list.reminders.timezone	uint32	时区。UTC偏移量表示(即偏离零时区的小时数)，东区为正数，西区为负数。
												例如：+8 表示北京时间东八区
												默认为北京时间东八区
												取值范围：-12 ~ +12
	schedule_list.location	string	日程地址
									不多于128个字符
	schedule_list.organizer	string	组织者
									不多于64字节
	schedule_list.status	uint32	日程状态。0-正常；1-已取消
	schedule_list.start_time	uint32	日程开始时间，Unix时间戳
	schedule_list.end_time	uint32	日程结束时间，Unix时间戳
	schedule_list.sequence	uint64	日程编号，是一个自增数字
	schedule_list.cal_id	string	日程所属日历ID。该日历必须是access_token所对应应用所创建的日历。
									注意，这个日历必须是属于组织者(organizer)的日历；
									如果不填，那么插入到组织者的默认日历上。
									第三方应用必须指定cal_id 
									不多于64字节

注意，被取消的日程也可以拉取详情，调用者需要检查status

=cut

sub get_by_calendar {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/schedule/get_by_calendar?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 add_attendees(access_token, hash);

新增日程参与者

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93648#新增日程参与者>

=head3 请求说明：

该接口用于在日历中更新指定的日程参与者列表

注意，该接口是增量式

=head4 请求包结构体为：

    {
		"schedule_id": "17c7d2bd9f20d652840f72f59e796AAA",
		"attendees": [
			{
				"userid": "userid2"
			}
		]
	}

=head4 参数说明：

    参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	schedule_id	是	string	日程ID。创建日程时返回的ID
	attendees	否	obj[]	日程参与者列表。累积最多支持2000人
	attendees.userid	是	string	日程参与者ID
									不多于64字节

=head3 权限说明

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok"
    }

=head3 RETURN 参数说明

    参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=cut

sub add_attendees {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/schedule/add_attendees?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del_attendees(access_token, hash);

删除日程参与者

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93648#删除日程参与者>

=head3 请求说明：

该接口用于在日历中更新指定的日程参与者列表

注意，该接口是增量式

=head4 请求包结构体为：

    {
		"schedule_id": "17c7d2bd9f20d652840f72f59e796AAA",
		"attendees": [
			{
				"userid": "userid2"
			}
		]
	}

=head4 参数说明：

    参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	schedule_id	是	string	日程ID。创建日程时返回的ID
	attendees	否	obj[]	日程参与者列表。最多支持2000人
	attendees.userid	是	string	日程参与者ID
									不多于64字节

=head3 权限说明

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok"
    }

=head3 RETURN 参数说明

    参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=cut

sub del_attendees {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/schedule/del_attendees?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
