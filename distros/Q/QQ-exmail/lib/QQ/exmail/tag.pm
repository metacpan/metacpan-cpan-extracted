package QQ::exmail::tag;

=encoding utf8

=head1 Name

QQ::exmail::tag

=head1 DESCRIPTION

通讯录管理->管理标签

=cut

use strict;
use base qw(QQ::exmail);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '1.10';
our @EXPORT = qw/ create update delete get addtagusers deltagusers list /;

=head1 FUNCTION

=head2 create(access_token, hash);

创建标签

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10050>

=head3 请求说明：

=head4 请求包结构体为：

    {
        "tagname": "UI",
        "tagid": 12
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    tagname	        是	标签名称，长度限制为32个字以内（汉字或英文字母），标签名不可与其他标签重名。
    tagid	        否	标签id，非负整型，指定此参数时新增的标签会生成对应的标签id，不指定时则以目前最大的id自增。

=head4 注意

标签总数不能超过3000个。

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "created",
       "tagid": 12
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    tagid	标签id

=cut

sub create {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/tag/create?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update(access_token, hash);

更新标签名字

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10051>

=head3 请求说明：

=head4 请求包结构体为：

    {
        "tagid": 12,
        "tagname": "UI"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    tagid	        是	标签ID
    tagname	        是	标签名称，长度限制为32个字（汉字或英文字母），标签不可与其他标签重名。

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "updated"
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

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/tag/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete(access_token, tagid);

删除标签

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10052>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    tagid	        是	标签ID

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "deleted"
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

=cut

sub delete {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $tagid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/tag/delete?access_token=$access_token&tagid=$tagid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token, tagid);

获取标签成员

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10053>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    tagid	        是	标签ID

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "ok",
       "tagname": "乒乓球协会",
       "userlist": [
            {
                "userid": "zhangsan@gz.com",
                "name": "李四"
            }
         ],
       "partylist": [2]
    }

=head4 RETURN 参数说明

    参数	        说明
    errcode	    返回码
    errmsg	    对返回码的文本描述内容
    tagname	    标签名
    userlist	标签中包含的成员列表
    userid	    成员UserID。企业邮帐号名，邮箱格式
    name	    成员名
    partylist	标签中包含的部门id列表

=cut

sub get {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $tagid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/tag/get?access_token=$access_token&tagid=$tagid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 addtagusers(access_token, hash);

增加标签成员

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10054>

=head3 请求说明：

=head4 请求包结构体为：

    {
        "tagid": 12,
        "userlist":[ "user1@gz.com","user2@gz.com"],
        "partylist": [4]
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    tagid	        是	标签ID
    userlist    	否	企业成员ID列表，邮箱格式，注意：userlist、partylist不能同时为空，单次请求长度不超过1000
    partylist	    否	企业部门ID列表，注意：userlist、partylist不能同时为空，单次请求长度不超过100

=head4 注意

每个标签下部门、人员总数不能超过3万个。

=head3 RETURN 返回结果

    a)正确时返回
    
    {
       "errcode": 0,
       "errmsg": "ok"
    }

    b)若部分userid、partylist非法，则返回
    
    {
        "errcode": 0,
        "errmsg": "ok",
        "invalidlist"："usr1@gz.com|usr2@gz.com|usr@gz.com",
        "invalidparty"：[2,4]
    }

    c)当包含userid、partylist全部非法时返回
    
    {
        "errcode": 40070,
        "errmsg": "all list invalid"
    }

=head4 RETURN 参数说明

    参数	            说明
    errcode	        返回码
    errmsg	        对返回码的文本描述内容
    invalidlist	    非法的成员帐号列表
    invalidparty	非法的部门id列表

=cut

sub addtagusers {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/tag/addtagusers?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 deltagusers(access_token, hash);

删除标签成员

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10055>

=head3 请求说明：

=head4 请求包结构体为：

    {
        "tagid": 12,
        "userlist":[ "user1@gz.com","user2@gz.com"],
        "partylist": [2,4]
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    tagid	        是	标签ID
    userlist	    否	企业成员ID列表，邮箱格式，注意：userlist、partylist不能同时为空
    partylist	    否	企业部门ID列表，注意：userlist、partylist不能同时为空

=head3 RETURN 返回结果

    a)正确时返回
    
    {
       "errcode": 0,
       "errmsg": "deleted"
    }

    b)若部分userid、partylist非法，则返回
    
    {
        "errcode": 0,
        "errmsg": "deleted",
        "invalidlist"："usr1@gz.com|usr2@gz.com|usr@gz.com",
        "invalidparty"：[2,4]
    }

    c)当包含userid、partylist全部非法时返回
    
    {
        "errcode": 40031,
        "errmsg": "all list invalid"
    }

=head4 RETURN 参数说明

    参数	            说明
    errcode	        返回码
    errmsg	        对返回码的文本描述内容
    invalidlist	    非法的成员帐号列表
    invalidparty	非法的部门id列表

=cut

sub deltagusers {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/tag/deltagusers?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token);

获取标签列表

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10056>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "ok",
       "taglist":[
          {"tagid":1,"tagname":"a"},
          {"tagid":2,"tagname":"b"}
       ]
    }

=head4 RETURN 参数说明
    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    taglist	标签列表
    tagid	标签id
    tagname	标签名

=cut

sub list {
    if ( @_ && $_[0] ) {
        my $access_token = $_[0];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/tag/list?access_token=$access_token");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
