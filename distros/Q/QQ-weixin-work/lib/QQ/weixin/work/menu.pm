package QQ::weixin::work::menu;

=encoding utf8

=head1 Name

QQ::weixin::work::menu

=head1 DESCRIPTION

应用管理

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.04';
our @EXPORT = qw/ create get delete /;

=head1 FUNCTION

=head2 create(access_token, agentid, hash);

设置应用

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90231>

=head3 请求说明：

=head4 请求包结构体为：

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
    agentid	是	企业应用的id
    button	是	一级菜单数组，个数应为1~3个
    sub_button	否	二级菜单数组，个数应为1~5个
    type	是	菜单的响应动作类型
    name	是	菜单的名字。不能为空，主菜单不能超过16字节，子菜单不能超过40字节。
    key	click等点击类型必须	菜单KEY值，用于消息接口推送，不超过128字节
    url	view类型必须	网页链接，成员点击菜单可打开链接，不超过1024字节。为了提高安全性，建议使用https的url
    pagepath	view_miniprogram类型必须	小程序的页面路径
    appid	view_miniprogram类型必须	小程序的appid（仅与企业绑定的小程序可配置）

=head3 权限说明

仅企业可调用；第三方不可调用。

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok"
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

=cut

sub create {
    if ( @_ && $_[0] && $_[1] && ref $_[2] eq 'HASH' ) {
        my $access_token = $_[0];
        my $agentid = $_[1];
        my $json = $_[2];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/menu/create?access_token=$access_token&agentid=$agentid",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token,agentid);

获取菜单

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90232>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    agentid	是	应用id

=head4 权限说明：

仅企业可调用；第三方不可调用。

=head3 RETURN 返回结果：

返回结果与请参考菜单创建接口

=cut

sub get {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $agentid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/menu/get?access_token=$access_token&agentid=$agentid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete(access_token,agentid);

删除菜单

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90233>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    agentid	是	应用id

=head4 权限说明：

仅企业可调用；第三方不可调用。

=head3 RETURN 返回结果：

  {
    "errcode":0,
    "errmsg":"ok"
  }

=cut

sub delete {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $agentid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/menu/delete?access_token=$access_token&agentid=$agentid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
