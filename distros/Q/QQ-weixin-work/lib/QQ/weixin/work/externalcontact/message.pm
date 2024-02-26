package QQ::weixin::work::externalcontact::message;

=encoding utf8

=head1 Name

QQ::weixin::work::externalcontact::message

=head1 DESCRIPTION

家校消息推送

=cut

use strict;
use base qw(QQ::weixin::work::externalcontact);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ send /;

=head1 FUNCTION

=head2 send(access_token, hash);

发送「学校通知」
最后更新：2022/05/23

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/91609>

=head3 请求说明：

学校可以通过此接口来给家长发送不同类型的学校通知，来满足多种场景下的学校通知需求。目前支持的消息类型为文本、图片、语音、视频、文件、图文。

=head4 请求包结构体为：

=head4 参数说明：

	参数	是否必须	说明
	access_token	是	调用接口凭证

各个消息类型的具体POST格式参考以下文档。
支持id转译，将userid/部门id转成对应的企业通讯录内部的用户名/部门名，目前仅文本/图文/图文（mpnews）/小程序消息这四种消息类型的部分字段支持。具体支持的范围和语法，请查看附录id转译说明。
支持重复消息检查，当指定 "enable_duplicate_check": 1开启: 表示在一定时间间隔内，同样内容（请求json）的消息，不会重复收到；时间间隔可通过duplicate_check_interval指定，默认1800秒。

=head3 权限说明

学校管理员需要将应用配置在「家长可使用的应用」才可调用

=head3 RETURN 返回结果

	{
	  "errcode" : 0,
	  "errmsg" : "ok",
	  "invalid_parent_userid" : ["parent_userid1"],
	  "invalid_student_userid" : ["student_userid1"],
	  "invalid_party" : ["party1"]
	}

如果部分接收人无权限或不存在，发送仍然执行，但会返回无效的部分（invalid_parent_userid/invalid_student_userid/invalid_party）。

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
	errmsg	对返回码的文本描述内容

=cut

sub send {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/message/send?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
