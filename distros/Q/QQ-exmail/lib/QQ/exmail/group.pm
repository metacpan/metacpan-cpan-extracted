package QQ::exmail::group;

=encoding utf8

=head1 Name

QQ::exmail::group

=head1 DESCRIPTION

通讯录管理->管理邮件群组

=cut

use strict;
use base qw(QQ::exmail);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '1.10';
our @EXPORT = qw/ create update delete get /;

=head1 FUNCTION

=head2 create(access_token, hash);

创建邮件群组

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10022>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"groupid": "zhangsangroup@gzdev.com",
    	"groupname": "zhangsangroup ,
    	"userlist": ["zhangsanp@gzdev.com", "lisi@gzdev.com"],
    	"grouplist": ["group@gzdev.com"],
    	"department": [1, 2],
    	"allow_type": 4,
    	"allow_userlist": ["zhangsanp@gzdev.com"]
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    groupid	        是	邮件群组名称
    groupname	    是	邮件群组名称
    userlist	    否	成员帐号，userlist，grouplist，department至少一个。成员由userlist，grouplist，department共同组成
    grouplist	    否	成员邮件群组，userlist，grouplist，department至少一个。成员由userlist，grouplist，department共同组成
    department	    否	成员部门，userlist，grouplist，department至少一个。成员由userlist，grouplist，department共同组成
    allow_type	    是	群发权限。0: 企业成员, 1任何人， 2:组内成员，3:指定成员
    allow_userlist	否	群发权限为指定成员时，需要指定成员

=head3 权限说明

系统应用须拥有邮件群组的写管理权限。

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "created"
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

=cut

sub create {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/group/create?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update(access_token, hash);

更新邮件群组

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10023>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"groupid": "zhangsangroup@gzdev.com",
    	"groupname": "zhangsangroup",
    	"userlist": ["zhangsanp@gzdev.com","lisi@gzdev.com"],
    	"grouplist": ["group@gzdev.com"],
    	"department":[1,2],
    	"allow_type":3,
    	"allow_userlist":["zhangsanp@gzdev.com"]
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    groupid	        是	邮件群组id，邮件格式
    groupname	    否	邮件群组名称
    userlist	    否	成员帐号，userlist，grouplist，department至少一个。成员由userlist，grouplist，department共同组成
    grouplist	    否	成员邮件群组，userlist，grouplist，department至少一个。成员由userlist，grouplist，department共同组成
    department	    否	成员部门，userlist，grouplist，department至少一个。成员由userlist，grouplist，department共同组成
    allow_type	    否	群发权限。0: 企业成员,1任何人，2:组内成员，3:指定成员
    allow_userlist	否	群发权限为指定成员时，需要指定成员

=head3 权限说明

系统应用须拥有邮件群组的写管理权限。

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

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/group/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete(access_token, groupid);

删除邮件群组

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10024>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    groupid	        是	邮件群组id，邮件格式
    权限说明
    系统应用须拥有邮件群组的写管理权限

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
        my $groupid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/group/delete?access_token=$access_token&groupid=$groupid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token, groupid);

获取邮件群组信息

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10025>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    groupid	        是	邮件群组id，邮件格式

=head3 权限说明

系统应用须拥有邮件群组的读权限

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok",
        "groupid": "zhangsangroup@gzdev.com",
        "groupname": "zhangsangroup",
        "userlist": ["zhangsanp@gzdev.com", "lisi@gzdev.com"],　
        "grouplist": [" group@gzdev.com "],
        "department": [1, 2],
        "allow_type": 3,
        "allow_userlist": ["zhangsanp@gzdev.com"]
    }

=head4 RETURN 参数说明

    参数	            说明
    errcode	        返回码
    errmsg	        对返回码的文本描述内容
    groupid	        邮件群组id，邮件格式
    groupname	    邮件群组名称
    userlist	    成员帐号
    grouplist	    成员邮件群组
    department	    成员部门
    allow_type	    群发权限。0: 企业成员, 1任何人， 2:组内成员，3:指定成员
    allow_userlist	群发权限为指定成员时，需要指定成员，否则赋值失效

=cut

sub get {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $groupid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/group/get?access_token=$access_token&groupid=$groupid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
