package QQ::weixin::work::wedrive;

=encoding utf8

=head1 Name

QQ::weixin::work::wedrive

=head1 DESCRIPTION

微盘

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ space_create space_rename space_dismiss space_info
				space_acl_add space_acl_del space_setting space_share new_space_info
				file_list file_upload
				file_upload_init file_upload_part file_upload_finish
				file_download file_create file_rename file_move file_delete file_info
				file_acl_add file_acl_del file_setting file_share
				get_file_permission file_secure_setting
				mng_pro_info mng_capacity /;

=head1 FUNCTION

管理空间

=head2 space_create(access_token, hash);

新建空间
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93655>

=head3 请求说明：

该接口用于在微盘内新建空间，创建者为应用本身。

=head4 请求包结构体为：

	{
		"space_name": "SPACE_NAME",
		"auth_info": [{
			"type": 1,
			"userid": "USERID",
			"auth": 7
		}, {
			"type": 2,
			"departmentid": DEPARTMENTID,
			"auth": 1
		}],
		"space_sub_type": 0
	}

=head4 参数说明：

	参数		类型   必须	说明
    access_token	是	调用接口凭证
    space_name	string	是	空间标题
	auth_info	obj[]	否	空间其他成员信息
	type	uint32	否	成员类型 1:个人 2:部门
	userid	string	否	成员userid,字符串
	departmentid	uint32	否	部门departmentid, 32位整型范围是[0, 2^32)
	auth	uint32	否	成员权限 1:仅下载 4:可预览（仅专业版微盘企业可设置） 7:应用空间管理员(最多可指定3个，不支持设置部门)
	space_sub_type	uint32	否	区分创建空间类型, 0:普通（目前只支持0）

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"spaceid": "SPACEID"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	spaceid	string	空间id

=cut

