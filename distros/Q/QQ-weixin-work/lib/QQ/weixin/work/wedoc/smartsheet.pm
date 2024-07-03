package QQ::weixin::work::wedoc::smartsheet;

=encoding utf8

=head1 Name

QQ::weixin::work::wedoc::smartsheet

=head1 DESCRIPTION

智能表格

=cut

use strict;
use base qw(QQ::weixin::work::wedoc);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.12';
our @EXPORT = qw/ add_sheet delete_sheet update_sheet
				add_view delete_views update_view
				add_fields delete_fields update_fields
				add_records delete_records update_records/;

=head1 FUNCTION

编辑智能表格内容

=head2 add_sheet(access_token, hash);

添加子表
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99896>

=head3 请求说明：

本接口用于在表格的某个位置添加一个智能表，该智能表不存在视图、记录和字段，可以使用 API 在该智能表中添加视图、记录和字段。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"properties": {
			"title": "智能表",
			"index": 3
		}
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	properties	object	否	智能表属性
	properties.title	string	否	智能表标题
	properties.index	int32	否	智能表下标

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"properties": {
			"title": "智能表",
			"index": 3,
			"sheet_id": "123abc"
		}
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	properties	object	智能表属性
	properties.sheet_id	string	智能表 ID，创建子表时生成的 6 位随机 ID
	properties.title	string	智能表标题
	properties.index	int32	智能表下标

=cut

