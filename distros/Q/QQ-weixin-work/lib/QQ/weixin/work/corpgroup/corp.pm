package QQ::weixin::work::corpgroup::corp;

=encoding utf8

=head1 Name

QQ::weixin::work::corpgroup::corp

=head1 DESCRIPTION

=cut

use strict;
use base qw(QQ::weixin::work::corpgroup);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ list_app_share_info gettoken get_chain_list
				get_chain_group get_chain_corpinfo_list get_chain_corpinfo
				remove_corp get_chain_user_custom_id /;

=head1 FUNCTION

=head2 list_app_share_info(access_token, hash);

获取应用共享信息
最后更新：2022/08/25

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93403>
L<https://developer.work.weixin.qq.com/document/path/95813>

=head3 请求说明：

局校互联中的局端或者上下游中的上游企业通过该接口可以获取某个应用分享给的所有企业列表。
特别注意，对于有敏感权限的应用，需要下级/下游企业确认后才能共享成功，若下级/下游企业未确认，则不会存在于该接口的返回列表

=head4 请求包结构体为：

	{
			"agentid":1111,
			"business_type":1,
			"corpid":"wwcorp",
			"limit":100,
			"cursor":"xxxxxx"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    business_type	否	填0则为企业互联/局校互联，填1则表示上下游企业
	agentid	是	上级/上游企业应用agentid
	corpid	否	下级/下游企业corpid，若指定该参数则表示拉取该下级/下游企业的应用共享信息
	limit	否	返回的最大记录数，整型，最大值100，默认情况或者值为0表示下拉取全量数据，建议分页拉取或者通过指定corpid参数拉取。
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用可不填

=head3 权限说明

	自建应用和第三方应用

=head3 RETURN 返回结果

	{
	   "errcode": 0,
	   "errmsg": "ok",
	   "ending":0
	   "corp_list":[
					{
							"corpid": "wwcorpid1",
							"corp_name": "测试企业1"
							"agentid": 1111
					},
					{
							"corpid": "wwcorpid2",
							"corp_name": "测试企业2",
							"agentid": 1112
					}
	   ],
	   "next_cursor": "next_cursor1111"
	}

=head3 RETURN 参数说明

	参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	ending	1表示拉取完毕，0表示数据没有拉取完
	next_cursor	分页游标，再下次请求时填写以获取之后分页的记录，如果已经没有更多的数据则返回空
	corp_list	应用共享信息
	corp_list.corpid	下级/下游企业corpid
	corp_list.corp_name	下级/下游企业名称
	corp_list.agentid	下级/下游企业应用id

=cut

sub list_app_share_info {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/corp/list_app_share_info?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 gettoken(access_token, hash);

获取下级/下游企业的access_token
最后更新：2022/09/29

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93359>
L<https://developer.work.weixin.qq.com/document/path/95816>

=head3 请求说明：

获取应用可见范围内下级/下游企业的access_token，该access_token可用于调用下级/下游企业通讯录的只读接口。

=head4 请求包结构体为：

	{
		"corpid": "wwabc",
		"business_type":1,
		"agentid": 1111
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    corpid	是	已授权的下级/下游企业corpid
	agentid	是	已授权的下级/下游企业应用ID
	business_type	否	填0则为企业互联/局校互联，填1则表示上下游企业

=head3 权限说明

	自建应用和代开发应用

=head3 RETURN 返回结果

	{
	   "errcode": 0,
	   "errmsg": "ok",
	   "access_token": "accesstoken000001",
	   "expires_in": 7200
	}

=head3 RETURN 参数说明

	参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	access_token	获取到的下级/下游企业调用凭证，最长为512字节
	expires_in	凭证的有效时间（秒）

=cut

sub gettoken {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/corp/gettoken?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_chain_list(access_token);

获取上下游列表
最后更新：2023/11/29

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95820>

=head3 请求说明：

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证。上游企业应用access_token

=head4 权限说明：

	自建应用/代开发应用可调用，仅返回应用可见范围内的上下游列表
	「上下游- 可调用接口的应用」调用，返回全部的上下游列表

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"chains": [
			{
				"chain_id": "chainid1",
				"chain_name": "能源供应链"
			},
			{
				"chain_id": "chainid2",
				"chain_name": "原材料供应链"
			}
		]
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    chains	企业上下游列表
	chains.chain_id	上下游id
	chains.chain_name	上下游名称

=cut

sub get_chain_list {
    if ( @_ && $_[0] ) {
        my $access_token = $_[0];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/corp/get_chain_list?access_token=$access_token");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_chain_group(access_token, hash);

获取上下游通讯录分组
最后更新：2023/11/29

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95820>

=head3 请求说明：

自建应用/代开发应用可通过该接口获取企业上下游通讯录分组详情

=head4 请求包结构体为：

	{
		"chain_id":"Chxxxxxx",
		"groupid":1
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证。上游企业应用access_token
    chain_id	是	上下游id
	groupid	否	分组id。填写此参数返回指定分组，不填则返回全部分组

=head4 权限说明：

	自建应用/代开发应用可调用，仅可指定或返回应用可见范围内的分组列表
	上下游- 可调用接口的应用」调用，可指定或返回全部的分组列表

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"groups": [
			{
				"groupid": 2,
				"group_name": "一级经销商",
				"parentid": 1,
				"order": 1
			},
			{
				"groupid": 3,
				"group_name": "二级经销商",
				"parentid": 2,
				"order": 3
			}
		]
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    groups	分组列表数据。
	groups.groupid	分组id
	groups.group_name	分组名称
	groups.parentid	父分组id。根分组id为1
	groups.order	父部门中的次序值。order值大的排序靠前。值范围是[0, 2^32)

=cut

sub get_chain_group {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/corp/get_chain_group?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_chain_corpinfo_list(access_token, hash);

获取企业上下游通讯录分组下的企业详情列表
最后更新：2023/11/29

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95820>

=head3 请求说明：

自建应用/代开发应用可通过该接口获取企业上下游通讯录的某个分组下的企业列表

=head4 请求包结构体为：

	{
		"chain_id":"Chxxxxxx",
		"groupid":1,
		"need_pending":false,
		"cursor": "",
		"limit": 0
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证。上游企业应用access_token
    chain_id	是	上下游id
	groupid	否	分组id。如果不填，表示根目录
	need_pending	否	是否需要返回未加入的企业。默认不返回
	cursor	否	开启分页使用，传入返回值next_cursor
	limit	否	>0开启分页功能。
	
	如需获取该分组及其子分组的所有企业详情，需先获取该分组下的所有子分组，然后再获取子分组下的企业，逐层递归获取。

=head4 权限说明：

	自建应用/代开发应用可调用，仅返回应用可见范围内的企业列表
	上下游- 可调用接口的应用」应用调用，返回全部的企业列表

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"has_more": false,
		"next_cursor": "xxx",
		"group_corps": [
			{
				"groupid": 2,
				"corpid": "wwxxxx",
				"corp_name":"美馨粮油公司",
				"custom_id":"custom_id",
				"invite_userid":"zhangsan",
				"pending_corpid":"wwxxxx",
				"is_joined":1
			}
		]
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    group_corps	分组列表数据。
	group_corps.groupid	企业所属上下游的分组id
	group_corps.corpid	企业id，最多64个字节，已加入的企业返回
	group_corps.corp_name	企业名称
	group_corps.custom_id	上下游企业自定义id，返回批量导入上下游联系人时指定的企业自定义id，如未指定则该字段为空
	group_corps.invite_userid	该上下游的邀请人的userid，仅 上下游- 可调用接口的应用」应用调用时返回，切成员需在应用的可见范围内
	group_corps.pending_corpid	未加入企业id，未加入的企业返回
	group_corps.is_joined	企业是否已加入
	next_cursor	下次请求时应传入的cursor
	has_more	开启分页时告知是否还有更多记录

=cut

sub get_chain_corpinfo_list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/corp/get_chain_corpinfo_list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_chain_corpinfo(access_token, hash);

获取企业上下游通讯录下的企业信息
最后更新：2023/11/29

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95820>

=head3 请求说明：

自建应用/代开发应用可通过该接口获取企业上下游通讯录的某个企业的自定义id和所属分组的分组id

=head4 请求包结构体为：

	{
		"chain_id":"Chxxxxxx",
		"corpid":"xxxxx",
		"pending_corpid":"xxxxx"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证。上游企业应用access_token
    chain_id	是	上下游id
	corpid	否	已加入企业id
	pending_corpid	否	待加入企业id（corpid和pending_corpid至少填一个，同时填corpid生效

=head4 权限说明：

	自建应用/代开发应用可调用，仅可指定应用可见范围内的企业
	上下游- 可调用接口的应用」应用调用，可指定上下游内的所有企业

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"corp_name":"美馨粮油公司",
		"qualification_status":1,
		"custom_id": "xxxxx",
		"groupid": 1,
		"is_joined": false
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    corp_name	企业名称
	qualification_status	企业是否验证或认证，1表示未验证，2表示已验证，3表示已认证，已加入的企业返回
	custom_id	上下游企业自定义id，返回批量导入上下游联系人时指定的企业自定义id，如未指定则该字段为空
	groupid	企业所属上下游的分组id
	is_joined	企业是否已加入

=cut

sub get_chain_corpinfo {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/corp/get_chain_corpinfo?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 remove_corp(access_token, hash);

移除企业
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95822>

=head3 请求说明：

上级/上游企业通过该接口移除下游企业

=head4 请求包结构体为：

	{
			"chain_id":"xxxx",
			"corpid":"xxxxx",
			"pending_corpid":"xxxx"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证。上游企业应用access_token
    chain_id	是	上下游id
	corpid	否	需要移除的下游企业corpid
	pending_corpid	否	需要移除的未加入下游企业corpid，corpid和pending_corpid至少填一个，都填corpid生效

=head4 权限说明：

	仅已验证的企业可调用
	调用的应用需要满足如下的权限
	应用类型	权限要求
	自建应用	配置到「上下游- 可调用接口的应用」中

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情
并发限制：1

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

sub remove_corp {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/corp/remove_corp?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_chain_user_custom_id(access_token, hash);

查询成员自定义id
最后更新：2023/11/29

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97441>

=head3 请求说明：

上级企业自建应用/代开发应用通过本接口查询成员自定义 id

=head4 请求包结构体为：

	{
		"chain_id":"Chxxxxxx",
		"corpid":"xxxxx",
		"userid":"xxxxx"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证。上游企业应用access_token
    chain_id	是	上下游id
	corpid	否	已加入企业id
	userid	是	企业内的成员

=head4 权限说明：

	自建应用、代开发应用和「上下游- 可调用接口的应用」可调用，仅可指定应用可见范围内的企业

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"user_custom_id":"1234"
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    user_custom_id	成员自定义 id

=cut

sub get_chain_user_custom_id {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/corp/get_chain_user_custom_id?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
