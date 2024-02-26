package QQ::weixin::work::wedoc::document;

=encoding utf8

=head1 Name

QQ::weixin::work::wedoc::document

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
our @EXPORT = qw/ batch_update get /;

=head1 FUNCTION

编辑文档

=head2 batch_update(access_token, hash);

编辑文档内容
最后更新：2022/12/10

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97626>

=head3 请求说明：

该接口可以对一个在线文档批量执行多个更新操作。

注意：

批量更新请求，若其中有一个操作报错则全部更新操作不生效。
单次批量更新操作数量 <= 30。

=head4 请求包结构体为：

	{
		"docid": "DOCID",
		"verison": 10,
		"requests": [
			{
				"insert_text": {
					"text": "text content",
					"location": {
						"index": 10
					}
				}
			},
			{
				"insert_table": {
					"rows": 2,
					"cols": 2,
					"location": {
						"index": 10
					}
				}
			}
		]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid
	version	uint32	否	操作的文档版本, 该参数可以通过获取文档内容接口获得。操作后文档版本将更新一版。要更新的文档版本与最新文档版本相差不能超过100个。
	requests	object[]	是	更新操作列表，详见 UpdateRequest

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

=head4 参数详细说明

L<https://developer.work.weixin.qq.com/document/path/97626#参数详细说明>

=cut

sub batch_update {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/document/batch_update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head1 FUNCTION

获取文档数据

=head2 get(access_token, hash);

获取文档数据
最后更新：2023/10/19

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97659>

=head3 请求说明：

该接口用于获取文档数据

=head4 请求包结构体为：

	{
		"docid": "DOCID"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	docid	string	是	文档的docid

=head4 权限说明：

自建应用需配置到“可调用应用”列表中的应用secret所获取的accesstoken来调用（accesstoken如何获取？）
第三方应用需具有“文档”权限
代开发自建应用需具有“文档”权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"version": 10,
		"document": {
			...
		}
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	int32	错误码
	errmsg	string	错误码说明
	version	uint32	文档版本
	document	object(Node)	文档内容根节点，详见Node

=head4 参数详细说明

L<https://developer.work.weixin.qq.com/document/path/97659#参数详细说明>

=cut

sub get {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/document/get?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
