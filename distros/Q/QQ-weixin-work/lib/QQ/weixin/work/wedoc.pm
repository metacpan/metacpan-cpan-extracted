package QQ::weixin::work::wedoc;

=encoding utf8

=head1 Name

QQ::weixin::work::wedoc

=head1 DESCRIPTION

文档

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ create_doc rename_doc del_doc get_doc_base_info doc_share
				doc_get_auth mod_doc_join_rule mod_doc_member mod_doc_safty_setting
				create_form modify_form get_form_info get_form_statistic get_form_answer
				 file_acl_del file_setting file_share /;

=head1 FUNCTION

管理文档

=head2 create_doc(access_token, hash);

新建文档
最后更新：2023/11/08

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97460>

=head3 请求说明：

该接口用于新建文档和表格，新建收集表可前往 收集表管理 查看。

=head4 请求包结构体为：

	{
		"spaceid": "SPACEID",
		"fatherid": "FATHERID",
		"doc_type": "DOC_TYPE",
		"doc_name": "DOC_NAME",
		"admin_users": ["USERID1", "USERID2", "USERID3"]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	spaceid	string	否	空间spaceid。若指定spaceid，则fatherid也要同时指定
	fatherid	string	否	父目录fileid, 在根目录时为空间spaceid
	doc_type	uint32	是	文档类型, 3:文档 4:表格
	doc_name	string	是	文档名字（注意：文件名最多填255个字符, 超过255个字符会被截断）
	admin_users	string[]	否	文档管理员userid

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"url": "URL",
		"docid": "DOCID"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	url	string	新建文档的访问链接
	docid	string	新建文档的docid

=cut

sub create_doc {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/create_doc?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 rename_doc(access_token, hash);

重命名文档/收集表
最后更新：2022/12/09

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97736>

=head3 请求说明：

该接口用于对指定文档/收集表进行重命名。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"formid": "FORMID",
		"new_name": "NEW_NAME"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	否	文档docid（docid、formid只能填其中一个）
	formid	string	否	收集表id（docid、formid只能填其中一个）
	new_name	string	是	重命名后的文档名 （注意：文档名最多填255个字符, 英文算1个, 汉字算2个, 超过255个字符会被截断）

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明

=cut

sub rename_doc {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/rename_doc?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del_doc(access_token, hash);

删除文档/收集表
最后更新：2022/12/09

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97735>

=head3 请求说明：

该接口用于删除指定文档/收集表。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"formid": "FORMID"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	否	文档docid（docid、formid只能填其中一个）
	formid	string	否	收集表id（docid、formid只能填其中一个）

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明

=cut

sub del_doc {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/del_doc?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_doc_base_info(access_token, hash);

获取文档基础信息
最后更新：2022/12/09

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97734>

=head3 请求说明：

该接口用于获取指定文档的基础信息。

=head4 请求包结构体为：

	{
		"docid": "DOCID"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	否	文档docid

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"doc_base_info": {
			"docid": "DOCID",
			"doc_name": "DOC_NAME",
			"create_time": CREATE_TIME,
			"modify_time": MODIFY_TIME,
			"doc_type": DOC_TYPE
		}
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	docid	string	文档docid
	doc_name	string	文档名字
	create_time	uint64	文档创建时间
	modify_time	uint64	文档最后修改时间
	doc_type	uint32	3: 文档 4: 表格

=cut

sub get_doc_base_info {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/get_doc_base_info?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 doc_share(access_token, hash);

分享文档
最后更新：2022/12/09

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97733>

=head3 请求说明：

该接口用于获取文档的分享链接。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"formid": "FORMID"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	否	文档docid（docid、formid只能填其中一个）
	formid	string	否	收集表id（docid、formid只能填其中一个）

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限
只能访问该应用创建的文档

=head3 RETURN 返回结果：

	{
		"errcode":0,
		"errmsg":"ok",
		"share_url":"URL1"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	share_url	string	文档分享链接

=cut

sub doc_share {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/doc_share?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head1 FUNCTION

设置文档权限

=head2 doc_get_auth(access_token, hash);

获取文档权限信息
最后更新：2022/12/09

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97461>

=head3 请求说明：

该接口用于获取文档的查看规则、文档通知范围及权限、安全设置信息

=head4 请求包结构体为：

	{
		"docid":"DOCID"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档id

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限
只能访问该应用创建的文档

=head3 RETURN 返回结果：

	{
		"errcode":0,
		"errmsg":"ok",
		"access_rule":{
			"enable_corp_internal":true,
			"corp_internal_auth":1,
			"enable_corp_external":true,
			"corp_external_auth":1,
			"corp_internal_approve_only_by_admin":true,
			"corp_external_approve_only_by_admin":true,
			"ban_share_external":false
		},
		"secure_setting":{
			"enable_readonly_copy":false,
			"watermark":{
				"margin_type":2,
				"show_visitor_name":false,
				"show_text":false,
				"text":""
			},
			"enable_readonly_comment":false
		},
		"doc_member_list":[
			{
				"type":1,
				"userid":"USERID1",
				"auth":7
			},
			{
				"type":1,
				"tmp_external_userid":"TMP_EXTERNAL_USERID2",
				"auth":1
			}
		],
		"co_auth_list":[
			{
				"type":2,
				"departmentid":DEPARTMENTID1,
				"auth":1
			}
		]
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	access_rule	object	文档的查看规则
	enable_corp_internal	bool	是否允许企业内成员浏览文档
	corp_internal_auth	uint32	企业内成员主动查看文档后获得的权限类型 1:只读
	enable_corp_external	bool	是否允许企业外成员浏览文档
	corp_external_auth	uint32	企业内成员主动查看文档后获得的权限类型 1:只读
	corp_internal_approve_only_by_admin	bool	企业内成员浏览文档是否必须由管理员审批，enable_corp_internal为false时，只能为true
	corp_external_approve_only_by_admin	bool	企业外成员浏览文档是否必须由管理员审批，enable_corp_external和ban_share_external均为false时，该参数只能为true
	ban_share_external	bool	是否允许企业外成员浏览文档
	enable_readonly_copy	bool	仅浏览权限的成员是否允许导出、复制、打印
	watermark	object	文档水印设置
	margin_type	uint32	水印密度 1:稀疏 2:紧密
	show_visitor_name	bool	是否展示访问者名字
	show_text	bool	是否展示水印文字
	text	bytes	水印文字
	doc_member_list	obj[]	文档通知范围及权限列表
	type	uint32	文档通知范围成员种类 1:user, 只支持成员
	userid	bytes	企业成员的userid
	tmp_external_userid	string	外部用户临时id。同一个用户在不同的文档中返回的该id不一致。
	auth	uint32	该文档通知范围成员的权限 1:只读 7:管理员
	co_auth_list	object	文档查看权限特定部门列表，可以直接浏览文档
	type	uint32	特定部门列表 2:部门, 目前只支持部门
	departmentid	uint64	特定部门id
	auth	uint32	权限类型 1:只读, 目前只支持只读权限

=cut

sub doc_get_auth {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/doc_get_auth?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 mod_doc_join_rule(access_token, hash);

修改文档查看规则
最后更新：2022/12/09

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97778>

=head3 请求说明：

该接口用于修改文档查看规则。

=head4 请求包结构体为：

	{
		"docid":"DOCID",
		"enable_corp_internal":true,
		"corp_internal_auth":1,
		"enable_corp_external":true,
		"corp_external_auth":1,
		"corp_internal_approve_only_by_admin":true,
		"corp_external_approve_only_by_admin":true,
		"ban_share_external":false,
		"update_co_auth_list":true,
		"co_auth_list":[
			{
				"departmentid":DEPARTMENTID1,
				"auth":1,
				"type":2
			}
		]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	操作的docid
	enable_corp_internal	bool	否	是否允许企业内成员浏览文档, 有值则覆盖
	corp_internal_auth	uint32	否	企业内成员主动查看文档后获得的权限类型 1:只读, 有值则覆盖
	enable_corp_external	uint32	否	是否允许企业外成员浏览文档, 有值则覆盖
	corp_external_auth	uint32	否	企业外成员主浏览文档后获得的权限类型 1:只读, 有值则覆盖
	corp_internal_approve_only_by_admin	bool	否	企业内成员加入文档是否必须由管理员审批，enable_corp_internal为false时，只能为true，有值则覆盖。设置为true之前，文档需要有至少一个管理员。
	corp_external_approve_only_by_admin	bool	否	企业外成员加入文档是否必须由管理员审批，enable_corp_external和ban_share_external均为false时，该参数只能为true，有值则覆盖。设置为true之前，文档需要有至少一个管理员。
	ban_share_external	bool	否	是否允许企业外成员浏览, 有值则覆盖
	update_co_auth_list	bool	否	是否更新文档查看权限的特定部门, true时更新特定部门列表
	co_auth_list	object[]	否	需要更新文档查看权限特定部门时, 覆盖之前部门, 特别的: 列表为空则清空
	departmentid	uint64	否	文档查看权限特定部门id
	auth	uint32	否	文档特定部门权限 1:只读, 目前只支持只读权限
	type	uint32	否	文档特定部门类型 2:部门, 目前只支持部门

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限
只能访问该应用创建的文档

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明

=cut

sub mod_doc_join_rule {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/mod_doc_join_rule?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 mod_doc_member(access_token, hash);

修改文档通知范围及权限
最后更新：2023/02/22

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97781>

=head3 请求说明：

该接口用于修改文档通知范围列表，可以新增文档通知范围并设置权限、修改已有范围的权限以及删除文档通知范围内的人员

=head4 请求包结构体为：

	{
		"docid":"DOCID",
		"update_file_member_list":[
			{
				"type":1,
				"auth":7,
				"userid":"USERID1"
			}
		 ],
		"del_file_member_list":[
			{
				"type":1,
				"userid":"USERID2"
			},
			{
				"type":1,
				"tmp_external_userid":"TMP_EXTERNAL_USERID2"
			}
	   ]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	操作的文档id
	update_file_member_list	obj[]	否	更新文档通知范围的列表, 批次大小最大100
	type	uint32	是	文档通知范围的类型 1:用户。文档通知范围仅支持按人配置
	auth	uint32	是	文档通知范围内人员获得的权限 1:只读权限, 7:管理员权限，文档管理员最多三个
	userid	string	否	企业内成员的ID
	tmp_external_userid	string	否	外部用户临时id。同一个用户在不同的文档中返回的该id不一致。
	del_file_member_list	obj[]	否	删除的文档通知范围列表，批次大小最大一百
	type	uint32	是	文档通知范围的类型 1:用户。文档通知范围仅支持按人配置
	userid	string	否	企业内成员的ID
	tmp_external_userid	string	否	外部用户临时id。同一个用户在不同的文档中返回的该id不一致。

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限
只能访问该应用创建的文档

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明

=cut

sub mod_doc_member {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/mod_doc_member?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 mod_doc_safty_setting(access_token, hash);

修改文档安全设置
最后更新：2022/12/09

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97782>

=head3 请求说明：

该接口用于修改文档的安全设置

=head4 请求包结构体为：

	{
		"docid":"DOCID",
		"enable_readonly_copy":false,
		"watermark":{
			"margin_type":1,
			"show_visitor_name":true,
			"show_text":true,
			"text":"test mark"
		}
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	操作的文档id
	enable_readonly_copy	bool	否	是否允许只读成员复制、下载文档，有值则覆盖
	watermark	object	否	水印设置
	margin_type	uint32	否	水印疏密度，1:稀疏，2:紧密
	show_visitor_name	bool	否	是否展示访问者名字水印，有值则覆盖
	show_text	bool	否	是否展示文本水印，有值则覆盖
	text	string	否	文字水印的文字，有值则覆盖

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限
只能访问该应用创建的文档

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明

=cut

sub mod_doc_safty_setting {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/mod_doc_safty_setting?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head1 FUNCTION

管理收集表

=head2 create_form(access_token, hash);

创建收集表
最后更新：2023/07/12

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97462>

=head3 请求说明：

该接口用于创建收集表。

=head4 请求包结构体为：

	{
	  "spaceid": "SPACEID",
	  "fatherid": "FATHERID",
	  "form_info": {
		"form_title": "FORM_TITLE",
		"form_desc": "FORM_DESC",
		"form_header": "FORM_HEADER",
		"form_question": {
		  "items": [
			{
			  "question_id": 1,
			  "title": "TITLE",
			  "pos": 1,
			  "status": 1,
			  "reply_type": 1,
			  "must_reply": false,
			  "note": "NOTE",
			  "option_item": [
				{
				  "key": 1,
				  "value": "VALUE",
				  "status": 1
				}
			  ],
			  "placeholder": "PLACEHOLDER",
			  "question_extend_setting": {}
			}
		  ]
		},
		"form_setting": {
		  "fill_out_auth": 0,
		  "fill_in_range": {
			"userids": [
			  "USER_1",
			  "USER_2",
			  "USER_3"
			],
			"departmentids": [
			  10001,
			  10002,
			  10003
			]
		  },
		  "setting_manager_range": {
			"userids": [
			  "USER_4",
			  "USER_5",
			  "USER_6"
			]
		  },
		  "timed_repeat_info": {
			"enable": false,
			"week_flag": 0,
			"remind_time": 0,
			"repeat_type": 0,
			"skip_holiday": false,
			"day_of_month": 1,
			"fork_finish_type": 0
		  },
		  "allow_multi_fill": false,
		  "timed_finish": 0,
		  "can_anonymous": false,
		  "can_notify_submit": false
		}
	  }
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	spaceid	string	否	空间spaceid
	fatherid	string	否	父目录fileid, 在根目录时为空间spaceid
	form_info	obj	是	收集表信息
	form_title	string	是	收集表标题
	form_desc	string	否	收集表描述
	form_header	string	否	收集表表头背景图链接
	form_question	object	是	收集表的问题列表
	items	object[]	是	问题数组
	question_id	uint32	是	问题id，从1开始。如果是家校范围收集表，id从2开始。
	title	string	是	问题描述
	pos	uint32	是	问题序号，从1开始。
	status	uint32	是	问题状态。1：正常；2：被删除
	reply_type	uint32	是	问题类型。1：文本；2：单选；3：多选；5：位置；9：图片；10：文件；11：日期；14：时间；15：下拉列表；16：体温；17：签名；18：部门；19：成员 22：时长
	must_reply	bool	是	是否必答
	note	string	否	问题备注
	placeholder	string	否	编辑提示
	question_extend_setting	object	否	问题的额外设置。不同问题类型有相应的设置，详见question_extend_setting字段描述
	option_item	object[]	是	单选或者多选题的选项列表
	key	uint32	是	选项key（1，2，3...）
	value	string	是	选项内容
	status	uint32	是	选项状态。1：正常；2：被删除
	form_setting	object	否	收集表设置
	fill_out_auth	uint32	否	填写权限。0：所有人；1：企业内指定人/部门；4:家校所有范围。默认为0，所有人可填写。
	fill_in_range	object	否	指定的可填写的人/部门
	userids	string[]	否	企业成员userid列表
	departmentids	uint64[]	否	部门id列表
	setting_manager_range	object	否	收集表管理员
	timed_repeat_info	object	否	定时重复设置项
	timed_repeat_info.enable	bool	否	是否开启定时重复
	timed_repeat_info.remind_time	uint32	否	提醒时间，为第一次提醒的时间戳。重复提醒的时间根据timed_repeat_info的相关字段计算。
	如remind_time设置为当天10:00的时间戳，同时repeated_type设置了每天重复，那么每天的10:00都会触发提醒。
	timed_repeat_info.repeat_type	uint32	否	重复类型。0：每周；1：每天；2：每月
	timed_repeat_info.week_flag	uint32	否	每周几重复，按bit组合，只能repeat_type = 0 时填写。
	bit 0: 周一； bit 1: 周二；bit 2: 周三；bit 3: 周四； bit 4: 周五；bit 5: 周六 bit 6: 周日。如1表示周一，2表示周二，4表示周三，96表示周六和周日
	timed_repeat_info.skip_holiday	bool	否	自动跳过节假日，只能repeat_type = 1 时填写。
	timed_repeat_info.day_of_month	uint32	否	每月的第几天（1 - 31），只能repeat_type = 2时填写
	timed_repeat_info.fork_finish_type	uint32	否	是否允许补填。0：允许；1：仅当天；2：最后五天内；3：一个月内；4：下一次生成前
	allow_multi_fill	bool	否	是否允许每人提交多份。默认false
	timed_finish	uint32	否	定时关闭。定时重复与定时结束互斥，若都填，优先定时重复
	can_anonymous	bool	否	是否支持匿名填写。默认false
	can_notify_submit	bool	否	是否有回复时提醒。默认false

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限

=head3 RETURN 返回结果：

	{
	  "errcode": 0,
	  "errmsg": "ok",
	  "formid": "FORMID"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	formid	string	收集表id

=head4 question_extend_setting字段描述

L<https://developer.work.weixin.qq.com/document/path/97462#question-extend-setting字段描述>

=cut

sub create_form {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/create_form?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 modify_form(access_token, hash);

编辑收集表
最后更新：2023/06/13

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97816>

=head3 请求说明：

该接口用于编辑收集表。

=head4 请求包结构体为：

	{
	  "oper": 1,
	  "formid": "FORMID",
	  "form_info": {
		"form_title": "FORM_TITLE",
		"form_desc": "FORM_DESC",
		"form_header": "FORM_HEADER",
		"form_question": {
		  "items": [
			{
			  "question_id": 1,
			  "title": "TITLE",
			  "pos": 1,
			  "status": 1,
			  "reply_type": 1,
			  "must_reply": false,
			  "note": "NOTE",
			  "option_item": [
				{
				  "key": 1,
				  "value": "VALUE",
				  "status": 1
				}
			  ],
			  "placeholder": "PLACEHOLDER",
			  "question_extend_setting": {}
			}
		  ]
		},
		"form_setting": {
		  "fill_out_auth": 0,
		  "fill_in_range": {
			"userids": [
			  "USER_1",
			  "USER_2",
			  "USER_3"
			],
			"departmentids": [
			  10001,
			  10002,
			  10003
			]
		  },
		  "setting_manager_range": {
			"userids": [
			  "USER_4",
			  "USER_5",
			  "USER_6"
			]
		  },
		  "timed_repeat_info": {
			"enable": false,
			"week_flag": 0,
			"remind_time": 0,
			"repeat_type": 0,
			"skip_holiday": false,
			"day_of_month": 1,
			"fork_finish_type": 0
		  },
		  "allow_multi_fill": false,
		  "timed_finish": 0,
		  "can_anonymous": false,
		  "can_notify_submit": false
		}
	  }
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	oper	uint32	是	操作类型。1：全量修改问题；2：全量修改设置
	formid	string	是	收集表id
	form_title	string	否	收集表标题（操作1修改）
	form_desc	string	否	收集表描述（操作1修改）
	form_header	string	否	收集表表头背景图链接（操作1修改）
	form_question	object	否	收集表的问题列表（操作1修改）
	items	object[]	是	问题数组
	question_id	uint32	是	问题id，从1开始。如果是家校范围收集表，id从2开始。
	title	string	是	问题描述
	pos	uint32	是	问题序号，从1开始。
	status	uint32	是	问题状态。1：正常；2：被删除
	reply_type	uint32	是	问题类型。1：文本；2：单选；3：多选；5：位置；9：图片；10：文件；11：日期；14：时间；15：下拉列表；16：体温；17：签名；18：部门；19：成员 22：时长
	must_reply	bool	是	是否必答
	note	string	否	问题备注
	placeholder	string	否	编辑提示
	question_extend_setting	object	否	问题的额外设置。不同问题类型有相应的设置，详见question_extend_setting字段描述
	option_item	object[]	是	单选或者多选题的选项列表
	key	uint32	是	选项key（1，2，3...）
	value	string	是	选项内容
	status	uint32	是	选项状态。1：正常；2：被删除
	form_setting	object	否	收集表设置（操作2修改）
	fill_out_auth	uint32	是	填写权限。0：所有人；1：企业内指定人/部门。若收集表当前为家校范围，则无法修改。
	fill_in_range	object	否	指定的可填写的人/部门
	userids	string[]	否	企业成员userid列表
	departmentids	uint64[]	否	部门id列表
	setting_manager_range	object	否	收集表管理员
	timed_repeat_info	object	否	定时重复设置项
	timed_repeat_info.enable	bool	否	是否开启定时重复
	timed_repeat_info.remind_time	uint32	否	提醒时间
	timed_repeat_info.repeat_type	uint32	否	重复类型。0：每周；1：每天；2：每月
	timed_repeat_info.week_flag	uint32	否	每周几重复，只能repeat_type = 0 时填写。1：星期一；2：星期二；4：星期三；8：星期四；16：星期五；32：星期六；64：星期日
	timed_repeat_info.skip_holiday	bool	否	自动跳过节假日，只能repeat_type = 1 时填写。
	timed_repeat_info.day_of_month	uint32	否	每月的第几天（1 - 31），只能repeat_type = 2时填写
	timed_repeat_info.fork_finish_type	uint32	否	是否允许补填。0：允许；1：仅当天；2：最后五天内；3：一个月内；4：下一次生成前
	allow_multi_fill	bool	否	是否允许每人提交多份。默认false
	timed_finish	uint32	否	定时关闭。定时重复与定时结束互斥，若都填，优先定时重复
	can_anonymous	bool	否	是否支持匿名填写。默认false
	can_notify_submit	bool	否	是否有回复时提醒。默认false

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明

=cut

sub modify_form {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/modify_form?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_form_info(access_token, hash);

获取收集表信息
最后更新：2023/03/15

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97817>

=head3 请求说明：

该接口用于读取收集表的信息

=head4 请求包结构体为：

	{
		"formid":"FORMID"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	formid	string	是	操作的收集表ID

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限
只能操作该应用创建的文档

=head3 RETURN 返回结果：

	{
		"errcode":0,
		"errmsg":"ok",
		"form_info":{
			"formid":"FORMID1",
			"form_title":"api创建的收集表_周期",
			"form_desc":"这是描述",
			"form_header":"URL",
			"form_question":{
				"items":[
					{
						"question_id":1,
						"title":"问题1",
						"pos":1,
						"status":1,
						"reply_type":1,
						"must_reply":true,
						"note":"问题备注1",
						"placeholder":"提示1"
					},
					{
						"question_id":2,
						"title":"问题2",
						"pos":2,
						"status":1,
						"reply_type":2,
						"must_reply":false,
						"note":"问题备注2",
						"option_item":[
							{
								"key":1,
								"value":"A",
								"status":1
							},
							{
								"key":2,
								"value":"B",
								"status":1
							},
							{
								"key":3,
								"value":"C",
								"status":1
							}
						],
						"placeholder":"提示2"
					}
				]
			},
			"form_setting":{
				"fill_out_auth":1,
				"fill_in_range":{
					"departmentids":[
						1
					],
					"userids": [
						"USERID1",
						"USERID2"
				},
				"setting_manager_range":{
					"userids":[
						"USERID1",
						"USERID2"
					]
				},
				"timed_repeat_info":{
					"enable":true,
					"remind_time":1668389400,
					"rule_ctime":1668418140,
					"rule_mtime":1668418140,
					"repeat_type":1,
					"skip_holiday":false
				},
				"allow_multi_fill":false,
				"timed_finish":0,
				"can_anonymous":false,
				"can_notify_submit":true
			},
			"repeated_id":[
				"REPEAT_ID1"
			]
		}
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	form_info	object	收集表信息
	formid	string	收集表id
	form_title	string	收集表标题
	form_desc	string	收集表描述
	form_header	string	收集表表头背景图链接
	form_question	object	收集表的问题列表
	form_setting	object	收集表的设置
	repeated_id	string[]	收集表的周期id，用于获取答案列表和具体的回答

=cut

sub get_form_info {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/get_form_info?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_form_statistic(access_token, hash);

收集表的统计信息查询
最后更新：2023/03/07

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97818>

=head3 请求说明：

该接口用于获取收集表的统计信息、已回答成员列表和未回答成员列表

=head4 请求包结构体为：

	// 仅获取统计结果
	{
		"repeated_id":"REPEATED_ID1",
		"req_type":1
	}
	// 获取已提交的列表
	{
		"repeated_id":"REPEATED_ID2",
		"req_type":2,
		"start_time":1667395287,
		"end_time":1668418369,
		"limit":20,
		"cursor":1
	}
	// 获取未提交的列表
	{
		"repeated_id":"REPEATED_ID3",
		"req_type":3,
		"limit":20,
		"cursor":1
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	repeated_id	string	是	操作的收集表的repeated_id,来源于get_form_info的返回
	req_type	uint32	是	请求类型 1:只获取统计结果 2:获取已提交列表 3:获取未提交列表
	start_time	uint64	否	拉取已提交列表时必填，其余type不填。筛选开始时间，以当天的00:00:00开始筛选
	end_time	uint64	否	拉取已提交列表时必填，其余type不填。筛选结束时间，以当天的23:59:59结束筛选
	limit	uint64	否	分页拉取时批次大小，最大10000
	cursor	uint64	否	分页拉取的游标，首次不传

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限
只能操作该应用创建的文档

=head3 RETURN 返回结果：

	// req_type = 1 仅获取统计信息
	{
		"errcode":0,
		"errmsg":"ok",
		"fill_cnt":1,
		"fill_user_cnt":1,
		"unfill_user_cnt":90
	}
	// req_type = 2,获取已提交列表
	{
		"errcode":0,
		"errmsg":"ok",
		"fill_cnt":1,
		"fill_user_cnt":1,
		"unfill_user_cnt":90,
		"submit_users":[
			{
				"userid":"USERID1",
				"submit_time":1668418200,
				"answer_id":1,
				"user_name":"USER_NAME1"
			},
			{
				"tmp_external_userid":"TMP_EXTERNAL_USERID1",
				"submit_time":1668418200,
				"answer_id":2,
				"user_name":"USER_NAME2"
			}
		 ],
		"has_more":false,
		"cursor":1
	}
	// req_type = 3,获取未提交列表，仅当限制提交范围时有结果
	{
		"errcode":0,
		"errmsg":"ok",
		"fill_cnt":1,
		"fill_user_cnt":1,
		"unfill_user_cnt":90,
		"unfill_users":[
			{
				"userid":"USERID1",
				"user_name":"USER_NAME1"
			}
		],
		"has_more":false,
		"cursor":1
	} 

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	fill_cnt	uint64	已填写次数
	fill_user_cnt	uint64	已填写人数
	unfill_user_cnt	uint64	未填写人数
	submit_users	object[]	已填写人列表
	tmp_external_userid	string	外部用户临时id，匿名填写不返回，同一个用户在不同的收集表中返回的该id不一致。
	可进一步通过tmp_external_userid的转换接口转换成external_userid，方便识别外部填写人的身份。
	userid	string	企业内成员的id，匿名填写不返回
	submit_time	uint64	提交时间
	answer_id	uint64	答案id
	user_name	string	名字，匿名填写不返回
	userid	string	企业内成员的id，匿名填写不返回
	unfill_users	object[]	未填写人列表
	user_name	string	名字
	userid	string	企业内成员的id
	has_more	bool	是否还有更多
	cursor	uint64	上次分页拉取返回的cursor

=cut

sub get_form_statistic {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/get_form_statistic?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_form_answer(access_token, hash);

读取收集表答案
最后更新：2023/07/12

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97819>

=head3 请求说明：

该接口用于读取收集表的答案

=head4 请求包结构体为：

	{
		"repeated_id":"REPEATED_ID1",
		"answer_ids":[
			1
		]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	repeated_id	string	是	操作的收集表周期id
	answer_ids	uint64[]	是	需要拉取的答案列表，批次大小最大100

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限
只能操作该应用创建的文档

=head3 RETURN 返回结果：

	{
	  "errcode": 0,
	  "errmsg": "ok",
	  "answer": {
		"answer_list": [
		  {
			"answer_id": 15,
			"user_name": "USER_NAME1",
			"ctime": 1668430580,
			"mtime": 1668430580,
			"reply": {
			  "items": [
				{
				  "question_id": 1,
				  "text_reply": "Ndjnd"
				},
				{
				  "question_id": 2,
				  "option_reply": [
					2
				  ]
				},
				{
				  "question_id": 3,
				  "text_reply": "20:53"
				},
				{
				  "question_id": 4,
				  "text_reply": "73℃"
				},
				{
				  "question_id": 5,
				  "file_extend_reply": [
					{
					  "name": "FILE_NAME1",
					  "fileid": "FILEID1"
					}
				  ]
				},
				{
				  "question_id": 6,
				  "text_reply": "四川省/成都市/武侯区/天府三街(峰汇中心)"
				},
				{
				  "question_id": 7,
				  "text_reply": "test"
				},
				{
				  "question_id": 8,
				  "option_reply": [
					1
				  ]
				},
				{
				  "question_id": 9,
				  "text_reply": "2022年11月"
				},
				{
				  "question_id": 10,
				  "option_reply": [
					5
				  ]
				},
				{
				  "question_id": 11,
				  "option_reply": [
					3
				  ],
				  "option_extend_reply": [
					{
					  "option_reply": 3,
					  "extend_text": "test"
					}
				  ]
				},
				{
				  "question_id": 12,
				  "department_reply": {
					"list": [
					  {
						"department_id": 3
					  }
					]
				  }
				},
				{
				  "question_id": 13,
				  "member_reply": {
					"list": [
					  {
						"userid": "zhangsan"
					  }
					]
				  }
				},
				{
				  "question_id": 14,
				  "duration_reply": {
					"begin_time": 1586136317,
					"end_time": 1586236317,
					"time_scale": 0,
					"day_range": 0,
					"days": 1.0,
					"hours": 2.5
				  }
				}
			  ]
			},
			"answer_status": 1,
			"tmp_external_userid": "TMP_EXTERNAL_USERID1"
		  }
		]
	  }
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	answer	object	答案
	answer_list	object[]	答案列表
	answer_id	uint64	答案id
	user_name	string	用户名
	ctime	uint64	创建时间
	mtime	uint64	修改时间
	reply	object	该用户的答案明细
	items	object[]	每个问题的答案
	question_id	uint64	问题id
	text_reply	string	答案
	option_reply	uint32[]	选择题答案，多选题有多个答案
	option_extend_reply	object[]	选择题，其他选项列表
	option_extend_reply.option_reply	uint32	其他选项的答案id
	option_extend_reply.extend_text	string	其他选项的答案字符串
	file_extend_reply	object[]	文件题答案列表
	file_extend_reply.name	string	文件题答案的文件名
	file_extend_reply.fileid	string	文件题答案的文件id
	department_reply	object	部门题答案
	department_reply.list	object[]	部门题选择的部门列表
	department_reply.list[].department_id	object[]	部门id
	member_reply	object	成员题答案
	member_reply.list	object[]	成员选择的成员列表
	member_reply.list[].userid	object[]	成员id
	duration_reply	object	时长题答案
	duration_reply.begin_time	uint32	开始时间，时间戳
	duration_reply.end_time	uint32	结束时间，时间戳
	duration_reply.time_scale	uint32	时间刻度。1: 按天 2: 按小时
	duration_reply.day_range	uint32	单位换算，多少小时/天。time_scale为2返回
	duration_reply.days	float	天数。time_scale为1返回
	duration_reply.hours	float	小时数。time_scale为2返回
	answer_status	uint32	答案状态 1:正常 3:统计者移除此答案或删除
	tmp_external_userid	string	外部用户临时id，匿名填写不返回，同一个用户在不同的收集表中返回的该id不一致。
	可进一步通过tmp_external_userid的转换接口转换成外部联系人的external_userid，方便识别外部填写人的身份。
	userid	string	用户id，匿名填写不返回

=cut

sub get_form_answer {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/get_form_answer?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_acl_del(access_token, hash);

删除指定人

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93658#删除指定人>

=head3 请求说明：

该接口用于删除指定文件的指定人/部门。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"fileid": "FILEID",
		"auth_info": [{
			"type": 1,
			"userid": "USERID1"
		}, {
			"type": 2,
			"departmentid": DEPARTMENT_ID1	
		}]
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	fileid	string	是	文件fileid
	auth_info	obj[]	是	被移除的成员信息
	type	uint32	是	成员类型 1:个人 2:部门
	userid	string	是	成员userid,字符串 (type为1时填写)
	departmentid	uint32	是	部门departmentid, 32位整型范围是[0, 2^32) (type为2时填写)

=head4 权限说明：

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

    参数	类型	说明
    errcode	int32	错误码
	errmsg	string	错误码说明

=cut

sub file_acl_del {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_acl_del?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_setting(access_token, hash);

分享设置

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93658#分享设置>

=head3 请求说明：

该接口用于文件的分享设置。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"fileid": "FILDID",
		"auth_scope": AUTH_SCOPE,
		"auth": 1
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	fileid	string	是	文件fileid
	auth_scope	uint32	是	权限范围：1:指定人 2:企业内 3:企业外
	auth	uint32	否	权限信息
						普通文档： 1:仅浏览（可下载) 4:仅预览（仅专业版企业可设置）；如果不填充此字段为保持原有状态
						微文档： 1:仅浏览（可下载） 2:可编辑；如果不填充此字段为保持原有状态

=head4 权限说明：

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

    参数	类型	说明
    errcode	int32	错误码
	errmsg	string	错误码说明

=cut

sub file_setting {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_setting?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_share(access_token, hash);

获取分享链接

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93658#获取分享链接>

=head3 请求说明：

该接口用于获取文件的分享链接。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"fileid": "FILDID"
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	fileid	string	是	文件fileid

=head4 权限说明：

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"share_url": "SHARE_URL"
	}

=head4 RETURN 参数说明：

    参数	类型	说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	share_url	string	分享文件的链接

=cut

sub file_share {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_share?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
