package QQ::weixin::work::batch;

=encoding utf8

=head1 Name

QQ::weixin::work::batch

=head1 DESCRIPTION

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ invite syncuser replaceuser replaceparty getresult /;

=head1 FUNCTION

=head2 invite(access_token, hash);

邀请成员
最后更新：2022/01/14

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90975>

=head3 请求说明：

企业可通过接口批量邀请成员使用企业微信，邀请后将通过短信或邮件下发通知。

=head4 请求包结构体为：

    {
      "user" : ["UserID1", "UserID2", "UserID3"],
      "party" : [PartyID1, PartyID2],
      "tag" : [TagID1, TagID2]
    }

=head4 参数说明：

	参数		必须		说明
    access_token	是	调用接口凭证
    user	否	成员ID列表, 最多支持1000个。
    party	否	部门ID列表，最多支持100个。
    tag	否	标签ID列表，最多支持100个。

=head3 权限说明

须拥有指定成员、部门或标签的查看权限。
第三方仅通讯录应用可调用。

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
		"invaliduser" : ["UserID1", "UserID2"],
		"invalidparty" : [PartyID1, PartyID2],
		"invalidtag": [TagID1, TagID2]
    }

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    invaliduser	非法成员列表
    invalidparty	非法部门列表
    invalidtag	非法标签列表

=head3 更多说明

user, party, tag三者不能同时为空；
如果部分接收人无权限或不存在，邀请仍然执行，但会返回无效的部分（即invaliduser或invalidparty或invalidtag）;
同一用户只须邀请一次，被邀请的用户如果未安装企业微信，在3天内每天会收到一次通知，最多持续3天。
因为邀请频率是异步检查的，所以调用接口返回成功，并不代表接收者一定能收到邀请消息（可能受上述频率限制无法接收）。

=cut

