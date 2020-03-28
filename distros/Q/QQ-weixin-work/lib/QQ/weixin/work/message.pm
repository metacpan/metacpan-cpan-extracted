package QQ::weixin::work::message;

=encoding utf8

=head1 Name

QQ::weixin::work::message

=head1 DESCRIPTION

消息推送

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.04';
our @EXPORT = qw/ send update_taskcard get_statistics /;

=head1 FUNCTION

=head2 send(access_token, hash);

发送应用消息

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90236>

=head3 请求说明：

=head4 请求包结构体为：

=head4 参数说明：

=head3 权限说明

如果部分接收人无权限或不存在，发送仍然执行，但会返回无效的部分（即invaliduser或invalidparty或invalidtag），常见的原因是接收人不在应用的可见范围内。

如果全部接收人无权限或不存在，则本次调用返回失败，errcode为81013。

返回包中的userid，不区分大小写，统一转为小写

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
      "invaliduser" : "userid1|userid2",
      "invalidparty" : "partyid1|partyid2",
      "invalidtag": "tagid1|tagid2"
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

=cut

sub send {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update_taskcard(access_token, hash);

更新任务卡片消息状态

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/91579>

=head3 请求说明：

=head4 请求包结构体为：

    {
      "userids" : ["userid1","userid2"],
      "agentid" : 1,
      "task_id": "taskid122",
      "clicked_key": "btn_key123"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userids	是	企业的成员ID列表（消息接收者，最多支持1000个）。
    agentid	是	应用的agentid
    task_id	是	发送任务卡片消息时指定的task_id
    clicked_key	是	设置指定的按钮为选择状态，需要与发送消息时指定的btn:key一致

=head3 权限说明

系统应用须拥有邮件群组的写管理权限。

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
      "invaliduser" : ["userid1","userid2"], // 不区分大小写，返回的列表都统一转为小写
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

    如果部分指定的用户无权限或不存在，更新仍然执行，但会返回无效的部分（即invaliduser），常见的原因是用户不在应用的可见范围内或者不在消息的接收范围内。

=cut

sub update_taskcard {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/message/update_taskcard?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_statistics(access_token, hash);

查询应用消息发送统计

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/92369>

=head3 请求说明：

=head4 请求包结构体为：

    {
      "time_type": 0
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    time_type	否	查询哪天的数据，0：当天；1：昨天。默认为0。

=head3 权限说明

无

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
      "statistics": [
        {
            "agentid": 1000002,
           "app_name": "应用1",
           "count": 101
         }，
         {
           "agentid": 1000003,
           "app_name": "应用2",
           "count": 102
         }
      ]
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    statistics.agentid	应用id
    statistics.app_name	应用名
    statistics.count	发消息成功人次

=cut

sub get_statistics {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/message/get_statistics?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
