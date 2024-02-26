package QQ::weixin::work::kf::account;

=encoding utf8

=head1 Name

QQ::weixin::work::kf::account

=head1 DESCRIPTION

客服账号管理

=cut

use strict;
use base qw(QQ::weixin::work::kf);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ add del update list /;

=head1 FUNCTION

=head2 add(access_token, hash);

添加客服帐号
最后更新：2023/12/05

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94662>

=head3 请求说明：

添加客服账号，并可设置客服名称和头像。目前一家企业最多可添加5000个客服账号。

=head4 请求包结构体为：

    {
		"name": "新建的客服帐号",
		"media_id": "294DpAog3YA5b9rTK4PjjfRfYLO0L5qpDHAJIzhhQ2jAEWjb9i661Q4lk8oFnPtmj"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	name	是	string	客服名称
						不多于16个字符
	media_id	是	string	客服头像临时素材。可以调用上传临时素材接口获取。
							不多于128个字节

=head3 权限说明

调用的应用需要满足如下的权限

	应用类型	权限要求
	自建应用	配置到「 微信客服- 可调用接口的应用」中，且在管理后台「通过API管理会话消息」-「企业内部开发」对应的自建应用的「可管理的客服账号」处，配置至少一个客服账号
	第三方应用	具有“微信客服->管理账号、分配会话和收发消息”权限
	代开发自建应用	具有“微信客服->管理账号、分配会话和收发消息”权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

通过接口创建的客服账号，将自动拥有该客服账号的管理权限。企业可在管理后台“微信客服-通过API管理微信客服账号”处设置对应的客服账号通过API来管理。

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"open_kfid": "wkAJ2GCAAAZSfhHCt7IFSvLKtMPxyJTw"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	open_kfid	string	新创建的客服帐号ID

=cut

sub add {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/account/add?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del(access_token, hash);

删除客服账号
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94663>

=head3 请求说明：

删除已有的客服帐号

=head4 请求包结构体为：

    {
		"open_kfid": "wkAJ2GCAAAZSfhHCt7IFSvLKtMPxyJTw"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	open_kfid	是	string	客服帐号ID。
							不多于64字节

=head3 权限说明

调用的应用需要满足如下的权限

	应用类型	权限要求
	自建应用	配置到「 微信客服- 可调用接口的应用」中
	第三方应用	具有“微信客服->管理账号、分配会话和收发消息”权限
	代开发自建应用	具有“微信客服->管理账号、分配会话和收发消息”权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

只能通过API管理企业指定的客服账号。企业可在管理后台“微信客服-通过API管理微信客服账号”处设置对应的客服账号通过API来管理。
操作的客服账号对应的接待人员应在应用的可见范围内

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=cut

sub del {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/account/del?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update(access_token, hash);

修改客服帐号
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94664>

=head3 请求说明：

修改已有的客服帐号，可修改客服名称和头像。

=head4 请求包结构体为：

    {
		"open_kfid": "wkAJ2GCAAAZSfhHCt7IFSvLKtMPxyJTw",
		"name": "修改客服名",
		"media_id": "294DpAog3YA5b9rTK4PjjfRfYLO0L5qpDHAJIzhhQ2jAEWjb9i661Q4lk8oFnPtmj"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	open_kfid	是	string	要修改的客服帐号ID。
							不多于64字节
	name	否	string	新的客服名称，如不需要修改可不填。
						不多于16个字符
	media_id	否	string	新的客服头像临时素材，如不需要修改可不填。可以调用上传临时素材接口获取。
							不多于128个字节

=head3 权限说明

调用的应用需要满足如下的权限

	应用类型	权限要求
	自建应用	配置到「 微信客服- 可调用接口的应用」中
	第三方应用	具有“微信客服->管理账号、分配会话和收发消息”权限
	代开发自建应用	具有“微信客服->管理账号、分配会话和收发消息”权限

只能通过API管理企业指定的客服账号。企业可在管理后台“微信客服-通过API管理微信客服账号”处设置对应的客服账号通过API来管理。
操作的客服账号对应的接待人员应在应用的可见范围内
注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=cut

sub update {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/account/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token);

获取客服帐号列表
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94661>

=head3 请求说明：

获取客服帐号列表，包括所有的客服帐号的客服ID、名称和头像。

=head4 请求包结构体为：

	{
		"offset": 0,
		"limit": 100
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	offset	否	uint32	分页，偏移量, 默认为0
	limit	否	uint32	分页，预期请求的数据量，默认为100，取值范围 1 ~ 100

=head3 权限说明

调用的应用需要满足如下的权限

	应用类型	权限要求
	自建应用	配置到「 微信客服- 可调用接口的应用」中
	第三方应用	具有“微信客服->获取基础信息”权限
	代开发自建应用	具有“微信客服->获取基础信息”权限
	微信客服组件应用	具有“管理接入的微信客服->获取企业授权接入的客服账号->客服账号信息与链接”权限，仅可获取企业已授权的客服账号

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"account_list": [
			{
				"open_kfid": "wkAJ2GCAAASSm4_FhToWMFea0xAFfd3Q",
				"name": "咨询客服",
				"avatar": "https://wework.qpic.cn/wwhead/duc2TvpEgSSjibPZlNR6chpx9W3dtd9Ogp8XEmSNKGa6uufMWn2239HUPuwIFoYYZ7Ph580FPvo8/0",
				"manage_privilege": false
			}
		]
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	account_list	obj[]	账号信息列表
	account_list.open_kfid	string	客服账号ID
	account_list.name	string	客服名称
	account_list.avatar	string	客服头像URL
	account_list.manage_privilege	bool	当前调用接口的应用身份，是否有该客服账号的管理权限（编辑客服账号信息、分配会话和收发消息）。组件应用不返回此字段

=cut

sub list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/account/list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