sub add_sheet {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/add_sheet?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete_sheet(access_token, hash);

删除子表
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99899>

=head3 请求说明：

本接口用于删除在线表格中的某个智能表。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "123Abc"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	是	删除的Smartsheet 子表 ID

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

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

sub delete_sheet {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/delete_sheet?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update_sheet(access_token, hash);

更新子表
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99898>

=head3 请求说明：

本接口用于修改表格中某个子表的标题。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"properties": {
			"sheet_id": "123abc",
			"title": "XXXX"
		}
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	properties.sheet_id	string	是	子表 ID
	properties.title	string	否	子表标题

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

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

sub update_sheet {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/update_sheet?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 add_view(access_token, hash);

添加视图
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99900>

=head3 请求说明：

本接口用于在 Smartsheet 中的某个子表里添加一个新视图。单表最多允许有200个视图。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "123Abc",
		"view_title": "XXX",
		"view_type": "VIEW_TYPE_GRID"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	是	Smartsheet 子表ID
	view_title	string	是	视图标题
	view_type	string	是	视图类型。见ViewType
	property_gantt	obect(GanttViewProperty)	否	甘特视图属性,添加甘特图时必填
	property_calendar	object(CalendarViewProperty)	否	日历视图属性，添加日历视图时必填

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"view": {
			"view_id": "vFYZUS",
			"view_title": "XXX",
			"view_type": "VIEW_TYPE_GRID"
		}
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	view	object(View)	添加视图响应

=head4 参数详细说明

L<https://developer.work.weixin.qq.com/document/path/99900#参数详细说明>

=cut

sub add_view {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/add_view?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete_views(access_token, hash);

删除视图
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99901>

=head3 请求说明：

本接口用于在 smartsheet 中的某个子表里删除若干个视图。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "123Abc",
		"view_ids": [
			"VIEWID1", "VIEWID2"
		]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	是	Smartsheet 子表ID
	view_ids	string[]	是	要删除的视图ID列表

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

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

sub delete_views {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/delete_views?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update_view(access_token, hash);

更新视图
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99902>

=head3 请求说明：

本接口用于在 Smartsheet 中的某个子表里添加一个新视图。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "123Abc",
		"view_id": "VIEWID",
		"view_title": "XXX",
		"property": {
		}
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	是	Smartsheet 子表ID
	view_id	string	是	视图ID
	view_title	string	否	视图标题
	property	object(ViewProperty)	否	视图的排序/过滤/分组配置，详见ViewProperty

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"view": {
		}
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	view	object(View)	更新成功的视图内容

=head4 参数详细说明

L<https://developer.work.weixin.qq.com/document/path/99902#参数详细说明>

=cut

sub update_view {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/update_view?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 add_fields(access_token, hash);

添加字段
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99904>

=head3 请求说明：

本接口用于在智能表中的某个子表里添加一列或多列新字段。单表最多允许有150个字段。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "SHEETID",
		"fields": [{
			"field_title": "TITLE",
			"field_type": "FIELD_TYPE_TEXT"
		}]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	是	表格ID
	fields	object [] (AddFiled)	是	字段详情

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"fields": [{
			"field_id": "FIELDID",
			"field_title": "TITLE",
			"field_type": "FIELD_TYPE_TEXT"
		}]
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	fields	object [] (Filed)	字段详情

=head4 参数详细说明

L<https://developer.work.weixin.qq.com/document/path/99904#参数详细说明>

=cut

sub add_fields {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/add_fields?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete_fields(access_token, hash);

添加字段
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99905>

=head3 请求说明：

本接口用于删除智能表中的某个子表里的一列或多列字段。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "SHEETID",
		"field_ids": [
			"FIELDID"
		]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	是	表格ID
	field_ids	string[]	是	需要删除的字段id列表

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

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

sub delete_fields {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/delete_fields?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update_fields(access_token, hash);

更新字段
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99906>

=head3 请求说明：

本接口用于更新智能中的某个子表里的一个或多个字段的标题和字段属性信息。
注意
该接口只能更新字段名、字段属性，不能更新字段类型。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "SHEETID",
		"fields": [{
			"field_id": "FIELD_ID",
			"field_title": "TITLE",
			"field_type": "FIELD_TYPE_TEXT"
		}]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	是	表格ID
	fields	object [](UpdateField)	是	字段详情

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"fields": [{
			"field_id": "FIELDID",
			"field_title": "TITLE",
			"field_type": "FIELD_TYPE_TEXT"
		}]
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	fields	object [] (Filed)	字段详情

=head4 参数详细说明

L<https://developer.work.weixin.qq.com/document/path/99906#参数详细说明>

=cut

sub update_fields {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/update_fields?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 add_records(access_token, hash);

添加记录
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99907>

=head3 请求说明：

本接口用于在 Smartsheet 中的某个子表里添加一行或多行新记录。单表最多允许有40000行记录。
注意
不能通过添加记录接口给创建时间、最后编辑时间、创建人和最后编辑人四种类型的字段添加记录。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "123Abc",
		"key_type": "CELL_VALUE_KEY_TYPE_FIELD_TITLE",
		"records": [{
			"values": {
				"FILED_TITLE": [{
					"type": "text",
					"text": "文本内容"
				}]
			}
		}]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	是	Smartsheet 子表ID
	key_type	string(CellValueKeyType)	否	返回记录中单元格的key类型，默认用标题
	records	Object[](AddRecord)	是	需要添加的记录的具体内容组成的 JSON 数组

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"records": [
				
		]
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	records	Object[](CommonRecord)	由添加成功的记录的具体内容组成的 JSON 数组

=head4 参数详细说明

L<https://developer.work.weixin.qq.com/document/path/99904#参数详细说明>

=cut

sub add_records {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/add_records?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete_records(access_token, hash);

添加字段
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99908>

=head3 请求说明：

本接口用于删除 Smartsheet 的某个子表中的一行或多行记录。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "123Abc",
		"record_ids": [
			"re9IqD",
			"rpS0P9"
		]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	是	Smartsheet 子表ID
	record_ids	string[]	是	要删除的记录 ID

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

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

sub delete_records {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/delete_records?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update_records(access_token, hash);

更新记录
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99909>

=head3 请求说明：

本接口用于更新 Smartsheet 中的某个子表里的一行或多行记录。
注意
不能通过更新记录接口给创建时间、最后编辑时间、创建人和最后编辑人四种类型的字段更新记录。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "123Abc",
		"key_type": "CELL_VALUE_KEY_TYPE_FIELD_TITLE",
		"records": [
		]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	是	Smartsheet 子表ID
	key_type	string(CellValueKeyType)	否	返回记录中单元格的key类型
	records	Object[](UpdateRecord)	是	由需要更新的记录组成的 JSON 数组

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"records": [
		]
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	records	Object[](CommonRecord)	由更新成功的记录的具体内容组成的 JSON 数组

=head4 参数详细说明

L<https://developer.work.weixin.qq.com/document/path/99909#参数详细说明>

=cut

sub update_records {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/update_records?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head1 FUNCTION

获取智能表格数据

=head2 get_sheet(access_token, hash);

查询子表
最后更新：2024/06/13

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99911>

=head3 请求说明：

本接口用于查询一篇在线表格中全部智能表信息。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "xxx"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	否	指定子表ID查询

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"sheet_list": [
			{
				"sheet_id": "123Abc",
				"title": "XXXX",
				"is_visible": true
			}
		]
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	sheet_list	object[] 智能表信息	 
	sheet_list.sheet_id	string	子表id
	sheet_list.title	string	子表名称
	sheet_list.is_visible	bool	子表是否可见

=cut

sub get_sheet {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/get_sheet?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_views(access_token, hash);

查询视图
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99913>

=head3 请求说明：

本接口用于获取 Smartsheet 中某个子表里全部视图信息。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "ezPcdA",
		"view_ids": [
			"vPpw9C",
			"vfM2tt"
		],
		"offset": 0,
		"limit": 1
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	是	Smartsheet 子表ID
	view_ids	string[]	否	需要查询的视图 ID 数组
	offset	uint32	否	偏移量，初始值为 0
	limit	uint32	否	分页大小 , 每页返回多少条数据；当不填写该参数或将该参数设置为 0 时，如果总数大于 1000，一次性返回 1000 个视图，当总数小于 1000 时，返回全部视图；limit 最大值为 1000

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"total": 2,
		"has_more": true,
		"next": 1,
		"views": [
		]
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	total	uint32	符合筛选条件的视图总数
	has_more	bool	是否还有更多项
	next	uint32	下次下一个搜索结果的偏移量
	views	Object[](View)	视图数据

=head4 参数详细说明

L<https://developer.work.weixin.qq.com/document/path/99913#参数详细说明>

=cut

sub get_views {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/get_views?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_fields(access_token, hash);

查询字段
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99914>

=head3 请求说明：

本接口用于获取智能表中某个子表下字段信息，该接口可以完成下面三种功能：获取全部字段信息、依据字段名获取对应字段、依据字段 ID 获取对应字段信息。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "SHEETID",
		"offset": 0,
		"limit": 10
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	是	表格ID
	view_id	string	否	视图 ID
	field_ids	string []	否	由字段 ID 组成的 JSON 数组
	field_titles	string []	否	由字段标题组成的 JSON 数组
	offset	int	否	偏移量，初始值为 0
	limit	int	否	分页大小 , 每页返回多少条数据；当不填写该参数或将该参数设置为 0 时，如果总数大于 1000，一次性返回 1000 个字段，当总数小于 1000 时，返回全部字段；limit 最大值为 1000

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"total": 1,
		"fields": [{
			"field_id": "ID1",
			"field_title": "TITLE1",
			"field_type": "FIELD_TYPE_TEXT"
		}]
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	total	Object	字段总数
	fields	object [](Field)	字段详情

=head4 参数详细说明

L<https://developer.work.weixin.qq.com/document/path/99914#参数详细说明>

=cut

sub get_fields {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/get_fields?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_records(access_token, hash);

查询记录
最后更新：2024/05/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99914>

=head3 请求说明：

本接口用于获取 Smartsheet 中某个子表下记录信息，该接口可以完成下面三种功能：获取全部记录信息、依据字段名和记录 ID 获取对应记录、对记录进行排序。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "123Abc",
		"view_id": "vCRl8n",
		"record_ids": [
		],
		"key_type": "CELL_VALUE_KEY_TYPE_FIELD_TITLE",
		"field_titles": [
		],
		"field_ids": [
		],
		"sort": [
		],
		"offset": 0,
		"limit": 100
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	sheet_id	string	是	Smartsheet 子表ID
	view_id	string	否	视图 ID
	record_ids	string[]	否	由记录 ID 组成的 JSON 数组
	key_type	string(CellValueKeyType)	否	返回记录中单元格的key类型
	field_titles	string[]	否	返回指定列，由字段标题组成的 JSON 数组 ，key_type 为 CELL_VALUE_KEY_TYPE_FIELD_TITLE 时有效
	field_ids	string[]	否	返回指定列，由字段 ID 组成的 JSON 数组 ，key_type 为 CELL_VALUE_KEY_TYPE_FIELD_ID 时有效
	sort	Object[](Sort)	否	对返回记录进行排序
	offset	uint32	否	偏移量，初始值为 0
	limit	uint32	否	分页大小 , 每页返回多少条数据；当不填写该参数或将该参数设置为 0 时，如果总数大于 1000，一次性返回 1000 行记录，当总数小于 1000 时，返回全部记录；limit 最大值为 1000

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	total	uint32	符合筛选条件的视图总数
	has_more	bool	是否还有更多项
	next	uint32	下次下一个搜索结果的偏移量
	records	Object[](Record)	由查询记录的具体内容组成的 JSON 数组

=head4 参数详细说明

L<https://developer.work.weixin.qq.com/document/path/99915#参数详细说明>

=cut

sub get_records {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/smartsheet/get_records?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
