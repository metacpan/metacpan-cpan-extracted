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

our $VERSION = '0.06';
our @EXPORT = qw/ space_create space_rename space_dismiss space_info
				space_acl_add space_acl_del space_setting space_share
				file_list file_upload file_download file_create file_rename file_move file_delete file_info
				file_acl_add file_acl_del file_setting file_share /;

=head1 FUNCTION

=head2 space_create(access_token, hash);

新建空间

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93655#新建空间>

=head3 请求说明：

该接口用于在微盘内新建空间，可以指定人创建空间。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"space_name": "SPACE_NAME",
		"auth_info": [{
			"type": 1,
			"userid": "USERID",
			"auth": 2
		}, {
			"type": 2,
			"departmentid": DEPARTMENTID,
			"auth": 1
		}]
	}

=head4 参数说明：

    参数		类型   必须	说明
    access_token	是	调用接口凭证
    userid	string	是	操作者userid
	space_name	string	是	空间标题
	auth_info	obj[]	否	空间其他成员信息
	type	uint32	否	成员类型 1:个人 2:部门
	userid	string	否	成员userid,字符串
	departmentid	uint32	否	部门departmentid, 32位整型范围是[0, 2^32)
	auth	uint32	否	成员权限 1:可下载 2:可编辑 4:可预览（仅专业版企业可设置）

=head4 权限说明：

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"spaceid": "SPACEID"
	}

=head4 RETURN 参数说明：

    参数	类型	说明
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

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93655#重命名空间>

=head3 请求说明：

该接口用于重命名已有空间，接收userid参数，以空间管理员身份来重命名。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"spaceid": "SPACEID",
		"space_name": "SPACE_NAME"
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	string	是	操作者userid
	spaceid	string	是	空间spaceid
	space_name	string	是	重命名后的空间名

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

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93655#解散空间>

=head3 请求说明：

该接口用于解散已有空间，需要以空间管理员身份来解散。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"spaceid": "SPACEID"
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	string	是	操作者userid
	spaceid	string	是	空间spaceid

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

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93655#获取空间信息>

=head3 请求说明：

该接口用于获取空间成员列表、信息、权限等信息。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"spaceid": "SPACEID"
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	string	是	操作者userid
	spaceid	string	是	空间spaceid

=head4 权限说明：

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
					"auth": 3
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
		}
	}

=head4 RETURN 参数说明：

    参数	类型	说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	spaceid	string	空间spaceid
	space_name	string	空间名称
	auth_list	obj[]	空间成员列表
	auth_info	obj[]	空间成员信息
	type	uint32	成员类型 1:个人 2:部门
	userid	string	成员userid,字符串
	departmentid	uint32	部门departmentid, 32位整型范围是[0, 2^32)
	auth	uint32	成员权限 1:可下载 2:可编辑 3;管理员 4:可预览
	quit_userid	string[]	空间无权限成员userid (成员在一个有权限的部门中, 自己退出空间或者被移除权限)

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

=head2 space_acl_add(access_token, hash);

添加成员/部门

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93656#添加成员部门>

=head3 请求说明：

该接口用于对指定空间添加成员/部门，可一次性添加多个。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"spaceid": "SPACEID",
		"auth_info": [{
			"type": 1,
			"userid": "USERID1",
			"auth": 2
		}, {
			"type": 2,
			"departmentid": DEPARTMENTID1,
			"auth": 2
		}]
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	spaceid	string	是	空间spaceid
	auth_info	obj[]	是	被添加的空间成员信息
	type	uint32	是	成员类型 1:个人 2:部门
	userid	string	是	成员userid,字符串 (type为1时填写)
	departmentid	uint32	是	部门departmentid, 32位整型范围是[0, 2^32) (type为2时填写)
	auth	uint32	是	1:可下载 2:可编辑 4:可预览（仅专业版企业可设置）

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

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93656#移除成员部门>

=head3 请求说明：

该接口用于对指定空间移除成员/部门，操作者需要有移除权限。

