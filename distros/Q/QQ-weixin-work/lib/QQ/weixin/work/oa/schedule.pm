package QQ::weixin::work::oa::schedule;

=encoding utf8

=head1 Name

QQ::weixin::work::oa::schedule

=head1 DESCRIPTION

日历

=cut

use strict;
use base qw(QQ::weixin::work::oa);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.04';
our @EXPORT = qw/ add update get del get_by_calendar /;

=head1 FUNCTION

=head2 add(access_token, hash);

创建日程

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/92622>

=head3 请求说明：

=head4 请求包结构体为：

    {
        "schedule": {
            "organizer": "userid1",
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
                "repeat_type": 7
            },
            "location": "test_place",
            "cal_id": "wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA"
        }
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证。获取方法查看“获取access_token”
    schedule	是	日程信息
    organizer	是	组织者
    start_time	是	日程开始时间，Unix时间戳
    end_time	是	日程结束时间，Unix时间戳
    attendees	否	日程参与者列表。最多支持2000人
    userid	是	日程参与者ID
    summary	否	日程标题。0 ~ 128 字符。不填会默认显示为“新建事件”
    description	否	日程描述。0 ~ 512 字符
    reminders	否	提醒相关信息
    is_remind	否	是否需要提醒。0-否；1-是
    remind_before_event_secs	否	日程开始（start_time）前多少秒提醒，当is_remind为1时有效。例如： 300表示日程开始前5分钟提醒。目前仅支持以下数值：
    0 - 事件开始时
    300 - 事件开始前5分钟
    900 - 事件开始前15分钟
    3600 - 事件开始前1小时
    86400 - 事件开始前1天
    is_repeat	否	是否重复日程。0-否；1-是
    repeat_type	否	重复类型，当is_repeat为1时有效。目前支持如下类型：
    0 - 每日
    1 - 每周
    2 - 每月
    5 - 每年
    7 - 工作日
    location	否	日程地址。0 ~ 128 字符
    cal_id	否	日程所属日历ID。注意，这个日历必须是属于组织者(organizer)的日历；如果不填，那么插入到组织者的默认日历上

=head3 权限说明

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "ok",
       "schedule_id":"17c7d2bd9f20d652840f72f59e796AAA"
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
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

L<https://work.weixin.qq.com/api/doc/90000/90135/92623>

=head3 请求说明：

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
                "repeat_type": 7
            },
            "location": "test_place",
            "cal_id": "wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA"
        }
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    schedule	是	日程信息
    organizer	是	组织者。注意，暂不支持变更组织者
    schedule_id	是	日程ID
    start_time	是	日程开始时间，Unix时间戳
    end_time	是	日程结束时间，Unix时间戳
    attendees	否	日程参与者列表。最多支持2000人
    userid	是	日程参与者ID
    summary	否	日程标题。0 ~ 128 字符。不填会默认显示为“新建事件”
    description	否	日程描述。0 ~ 512 字符
    reminders	否	提醒相关信息
    is_remind	否	是否需要提醒。0-否；1-是
    remind_before_event_secs	否	日程开始（start_time）前多少秒提醒，当is_remind为1时有效。例如： 300表示日程开始前5分钟提醒。目前仅支持以下数值：
                                  0 - 事件开始时
                                  300 - 事件开始前5分钟
                                  900 - 事件开始前15分钟
                                  3600 - 事件开始前1小时
                                  86400 - 事件开始前1天
    is_repeat	否	是否重复日程。0-否；1-是
    repeat_type	否	重复类型，当is_repeat为1时有效。目前支持如下类型：
                  0 - 每日
                  1 - 每周
                  2 - 每月
                  5 - 每年
                  7 - 工作日
    location	否	日程地址。0 ~ 128 字符
    cal_id	否	日程所属日历ID。注意，这个日历必须是属于组织者(organizer)的日历；如果不填，那么插入到组织者的默认日历上

=head3 权限说明

注意, 更新操作是覆盖式，而不是增量式

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "ok"
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

L<https://work.weixin.qq.com/api/doc/90000/90135/92624>

=head3 请求说明：

