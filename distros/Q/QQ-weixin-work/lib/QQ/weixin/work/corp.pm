package QQ::weixin::work::corp;

=encoding utf8

=head1 Name

QQ::weixin::work::corp

=head1 DESCRIPTION

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ get_join_qrcode
				getapprovaldata /;

=head1 FUNCTION

=head2 get_join_qrcode(access_token, size_type);

获取加入企业二维码
最后更新：2019/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/91714>

=head3 请求说明：

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    size_type	否	qrcode尺寸类型，1: 171 x 171; 2: 399 x 399; 3: 741 x 741; 4: 2052 x 2052

=head4 权限说明：

须拥有通讯录的管理权限，使用通讯录同步的Secret。

=head3 RETURN 返回结果：

    {
    	"errcode": 0,
    	"errmsg": "ok",
		"join_qrcode": "https://work.weixin.qq.com/wework_admin/genqrcode?action=join&vcode=3db1fab03118ae2aa1544cb9abe84&r=hb_share_api_mjoin&qr_size=3"
    }

=head4 RETURN 参数说明：

	参数	        说明
    errcode	    出错返回码，为0表示成功，非0表示调用失败
    errmsg	对返回码的文本描述内容
    join_qrcode	二维码链接，有效期7天

=cut

sub get_join_qrcode {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $size_type = $_[1] || 1;
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/corp/get_join_qrcode?access_token=$access_token&size_type=$size_type");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getapprovaldata(access_token, hash);

获取审批数据（旧）
最后更新：2019/11/22
提示：推荐使用新接口“批量获取审批单号”及“获取审批申请详情”，此接口后续将不再维护、逐步下线。

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/91530>

=head3 请求说明：

通过本接口来获取公司一段时间内的审批记录。一次拉取调用最多拉取100个审批记录，可以通过多次拉取的方式来满足需求，但调用频率不可超过600次/分。

=head4 请求包结构体为：

	{
	   "starttime":  1492617600,
	   "endtime":    1492790400,
	   "next_spnum": 201704200003
	}

=head4 参数说明：

	参数		必须		说明
	access_token	是	调用接口凭证。必须使用审批应用的secret获取，获取方式参考：文档-获取access_token
	starttime	是	获取审批记录的开始时间。Unix时间戳
	endtime	是	获取审批记录的结束时间。Unix时间戳
	next_spnum	否	第一个拉取的审批单号，不填从该时间段的第一个审批单拉取

1. 获取审批记录请求参数endtime需要大于startime， 同时起始时间跨度不要超过30天；
2. 一次请求返回的审批记录上限是100条，超过100条记录请使用next_spnum进行分页拉取。

=head4 权限说明：

=head3 RETURN 返回结果：

	{
		"errcode":0,
		"errmsg":"ok",
		"count":3,
		"total":5,
		"next_spnum":201704240001,
		"data":[
			{
				"spname":"报销",
				"apply_name":"报销测试",
				"apply_org":"报销测试企业",
				"approval_name":[
					"审批人测试"
				],
				"notify_name":[
						"抄送人测试"
				],
				"sp_status":1,
				"sp_num":201704200001,
				"mediaids":["WWCISP_G8PYgRaOVHjXWUWFqchpBqqqUpGj0OyR9z6WTwhnMZGCPHxyviVstiv_2fTG8YOJq8L8zJT2T2OvTebANV-2MQ"],
				"apply_time":1499153693,
				"apply_user_id":"testuser",
				"expense":{
					"expense_type":1,
					"reason":"",
					"item":[
						{
							"expenseitem_type":6,
							"time":1492617600,
							"sums":9900,
							"reason":""
						}
					]
				}，
				"comm":{
					"apply_data":"{\"item-1492610773696\":{\"title\":\"abc\",\"type\":\"text\",\"value\":\"\"}}"
				}
			},
			{
				"spname":"请假",
				"apply_name":"请假测试",
				"apply_org":"请假测试企业",
				"approval_name":[
					"审批人测试"
				],
				"notify_name":[
						"抄送人测试"
				],
				"sp_status":1,
				"sp_num":201704200004,
				"apply_time":1499153693,
				"apply_user_id":"testuser",
				"leave":{
					"timeunit":0,
					"leave_type":4,
					"start_time":1492099200,
					"end_time":1492790400,
					"duration":144,
					"reason":""
				}，
				"comm":{
					"apply_data":"{\"item-1492610773696\":{\"title\":\"abc\",\"type\":\"text\",\"value\":\"\"}}"
				}
			},
			{
				"spname":"自定义审批",
				"apply_name":"自定义",
				"apply_org":"自定义测试企业",
				"approval_name":[
					"自定义审批人"
				],
				"notify_name":[
						"自定义抄送人"
				],
				"sp_status":1,
				"sp_num":201704240001,
				"apply_time":1499153693,
				"apply_user_id":"testuser",
				"comm":{
					"apply_data":"{\"item-1492610773696\":{\"title\":\"abc\",\"type\":\"text\",\"value\":\"\"}}"
				}
			}
		]
	}

=head4 RETURN 参数说明：

	参数	类型	说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	count	拉取的审批单个数，最大值为100，当total参数大于100时，可运用next_spnum参数进行多次拉取
	total	时间段内的总审批单个数
	next_spnum	拉取列表的最后一个审批单号
	spname	审批名称(请假，报销，自定义审批名称)
	apply_name	申请人姓名
	apply_org	申请人部门
	approval_name	审批人姓名
	notify_name	抄送人姓名
	sp_status	审批状态：1审批中；2 已通过；3已驳回；4已取消；6通过后撤销；10已支付
	sp_num	审批单号
	apply_time	审批单提交时间
	apply_user_id	审批单提交者的userid
	leave	请假类型(只有请假模板审批记录有此数据项)
	timeunit	请假时间单位：0半天；1小时
	leave_type	请假类型：1年假；2事假；3病假；4调休假；5婚假；6产假；7陪产假；8其他
	start_time	请假开始时间，unix时间
	end_time	请假结束时间，unix时间
	duration	请假时长，单位小时
	reason	请假事由
	expense	报销类型（只有报销模板的审批记录有此数据项）
	expense_type	报销类型：1差旅费；2交通费；3招待费；4其他报销
	reason	报销事由
	item	报销明细 (历史单据字段，新申请单据不再提供)
	expenseitem_type	费用类型：1飞机票；2火车票；3的士费；4住宿费；5餐饮费；6礼品费；7活动费；8通讯费；9补助；10其他 (历史单据字段，新申请单据不再提供)
	time	发生时间，unix时间 (历史单据字段，新申请单据不再提供)
	sums	费用金额，单位元 (历史单据字段，新申请单据不再提供)
	reason	明细事由 (历史单据字段，新申请单据不再提供)
	comm	审批模板信息
	apply_data	审批申请的单据数据，请参见下方返回数据注解2；
	mediaids	审批的附件media_id，可使用media/get获取附件

=cut

sub getapprovaldata {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corp/getapprovaldata?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
