package QQ::weixin::work::oa::meetingroom;

=encoding utf8

=head1 Name

QQ::weixin::work::oa::meetingroom

=head1 DESCRIPTION

会议室

=cut

use strict;
use base qw(QQ::weixin::work::oa);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ add list edit del
				get_booking_info book book_by_schedule book_by_meeting
				cancel_book get_booking_info_by_meeting_id /;

=head1 FUNCTION

=head2 会议室管理

最后更新：2023/11/30

=head3 权限说明

调用会议室相关接口的应用有如下的权限要求：

	应用类型	权限要求
	自建应用	配置到「应用管理 - 会议室 - 可调用接口的应用」中
	代开发应用	暂不支持
	第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head2 add(access_token, hash);

添加会议室

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93619#添加会议室>

=head3 请求说明：

企业可通过此接口添加一个会议室。

=head4 请求包结构体为：

	{
	  "name":"18F-会议室",
	  "capacity":10,
	  "city":"深圳",
	  "building":"腾讯大厦",
	  "floor":"18F",
	  "equipment":[1,2,3],
	  "coordinate":
	  {
		"latitude":"22.540503",
		"longitude":"113.934528"
	  },
	  "range":
	  {
				"user_list":["zhangsan","lisi"],
				"department_list":[1]
	  }
	}

=head4 参数说明：

	参数		必须		说明
	access_token	是	调用接口凭证
	name	是	会议室名称，最多30个字符
	capacity	是	会议室所能容纳的人数
	city	否	会议室所在城市
	building	否	会议室所在楼宇
	floor	否	会议室所在楼层
	equipment	否	会议室支持的设备列表,参数详细含义见附录
	coordinate.latitude	否	会议室所在建筑纬度,可通过腾讯地图坐标拾取器获取
	coordinate.longitude	否	会议室所在建筑经度,可通过腾讯地图坐标拾取器获取
	range.user_list	否	会议室使用范围的userid列表，最多指定1000个成员
	range.department_list	否	会议室使用范围的部门id列表，最多指定1000个部门

如果不填写range参数，则默认为全公司可用。
如果需要为会议室设置位置信息，则必须同时填写城市（city），楼宇（building）和楼层(floor)三个参数。

=head3 权限说明

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "meetingroom_id":1
	}

=head3 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    meetingroom_id	会议室的id

=cut

sub add {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/meetingroom/add?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token, hash);

查询会议室

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93619#查询会议室>

=head3 请求说明：

企业可通过此接口查询满足条件的会议室。

=head4 请求包结构体为：

    {
	  "city":"深圳",
	  "building":"腾讯大厦",
	  "floor":"18F",
	  "equipment":[1,2,3]
	}

=head4 参数说明：

	参数		是否必须		说明
	access_token	是	调用接口凭证
	city	否	会议室所在城市
	building	否	会议室所在楼宇
	floor	否	会议室所在楼层
	equipment	否	会议室支持的设备列表,参数详细含义见附录

如果需要使用某个位置信息进行查询，则需要保证其上一级的位置信息已填写，即如需使用楼宇进行过滤，则必须同时填写城市字段

=head3 权限说明

=head3 RETURN 返回结果

	 {
	   "errcode": 0,
	   "errmsg": "ok",
	   "meetingroom_list":
	   [
	   {
		"meetingroom_id":1,
		"name":"18F-会议室",
		"capacity":10,
		"city":"深圳",
		"building":"腾讯大厦",
		"floor":"18F",
		"equipment":[1,2,3],
		"coordinate":
		{
		 "latitude":"22.540503",
		 "longitude":"113.934528"
		},
		"need_approval":1
	   },
	   {
		"meetingroom_id":2,
		"name":"19F-会议室",
		"capacity":20,
		"city":"深圳",
		"building":"腾讯大厦",
		"floor":"19F",
		"equipment":[2,3],
		"coordinate":
		{
				"latitude":"22.540503",
				"longitude":"113.934528"
		},
		 "range":
		{
				"user_list":["zhangsan","lisi"],
				"department_list":[1]
		 }
	   },
	   ]
	}

