package QQ::weixin::work::menu;

=encoding utf8

=head1 Name

QQ::weixin::work::menu

=head1 DESCRIPTION

应用管理-自定义菜单

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ create get delete /;

=head1 FUNCTION

=head2 create(access_token, agentid, hash);

创建菜单
最后更新：2021/03/18

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90231>

=head3 请求说明：

	自定义菜单接口可实现多种类型按钮，如下：

	字段值	功能名称	说明
	click	点击推事件	成员点击click类型按钮后，企业微信服务器会通过消息接口推送消息类型为event 的结构给开发者（参考消息接口指南），并且带上按钮中开发者填写的key值，开发者可以通过自定义的key值与成员进行交互；
	view	跳转URL	成员点击view类型按钮后，企业微信客户端将会打开开发者在按钮中填写的网页URL，可与网页授权获取成员基本信息接口结合，获得成员基本信息。
	scancode_push	扫码推事件	成员点击按钮后，企业微信客户端将调起扫一扫工具，完成扫码操作后显示扫描结果（如果是URL，将进入URL），且会将扫码的结果传给开发者，开发者可用于下发消息。
	scancode_waitmsg	扫码推事件 且弹出“消息接收中”提示框	成员点击按钮后，企业微信客户端将调起扫一扫工具，完成扫码操作后，将扫码的结果传给开发者，同时收起扫一扫工具，然后弹出“消息接收中”提示框，随后可能会收到开发者下发的消息。
	pic_sysphoto	弹出系统拍照发图	弹出系统拍照发图 成员点击按钮后，企业微信客户端将调起系统相机，完成拍照操作后，会将拍摄的相片发送给开发者，并推送事件给开发者，同时收起系统相机，随后可能会收到开发者下发的消息。
	pic_photo_or_album	弹出拍照或者相册发图	成员点击按钮后，企业微信客户端将弹出选择器供成员选择“拍照”或者“从手机相册选择”。成员选择后即走其他两种流程。
	pic_weixin	弹出企业微信相册发图器	成员点击按钮后，企业微信客户端将调起企业微信相册，完成选择操作后，将选择的相片发送给开发者的服务器，并推送事件给开发者，同时收起相册，随后可能会收到开发者下发的消息。
	location_select	弹出地理位置选择器	成员点击按钮后，企业微信客户端将调起地理位置选择工具，完成选择操作后，将选择的地理位置发送给开发者的服务器，同时收起位置选择工具，随后可能会收到开发者下发的消息。
	view_miniprogram	跳转到小程序	成员点击按钮后，企业微信客户端将会打开开发者在按钮中配置的小程序

=head4 请求包结构体为：

	示例：构造click和view类型的请求包如下

	{
	   "button":[
		   {    
			   "type":"click",
			   "name":"今日歌曲",
			   "key":"V1001_TODAY_MUSIC"
		   },
		   {
			   "name":"菜单",
			   "sub_button":[
				   {
					   "type":"view",
					   "name":"搜索",
					   "url":"http://www.soso.com/"
				   },
				   {
					   "type":"click",
					   "name":"赞一下我们",
					   "key":"V1001_GOOD"
				   }
			   ]
		  }
	   ]
	}
	示例：其他新增按钮类型的请求

	{
		"button": [
			{
				"name": "扫码", 
				"sub_button": [
					{
						"type": "scancode_waitmsg", 
						"name": "扫码带提示", 
						"key": "rselfmenu_0_0", 
						"sub_button": [ ]
					}, 
					{
						"type": "scancode_push", 
						"name": "扫码推事件", 
						"key": "rselfmenu_0_1", 
						"sub_button": [ ]
					},
					{
						"type":"view_miniprogram",
						"name":"小程序",
						"pagepath":"pages/lunar/index",
						"appid":"wx4389ji4kAAA"
					}
				]
			}, 
			{
				"name": "发图", 
				"sub_button": [
					{
						"type": "pic_sysphoto", 
						"name": "系统拍照发图", 
						"key": "rselfmenu_1_0", 
					   "sub_button": [ ]
					 }, 
					{
						"type": "pic_photo_or_album", 
						"name": "拍照或者相册发图", 
						"key": "rselfmenu_1_1", 
						"sub_button": [ ]
					}, 
					{
						"type": "pic_weixin", 
						"name": "微信相册发图", 
						"key": "rselfmenu_1_2", 
						"sub_button": [ ]
					}
				]
			}, 
			{
				"name": "发送位置", 
				"type": "location_select", 
				"key": "rselfmenu_2_0"
			}
		]
	}

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
最后更新：2019/02/28

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90232>

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
最后更新：2019/02/28

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
