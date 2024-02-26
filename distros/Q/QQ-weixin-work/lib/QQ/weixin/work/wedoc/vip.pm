package QQ::weixin::work::wedoc::vip;

=encoding utf8

=head1 Name

QQ::weixin::work::wedoc::vip

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
our @EXPORT = qw/ batch_add batch_del list /;

=head1 FUNCTION

高级功能账号管理

=head2 batch_add(access_token, hash);

分配高级功能账号
最后更新：2023/12/07

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99516>

=head3 请求说明：

该接口用于分配应用可见范围内企业成员的高级功能。

=head4 请求包结构体为：

	{
	  "userid_list": ["zhangsan","lisi","wangwu"]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	userid_list	是	要分配高级功能的企业成员userid列表，单次操作最大限制100个

=head4 权限说明：

	应用类型	权限要求
	自建应用	配置到「协作 - 文档 - 可调用接口的应用」中
	代开发应用	暂不支持
	第三方应用	暂不支持

=head3 RETURN 返回结果：

	{
	   "errcode": 0,
	   "errmsg": "ok",
	   "succ_userid_list":["zhangsan","lisi"],
	   "fail_userid_list":["wangwu"]
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	返回码
	errmsg	对返回码的文本描述内容
	succ_userid_list	分配成功的userid列表，包括已经是高级功能账号的userid
	fail_userid_list	分配失败的userid列表

=cut

sub batch_add {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/vip/batch_add?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 batch_del(access_token, hash);

取消高级功能账号
最后更新：2023/12/07

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99517>

=head3 请求说明：

该接口用于撤销分配应用可见范围企业成员的高级功能。

=head4 请求包结构体为：

	{
	  "userid_list": ["zhangsan","lisi","wangwu"]
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	userid_list	是	要撤销分配高级功能的企业成员userid列表，单次操作最多限制100个

=head4 权限说明：

	应用类型	权限要求
	自建应用	配置到「协作 - 文档 - 可调用接口的应用」中
	代开发应用	暂不支持
	第三方应用	暂不支持

=head3 RETURN 返回结果：

	{
	   "errcode": 0,
	   "errmsg": "ok",
	   "succ_userid_list":["zhangsan","lisi"],
	   "fail_userid_list":["wangwu"]
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	返回码
	errmsg	对返回码的文本描述内容
	succ_userid_list	撤销分配成功的userid列表
	fail_userid_list	撤销分配失败的userid列表

=cut

sub batch_del {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/vip/batch_del?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token, hash);

获取高级功能账号列表
最后更新：2023/12/07

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99518>

=head3 请求说明：

该接口用于查询企业已分配高级功能且在应用可见范围的账号列表。

=head4 请求包结构体为：

	{
		"cursor":"CURSOR",
		"limit":2
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	是	调用接口凭证
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用可不填
	limit	否	用于分页查询，每次请求返回的数据上限。默认100，最大200
				注意：不保证每次返回的数据刚好为指定limit，必须用返回的has_more判断是否继续请求

=head4 权限说明：

	应用类型	权限要求
	自建应用	配置到「协作 - 文档 - 可调用接口的应用」中
	代开发应用	暂不支持
	第三方应用	暂不支持

=head3 RETURN 返回结果：

	{
	   "errcode": 0,
	   "errmsg": "ok",
	   "has_more":true,
	   "next_cursor":"GNIJIGEO",
	   "userid_list":["zhangsan","lisi"]
	}

=head4 RETURN 参数说明：

	参数		类型		说明
	errcode	返回码
	errmsg	对返回码的文本描述内容
	has_more	是否还有更多数据未获取
	next_cursor	下一次请求的cursor值
	userid_list	符合条件的企业成员userid列表

=cut

sub list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/wedoc/vip/list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
