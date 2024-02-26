package QQ::weixin::work::kf::service_state;

=encoding utf8

=head1 Name

QQ::weixin::work::kf::service_state

=head1 DESCRIPTION

微信客服->会话分配与消息收发->分配客服会话
最后更新：2023/11/30

=cut

use strict;
use base qw(QQ::weixin::work::kf);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ get trans /;

=head1 FUNCTION

=head2 get(access_token, hash);

获取会话状态

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94669#获取会话状态>

=head3 请求说明：

=head4 请求包结构体为：

    {
		"open_kfid": "wkxxxxxxxxxxxxxxxxxx",
		"external_userid": "wmxxxxxxxxxxxxxxxxxx"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	调用接口凭证
	open_kfid	是	客服帐号ID
	external_userid	是	微信客户的external_userid

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
		"service_state": 3,
		"servicer_userid": "zhangsan"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	service_state	int	当前的会话状态，状态定义参考概述中的表格
	servicer_userid	string	接待人员的userid。第三方应用为密文userid，即open_userid。仅当state=3时有效

=cut

sub get {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/service_state/get?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 trans(access_token, hash);

变更会话状态

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/94669#变更会话状态>

=head3 请求说明：

=head4 请求包结构体为：

    {
		"open_kfid": "wkxxxxxxxxxxxxxxxxxx",
		"external_userid": "wmxxxxxxxxxxxxxxxxxx",
		"service_state": 3,
		"servicer_userid": "zhangsan"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	调用接口凭证
	open_kfid	是	客服账号ID
	external_userid	是	微信客户的external_userid
	service_state	是	变更的目标状态，状态定义和所允许的变更可参考概述中的流程图和表格
	servicer_userid	否	接待人员的userid。第三方应用填密文userid，即open_userid。当state=3时要求必填，接待人员须处于“正在接待”中。
						注意：要求接待人员必须在企业微信激活使用，否则会返回95014错误。

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
		"msg_code": "MSG_CODE"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	msg_code	string	用于发送响应事件消息的code，将会话初次变更为service_state为2和3时，返回回复语code，service_state为4时，返回结束语code。
						可用该code调用发送事件响应消息接口给客户发送事件响应消息

=cut

sub trans {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/service_state/trans?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}



1;
__END__
