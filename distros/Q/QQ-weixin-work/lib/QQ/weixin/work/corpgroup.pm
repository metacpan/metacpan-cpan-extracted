package QQ::weixin::work::corpgroup;

=encoding utf8

=head1 Name

QQ::weixin::work::corpgroup

=head1 DESCRIPTION

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ unionid_to_external_userid unionid_to_pending_id
				import_chain_contact getresult get_corp_shared_chain_list /;

=head1 FUNCTION

=head2 unionid_to_external_userid(access_token, hash);

通过unionid和openid查询external_userid
最后更新：2023/09/28

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95818>

=head3 请求说明：

external_userid的说明

external_userid是企业微信用于表示企业的外部联系人而设立的id，且满足以下条件
假设同一个微信用户属于多个下游企业的外部联系人
1.同一上游企业获取到不同企业的外部联系人的external_userid不一致。
2.不同一上游企业获取同一个企业的同一个外部联系人的external_userid也不一致。

=head4 请求包结构体为：

	{
	  "unionid":"xxxxx",
	  "openid":"xxxxx",
	  "corpid":"xxxxx",
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    unionid	是	微信客户的unionid
	openid	是	微信客户的openid
	corpid	否	需要换取的企业corpid，不填则拉取所有企业

=head4 权限说明：

调用该接口的应用必须是上下游共享的应用
上游企业须已认证
unionid（unionid的主体为绑定了该小程序的微信开放平台账号主体）和openid（即小程序账号主体）的主体需与当前企业的主体一致
openid与unionid必须是在同一个小程序获取到的
应用需要具有客户联系权限
自建应用/代开发应用可调用，第三方应用请查看企业客户微信unionid的升级方案
调用频率最大为2万次/小时，24万次/天

=head3 RETURN 返回结果：

	｛
	 "errcode":0,
	 "errmsg":"ok",
	 "external_userid_info":[
			{
				"corpid":"AAAAA", 
				"external_userid":"BBBB"
			}, 
			{
				"corpid":"CCCCC", 
				"external_userid":"DDDDD"
			}
		]
	｝

=head4 RETURN 参数说明：

	参数	        说明
    errcode	    出错返回码，为0表示成功，非0表示调用失败
    errmsg	对返回码的文本描述内容
    external_userid_info	该unionid对应的外部联系人信息
	external_userid_info.corpid	所属企业id
	external_userid_info.external_userid	外部联系人id

=cut

sub unionid_to_external_userid {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/unionid_to_external_userid?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 unionid_to_pending_id(access_token, hash);

unionid查询pending_id
最后更新：2023/03/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97357>

=head3 请求说明：

pending_id的说明

pending_id主要用于关联微信unionid与外部联系人external_userid，可理解为临时外部联系人ID；
上游企业可通过此接口将微信unionid转为pending_id，当微信用户成为下游企业客户后，可使用上下游external_userid转pending_id接口将下游external_userid转换为pending_id，建立unionid => pending_id => external_userid的映射关系；
pending_id有效期90天，共享应用内唯一。

=head4 请求包结构体为：

	{
		"unionid":"UNIONID",
		"openid":"OPENID"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    unionid	是	微信客户的unionid
	openid	是	微信客户的openid

=head4 权限说明：

1. 调用该接口的应用必须是上下游共享的自建应用或代开发应用
2. 应用需要具有客户联系权限
3. 当前授权企业必须已认证或已验证；若为代开发应用，服务商必须已认证
4. unionid（即微信开放平台账号主体）与openid（即小程序或服务号账号主体）需要认证，且主体名称需与上游企业的主体名称一致（查看由服务商代注册的开放平台账号认证流程）
5. openid与unionid必须是在同一个小程序获取到的
6. pending_id有效期90天

=head3 RETURN 返回结果：

	{
		"errcode":0,
		"errmsg":"ok",
		"pending_id":"PENDINGID"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	    出错返回码，为0表示成功，非0表示调用失败
    errmsg	对返回码的文本描述内容
    pending_id	unionid和openid对应的pending_id

=cut

sub unionid_to_pending_id {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/unionid_to_pending_id?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 import_chain_contact(access_token, hash);

批量导入上下游联系人
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95821>

=head3 请求说明：

提交批量导入上下游联系人任务

=head4 请求包结构体为：

	{
		"chain_id":"xxxxxx",
		"contact_list":[
			{
				"corp_name":"飞飞培训学校",
				"group_path":"华北区/北京市/海淀区",
				"custom_id":"wof3du51quo5sl1is",
				"contact_info_list":[
					{
						"name":"张三",
						"identity_type":1,
						"mobile":"13000000001",
						"user_custom_id":"100"
					},
					{
						"name":"李四",
						"identity_type":2,
						"mobile":"13000000001",
						"user_custom_id":"100"
					}
				]
			}
		]
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证。上游企业应用access_token
    chain_id	是	上下游id。文件中的联系人将会被导入此上下游中
	contact_list	是	上下游联系人列表。这些联系人将会被导入此上下游中
	contact_list.corp_name	是	上下游企业名称。长度为1-32个utf8字符。只能由中文、字母、数字和“ -_()（）”六种字符组成
	contact_list.group_path	否	导入后企业所在分组。分组为空的企业会放在根分组下。仅针对新导入企业生效，不会修改已导入企业的分组。
	contact_list.custom_id	否	上下游企业自定义 id。长度为0～64 个字节，只能由数字和字母组成
	contact_list.contact_info_list	是	上下游联系人信息列表
	contact_list.contact_info_list.name	是	上下游联系人姓名。长度为1～32个utf8字符
	contact_list.contact_info_list.identity_type	是	联系人身份类型。1:成员，2:负责人。
	contact_list.contact_info_list.mobile	是	手机号。支持国内、国际手机号（国内手机号直接输入手机号即可，格式示例：“138****0001”；国际手机号必须包含加号以及国家地区码，格式示例：“+85259****45”
	contact_list.contact_info_list.user_custom_id	否	上下游用户自定义 id。类型为字符串，暂时只支持传入64比特无符号整型，取值范围1到2^64-2，必须是全数字，不得传入前置0，且不能为11位或13位数字。

=head4 权限说明：

	调用的应用需要满足如下的权限，仅已验证的企业可调用
	
	应用类型	权限要求
	自建应用	配置到「上下游- 可调用接口的应用」中
	注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

	导入任务限制：
	同时只能存在一个导入任务。导入任务包括通过API提交的任务和从管理后台提交的导入任务。

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"jobid": "xxxxx"
	}

	可使用jobid通过获取异步任务结果接口查询任务执行状态及结果
	当开启了上下游应用回调通知后，任务运行完成时会推送异步任务完成通知

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码。仅表示提交任务的结果。任务执行结果需在任务提交成功后调用获取异步任务结果接口查询
	errmsg	对返回码的文本描述内容
	jobid	异步任务id，最大长度为64字节

=cut

sub import_chain_contact {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/import_chain_contact?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getresult(access_token, jobid);

获取异步任务结果
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95823>

=head3 请求说明：

=head4 参数说明：

	参数		必须		说明
    access_token	是	调用接口凭证
    jobid	是	异步任务id，最大长度为64字节

=head3 权限说明

只能查询已经提交过的历史任务
调用的应用需要满足如下的权限
应用类型	权限要求
自建应用	配置到「上下游- 可调用接口的应用」中

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情
并发限制：5

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"status": 3,
		"result": {
			"chain_id": "xxxx",
			"import_status": 2,
			"fail_list": [{
				"corp_name": "飞飞培训学校2入2222",
				"custom_id": "",
				"errcode": 670016,
				"errmsg": "invalid contact identity",
				"contact_info_list": [{
					"mobile": "13000000001",
					"errcode": 670016,
					"errmsg": "invalid contact identity"
				}]
			}]
		}
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    status	任务状态，整型，1表示任务开始，2表示任务进行中，3表示任务已完成
	result	详细的处理结果。当任务完成后此字段有效
	result.chain_id	上下游id
	result.import_status	导入状态。1:全部企业导入成功，2:部分企业导入成功，3:全部企业导入失败
	result.fail_list	导入失败结果列表 。当企业中有联系人导入失败时，本次导入该企业所有联系人的导入都会被阻断。
	result.fail_list.custom_id	自定义企业id
	result.fail_list.corp_name	自定义企业名称
	result.fail_list.errmsg	该企业导入操作的结果错误码
	result.fail_list.errcode	该企业导入操作的结果错误码描述
	result.fail_list.contact_info_list	导入失败的联系人结果
	result.fail_list.contact_info.user_mobile	导入失败的联系人手机号。有此联系人相关的错误时才会返回
	result.fail_list.contact_info.errcode	导入失败的联系人错误码。有此联系人相关的错误时才会返回
	result.fail_list.contact_info.errmsg	导入失败的联系人错误码描述。有此联系人相关的错误时才会返回

=cut

sub getresult {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $jobid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/getresult?access_token=$access_token&jobid=$jobid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_corp_shared_chain_list(access_token, hash);

获取下级企业加入的上下游
最后更新：2023/11/29

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97442>

=head3 请求说明：

上级企业自建应用/代开发应用通过本接口查询下级企业所在上下游

=head4 请求包结构体为：

	{
		"corpid":"xxxxx"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证。上游企业应用access_token
    corpid	否	已加入企业id
    
=head4 权限说明：

	调自建应用、代开发应用和「上下游- 可调用接口的应用」可调用，仅可指定应用可见范围内的企业

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"chains": [
		  {
			 "chain_id": "xxx",
			 "chain_name": "xxx"
		  }
		]
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码。仅表示提交任务的结果。任务执行结果需在任务提交成功后调用获取异步任务结果接口查询
	errmsg	对返回码的文本描述内容
	chains	上下游列表
	chains.chain_id	上下游id
	chains.chain_name	上下游名称

=cut

sub get_corp_shared_chain_list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/get_corp_shared_chain_list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
