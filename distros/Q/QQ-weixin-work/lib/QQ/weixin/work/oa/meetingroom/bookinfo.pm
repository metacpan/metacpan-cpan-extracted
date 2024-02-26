package QQ::weixin::work::oa::meetingroom::bookinfo;

=encoding utf8

=head1 Name

QQ::weixin::work::oa::meetingroom::bookinfo

=head1 DESCRIPTION

会议室

=cut

use strict;
use base qw(QQ::weixin::work::oa::meetingroom);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ get /;

=head1 FUNCTION

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

=head2 get(access_token, hash);

根据会议室预定ID查询预定详情

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93620#根据会议室预定id查询预定详情>

=head3 请求说明：

企业可通过此接口根据预定id查询相关会议室的预定情况

=head4 请求包体：

	{
		"meetingroom_id":1,
		"booking_id": "bkebsada6e027c123cbafAAA",
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	meetingroom_id	是	会议室id
	booking_id	是	会议室的预定id

=head3 权限说明

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"meetingroom_id": 1,
		"schedule": {
			"booking_id": "bkebsada6e027c123cbafAAA",
			"master_booking_id":"rbsho97cbidajgixnyk8eAA",
			"schedule_id": "17c7d2bd9f20d652840f72f59e796AAA",
			"start_time": 1593532800,
			"end_time": 1593662400,
			"booker": "zhangsan",
			"status":0
		}
	}

=head3 RETURN 参数说明

	参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	meetingroom_id	会议室id
	schedule	该会议室的预定情况
	schedule.start_time	开始时间的时间戳
	schedule.end_time	结束时间的时间戳
	schedule.booker	预定人的userid
	schedule.booking_id	会议室的预定id
	schedule.master_booking_id	如果该预定是某个周期性预定的一部分，则返回对应周期性预定的booking_id
	schedule.schedule_id	会议关联日程的id，若会议室已取消预定(未保留日历)，则schedule_id将无法再获取到日程详情
	schedule.status	会议室的预定状态，0：已预定、1：已取消、2：申请中、3：审批中

=cut

sub get {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/meetingroom/bookinfo/get?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
