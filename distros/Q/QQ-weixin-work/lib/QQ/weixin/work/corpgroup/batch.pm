package QQ::weixin::work::corpgroup::batch;

=encoding utf8

=head1 Name

QQ::weixin::work::corpgroup::batch

=head1 DESCRIPTION

=cut

use strict;
use base qw(QQ::weixin::work::corpgroup);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ external_userid_to_pending_id /;

=head1 FUNCTION

=head2 external_userid_to_pending_id(access_token, hash);

external_userid查询pending_id
最后更新：2023/03/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97357>

=head3 请求说明：

external_userid的说明

external_userid是企业微信用于表示企业的外部联系人而设立的id，且满足以下条件
假设同一个微信用户属于多个下游企业的外部联系人
1.同一上游企业获取到不同企业的外部联系人的external_userid不一致。
2.不同一上游企业获取同一个企业的同一个外部联系人的external_userid也不一致。

pending_id的说明

pending_id主要用于关联微信unionid与外部联系人external_userid，可理解为临时外部联系人ID；
上游企业可通过此接口将微信unionid转为pending_id，当微信用户成为下游企业客户后，可使用上下游external_userid转pending_id接口将下游external_userid转换为pending_id，建立unionid => pending_id => external_userid的映射关系；
pending_id有效期90天，共享应用内唯一。

=head4 请求包结构体为：

	{
	  "chat_id":"xxxxxx",
	  "external_userid":["oAAAAAAA", "oBBBBB"]
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    external_userid	是	上游或下游企业外部联系人id，最多同时查询100个
	chat_id	否	群id，如果有传入该参数，则只检查群主是否在可见范围，同时会忽略在该群以外的external_userid。如果不传入该参数，则只检查客户跟进人是否在可见范围内。

=head4 权限说明：

调用该接口的应用必须是上下游共享的自建应用或代开发应用
应用需要具有客户联系权限
该客户的跟进人或其所在客户群群主必须在应用的可见范围之内
上游应用须调用过unionid转pending_id接口
上游和下游企业须认证或验证；若为代开发应用，服务商必须已认证

=head3 RETURN 返回结果：

	{
		"errcode":0,
		"errmsg":"ok",
		"result":[
			 {
				"external_userid":"oAAAAAAA",
				"pending_id":"pAAAAA"
			 },
			 {
				"external_userid":"oBBBBB",
				"pending_id":"pBBBBB"
			 }
		 ]
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	    出错返回码，为0表示成功，非0表示调用失败
    errmsg	对返回码的文本描述内容
    result	转换结果
	result.external_userid	转换的external_userid
	result.pending_id	该微信账号还未成为企业客户时，返回的临时外部联系人ID

=cut

sub external_userid_to_pending_id {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/batch/external_userid_to_pending_id?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
