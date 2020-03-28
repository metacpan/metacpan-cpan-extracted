package QQ::weixin::work::appchat;

=encoding utf8

=head1 Name

QQ::weixin::work::appchat

=head1 DESCRIPTION

发送消息到群聊会话

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.04';
our @EXPORT = qw/ create update get send /;

=head1 FUNCTION

=head2 create(access_token, hash);

创建群聊会话

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90245>

=head3 请求说明：

=head4 请求包结构体为：

  {
    "name" : "NAME",
    "owner" : "userid1",
    "userlist" : ["userid1", "userid2", "userid3"],
    "chatid" : "CHATID"
  }

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
    name	否	群聊名，最多50个utf8字符，超过将截断
    owner	否	指定群主的id。如果不指定，系统会随机从userlist中选一人作为群主
    userlist	是	群成员id列表。至少2人，至多500人
    chatid	否	群聊的唯一标志，不能与已有的群重复；字符串类型，最长32个字符。只允许字符0-9及字母a-zA-Z。如果不填，系统会随机生成群id

=head3 权限说明

只允许企业自建应用调用，且应用的可见范围必须是根部门；
群成员人数不可超过管理端配置的“群成员人数上限”，且最大不可超过500人；
每企业创建群数不可超过1000/天；

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
      "chatid" : "CHATID"
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    chatid	群聊的唯一标志

=cut

sub create {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/appchat/create?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update(access_token, hash);

修改群聊会话

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90246>

=head3 请求说明：

=head4 请求包结构体为：

  {
    "chatid" : "CHATID",
    "name" : "NAME",
    "owner" : "userid2",
    "add_user_list" : ["userid1", "userid2", "userid3"],
    "del_user_list" : ["userid3", "userid4"]
  }

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
    chatid	是	群聊id
    name	否	新的群聊名。若不需更新，请忽略此参数。最多50个utf8字符，超过将截断
    owner	否	新群主的id。若不需更新，请忽略此参数
    add_user_list	否	添加成员的id列表
    del_user_list	否	踢出成员的id列表

=head3 权限说明

只允许企业自建应用调用，且应用的可见范围必须是根部门；
chatid所代表的群必须是该应用所创建；
群成员人数不可超过500人；
每企业变更群的次数不可超过100/小时；

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

sub update {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/appchat/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token, chatid);

获取群聊会话

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90247>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    chatid	是	群聊id

=head4 权限说明：

只允许企业自建应用调用，且应用的可见范围必须是根部门；
chatid所代表的群必须是该应用所创建；
第三方不可调用。

=head3 RETURN 返回结果：

    {
       "errcode" : 0,
       "errmsg" : "ok"
       "chat_info" : {
          "chatid" : "CHATID",
          "name" : "NAME",
          "owner" : "userid2",
          "userlist" : ["userid1", "userid2", "userid3"]
       }
     }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    chat_info	群聊信息
    chatid	群聊唯一标志
    name	群聊名
    owner	群主id
    userlist	群成员id列表

=cut

sub get {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $chatid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/appchat/get?access_token=$access_token&chatid=$chatid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 send(access_token, hash);

应用推送消息

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90248>

=head3 请求说明：

=head4 请求包结构体为：

    参数	            必须	说明
    access_token	是	调用接口凭证

=head4 参数说明：

=head3 权限说明

只允许企业自建应用调用，且应用的可见范围必须是根部门；
chatid所代表的群必须是该应用所创建；
每企业消息发送量不可超过2万人次/分，不可超过20万人次/小时（若群有100人，每发一次消息算100人次）；
每个成员在群中收到的应用消息不可超过200条/分，1万条/天，超过会被丢弃（接口不会报错）；

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

sub send {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/appchat/send?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