=head4 请求包结构体为：

    {
		"userid": "USERID",
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

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	spaceid	string	是	空间spaceid
	auth_info	obj[]	是	被移除的空间成员信息
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

权限管理

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93656#权限管理>

=head3 请求说明：

该接口用于修改空间权限，需要传入userid，修改权限范围继承传入用户的权限范围。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"spaceid": "SPACEID",
		"enable_watermark": true,
		"add_member_only_admin": true,
		"enable_share_url": false,
		"share_url_no_approve": true,
		"share_url_no_approve_default_auth": 4
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	spaceid	string	是	空间spaceid
	enable_watermark	bool	否	（本字段仅专业版企业可设置）启用水印。false:关 true:开 ;如果不填充此字段为保持原有状态
	add_member_only_admin	bool	否	仅管理员可增减空间成员和修改文件分享设置。false:关 true:开 ；如果不填充此字段为保持原有状态
	enable_share_url	bool	否	启用成员邀请链接。false:关 true:开 ；如果不填充此字段为保持原有状态
	share_url_no_approve	bool	否	通过链接加入空间无需审批。false:关； true:开； 如果不填充此字段为保持原有状态
	share_url_no_approve_default_auth	uint32	否	邀请链接默认权限。1:仅浏览（可下载）2:可编辑 4:可预览（仅专业版企业可设置）；如果不填充此字段为保持原有状态

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

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93656#获取邀请链接>

=head3 请求说明：

该接口用于获取空间邀请分享链接。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"spaceid": "SPACEID"
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	spaceid	string	是	空间spaceid

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

=head2 file_list(access_token, hash);

获取文件列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93657#获取文件列表>

=head3 请求说明：

该接口用于获取指定地址下的文件列表。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"spaceid": "SPACEID",
		"fatherid": "FATHERID",
		"sort_type": SORT_TYPE,
		"start": START,
		"limit": LIMIT
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	spaceid	string	是	空间spaceid
	fatherid	string	是	当前目录的fileid,根目录时为空间spaceid
	sort_type	uint32	是	列表排序方式 1:名字升序；2:名字降序；3:大小升序；4:大小降序；5:修改时间升序；6:修改时间降序
	start	uint32	是	首次填0, 后续填上一次请求返回的next_start
	limit	uint32	是	分批拉取最大文件数, 不超过1000

=head4 权限说明：

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"has_more": true,
		"next_start": NEXT_START,
		"file_list": {
			"item": [{
				"fileid": "FILEID1",
				"file_name": "FILE_NAME1",
				"spaceid": "SPACEID",
				"fatherid": "FATHERID",
				"file_size": FILE_SIZE,
				"ctime": CTIME,
				"mtime": MTIME,
				"file_type": FILE_TYPE,
				"file_status": FILE_STATUS,
				"create_userid": "CREATE_USERID",
				"update_userid": "UPDATE_USERID",
				"sha": "SHA",
				"md5": "MD5",
				"url": "URL"
			}, {
				"fileid": "FILEID2",
				"file_name": "FILE_NAME2"
			}]
	}

=head4 RETURN 参数说明：

    参数	类型	说明
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
	create_userid	string	文件创建者userid
	update_userid	string	文件最后修改者userid
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

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93657#上传文件>

=head3 请求说明：

该接口用于向微盘中的指定位置上传文件。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"spaceid": "SPACEID",
		"fatherid": "FATHERID",
		"file_name": "FILE_NAME",
		"file_base64_content": "FILE_BASE64_CONTENT"
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	spaceid	string	是	空间spaceid
	fatherid	string	是	父目录fileid, 在根目录时为空间spaceid
	file_name	string	是	文件名字
	file_base64_content	string	是	文件内容base64（注意：只需要填入文件内容的Base64，不需要添加任何如："data:application/x-javascript;base64" 的数据类型描述信息）

=head4 权限说明：

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"fileid": "FILEID"
	}

=head4 RETURN 参数说明：

    参数	类型	说明
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

=head2 file_download(access_token, hash);

下载文件

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93657#下载文件>

=head3 请求说明：

该接口用于下载文件，请求的userid需有下载权限。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"fileid": "FILEID"
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	fileid	string	是	文件fileid（只支持下载普通文件，不支持下载文件夹或微文档）

=head4 权限说明：

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"download_url": "DOWNLOAD_URL",
		"cookie_name": "COOKIE_NAME",
		"cookie_value": "COOKIE_VALUE"
	}

=head4 RETURN 参数说明：

    参数	类型	说明
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

新建文件/微文档

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93657#新建文件微文档>

=head3 请求说明：

