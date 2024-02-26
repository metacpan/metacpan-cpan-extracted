package QQ::weixin::work::externalcontact::group_welcome_template;

=encoding utf8

=head1 Name

QQ::weixin::work::externalcontact::group_welcome_template

=head1 DESCRIPTION

入群欢迎语素材管理
最后更新：2023/12/01

=cut

use strict;
use base qw(QQ::weixin::work::externalcontact);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ add edit get del /;

=head1 FUNCTION

=head2 add(access_token, hash);

添加入群欢迎语素材

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92366#添加入群欢迎语素材>

=head3 请求说明：

企业可通过此API向企业的入群欢迎语素材库中添加素材。每个企业的入群欢迎语素材库中，最多容纳100个素材。

=head4 请求包结构体为：

    {
		"text": {
			"content": "亲爱的%NICKNAME%用户，你好"
		},
		"image": {
			"media_id": "MEDIA_ID",
			"pic_url": "http://p.qpic.cn/pic_wework/3474110808/7a6344sdadfwehe42060/0"
		},
		"link": {
			"title": "消息标题",
			"picurl": "https://example.pic.com/path",
			"desc": "消息描述",
			"url": "https://example.link.com/path"
		},
		"miniprogram": {
			"title": "消息标题",
			"pic_media_id": "MEDIA_ID",
			"appid": "wx8bd80126147dfAAA",
			"page": "/path/index"
		},
		"file": {
			"media_id": "1Yv-zXfHjSjU-7LH-GwtYqDGS-zz6w22KmWAT5COgP7o"
		},
		"video": {
			"media_id": "MEDIA_ID"
		},
		"agentid": 1000014,
		"notify": 1
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	text.content	否	消息文本内容,最长为3000字节
	image.media_id	否	图片的media_id，可以通过素材管理接口获得
	image.pic_url	否	图片的链接，仅可使用上传图片接口得到的链接
	link.title	是	图文消息标题，最长为128字节
	link.picurl	否	图文消息封面的url
	link.desc	否	图文消息的描述，最长为512字节
	link.url	是	图文消息的链接
	miniprogram.title	是	小程序消息标题，最长为64字节
	miniprogram.pic_media_id	是	小程序消息封面的mediaid，封面图建议尺寸为520*416
	miniprogram.appid	是	小程序appid，必须是关联到企业的小程序应用
	miniprogram.page	是	小程序page路径
	file.media_id	是	文件id，可以通过素材管理接口获得
	video.media_id	是	视频媒体文件id，可以通过素材管理接口获得
	agentid	否	授权方安装的应用agentid。仅旧的第三方多应用套件需要填此参数
	notify	否	是否通知成员将这条入群欢迎语应用到客户群中，0-不通知，1-通知， 不填则通知

text中支持配置多个%NICKNAME%(大小写敏感)形式的欢迎语，当配置了欢迎语占位符后，发送给客户时会自动替换为客户的昵称;
text、image、link、miniprogram、file、video不能全部为空；
text与其它消息类型可以同时发送，此时将会以两条消息的形式触达客户
text以外的消息类型，只能有一个，如果三者同时填，则按image、link、miniprogram、file、video的优先顺序取参。例如：image与link同时传值，则只有image生效。
图片消息中，media_id和pic_url只需填写一个，两者同时填写时使用media_id，二者不可同时为空。

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需具有“企业客户权限->客户联系->配置入群欢迎语素材”权限

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"template_id": "msgXXXXXX"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	template_id	欢迎语素材id

=cut

sub add {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/group_welcome_template/add?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 edit(access_token, hash);

编辑入群欢迎语素材

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92366#编辑入群欢迎语素材>

=head3 请求说明：

企业可通过此API编辑入群欢迎语素材库中的素材，且仅能够编辑调用方自己创建的入群欢迎语素材。

=head4 请求包结构体为：

    {
		"template_id": "msgXXXXXXX",
		"text": {
			"content": "文本消息内容"
		},
		"image": {
			"media_id": "MEDIA_ID",
			"pic_url": "http://p.qpic.cn/pic_wework/3474110808/7a6344sdadfwehe42060/0"
		},
		"link": {
			"title": "消息标题",
			"picurl": "https://example.pic.com/path",
			"desc": "消息描述",
			"url": "https://example.link.com/path"
		},
		"miniprogram": {
			"title": "消息标题",
			"pic_media_id": "MEDIA_ID",
			"appid": "wx8bd80126147df384",
			"page": "/path/index"
		},
		"file": {
			"media_id": "1Yv-zXfHjSjU-7LH-GwtYqDGS-zz6w22KmWAT5COgP7o"
		},
		"video": {
			"media_id": "MEDIA_ID"
		},
		"agentid": 1000014
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	template_id	是	欢迎语素材id
	text.content	否	消息文本内容,最长为4000字节
	image.media_id	否	图片的media_id，可以通过素材管理接口获得
	image.pic_url	否	图片的链接，仅可使用上传图片接口得到的链接
	link.title	是	图文消息标题，最长为128字节
	link.picurl	否	图文消息封面的url
	link.desc	否	图文消息的描述，最长为512字节
	link.url	是	图文消息的链接
	miniprogram.title	是	小程序消息标题，最长为64字节
	miniprogram.pic_media_id	是	小程序消息封面的mediaid，封面图建议尺寸为520*416
	miniprogram.appid	是	小程序appid，必须是关联到企业的小程序应用
	miniprogram.page	是	小程序page路径
	file.media_id	是	文件id，可以通过素材管理接口获得
	video.media_id	是	视频媒体文件id，可以通过素材管理接口获得
	agentid	否	授权方安装的应用agentid。仅旧的第三方多应用套件需要填此参数

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需具有“企业客户权限->客户联系->配置入群欢迎语素材”权限
仅可编辑本应用创建的入群欢迎语素材

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub edit {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/group_welcome_template/edit?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token, hash);

获取入群欢迎语素材

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92366#获取入群欢迎语素材>

=head3 请求说明：

企业可通过此API获取入群欢迎语素材。

=head4 请求包结构体为：

    {
		"template_id": "msgXXXXXXX"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	template_id	是	群欢迎语的素材id

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需具有“企业客户权限->客户联系->配置入群欢迎语素材”权限

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok",
		"text": {
			"content": "文本消息内容"
		},
		"image": {
			"pic_url": "http://p.qpic.cn/pic_wework/XXXXX"
		},
		"link": {
			"title": "消息标题",
			"picurl": "https://example.pic.com/path",
			"desc": "消息描述",
			"url": "https://example.link.com/path"
		},
		"miniprogram": {
			"title": "消息标题",
			"pic_media_id": "MEDIA_ID",
			"appid": "wx8bd80126147df384",
			"page": "/path/index"
		},
		"file": {
			"media_id": "1Yv-zXfHjSjU-7LH-GwtYqDGS-zz6w22KmWAT5COgP7o"
		},
		"video": {
			"media_id": "MEDIA_ID"
		}
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	text.content	消息文本内容
	image.pic_url	图片的url
	link.title	图文消息标题
	link.picurl	图文消息封面的url
	link.desc	图文消息的描述
	link.url	图文消息的链接
	miniprogram.title	小程序消息标题
	miniprogram.pic_media_id	小程序消息封面的mediaid
	miniprogram.appid	小程序appid
	miniprogram.page	小程序page路径
	file.media_id	文件id，可以通过素材管理接口获得
	video.media_id	视频媒体文件id，可以通过素材管理接口获得

=cut

sub get {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/group_welcome_template/get?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del(access_token, hash);

删除入群欢迎语素材

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92366#删除入群欢迎语素材>

=head3 请求说明：

企业可通过此API删除入群欢迎语素材，且仅能删除调用方自己创建的入群欢迎语素材。

=head4 请求包结构体为：

    {
		"template_id":"msgXXXXXXX",
		"agentid" : 1000014
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	template_id	是	群欢迎语的素材id
	agentid	否	授权方安装的应用agentid。仅旧的第三方多应用套件需要填此参数

=head4 权限说明：

企业需要使用配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）。
第三方应用需具有“企业客户权限->客户联系->配置入群欢迎语素材”权限
仅可删除本应用创建的入群欢迎语素材

=head3 RETURN 返回结果：

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub del {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/group_welcome_template/del?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