=head3 RETURN 参数说明

	参数		说明
	errcode	返回码
	errmsg	对返回码的文本描述内容
	meetingroom_list	满足条件的会议室列表
	meetingroom_list.meetingroom_id	会议室id
	meetingroom_list.name	会议室名称
	meetingroom_list.capacity	会议室容纳人数
	meetingroom_list.city	会议室所在城市
	meetingroom_list.building	会议室所在楼宇
	meetingroom_list.floor	会议室所在楼层
	meetingroom_list.equipment	会议室支持的设备列表
	meetingroom_list.coordinate.latitude	会议室所在楼宇的纬度
	meetingroom_list.coordinate.longitude	会议室所在楼宇的经度
	meetingroom_list.need_approval	是否需要审批 0-无需审批 1-需要审批
	range.user_list	会议室使用范围的userid列表（仅会议室系统应用查询时返回）
	range.department_list	会议室使用范围的部门id列表，（仅会议室系统应用查询时返回）

=cut

sub list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/meetingroom/list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 edit(access_token, hash);

编辑会议室

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93619#编辑会议室>

=head3 请求说明：

企业可通过此接口编辑相关会议室的基本信息。

注意，会议室使用范围(range)为覆盖操作，而非增量添加。

=head4 请求包结构体为：

	{
	  "meetingroom_id":2,
	  "name":"18F-会议室",
	  "capacity":10,
	  "city":"深圳",
	  "building":"腾讯大厦",
	  "floor":"18F",
	  "equipment":[1,2,3],
	  "coordinate":
	  {
				"latitude":"22.540503",
				"longitude":"113.934528"
	  },
	  "range":
	  {
				"user_list":["zhangsan","lisi"],
				"department_list":[1]
	  }
	}

=head4 参数说明：

	参数		必须		说明
	access_token	是	调用接口凭证
	meetingroom_id	是	会议室的id
	name	否	会议室名称，最多30个字符
	capacity	否	会议室所能容纳的人数
	city	否	会议室所在城市
	building	否	会议室所在楼宇
	floor	否	会议室所在楼层
	equipment	否	会议室支持的设备列表,参数详细含义见附录
	coordinate.latitude	否	会议室所在建筑纬度,可通过腾讯地图坐标拾取器获取
	coordinate.longitude	否	会议室所在建筑经度,可通过腾讯地图坐标拾取器获取
	range.user_list	否	会议室使用范围的userid列表，最多指定1000个成员，填写后将覆盖整个使用范围
	range.department_list	否	会议室使用范围的部门id列表，最多指定1000个部门，填写后将覆盖整个使用范围

如果需要修改位置信息，请同时输入城市，楼宇和楼层三个参数，已经生成的建筑，暂不支持修改经纬度。

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