sub space_create {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/space_create?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 space_rename(access_token, hash);

重命名空间
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97856>

=head3 请求说明：

该接口用于重命名已有空间。

=head4 请求包结构体为：

	{
		"spaceid": "SPACEID",
		"space_name": "SPACE_NAME"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
    access_token	是	调用接口凭证
	spaceid	string	是	空间spaceid
	space_name	string	是	重命名后的空间名

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

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

sub space_rename {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/space_rename?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 space_dismiss(access_token, hash);

解散空间
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97857>

=head3 请求说明：

该接口用于解散已有空间。

=head4 请求包结构体为：

	{
		"spaceid": "SPACEID"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
    access_token	是	调用接口凭证
	spaceid	string	是	空间spaceid

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

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

sub space_dismiss {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/space_dismiss?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 space_info(access_token, hash);

获取空间信息
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97858>

=head3 请求说明：

该接口用于获取空间成员列表、信息、权限等信息。

=head4 请求包结构体为：

	{
		"spaceid": "SPACEID"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
    access_token	是	调用接口凭证
	spaceid	string	是	空间spaceid

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"space_info": {
			"spaceid": "SPACEID",
			"space_name": "SPACE_NAME",
			"auth_list": {
				"auth_info": [{
					"type": 1,
					"userid": "USERID1",
					"auth": 3,
				}, {
					"type": 1,
					"userid": "USERID2",
					"auth": 2
				}, {
					"type": 2,
					"departmentid": DEPARTMENTID1,
					"auth": 1
				}],
				"quit_userid": ["USERID3","USERID4"]
			}
			"space_sub_type":0
		}
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	spaceid	string	空间spaceid
	space_name	string	空间名称
	auth_list	obj[]	空间成员列表
	auth_info	obj[]	空间成员信息
	type	uint32	成员类型 1:个人 2:部门
	userid	string	成员userid,字符串
	departmentid	uint32	部门departmentid, 32位整型范围是[0, 2^32)
	auth	uint32	成员权限 1:仅下载 4:可预览 7:应用空间管理员
	quit_userid	string[]	空间无权限成员userid (成员在一个有权限的部门中, 自己退出空间或者被移除权限)
	space_sub_type	uint32	空间类型 0:普通

=cut

sub space_info {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/space_info?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head1 FUNCTION

管理空间权限

=head2 space_acl_add(access_token, hash);

添加成员/部门
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93656>

=head3 请求说明：

该接口用于对指定空间添加成员/部门，可一次性添加多个。

=head4 请求包结构体为：

	{
		"spaceid": "SPACEID",
		"auth_info": [{
			"type": 1,
			"userid": "USERID1",
			"auth": 7
		}, {
			"type": 2,
			"departmentid": DEPARTMENTID1,
			"auth": 1
		}]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	spaceid	string	是	空间spaceid
	auth_info	obj[]	是	被添加的空间成员信息
	type	uint32	是	成员类型 1:个人 2:部门
	userid	string	是	成员userid,字符串 (type为1时填写)
	departmentid	uint32	是	部门departmentid, 32位整型范围是[0, 2^32) (type为2时填写)
	auth	uint32	是	1:仅下载 4:可预览 7:应用空间管理员(连同已经设置的管理员，最多可指定三个,不支持设置部门)

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

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

sub space_acl_add {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/space_acl_add?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 space_acl_del(access_token, hash);

移除成员/部门
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97875>

=head3 请求说明：

该接口用于对指定空间移除成员/部门，操作者为应用本身。

=head4 请求包结构体为：

	{
		"spaceid": "SPACEID",
		"auth_info": [{
			"type": 1,
			"userid": "USERID1"
		}, {
			"type": 2,
			"departmentid": DEPARTMENTID1
		}]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	spaceid	string	是	空间spaceid
	auth_info	obj[]	是	被移除的空间成员信息
	type	uint32	是	成员类型 1:个人 2:部门
	userid	string	是	成员userid,字符串 (type为1时填写)
	departmentid	uint32	是	部门departmentid, 32位整型范围是[0, 2^32) (type为2时填写)

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

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

sub space_acl_del {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/space_acl_del?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 space_setting(access_token, hash);

安全设置
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97876>

=head3 请求说明：

该接口用于修改空间权限，应用通过api调用仅支持设置由本应用创建的空间。

=head4 请求包结构体为：

	{
		"spaceid": "SPACEID",
		"enable_watermark": true,
		"share_url_no_approve": true,
		"share_url_no_approve_default_auth": 1,
		"enable_confidential_mode":true,
		"default_file_scope":1,
		"ban_share_external":false
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	spaceid	string	是	空间spaceid
	enable_watermark	bool	否	（本字段仅专业版企业可设置）启用水印。false:关 true:开 ;如果不填充此字段为保持原有状态
	enable_confidential_mode	bool	否	是否开启保密模式。false:关 true:开 如果不填充此字段为保持原有状态
	default_file_scope	uint32	否	文件默认可查看范围。1:仅成员；2:企业内。如果不填充此字段为保持原有状态
	ban_share_external	bool	否	是否禁止文件分享到企业外｜false:关 true:开 如果不填充此字段为保持原有状态

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

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

sub space_setting {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/space_setting?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 space_share(access_token, hash);

获取邀请链接
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97877>

=head3 请求说明：

该接口用于获取空间邀请分享链接。

=head4 请求包结构体为：

	{
		"spaceid": "SPACEID"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	spaceid	string	是	空间spaceid

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"space_share_url": "SPACE_SHARE_URL"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	space_share_url	string	邀请链接

=cut

sub space_share {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/space_share?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 new_space_info(access_token, hash);

获取空间信息
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97878>

=head3 请求说明：

该接口用于获取空间信息。包括：空间成员及权限及安全设置。

=head4 请求包结构体为：

	{
		"spaceid": "SPACEID"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	spaceid	string	是	空间spaceid

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"space_info": {
			"spaceid": "SPACEID",
			"space_name": "SPACE_NAME",
			"auth_list": {
				"auth_info": [
					{
						"type": 1,
						"userid": "USERID",
						"auth": 1
					},
					{
						"type": 2,
						"departmentid": "DEPARTMENTID",
						"auth": 7
					}
				],
				"quit_userid": [
					"USERID1",
					"USERID2"
				]
			},
			"space_sub_type": 0,
			"secure_setting": {
				"enable_watermark": false,
				"add_member_only_admin": true,
				"enable_share_url": false,
				"share_url_no_approve": false,
				"share_url_no_approve_default_auth": 2,
				"enable_share_external": false,
				"enable_share_external_admin": true,
				"enable_space_add_external_member": false,
				"enable_space_add_external_member_admin": true,
				"enable_confidential_mode": false,
				"default_file_scope": 2,
				"create_file_only_admin": false
			}
		}
	}

=head4 RETURN 参数说明：

	参数		类型		说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	space_info	obj	空间信息
	spaceid	string	空间id
	space_name	string	空间名

=cut

sub new_space_info {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/new_space_info?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head1 FUNCTION

管理文件

=head2 file_list(access_token, hash);

获取文件列表
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93657>

=head3 请求说明：

该接口用于获取指定地址下的文件列表。

=head4 请求包结构体为：

{
    "spaceid": "SPACEID",
    "fatherid": "FATHERID",
    "sort_type": 1,
    "start": 0,
    "limit": 100
}

=head4 参数说明：

	参数		类型		是否必须		说明
	spaceid	string	是	空间spaceid
	fatherid	string	是	当前目录的fileid,根目录时为空间spaceid
	sort_type	uint32	是	列表排序方式 1:名字升序；2:名字降序；3:大小升序；4:大小降序；5:修改时间升序；6:修改时间降序
	start	uint32	是	首次填0, 后续填上一次请求返回的next_start
	limit	uint32	是	分批拉取最大文件数, 不超过1000

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"has_more": true,
		"next_start": NEXT_START,
		"file_list": {
			"item": [
				{
					"fileid": "FILEID1",
					"file_name": "FILE_NAME1",
					"spaceid": "SPACEID",
					"fatherid": "FATHERID",
					"file_size": FILE_SIZE,
					"ctime": CTIME,
					"mtime": MTIME,
					"file_type": FILE_TYPE,
					"file_status": FILE_STATUS,
					"sha": "SHA",
					"md5": "MD5",
					"url": "URL"
				}
			]
		}
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	has_more	bool	true为列表还有内容, 需要继续分批拉取
	next_start	uint32	下次分批拉取对应的请求参数start值
	file_list	obj[]	文件列表
	fileid	string	文件fileid
	file_name	string	文件名字
	spaceid	string	文件所在的空间spaceid
	fatherid	string	文件所在的目录fileid, 在根目录时为fileid
	file_size	uint64	文件大小
	ctime	uint64	文件创建时间
	mtime	uint64	文件最后修改时间
	file_type	uint32	文件类型, 1:文件夹 2:文件 3:微文档(文档) 4:微文档(表格) 5:微文档(收集表)
	file_status	uint32	文件状态, 1:正常 2:删除
	sha	string	文件sha
	md5	string	文件md5
	url	string	仅微文档类型返回访问链接

=cut

sub file_list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_upload(access_token, hash);

上传文件
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97880>

=head3 请求说明：

该接口用于向微盘中的指定位置上传文件。

=head4 请求包结构体为：

	{
		"spaceid": "SPACEID",
		"fatherid": "FATHERID",
		"selected_ticket": "SELECTED_TICKET",
		"file_name": "FILE_NAME",
		"file_base64_content": "FILE_BASE64_CONTENT"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	spaceid	string	否	空间spaceid
	fatherid	string	否	父目录fileid, 在根目录时为空间spaceid
	selected_ticket	string	否	微盘和文件选择器jsapi返回的selectedTicket。若填此参数，则不需要填spaceid/fatherid。
	file_name	string	是	文件名字（注意：文件名最多填255个字符, 英文算1个, 汉字算2个）
	file_base64_content	string	是	文件内容base64（注意：只需要填入文件内容的Base64，不需要添加任何如："data:application/x-javascript;base64" 的数据类型描述信息），文件大小上限为10M。大于10M文件，可使用文件分块上传接口

注意：spaceid/fatherid和selected_ticket必须填且仅填其中一组参数。

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"fileid": "FILEID"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	fileid	string	新建文件的fielid

=cut

sub file_upload {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_upload?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 NAME

文件分块上传
最后更新：2023/03/09

=head2 file_upload_init(access_token, hash);

分块上传初始化

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98004#分块上传初始化>

=head3 请求说明：

请求分块上传初始化接口，如果命中秒传，则流程结束，完成上传。

=head4 请求包结构体为：

	{
		"spaceid": "SPACEID",
		"fatherid": "FATHERID",
		"selected_ticket": "SELECTED_TICKET",
		"file_name": "FILE_NAME",
		"size": 123,
		"block_sha": [
			"STATE1",
			"STATE2"
		],
		"skip_push_card": false
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	spaceid	string	否	空间spaceid
	fatherid	string	否	当前目录的fileid，根目录时为空间spaceid
	selected_ticket	string	否	微盘和文件选择器jsapi返回的selectedTicket。若填此参数，则不需要填spaceid/fatherid。
	file_name	string	是	文件名字
	size	uint64	是	文件大小。最大支持20G
	block_sha	string[]	是	文件分块累积sha值，按分块顺序填入数组。参考附录-分块累积sha说明
	skip_push_card	bool	否	文件创建完成时是否推送企业微信卡片。默认false，即默认推送卡片

注意：spaceid/fatherid和selected_ticket必须填且仅填其中一组参数。

=head4 权限说明：

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"hit_exist": false,
		"upload_key": "UPLOAD_KEY",
		"fileid": "FILEID"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	hit_exist	bool	是否命中秒传
	upload_key	string	文件上传凭证。不命中秒传时返回，作为file_upload_part参数
	fileid	string	文件fileid。命中秒传时返回，此时上传流程完成

=cut

sub file_upload_init {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_upload_init?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_upload_part(access_token, hash);

分块上传文件

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98004#分块上传文件>

=head3 请求说明：

将文件内容按2M分块，依次请求分块上传文件接口。

=head4 请求包结构体为：

	{
		"upload_key": "UPLOAD_KEY",
		"index": 1,
		"file_base64_content": "FILE_BASE64_CONTENT"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	upload_key	string	是	文件上传凭证。file_upload_init返回的upload_key
	index	int32	是	文件分块号。文件内容按2M分块，从1开始
	file_base64_content	string	是	分块的文件内容base64。（注意：只需要填入文件内容的Base64，不需要添加任何如："data:application/x-javascript;base64" 的数据类型描述信息）

=head4 权限说明：

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

sub file_upload_part {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_upload_part?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_upload_finish(access_token, hash);

分块上传完成

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98004#分块上传完成>

=head3 请求说明：

请求分块上传完成接口，流程结束，完成上传。

=head4 请求包结构体为：

	{
		"upload_key": "UPLOAD_KEY"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	upload_key	string	是	文件上传凭证。file_upload_init返回的upload_key

=head4 权限说明：

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"fileid": "FILEID"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	fileid	string	文件fileid

=head4 附录-分块累积sha说明

L<https://developer.work.weixin.qq.com/document/path/98004#附录-分块累积sha说明>

=cut

sub file_upload_finish {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_upload_finish?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_download(access_token, hash);

下载文件
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97881>

=head3 请求说明：

该接口用于下载文件。

=head4 请求包结构体为：

	{
		"fileid": "FILEID",
		"selected_ticket": "SELECTED_TICKET"
	}

=head4 参数说明：

	参数	类型	是否必须	说明
	fileid	string	否	文件fileid（只支持下载普通文件，不支持下载文件夹或微文档）
	selected_ticket	string	否	微盘和文件选择器jsapi返回的selectedTicket。若填此参数，则不需要填fileid。

注意：fileid和selected_ticket必须填且仅填其中一组参数。

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"download_url": "DOWNLOAD_URL",
		"cookie_name": "COOKIE_NAME",
		"cookie_value": "COOKIE_VALUE"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	download_url	string	下载请求url (有效期2个小时)
	cookie_name	string	下载请求带cookie的key
	cookie_value	string	下载请求带cookie的value

=cut

sub file_download {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_download?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_create(access_token, hash);

新建文件夹/文档
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97882>

=head3 请求说明：

该接口用于在微盘指定位置新建文件夹、文档（更多文档接口能力可见文档API接口说明）。

=head4 请求包结构体为：

	{
		"spaceid": "SPACEID",
		"fatherid": "FATHERID",
		"file_type": FILE_TYPE,
		"file_name": "FILE_NAME"
	}

=head4 参数说明：

	参数	类型	是否必须	说明
	spaceid	string	是	空间spaceid
	fatherid	string	是	父目录fileid, 在根目录时为空间spaceid
	file_type	uint32	是	文件类型, 1:文件夹 3:文档(文档) 4:文档(表格)
	file_name	string	是	文件名字（注意：文件名最多填255个字符, 英文算1个, 汉字算2个）

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"fileid": "FILEID",
		"url": "URL"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	fileid	string	新建文件的fileid
	url	string	文档的访问链接，仅在新建文档时返回

=cut

sub file_create {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_create?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_rename(access_token, hash);

重命名文件
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97883>

=head3 请求说明：

该接口用于对指定文件进行重命名。

=head4 请求包结构体为：

	{
		"fileid": "FILEID",
		"new_name": "NEW_NAME"
	}

=head4 参数说明：

	参数	类型	是否必须	说明
	fileid	string	是	文件fileid
	new_name	string	是	重命名后的文件名 （注意：文件名最多填255个字符, 英文算1个, 汉字算2个）

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"file": {
			"fileid": "FILEID",
			"file_name": "FILE_NAME",
			"spaceid": "SPACEID",
			"fatherid": "FATHERID",
			"file_size": FILE_SIZE,
			"ctime": CTIME,
			"mtime": MTIME,
			"file_type": FILE_TYPE,
			"file_status": FILE_STATUS,
			"sha": "SHA",
			"md5": "MD5"
		}
	}

=head4 RETURN 参数说明：

	参数	类型	说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	fileid	string	文件fileid
	file_name	string	文件名字
	spaceid	string	文件所在的空间spaceid
	fatherid	string	文件所在的目录fileid, 在根目录时为spaceid
	file_size	uint64	文件大小
	ctime	uint64	文件创建时间
	mtime	uint64	文件最后修改时间
	file_type	uint32	文件类型, 1:文件夹 2:文件 3:文档(文档) 4:文档(表格) 5:文档(收集表) 6:文档(幻灯片)
	file_status	uint32	文件状态, 1:正常 2:删除
	sha	string	文件sha
	md5	string	文件md5

=cut

sub file_rename {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_rename?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_move(access_token, hash);

移动文件
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97884>

=head3 请求说明：

该接口用于将文件移动到指定位置。

=head4 请求包结构体为：

	{
		"fatherid": "FATHERID",
		"replace": true,
		"fileid": ["FILEID1", "FILEID2"]
	}

=head4 参数说明：

	参数	类型	是否必须	说明
	fatherid	string	是	当前目录的fileid,根目录时为空间spaceid
	replace	bool	否	如果移动到的目标目录与需要移动的文件重名时，是否覆盖。true:重名文件覆盖 false:重名文件进行冲突重命名处理（移动后文件名格式如xxx(1).txt xxx(1).doc等）
	fileid	string	是	文件fileid

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"file_list": {
			"item": [
				{
					"fileid": "FILEID",
					"file_name": "FILE_NAME",
					"spaceid": "SPACEID",
					"fatherid": "FATHERID",
					"file_size": FILE_SIZE,
					"ctime": CTIME,
					"mtime": MTIME,
					"file_type": FILE_TYPE,
					"file_status": FILE_STATUS,
					"sha": "SHA",
					"md5": "MD5"
				}
			]
		}
	}

=head4 RETURN 参数说明：

	参数	类型	说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	file_list	obj[]	移动文件的信息列表
	fileid	string	文件fileid
	file_name	string	文件名字
	spaceid	string	文件所在的空间spaceid
	fatherid	string	文件所在的目录fileid, 在根目录时为fileid
	file_size	uint64	文件大小
	ctime	uint64	文件创建时间
	mtime	uint64	文件最后修改时间
	file_type	uint32	文件类型, 1:文件夹 2:文件 3:文档(文档) 4:文档(表格) 5:文档(收集表) 6:文档(幻灯片)
	file_status	uint32	文件状态, 1:正常 2:删除
	sha	string	文件sha
	md5	string	文件md5

=cut

sub file_move {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_move?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_delete(access_token, hash);

删除文件
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97885>

=head3 请求说明：

该接口用于删除指定文件。

=head4 请求包结构体为：

	{
		"fileid": ["FILEID1", "FILEID2"]
	}

=head4 参数说明：

	参数	类型	是否必须	说明
	fileid	string[]	是	文件fileid

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

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

sub file_delete {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_delete?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_info(access_token, hash);

获取文件信息
最后更新：2022/12/26

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97886>

=head3 请求说明：

该接口用于获取指定文件的信息。

=head4 请求包结构体为：

    {
		"fileid": "FILEID"
	}

=head4 参数说明：

	参数	类型	是否必须	说明
	fileid	string	是	文件fileid

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"file_info": {
			"fileid": "FILEID",
			"file_name": "FILE_NAME",
			"spaceid": "SPACEID",
			"fatherid": "FATHERID",
			"file_size": FILE_SIZE,
			"ctime": CTIME,
			"mtime": MTIME,
			"file_type": FILE_TYPE,
			"file_status": FILE_STATUS,
			"sha": "SHA",
			"md5": "MD5",
			"url": "URL"
		}
	}

=head4 RETURN 参数说明：

	参数	类型	说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	fileid	string	文件fileid
	file_name	string	文件名字
	spaceid	string	文件所在的空间spaceid
	fatherid	string	文件所在的目录fileid, 在根目录时为fileid
	file_size	uint64	文件大小
	ctime	uint64	文件创建时间
	mtime	uint64	文件最后修改时间
	file_type	uint32	1: 文件夹 2:文件 3: 文档(文档) 4: 文档(表格) 5:文档(收集表) 6:文档(幻灯片)
	file_status	uint32	文件状态, 1:正常 2:删除
	sha	string	文件sha。可用于确认是否跟与上传的文件一致，或避免重复上传相同的文件
	md5	string	文件md5。可用于确认是否跟与上传的文件一致，或避免重复上传相同的文件
	url	string	仅微文档类型返回访问链接

=cut

sub file_info {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_info?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head1 FUNCTION

管理文件权限

=head2 file_acl_add(access_token, hash);

新增成员
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93658>

=head3 请求说明：

该接口用于对指定文件添加成员。

=head4 请求包结构体为：

	{
		"fileid": "FILEID",
		"auth_info": [{
			"type":2,
			"departmentid": DEPARTMENTID1,
			"auth": 1
		}, {
			"type":1,
			"userid": "USERID1",
			"auth": 4
		}]
	}

=head4 参数说明：

	参数	类型	是否必须	说明
	fileid	string	是	文件fileid
	auth_info	obj[]	是	添加成员的信息
	type(后续将废弃)	uint32	是	成员类型 1:个人 2:部门
	userid	string	是	成员userid,字符串
	departmentid(后续将废弃)	uint32	是	部门departmentid, 32位整型范围是[0, 2^32) (type为2时填写)
	auth	uint32	是	选项包括1:仅下载（仅浏览）；4:仅预览

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

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

sub file_acl_add {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_acl_add?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_acl_del(access_token, hash);

删除成员
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97888>

=head3 请求说明：

该接口用于删除指定文件的成员。

=head4 请求包结构体为：

	{
		"fileid": "FILEID",
		"auth_info": [{
			"type":1,
			"userid": "USERID1"
		},{
			"type":2,
			"departmentid": DEPARTMENTID1
		}]
	}

=head4 参数说明：

	参数	类型	是否必须	说明
	fileid	string	是	文件fileid
	auth_info	obj[]	是	被移除的成员信息
	type(后续将废弃)	uint32	是	成员类型 1:个人 2:部门
	userid	string	是	成员userid,字符串
	departmentid(后续将废弃)	uint32	是	部门departmentid, 32位整型范围是[0, 2^32) (type为2时填写)

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

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
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97889>

=head3 请求说明：

该接口用于文件的分享设置。

=head4 请求包结构体为：

	{
		"fileid": "FILDID",
		"auth_scope": AUTH_SCOPE,
		"auth": 1
	}

=head4 参数说明：

	参数	类型	是否必须	说明
	fileid	string	是	文件fileid
	auth_scope	uint32	是	权限范围：1:指定人 2:企业内 3:企业外 4: 企业内需管理员审批（仅有管理员时可设置） 5: 企业外需管理员审批（仅有管理员时可设置）
	auth	uint32	否	权限信息
						普通文档： 1:仅浏览（可下载) 4:仅预览（仅专业版企业可设置）；如果不填充此字段为保持原有状态
						微文档： 1:仅浏览（可下载）；如果不填充此字段为保持原有状态

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

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
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97890>

=head3 请求说明：

该接口用于获取文件的分享链接。

=head4 请求包结构体为：

    {
		"fileid": "FILDID"
	}

=head4 参数说明：

	参数	类型	是否必须	说明
	fileid	string	是	文件fileid

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

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

=head2 get_file_permission(access_token, hash);

获取文件权限信息
最后更新：2023/03/15

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97891>

=head3 请求说明：

该接口用于获取文件的权限信息。

=head4 请求包结构体为：

    {
		"fileid": "FILDID"
	}

=head4 参数说明：

	参数	类型	是否必须	说明
	fileid	string	是	文件fileid

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"share_range": {
			"enable_corp_internal": true,
			"corp_internal_auth": 1,
			"enable_corp_external": false,
			"corp_external_auth": 2
		},
		"secure_setting": {
			"enable_readonly_copy": true,
			"modify_only_by_admin": true,
			"enable_readonly_comment": false,
			"ban_share_external": true
		},
		"inherit_father_auth": {
			"auth_list": [
				{
					"type": 1,
					"userid": "USERID",
					"auth": 1
				}
			],
			"inherit": true
		},
		"file_member_list": [
			{
				"type": 1,
				"userid": "USERID",
				"auth": 1
			}
		],
		"watermark": {
			"text": "WATERMARK_TEXT",
			"margin_type": 1,
			"show_visitor_name": false,
			"force_by_admin": false,
			"show_text": false,
			"force_by_space_admin": false
		}
	}

=head4 RETURN 参数说明：

	参数	类型	说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	share_range	obj	文件分享设置
	enable_corp_internal	bool	是否为企业内可访问
	corp_internal_auth	uint32	企业内权限信息
	普通文档： 1:仅浏览（可下载) 4:仅预览（仅专业版企业可设置）255:无权限或需要审批；如果不填充此字段为保持原有状态
	微文档： 1:仅浏览（可下载）；如果不填充此字段为保持原有状态
	enable_corp_external	bool	是否为企业外可访问
	corp_external_auth	uint32	企业外权限信息
	普通文档： 1:仅浏览（可下载) 4:仅预览（仅专业版企业可设置） 255:无权限或需要审批；如果不填充此字段为保持原有状态
	微文档： 1:仅浏览（可下载）；如果不填充此字段为保持原有状态
	corp_internal_approve_only_by_admin	bool	是否开启企业内管理员审批
	corp_external_approve_only_by_admin	bool	是否开启企业外管理员审批
	secure_setting	obj	文件安全配置
	enable_readonly_copy	bool	是否开启只读备份
	modify_only_by_admin	bool	是否只允许管理员进行修改
	enable_readonly_comment	bool	是否开启只读评论
	ban_share_external	bool	是否禁止分享到企业外部
	inherit_father_auth	obj	从文件父路径继承的权限
	inherit	bool	文件是否开启父路径权限继承
	member_list	obj	文件夹、文档成员
	file_member_list	obj	查询fileid为文档时返回，为文档所在目录成员，以及其他授权列表
	co_auth_list	obj	分享指定的部门列表
	type(后续将废弃)	uint32	成员类型 1:个人 2:部门
	userid	string	成员userid,字符串
	departmentid(后续将废弃)	uint32	部门departmentid, 32位整型范围是[0, 2^32) (type为2时填写)
	watermark	obj	水印相关设置（除show_visitor_name字段外，其余字段仅文档可设置）
	text	string	水印文字，此字段不填则保持原样
	margin_type	uint32	水印类型。1：低密度水印， 2： 高密度水印，此字段不填则保持原样
	show_visitor_name	bool	是否显示访问人名称，此字段不填则保持原样（仅专业版支持）
	force_by_admin	bool	管理员是否强制要求使用水印，此字段不填则保持原样
	show_text	bool	是否展示水印文本，此字段不填则保持原样
	force_by_space_admin	bool	空间管理员是否强制要求使用水印，此字段不填则保持原样

=cut

sub get_file_permission {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/get_file_permission?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 file_secure_setting(access_token, hash);

修改文件安全设置
最后更新：2022/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97892>

=head3 请求说明：

该接口用于修改文件安全设置，水印相关设置。

=head4 请求包结构体为：

	{
		"fileid": "FILEID",
		"watermark": {
			"text": "WATERMARK_TEXT",
			"margin_type": 0,
			"show_visitor_name": false,
			"show_text": false,
		}
	}

=head4 参数说明：

	参数	类型	是否必须	说明
	fileid	string	是	文件fileid
	text	string	否	水印文字，此字段不填则保持原样
	margin_type	uint32	否	水印类型。1：低密度水印， 2： 高密度水印，此字段不填则保持原样
	show_visitor_name	bool	否	是否显示访问人名称，此字段不填则保持原样
	show_text	bool	否	是否展示水印文本，此字段不填则保持原样

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

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

sub file_secure_setting {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/file_secure_setting?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head1 FUNCTION

版本和容量管理
最后更新：2022/07/05

=head2 mng_pro_info(access_token, hash);

获取盘专业版信息

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95856#获取盘专业版信息>

=head3 请求说明：

该接口用于获取专业版信息。

=head4 请求包结构体为：

	{
		"userid": "USERID"
	}

=head4 参数说明：

	参数	类型	是否必须	说明
	userid	string	是	操作者userid

=head4 权限说明：

企业需要使用“微盘”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"is_pro": true,
		"total_vip_acct_num": 10,
		"use_vip_acct_num": 5,
		"pro_expire_time": 1754827419
	}

=head4 RETURN 参数说明：

	参数	类型	说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	is_pro	bool	true为专业版，false为不是专业版
	total_vip_acct_num	uint32	总的vip账号数量
	use_vip_acct_num	uint32	已的vip账号数量
	pro_expire_time	uint32	专业版到期时间，时间戳，精确到秒

=cut

sub mng_pro_info {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/mng_pro_info?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 mng_capacity(access_token, hash);

获取盘容量信息

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95856#获取盘容量信息>

=head3 请求说明：

该接口用于获取盘容量信息。

=head4 请求包结构体为：

	{
	}

=head4 参数说明：

	参数	类型	是否必须	说明

=head4 权限说明：

企业需要使用“微盘”secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“微盘”权限
代开发自建应用需具有“微盘”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"total_capacity_for_all": 22666689904640,
		"total_capacity_for_vip": 22300038149020，
		"rest_capacity_for_all": 0,
		"rest_capacity_for_vip": 0
	}

=head4 RETURN 参数说明：

	参数	类型	说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	total_capacity_for_all	uint64	全员容量总数,单位是B
	total_capacity_for_vip	uint64	专业容量总数,单位是B
	rest_capacity_for_all	uint64	全员容量可用总数,单位是B（第三方不返回该字段）
	rest_capacity_for_vip	uint64	专业容量可用总数,单位是B（第三方不返回该字段）

=cut

sub mng_capacity {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedrive/mng_capacity?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
