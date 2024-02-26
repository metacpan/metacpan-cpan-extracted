package QQ::weixin::work::kf::servicer;

=encoding utf8

=head1 Name

QQ::weixin::work::kf::servicer

=head1 DESCRIPTION

微信客服->接待人员管理

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

添加接待人员
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94646>

=head3 请求说明：

添加指定客服账号的接待人员，每个客服账号目前最多可添加2000个接待人员，20个部门。

=head4 请求包结构体为：

	{
		"open_kfid": "kfxxxxxxxxxxxxxx",
		"userid_list": ["zhangsan", "lisi"],
		"department_id_list": [2, 4]
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	调用接口凭证
	open_kfid	是	客服帐号ID
	userid_list	否	接待人员userid列表。第三方应用填密文userid，即open_userid
					可填充个数：0 ~ 100。超过100个需分批调用。
	department_id_list	否	接待人员部门id列表
							可填充个数：0 ~ 100。超过100个需分批调用。

userid_list和department_id_list至少需要填其中一个

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
		"errmsg": "ok",
		"result_list": [
			{
				"userid": "zhangsan",
				"errcode": 0,
				"errmsg": "success"
			},
			{
				"userid": "lisi",
				"errcode": 0,
				"errmsg": "ignored"
			},
			{
				"department_id": 2,
				"errcode": 0,
				"errmsg": "success"
			},
			{
				"department_id": 3,
				"errcode": 0,
				"errmsg": "ignored"
			}
		]
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	result_list	arrary	操作结果
	result_list.userid	string	接待人员的userid
	result_list.department_id	int	接待人员部门的id
	result_list.errcode	int	该userid的添加结果
	result_list.errmsg	string	结果信息

=cut

sub add {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/servicer/add?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del(access_token, hash);

删除接待人员
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94647>

=head3 请求说明：

从客服帐号删除接待人员

=head4 请求包结构体为：

	{
		"open_kfid": "kfxxxxxxxxxxxxxx",
		"userid_list": ["zhangsan", "lisi"],
		"department_id_list": [2, 4]
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	调用接口凭证
	open_kfid	是	客服帐号ID
	userid_list	否	接待人员userid列表。第三方应用填密文userid，即open_userid
					可填充个数：0 ~ 100。超过100个需分批调用。
	department_id_list	否	接待人员部门id列表
							可填充个数：0 ~ 100。超过100个需分批调用。

userid_list和departmentid_list至少需要填其中一个

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
		"errmsg": "ok",
		"result_list": [
			{
				"userid": "zhangsan",
				"errcode": 0,
				"errmsg": "success"
			},
			{
				"userid": "lisi",
				"errcode": 0,
				"errmsg": "ignored"
			},
			{
				"department_id": 2,
				"errcode": 0,
				"errmsg": "success"
			},
			{
				"department_id": 3,
				"errcode": 0,
				"errmsg": "ignored"
			}
		]
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	result_list	arrary	操作结果
	result_list.userid	string	接待人员的userid
	result_list.department_id	int	接待人员部门的id
	result_list.errcode	int	该userid的删除结果
	result_list.errmsg	string	结果信息

=cut

sub del {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/servicer/del?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token);

获取接待人员列表
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94645>

=head3 请求说明：

获取某个客服帐号的接待人员列表

=head4 参数说明：

	参数	必须	说明
	access_token	是	调用接口凭证
	open_kfid	是	客服帐号ID

=head3 权限说明

调用的应用需要满足如下的权限

	应用类型	权限要求
	自建应用	配置到「 微信客服- 可调用接口的应用」中
	第三方应用	具有“微信客服权限->获取基础信息”权限
	代开发自建应用	具有“微信客服权限->获取基础信息”权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

操作的客服账号对应的接待人员应在应用的可见范围内

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"servicer_list": [
			{
				"userid": "zhangsan",
				"status": 0
			},
			{
				"userid": "lisi",
				"status": 1
			},
			{
				"department_id": 2
			},
			{
				"department_id": 3
			}
		]
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	servicer_list	arrary	客服账号的接待人员列表
	servicer_list.userid	string	接待人员的userid。第三方应用获取到的为密文userid，即open_userid
	servicer_list.status	uint	接待人员的接待状态。0:接待中,1:停止接待。
									注：企业内部开发，需有该客服账号的管理权限；第三方/代开发应用需具有“管理账号、分配会话和收发消息”权限，且有该客服账号的管理权限，才可获取
	servicer_list.stop_type	uint	接待人员的接待状态为「停止接待」的子类型。0:停止接待,1:暂时挂起
	servicer_list.department_id	uint	接待人员部门的id

=cut

sub list {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $open_kfid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/kf/account/list?access_token=$access_token&open_kfid=$open_kfid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