sub invite {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/batch/invite?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 syncuser(access_token, hash);

增量更新成员
最后更新：2022/01/05

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90980>

=head3 请求说明：

本接口以userid（账号）为主键，增量更新企业微信通讯录成员。请先下载CSV模板(下载增量更新成员模版)，根据需求填写文件内容。

=head3 注意事项：

模板中的部门需填写部门ID，多个部门用分号分隔，部门ID必须为数字，根部门的部门id默认为1
文件中存在、通讯录中也存在的成员，更新成员在文件中指定的字段值
文件中存在、通讯录中不存在的成员，执行添加操作
通讯录中存在、文件中不存在的成员，保持不变
成员字段更新规则：可自行添加扩展字段。文件中有指定的字段，以指定的字段值为准；文件中没指定的字段，不更新

=head4 请求包结构体为：

	{
		"media_id":"xxxxxx",
		"to_invite": true,
		"callback":
		{
			"url": "xxx",
			"token": "xxx",
			"encodingaeskey": "xxx"
		}
	}

=head4 参数说明：

	参数		必须		说明
    access_token	是	调用接口凭证
    media_id	是	上传的csv文件的media_id
	to_invite	否	是否邀请新建的成员使用企业微信（将通过微信服务通知或短信或邮件下发邀请，每天自动下发一次，最多持续3个工作日），默认值为true。
	callback	否	回调信息。如填写该项则任务完成后，通过callback推送事件给企业。具体请参考应用回调模式中的相应选项
	url	否	企业应用接收企业微信推送请求的访问协议和地址，支持http或https协议
	token	否	用于生成签名
	encodingaeskey	否	用于消息体的加密，是AES密钥的Base64编码

=head3 权限说明

须拥有通讯录的写权限。

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"jobid": "xxxxx"
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    jobid	异步任务id，最大长度为64字节

=cut

sub syncuser {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/batch/syncuser?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 replaceuser(access_token, hash);

全量覆盖成员
最后更新：2022/01/05

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90981>

=head3 请求说明：

本接口以userid为主键，全量覆盖企业的通讯录成员，任务完成后企业的通讯录成员与提交的文件完全保持一致。请先下载CSV文件(下载全量覆盖成员模版)，根据需求填写文件内容。

=head3 注意事项：

模板中的部门需填写部门ID，多个部门用分号分隔，部门ID必须为数字，根部门的部门id默认为1
文件中存在、通讯录中也存在的成员，完全以文件为准
文件中存在、通讯录中不存在的成员，执行添加操作
通讯录中存在、文件中不存在的成员，执行删除操作。出于安全考虑，下面两种情形系统将中止导入并返回相应的错误码。
需要删除的成员多于50人，且多于现有人数的20%以上
需要删除的成员少于50人，且多于现有人数的80%以上
成员字段更新规则：可自行添加扩展字段。文件中有指定的字段，以指定的字段值为准；文件中没指定的字段，不更新

=head4 请求包结构体为：

	{
		"media_id":"xxxxxx",
		"to_invite": true,
		"callback":
		{
			"url": "xxx",
			"token": "xxx",
			"encodingaeskey": "xxx"
		}
	}

=head4 参数说明：

	参数		必须		说明
    access_token	是	调用接口凭证
    media_id	是	上传的csv文件的media_id
	to_invite	否	是否邀请新建的成员使用企业微信（将通过微信服务通知或短信或邮件下发邀请，每天自动下发一次，最多持续3个工作日），默认值为true。
	callback	否	回调信息。如填写该项则任务完成后，通过callback推送事件给企业。具体请参考应用回调模式中的相应选项
	url	否	企业应用接收企业微信推送请求的访问协议和地址，支持http或https协议
	token	否	用于生成签名
	encodingaeskey	否	用于消息体的加密，是AES密钥的Base64编码

=head3 权限说明

须拥有通讯录的写权限。

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"jobid": "xxxxx"
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    jobid	异步任务id，最大长度为64字节

=cut

sub replaceuser {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/batch/replaceuser?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 replaceparty(access_token, hash);

全量覆盖部门
最后更新：2018/10/24

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90982>

=head3 请求说明：

本接口以partyid为键，全量覆盖企业的通讯录组织架构，任务完成后企业的通讯录组织架构与提交的文件完全保持一致。请先下载CSV文件(下载全量覆盖部门模版)，根据需求填写文件内容。

=head3 注意事项：

文件中存在、通讯录中也存在的部门，执行修改操作
文件中存在、通讯录中不存在的部门，执行添加操作
文件中不存在、通讯录中存在的部门，当部门下没有任何成员或子部门时，执行删除操作
文件中不存在、通讯录中存在的部门，当部门下仍有成员或子部门时，暂时不会删除，当下次导入成员把人从部门移出后自动删除
CSV文件中，部门名称、部门ID、父部门ID为必填字段，部门ID必须为数字，根部门的部门id默认为1；排序为可选字段，置空或填0不修改排序, order值大的排序靠前。

=head4 请求包结构体为：

	{
		"media_id":"xxxxxx",
		"to_invite": true,
		"callback":
		{
			"url": "xxx",
			"token": "xxx",
			"encodingaeskey": "xxx"
		}
	}

=head4 参数说明：

	参数		必须		说明
    access_token	是	调用接口凭证
    media_id	是	上传的csv文件的media_id
	callback	否	回调信息。如填写该项则任务完成后，通过callback推送事件给企业。具体请参考应用回调模式中的相应选项
	url	否	企业应用接收企业微信推送请求的访问协议和地址，支持http或https协议
	token	否	用于生成签名
	encodingaeskey	否	用于消息体的加密，是AES密钥的Base64编码

=head3 权限说明

须拥有通讯录的写权限。

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"jobid": "xxxxx"
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    jobid	异步任务id，最大长度为64字节

=cut

sub replaceparty {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/batch/replaceparty?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getresult(access_token, jobid);

获取异步任务结果
最后更新：2018/10/24

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90983>

=head3 请求说明：

=head4 参数说明：

	参数		必须		说明
    access_token	是	调用接口凭证
    jobid	是	异步任务id，最大长度为64字节

=head3 权限说明

只能查询已经提交过的历史任务。

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"status": 1,
		"type": "replace_user",
		"total": 3,
		"percentage": 33,
		"result": [{},{}]
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    status	任务状态，整型，1表示任务开始，2表示任务进行中，3表示任务已完成
	type	操作类型，字节串，目前分别有：1. sync_user(增量更新成员) 2. replace_user(全量覆盖成员)3. replace_party(全量覆盖部门)
	total	任务运行总条数
	percentage	目前运行百分比，当任务完成时为100
	result	详细的处理结果，具体格式参考下面说明。当任务完成后此字段有效

=head4 result结构：type为sync_user、replace_user时：

	"result": [
		{
			"userid":"lisi",
			"errcode":0,
			"errmsg":"ok"
		},
		{
			"userid":"zhangsan",
			"errcode":0,
			"errmsg":"ok"
		}
	]

	参数	说明
	userid	成员UserID。对应管理端的账号
	errcode	该成员对应操作的结果错误码
	errmsg	错误信息，例如无权限错误，键值冲突，格式错误等
	result结构：type为replace_party时：

	"result": [
		{
			"action":1,
			"partyid":1,
			"errcode":0,
			"errmsg":"ok"
		},
		{
			"action":4,
			"partyid":2,
			"errcode":0,
			"errmsg":"ok"
		}
	]

	参数	说明
	action	操作类型（按位或）：1 新建部门 ，2 更改部门名称， 4 移动部门， 8 修改部门排序
	partyid	部门ID
	errcode	该部门对应操作的结果错误码
	errmsg	错误信息，例如无权限错误，键值冲突，格式错误等

=cut

sub getresult {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $jobid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/batch/getresult?access_token=$access_token&jobid=$jobid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