sub edit {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/meetingroom/edit?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del(access_token, hash);

删除会议室

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93619#删除会议室>

=head3 请求说明：

企业可通过此接口删除指定的会议室。

=head4 请求包体：

    {
    	"meetingroom_id":1,
    }

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    meetingroom_id	是	会议室的id

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

=head4 附录

当前支持的会议室设备如下

	设备id	设备名称
	1	电视
	2	电话
	3	投影
	4	白板
	5	视频

=cut

sub del {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/meetingroom/del?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 会议室预定管理

最后更新：2023/12/01

=head3 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93620>

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「应用管理 - 会议室 - 可调用接口的应用」中
	代开发应用	暂不支持
	第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head2 get_booking_info(access_token, hash);

查询会议室的预定信息

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93620#查询会议室的预定信息>

=head3 请求说明：

企业可通过此接口查询相关会议室在指定时间段的预定情况，如是否已被预定，预定者的userid等信息，不支持跨天查询。

=head4 请求包体：

    {
	  "meetingroom_id":1,
	  "start_time":1593532800,
	  "end_time":1593619200,
	  "city":"深圳",
	  "building":"腾讯大厦",
	  "floor":"18F"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	meetingroom_id	否	会议室id
	start_time	否	查询预定的起始时间，默认为当前时间
	end_time	否	查询预定的结束时间， 默认为明日0时
	city	否	会议室所在城市
	building	否	会议室所在楼宇
	floor	否	会议室所在楼层

如果需要根据位置信息查询，则需要保证其上一级的位置信息已填写，即如需使用楼宇进行过滤，则必须同时填写城市字段。

=head3 权限说明

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"booking_list": [{
				"meetingroom_id": 1,
				"schedule": [{
					"booking_id": "bkebsada6e027c123cbafAAA",
					"schedule_id": "17c7d2bd9f20d652840f72f59e796AAA",
					"start_time": 1593532800,
					"end_time": 1593662400,
					"booker": "zhangsan",
					"status":0
				}]
			},
			{
				"meetingroom_id": 2,
				"schedule": []
			}
		]
	}

=head3 RETURN 参数说明

	参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	booking_list	会议室预订信息列表
	booking_list.meetingroom_id	会议室id
	booking_list.schedule	该会议室查询时间段内的预定情况
	booking_list.schedule.start_time	开始时间的时间戳
	booking_list.schedule.end_time	结束时间的时间戳
	booking_list.schedule.booker	预定人的userid
	booking_list.schedule.status	会议室的预定状态，0：已预定、1：已取消、2：申请中、3：审批中
	booking_list.schedule.booking_id	会议室的预定id
	booking_list.schedule.schedule_id	会议关联日程的id，若会议室已取消预定（未保留日历），则schedule_id将无法再获取到日程详情

=cut

sub get_booking_info {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/meetingroom/get_booking_info?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 book(access_token, hash);

预定会议室

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93620#预定会议室>

=head3 请求说明：

企业可通过此接口预定会议室并自动关联日程。

=head4 请求包体：

    {
	  "meetingroom_id":1,
	  "subject":"周会",
	  "start_time":1593532800,
	  "end_time":1593619200,
	  "booker":"zhangsan",
	  "attendees":["lisi", "wangwu"]
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	subject	否	会议主题
	meetingroom_id	是	会议室id
	start_time	是	预定开始时间
	end_time	是	预定结束时间
	booker	是	预定人的userid
	attendees	否	参与人的userid列表

最小预定时长为30分钟；
预定时间和结束时间会自动按30分钟取整，即如果传入的开始和结束时间戳分别对应时间为15:15和15:45，则预定时会自动取整为15:00和16:00；
此API仅可预定无需审批的会议室；
如果当前时间已经晚于预定时间，则按以下情况进行处理：
1.当前已过预定结束时间，则不允许预定
2.当前在预定开始时间15分钟内，则允许预定
3.当前已超过预定开始时间15分钟，则自动转换预定开始时间到下一个时间窗口，即增加30分钟到开始时间

=head3 权限说明

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok"
	   "meeting_id":"mtgsaseb6e027c123cbafAAA",
	   "schedule_id":"17c7d2bd9f20d652840f72f59e796AAA"
	}

=head3 RETURN 参数说明

	参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	meeting_id	会议的id
	schedule_id	会议关联日程的id

=cut

sub book {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/meetingroom/book?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 book_by_schedule(access_token, hash);

通过日程预定会议室

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93620#通过日程预定会议室>

=head3 请求说明：

企业可通过此接口为指定日程预定会议室，支持重复日程预定。

注意：通过日程预定会议室后，该日程将不能通过更新日程接口进行编辑，而只能调用新增日程参与者与删除日程参与者接口。如果需要更新日程的时间等字段，可以先取消会议室预定，再调用更新日程接口，之后再重新预定会议室。

=head4 请求包体：

	{
		"meetingroom_id":1,
		"schedule_id":"1c7e7226edae66468bc48e9859812402",
		"booker":"rocky"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	meetingroom_id	是	会议室id
	schedule_id	是	日程id，仅可使用同应用创建的日程
	booker	是	预定人的userid

此API仅可预定无需审批的会议室；

=head3 权限说明

=head3 RETURN 返回结果

	{
	   "errcode": 0,
	   "errmsg": "ok"
	   "booking_id":"bkgsaseb6e027c123cbafAAA",
	   "conflict_date":[1672502400,1675180800,1677600000]
	}

=head3 RETURN 参数说明

	参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	booking_id	会议室的预定的id
	conflict_date	会议室冲突日期列表，为当天0点的时间戳；使用重复日程预定会议室，部分日期与会议室预定情况冲突时返回

=cut

sub book_by_schedule {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/meetingroom/book_by_schedule?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 book_by_meeting(access_token, hash);

通过会议预定会议室

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93620#通过会议预定会议室>

=head3 请求说明：

企业可通过此接口为指定会议预定会议室，支持重复会议预定。

=head4 请求包体：

	{
		"meetingroom_id":1,
		"meetingid":"hy7e7226edae66468bc48e9859812402",
		"booker":"rocky"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	meetingroom_id	是	会议室id
	meetingid	是	会议id，仅可使用同应用创建的会议
	booker	是	预定人的userid

此API仅可预定无需审批的会议室；

=head3 权限说明

=head3 RETURN 返回结果

	{
	   "errcode": 0,
	   "errmsg": "ok"
	   "booking_id":"bkgsaseb6e027c123cbafAAA",
	   "conflict_date":[1672502400,1675180800,1677600000]
	}

=head3 RETURN 参数说明

	参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	booking_id	会议室的预定的id
	conflict_date	会议室冲突日期列表，为当天0点的时间戳；使用重复日程预定会议室，部分日期与会议室预定情况冲突时返回

=cut

sub book_by_meeting {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/meetingroom/book_by_meeting?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 cancel_book(access_token, hash);

取消预定会议室

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93620#取消预定会议室>

=head3 请求说明：

企业可通过此接口取消会议室的预定。

=head4 请求包体：

	{
	  "booking_id":"bk42b34949gsaseb6e027c123cbafAAA",
	  "keep_schedule":1,
	  "cancel_date":1672502400
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	booking_id	是	会议室的预定id
	keep_schedule	否	是否保留日程，0-同步删除 1-保留，仅对非重复日程有效
	cancel_date	否	对于重复日程，如果不填写此参数，表示取消所有重复预定；如果填写，则表示取消对应日期当天的会议室预定

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

sub cancel_book {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/meetingroom/cancel_book?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_booking_info_by_meeting_id(access_token, hash);

根据会议ID查询会议室的预定信息

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93620#根据会议id查询会议室的预定信息>

=head3 请求说明：

企业可通过此接口按照会议ID查询相关会议室的预定情况。

=head4 请求包体：

    {
		"meetingroom_id":1,
		"meeting_id": "mtebsada6e027c123cbafAAA",
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	meetingroom_id	是	会议室id
	meeting_id	是	会议的id

=head3 权限说明

企业需要使用“会议室”secret所获取的accesstoken来调用（accesstoken如何获取？）。
暂不支持第三方调用

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"meetingroom_id": 1,
		"schedule": [
			{
				"meeting_id": "mtebsada6e027c123cbafAAA",
				"schedule_id": "17c7d2bd9f20d652840f72f59e796AAA",
				"start_time": 1593532800,
				"end_time": 1593662400,
				"booker": "zhangsan"
			}
		]
	}

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	meetingroom_id	会议室id
	schedule	该会议室的预定情况
	schedule.start_time	开始时间的时间戳
	schedule.end_time	结束时间的时间戳
	schedule.booker	预定人的userid，仅在已预定时返回
	schedule.meeting_id	会议的id，仅在已预定的时返回
	schedule.schedule_id	会议关联日程的id，仅在已预定时返回

=cut

sub get_booking_info_by_meeting_id {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/meetingroom/get_booking_info_by_meeting_id?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
