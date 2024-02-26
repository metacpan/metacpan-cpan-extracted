package QQ::weixin::work::wedoc::spreadsheet;

=encoding utf8

=head1 Name

QQ::weixin::work::wedoc::spreadsheet

=head1 DESCRIPTION

文档

=cut

use strict;
use base qw(QQ::weixin::work::wedoc);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ batch_update
				get_sheet_properties get_sheet_range_data /;

=head1 FUNCTION

编辑文档

=head2 batch_update(access_token, hash);

编辑表格内容
最后更新：2022/12/10

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97628>

=head3 请求说明：

该接口可以对一个在线表格批量执行多个更新操作。

注意：

批量更新请求中的各个操作会逐个按顺序执行，直到全部执行完成则请求返回，或者其中一个操作报错则不再继续执行后续的操作。
每一个更新操作在执行之前都会做请求校验（包括权限校验、参数校验等等），如果校验未通过则该更新操作会报错并返回，不再执行后续操作。
单次批量更新请求的操作数量 <= 5。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"requests": [
			{
				"add_sheet_request": {...}
			},
			{
				"update_range_request": {...}
			},
			{
				"delete_dimension_request": {...}
			},
			{
				"delete_sheet_request": {...}
			}
		]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	requests	object[]	是	更新操作列表，详见 UpdateRequest

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"data" {
			"responses": [
				{
					"add_sheet_response": {...}
				},
				{
					"update_range_response": {...}
				},
				{
					"delete_dimension_response": {...}
				},
				{
					"delete_sheet_response": {...}
				}
			]
		}
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	data.responses	object[]	结果列表，详见UpdateResponse

=head4 参数详细说明

L<https://developer.work.weixin.qq.com/document/path/97628#参数详细说明>

=cut

sub batch_update {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/spreadsheet/batch_update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head1 FUNCTION

获取文档数据

=head2 get_sheet_properties(access_token, hash);

获取表格行列信息
最后更新：2024/02/04

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97711>

=head3 请求说明：

该接口用于获取在线表格的工作表、行数、列数等。

=head4 请求包结构体为：

	{
		"docid": "DOCID"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	在线表格的docid

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"properties": [
			{
				...
			}
		]
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	properties	object[](Properties)	工作表属性

=head4 参数详细说明

Properties
工作表元数据相关的资源描述

示例

	{
		"sheet_id", "ABCDE",
		"title": "XXXXXX",
		"row_count": 100,
		"column_count": 100
	}

	字段名	数据类型	描述
	sheet_id	string	工作表ID，工作表的唯一标识
	title	string	工作表名称
	row_count	uint32	表格的总行数
	column_count	uint32	表格的总列数

=cut

sub get_sheet_properties {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/spreadsheet/get_sheet_properties?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_sheet_range_data(access_token, hash);

获取表格数据
最后更新：2023/01/06

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97661>

=head3 请求说明：

本接口用于获取指定范围内的在线表格信息，单次查询的范围大小需满足以下限制：

查询范围行数 <=1000
查询范围列数 <=200
范围内的总单元格数量 <=10000

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"sheet_id": "AABBCC",
		"range": "A1:B2"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	在线表格唯一标识
	sheet_id	string	是	工作表ID，工作表的唯一标识
	range	string	是	查询的范围，格式遵循 A1表示法

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"data": {
			"result": {
				...
			}
		}
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	data.result	object(GridData)	表格数据

=head4 参数详细说明

L<https://developer.work.weixin.qq.com/document/path/97661#参数详细说明>

=cut

sub get_sheet_range_data {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/spreadsheet/get_sheet_range_data?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
