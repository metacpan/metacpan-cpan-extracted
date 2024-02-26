package QQ::weixin::work::pstncc;

=encoding utf8

=head1 Name

QQ::weixin::work::pstncc

=head1 DESCRIPTION

紧急通知应用

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ call getstates /;

=head1 FUNCTION

=head2 call(access_token, hash);

发起语音电话
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/91627>

=head3 请求说明：

通过此接口发起语音电话，提醒员工查看应用推送的重要消息。

=head4 请求包体：

	{
		"callee_userid":["james","paul"]
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	callee_userid	是	需要呼叫的列表
	
1. callee_userid不能为空

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「紧急通知 - 可调用接口的应用」中
	代开发应用	暂不支持
	第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

	{
		"errcode":0,
		"errmsg":"ok",
		"states":[
			{
				"code":0,
				"callid":"6-20190510201844181887818-4d0251082406000-out",
				"userid":"james"
			},
			{
				"code":0,
				"callid":"6-20190510201844181887818-4d025109f806000-out",
				"userid":"paul"
			}
		]
	}

=head3 RETURN 参数说明

	参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	states	自动语音来电呼叫状态列表
	userid	用户id
	callid	唯一标识一通呼叫的id
	code	呼叫结果状态：0成功发起呼叫，非0则失败

=head4 返回码：

	301049 调用接口的应用未在紧急通知应用中关联
	301050 紧急通知应用未开启
	301051 紧急通知应用余额不足

=cut

sub call {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/pstncc/call?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getstates(access_token, hash);

获取接听状态
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/91628>

=head3 请求说明：

通过此接口，了解员工是否已接听语音电话。

=head4 请求包体：

	{
	   "callee_userid" : "james",
	   "callid" : "6-20190510201844181887818-4d0251082406000-out"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	callee_userid	是	用户id
	callid	是	发起自动语音来电callid

1. callee_userid不能为空
2. callid 不能为空
3. 仅支持查询七天内的callid状态

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「紧急通知 - 可调用接口的应用」中
	代开发应用	暂不支持
	第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

	{
		"errcode":0,
		"errmsg":"ok",
		"istalked":1,
		"calltime":1557306531,
		"talktime":2,
		"reason":0
	}

=head3 RETURN 参数说明

	参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	istalked	0.表示未接听，1.表示接听
	calltime	呼叫发起时间戳
	talktime	通话时长单位（s）
	reason	呼叫结果状态：0正常结束

=head4 reason值含义：

	1: 振铃
	2: 接听
	3: 通话中
	4: 呼叫超时 – 用户挂机
	5: 不在服务区
	6: 欠费未接听
	7: 被叫拒接
	8: 被叫关机
	9: 空号
	10: 呼叫受限
	11: 线路错误
	12: 呼叫超时 – 系统挂机
	13: 呼叫超过限制（8分钟3次24小时8次）
	14: 线路超时未返回
	15: 超限（主叫超限，需要换号码呼叫）
	16: 线路繁忙-稍后在呼
	17: 呼叫取消通知
	20: 外呼超时未确认
	99: 其他

=cut

sub getstates {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/pstncc/getstates?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
