package QQ::weixin::work::externalcontact::resigned;

=encoding utf8

=head1 Name

QQ::weixin::work::externalcontact::resigned

=head1 DESCRIPTION

客户联系->离职继承

=cut

use strict;
use base qw(QQ::weixin::work::externalcontact);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.06';
our @EXPORT = qw/ transfer_customer transfer_result /;

=head1 FUNCTION

=head2 transfer_customer(access_token, hash);

分配离职成员的客户

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94081>

=head3 请求说明：

企业可通过此接口，分配离职成员的客户给其他成员。

=head4 请求包结构体为：

    {
	   "handover_userid": "zhangsan",
	   "takeover_userid": "lisi",
	   "external_userid": 
		[
			"woAJ2GCAAAXtWyujaWJHDDGi0mACBBBB",
			"woAJ2GCAAAXtWyujaWJHDDGi0mACAAAA"
		]
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
	handover_userid	是	原跟进成员的userid
	takeover_userid	是	接替成员的userid
	external_userid	是	客户的external_userid列表，最多一次转移100个客户

handover_userid必须是已离职用户。
external_userid必须是handover_userid的客户（即配置了客户联系功能的成员所添加的联系人）。

=head4 权限说明：

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需拥有“企业客户权限->客户联系->离职分配”权限
接替成员必须在此第三方应用或自建应用的可见范围内。
接替成员需要配置了客户联系功能。
接替成员需要在企业微信激活且已经过实名认证。

=head3 RETURN 返回结果：

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "customer":
	   [
		{
			"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACBBBB",
			"errcode":0
		},
		{
			"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACAAAA",
			"errcode":40096
		}
	   ]
	}

=head4 RETURN 参数说明：

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	customer.external_userid	客户的external_userid
	customer.errcode	对此客户进行分配的结果, 具体可参考全局错误码, 0表示开始分配流程,待24小时后自动接替,并不代表最终分配成功

原接口分配在职或离职成员的客户后续将不再更新维护，请使用新接口

=cut

sub transfer_customer {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/resigned/transfer_customer?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 transfer_result(access_token, hash);

查询客户接替状态

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94082>

=head3 请求说明：

企业和第三方可通过此接口查询离职成员的客户分配情况。

=head4 请求包结构体为：

    {
	   "handover_userid": "zhangsan",
	   "takeover_userid": "lisi",
	   "cursor":"CURSOR"
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
	handover_userid	是	原添加成员的userid
	takeover_userid	是	接替成员的userid
	cursor	否	分页查询的cursor，每个分页返回的数据不会超过1000条；不填或为空表示获取第一个分页

=head4 权限说明：

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需拥有“企业客户权限->客户联系->在职继承”权限
接替成员必须在此第三方应用或自建应用的可见范围内。

=head3 RETURN 返回结果：

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "customer":
	  [
	  {
		"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACCCC",
		"status":1,
		"takeover_time":1588262400
	  },
	  {
		"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACBBBB",
		"status":2,
		"takeover_time":1588482400
	  },
	  {
		"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACAAAA",
		"status":3,
		"takeover_time":0
	  }
	  ],
	  "next_cursor":"NEXT_CURSOR"
	}

=head4 RETURN 参数说明：

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	customer.external_userid	转接客户的外部联系人userid
	customer.status	接替状态， 1-接替完毕 2-等待接替 3-客户拒绝 4-接替成员客户达到上限
	customer.takeover_time	接替客户的时间，如果是等待接替状态，则为未来的自动接替时间
	next_cursor	下个分页的起始cursor

原接口查询客户接替结果后续将不再更新维护，请使用新接口

=cut

sub transfer_result {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/resigned/transfer_result?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