=head4 请求包结构体为：

    {
        "schedule_id_list": [
            "17c7d2bd9f20d652840f72f59e796AAA"
        ]
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    schedule_id_list	是	日程ID列表。一次最多拉取1000条

=head3 权限说明

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok",
        "schedule_list": [
            {
                "schedule_id": "17c7d2bd9f20d652840f72f59e796AAA",
                "organizer": "userid1",
                "attendees": [
                    {
                        "userid": "userid2",
                        "response_status": 1
                    }
                ],
                "summary": "test_summary",
                "description": "test_content",
                "reminders": {
                    "is_remind": 1,
                    "is_repeat": 1,
                    "remind_before_event_secs": 3600,
                    "repeat_type": 7
                },
                "location": "test_place",
                "cal_id": "wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA",
                "start_time": 1571274600,
                "end_time": 1571320210,
                "status": 1
            }
        ]
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    schedule_list	日程列表
    schedule_id	日程ID
    organizer	组织者
    start_time	日程开始时间，Unix时间戳
    end_time	日程结束时间，Unix时间戳
    attendees	日程参与者列表。最多支持2000人
    userid	日程参与者ID
    response_status	日程参与者的接受状态。
                    0 - 未处理
                    1 - 待定
                    2 - 全部接受
                    3 - 仅接受一次
                    4 - 拒绝
    summary	日程标题。0 ~ 128 字符。不填会默认显示为“新建事件”
    description	日程描述。0 ~ 512 字符
    reminders	提醒相关信息
    is_remind	是否需要提醒。0-否；1-是
    remind_before_event_secs	日程开始（start_time）前多少秒提醒，当is_remind为1时有效。例如： 300表示日程开始前5分钟提醒。目前仅支持以下数值：
                              0 - 事件开始时
                              300 - 事件开始前5分钟
                              900 - 事件开始前15分钟
                              3600 - 事件开始前1小时
                              86400 - 事件开始前1天
    is_repeat	是否重复日程。0-否；1-是
    repeat_type	重复类型，当is_repeat为1时有效。目前支持如下类型：
                0 - 每日
                1 - 每周
                2 - 每月
                5 - 每年
                7 - 工作日
    location	日程地址。0 ~ 128 字符
    cal_id	日程所属日历ID。如果是在默认日历上，该参数没有值
    status	日程状态。0-正常；1-已取消

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

L<https://work.weixin.qq.com/api/doc/90000/90135/92625>

=head3 请求说明：

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
    errcode	返回码
    errmsg	对返回码的文本描述内容

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

L<https://work.weixin.qq.com/api/doc/90000/90135/92626>

=head3 请求说明：

=head4 请求包结构体为：

    {
        "cal_id": "wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA",
        "offset" : 100,
        "limit" : 1000
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    cal_id	是	日历ID
    offset	否	分页，偏移量, 默认为0
    limit	否	分页，预期请求的数据量，默认为500，取值范围 1 ~ 1000

=head3 权限说明

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok",
        "schedule_list": [
            {
                "schedule_id": "17c7d2bd9f20d652840f72f59e796AAA",
                "sequence": 100,
                "attendees": [
                    {
                        "userid": "userid1",
                        "response_status": 0
                    }
                ],
                "summary": "test_summary",
                "description": "test_content",
                "reminders": {
                    "is_remind": 1,
                    "is_repeat": 1,
                    "remind_before_event_secs": 3600,
                    "repeat_type": 7
                },
                "place": "test_place",
                "location": "17732924216771328",
                "start_time": 1571274600,
                "end_time": 1571320210,
                "status": 1,
                "cal_id": "wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA"
            }
        ]
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    schedule_list	日程列表
    schedule_id	日程ID
    sequence	日程编号，是一个自增数字
    start_time	日程开始时间，Unix时间戳
    end_time	日程结束时间，Unix时间戳
    attendees	日程参与者列表。最多支持2000人
    userid	日程参与者ID
    response_status	日程参与者的接受状态。
                    0 - 未处理
                    1 - 待定
                    2 - 全部接受
                    3 - 仅接受一次
                    4 - 拒绝
    summary	日程标题。0 ~ 128 字符。不填会默认显示为“新建事件”
    description	日程描述。0 ~ 512 字符
    reminders	提醒相关信息
    is_remind	是否需要提醒。0-否；1-是
    remind_before_event_secs	日程开始（start_time）前多少秒提醒，当is_remind为1时有效。例如： 300表示日程开始前5分钟提醒。目前仅支持以下数值：
                              0 - 事件开始时
                              300 - 5分钟
                              900 - 15分钟
                              3600 - 1小时
                              86400 - 1天
    is_repeat	是否重复日程。0-否；1-是
    repeat_type	重复类型，当is_repeat为1时有效。目前支持如下类型：
                0 - 每日
                1 - 每周
                2 - 每月
                5 - 每年
                7 - 工作日
    location	日程地址。0 ~ 128 字符
    cal_id	日程所属日历ID
    status	日程状态。0-正常；1-已取消

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


1;
__END__