该接口用于在微盘指定位置新建文件、微文档。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"spaceid": "SPACEID",
		"fatherid": "FATHERID",
		"file_type": "FILE_TYPE",
		"file_name": "FILE_NAME"
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	spaceid	string	是	空间spaceid
	fatherid	string	是	父目录fileid, 在根目录时为空间spaceid
	file_type	uint32	是	文件类型, 1:文件夹 3:微文档(文档) 4:微文档(表格)
	file_name	string	是	文件名字

=head4 权限说明：

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"fileid": "FILEID",
		"url": "URL"
	}

=head4 RETURN 参数说明：

    参数	类型	说明
    errcode	int32	错误码
	errmsg	string	错误码说明
	fileid	string	新建文件的fileid
	url	string	微文档的访问链接，仅在新建微文档时返回

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

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93657#重命名文件>

=head3 请求说明：

该接口用于对指定文件进行重命名。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"fileid": "FILEID",
		"new_name": "NEW_NAME"
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	fileid	string	是	文件fileid
	new_name	string	是	重命名后的文件名

=head4 权限说明：

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
			"create_userid": "CREATE_USERID",
			"update_userid": "UPDATE_USERID",
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
	file_type	uint32	文件类型, 1:文件夹 2:文件 3:微文档(文档) 4:微文档(表格) 5:微文档(收集表)
	file_status	uint32	文件状态, 1:正常 2:删除
	create_userid	string	文件创建者userid
	update_userid	string	文件最后修改者userid
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

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93657#移动文件>

=head3 请求说明：

该接口用于将文件移动到指定位置。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"fatherid": "FATHERID",
		"replace": true,
		"fileid": ["FILEID1", "FILEID2"]
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	fatherid	string	是	当前目录的fileid,根目录时为空间spaceid
	replace	bool	否	如果移动到的目标目录与需要移动的文件重名时，是否覆盖。true:重名文件覆盖 false:重名文件进行冲突重命名处理（移动后文件名格式如xxx(1).txt xxx(1).doc等）
	fileid	string	是	文件fileid

=head4 权限说明：

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
				"create_userid": "CREATE_USERID",
				"update_userid": "UPDATE_USERID",
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
	file_type	uint32	文件类型, 1:文件夹 2:文件 3:微文档(文档) 4:微文档(表格) 5:微文档(收集表)
	file_status	uint32	文件状态, 1:正常 2:删除
	create_userid	string	文件创建者userid
	update_userid	string	文件最后修改者userid
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

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93657#删除文件>

=head3 请求说明：

该接口用于删除指定文件。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"fileid": ["FILEID1", "FILEID2"]
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	fileid	string[]	是	文件fileid

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

文件信息

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93657#文件信息>

=head3 请求说明：

该接口用于获取指定文件的信息。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"fileid": "FILEID"
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
			"create_userid": "CREATE_USERID",
			"update_userid": "UPDATE_USERID",
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
	file_type	uint32	1: 文件夹 2:文件 3: 微文档(文档) 4: 微文档(表格) 5:微文档(收集表)
	file_status	uint32	文件状态, 1:正常 2:删除
	create_userid	string	文件创建者userid
	update_userid	string	文件最后修改者userid
	sha	string	文件sha
	md5	string	文件md5
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

=head2 file_acl_add(access_token, hash);

新增指定人

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93658#新增指定人>

=head3 请求说明：

该接口用于对指定文件添加指定人/部门。

=head4 请求包结构体为：

    {
		"userid": "USERID",
		"fileid": "FILEID",
		"auth_info": [{
			"type": 1,
			"userid": "USERID1",
			"auth": 1
		}, {
			"type": 2,
			"departmentid": DEPARTMENT_ID1,
			"auth": 1	
		}]
	}

=head4 参数说明：

    参数	类型	是否必须	说明
	userid	string	是	操作者userid
	fileid	string	是	文件fileid
	auth_info	obj[]	是	添加成员的信息
	type	uint32	是	成员类型 1:个人 2:部门
	userid	string	是	成员userid,字符串 (type为1时填写)
	auth	uint32	是	新增成员的权限信息
						普通文档：1:仅浏览（可下载) 4:仅预览（仅专业版企业可设置）；如果不填充此字段为保持原有状态
						微 文 档：1:仅浏览（可下载）2:可编辑；如果不填充此字段为保持原有状态
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
