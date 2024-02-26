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

our $VERSION = '0.10';
our @EXPORT = qw/ send update_template_card recall update_taskcard get_statistics revoke /;

=head1 FUNCTION

=head2 send(access_token, hash);

发送应用消息
最后更新：2024/01/10

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90236>

=head3 请求说明：
应用支持推送文本、图片、视频、文件、图文等类型。

=head4 请求包结构体为：

=head4 参数说明：

	参数	是否必须	说明
	access_token	是	调用接口凭证

=head3 权限说明

如果部分接收人无权限或不存在，发送仍然执行，但会返回无效的部分（即invaliduser或invalidparty或invalidtag），常见的原因是接收人不在应用的可见范围内。

如果全部接收人无权限或不存在，则本次调用返回失败，errcode为81013。

返回包中的userid，不区分大小写，统一转为小写

=head3 RETURN 返回结果

	{
	  "errcode" : 0,
	  "errmsg" : "ok",
	  "invaliduser" : "userid1|userid2",
	  "invalidparty" : "partyid1|partyid2",
	  "invalidtag": "tagid1|tagid2",
	  "unlicenseduser" : "userid3|userid4",
	  "msgid": "xxxx",
	  "response_code": "xyzxyz"
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	invaliduser	不合法的userid，不区分大小写，统一转为小写
	invalidparty	不合法的partyid
	invalidtag	不合法的标签id
	unlicenseduser	没有基础接口许可(包含已过期)的userid
	msgid	消息id，用于撤回应用消息
	response_code	仅消息类型为“按钮交互型”，“投票选择型”和“多项选择型”的模板卡片消息返回，应用可使用response_code调用更新模版卡片消息接口，72小时内有效，且只能使用一次

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

=head2 update_template_card(access_token, hash);

更新模版卡片消息
最后更新：2023/09/21

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94888>

=head3 请求说明：

=head3 更新按钮为不可点击状态

可回调的卡片可以将按钮更新为不可点击状态，并且自定义文案

=head4 请求包结构体为：

    {
		"userids" : ["userid1","userid2"],
		"partyids" : [2,3],
		"tagids" : [44,55],
		"atall" : 0,
		"agentid" : 1,
		"response_code": "response_code",
		"button":{
			"replace_name": "replace_name"
		}
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    userids	否	企业的成员ID列表（最多支持1000个）
	partyids	否	企业的部门ID列表（最多支持100个）
	tagids	否	企业的标签ID列表（最多支持100个）
	atall	否	更新整个任务接收人员
	agentid	是	应用的agentid
	response_code	是	更新卡片所需要消费的code，可通过发消息接口和回调接口返回值获取，一个code只能调用一次该接口，且只能在24小时内调用
	replace_name	是	需要更新的按钮的文案

=head3 更新为新的卡片

可回调的卡片可以更新成任何一种模板卡片

=head4 请求包结构体为：

=head4 参数说明：

=head3 权限说明

=head3 RETURN 返回结果

    {
	  "errcode" : 0,
	  "errmsg" : "ok",
	  "invaliduser" : ["userid1","userid2"], // 不区分大小写，返回的列表都统一转为小写
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

如果部分指定的用户无权限或不存在，更新仍然执行，但会返回无效的部分（即invaliduser），常见的原因是用户不在应用的可见范围内或者不在消息的接收范围内。

=cut

sub update_template_card {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/message/update_template_card?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 recall(access_token, hash);

撤回应用消息
最后更新：2021/08/11

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94867>

=head3 请求说明：

本接口可以撤回24小时内通过发送应用消息接口推送的消息，仅可撤回企业微信端的数据，微信插件端的数据不支持撤回。

=head4 请求包结构体为：

    {
		"msgid": "vcT8gGc-7dFb4bxT35ONjBDz901sLlXPZw1DAMC_Gc26qRpK-AK5sTJkkb0128t"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证。获取方法查看“获取access_token”
	msgid	是	消息ID。从应用发送消息接口处获得。


=head3 权限说明

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok"
    }

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

=cut

sub recall {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/message/recall?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
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

=head2 revoke(access_token, hash);

图文消息撤回

=head2 SYNOPSIS

L<https://open.work.weixin.qq.com/api/doc/13568>

=head3 请求说明：

=head4 请求包结构体为：

    {
        "mpnews_url": "https://open.work.weixin.qq.com/wwopen/mpnews?mixuin=A_4ACQAABwD9eauwAAAUAA&mfid=WW0319-1tGqnAAABwBG0d1cPIxyBgup0HL23&idx=0&sn=70b8307095a856271494254f1eee99db"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    mpnews_url	是	mpnews 的 地址


=head3 权限说明

access_token 对应的secret必须与发送此消息使用的secret一致，否则无权限撤回

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok"
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

=cut

sub revoke {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/message/revoke?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
