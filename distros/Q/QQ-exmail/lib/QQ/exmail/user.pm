package QQ::exmail::user;

=encoding utf8

=head1 Name

QQ::exmail::user

=head1 DESCRIPTION

通讯录管理->管理成员

=cut

use strict;
use base qw(QQ::exmail);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '1.10';
our @EXPORT = qw/ create update delete get simplelist list batchcheck /;

=head1 FUNCTION

=head2 create(access_token, hash);

创建成员

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10014>

=head3 请求说明：

=head4 请求包结构体为：

    {
       	"userid": "zhangsan@gzdev.com",
       	"name": "张三",
       	"department": [1, 2],
       	"position": "产品经理",
       	"mobile": "15913215XXX",
       	"tel": "123456",
       	"extid": "01",
       	"gender": "1",
    　 	"slaves": ["zhangsan@gz.com", "zhangsan@bjdev.com"],
    	"password":"******",
    	"cpwd_login":0
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	        是	成员UserID。企业邮帐号名，邮箱格式
    name	        是	成员名称。长度为1~64个字节
    department	    是	成员所属部门id列表，不超过20个
    position	    否	职位信息。长度为0~64个字节
    mobile	        否	手机号码
    tel	            否	座机号码
    extid	        否	编号
    gender	        否	性别。1表示男性，2表示女性
    slaves	        否	别名列表
                        1.Slaves 上限为5个
                        2.Slaves 为邮箱格式
    password	    是	英文和数字
    cpwd_login	    否	用户重新登录时是否重设密码, 登陆重设密码后，该标志位还原。0表示否，1表示是，缺省为0

=head3 权限说明

系统应用须拥有指定部门的管理权限。

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "created"
    }

=head3 RETURN 参数说明

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

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/user/create?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update(access_token, hash);

更新成员

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10015>

=head3 请求说明：

=head4 请求包示例如下（如果非必须的字段未指定，则不更新该字段之前的设置值）:

    {
       "userid": " zhangsan@gzdev.com ",
       "name": "张三",
       "department": [1, 2],
       "position": "产品经理",
       "mobile": "15913215421",
       "gender": "1",
       "enable": 1,
       "password":"******",
       "cpwd_login":1
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	        是	成员UserID。企业邮帐号名，邮箱格式
    name	        否	成员名称。长度为0~64个字节
    department	    否	成员所属部门id列表，不超过20个
    position	    否	职位信息。长度为0~64个字节
    mobile	        否	手机号码
    tel	            否	座机号码
    extid	        否	编号
    gender	        否	性别。1表示男性，2表示女性
    slaves	        否	别名列表
                        1.Slaves 上限为5个
                        2.Slaves 为邮箱格式
    enable	        否	启用/禁用成员。1表示启用成员，0表示禁用成员
    password	    否	密码
    cpwd_login	    否	用户重新登录时是否重设密码, 登陆重设密码后，该标志位还原。0表示否，1表示是，缺省为0

=head3 权限说明

系统应用须拥有指定部门、成员的管理权限。

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "updated"
    }

=head3 RETURN 参数说明

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

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/user/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete(access_token, userid);

删除成员

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10016>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	        是	成员UserID。企业邮帐号名，邮箱格式

=head3 权限说明

系统应用须拥有指定成员的管理权限。

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
        my $userid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/user/delete?access_token=$access_token&userid=$userid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token, userid);

获取成员

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10017>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	        是	成员UserID

=head3 权限说明

系统应用须拥有指定成员的查看权限。

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "ok",
       "userid": " zhangsan@gzdev.com ",
       "name": "李四",
       "department": [1, 2],
       "position": "后台工程师",
       "mobile": "15913215421",
       "gender": "1",
       "enable": 1,
       "slaves":[ zhangsan@gz.com, zhangsan@bjdev.com],
       "cpwd_login":0
    }

=head4 RETURN 参数说明

    参数	        说明
    errcode	    返回码
    errmsg	    对返回码的文本描述内容
    userid	    成员UserID
    name	    成员名称
    department	成员所属部门id列表
    position	职位信息
    mobile	    手机号码
    tel	        座机号码
    extid	    编号
    gender	    性别。0表示未定义，1表示男性，2表示女性
    enable	    启用/禁用成员。1表示启用成员，0表示禁用成员
    slaves	    别名列表
                1、Slaves上限为5个
                2、Slaves为邮箱格式
    cpwd_login	用户重新登录时是否重设密码, 登陆重设密码后，该标志位还原。0表示否，1表示是，缺省为0

=cut

sub get {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $userid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/user/get?access_token=$access_token&userid=$userid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 simplelist(access_token, department_id, fetch_child);

获取部门成员

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10018>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    department_id	是	获取的部门id。id为1时可获取根部门下的成员
    fetch_child	    否	1/0：是否递归获取子部门下面的成员

=head3 权限说明

系统应用须拥有指定部门的查看权限。

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
    	"userlist": [
            {
            	"userid": "zhangsan@gzdev.com",
            	"name": "李四",
            	"t": [1, 2]
            }
        ]
    }

=head4 RETURN 参数说明

    参数	        说明
    errcode	    返回码
    errmsg	    对返回码的文本描述内容
    userlist	成员列表
    userid	    成员UserID
    name	    成员名称
    department	成员所属部门

=cut

sub simplelist {
    if ( @_ && $_[0] && $_[1] && $_[2] ) {
        my $access_token = $_[0];
        my $department_id = $_[1];
        my $fetch_child = $_[2];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/user/simplelist?access_token=$access_token&department_id=$department_id&fetch_child=$fetch_child");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token, department_id, fetch_child);

获取部门成员（详情）

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10019>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    department_id	是	获取的部门id。id为1时可获取根部门下的成员
    fetch_child	    否	1/0：是否递归获取子部门下面的成员

=head3 权限说明

系统应用须拥有指定部门的查看权限。

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok",
        "userlist": [
            {
                "userid": "zhangsan@gzdev.com",
                "name": "李四",
                "department": [1, 2],
                "position": "后台工程师",
                "tel": "60000",
                "mobile": "15913215421",
                "extid": "123456789",
                "gender": "1",
                "enable": "1",
                "slaves": ["zhangsan@gz.com", "zhangsan@bjdev.com"],
                "cpwd_login": 0
            }
        ]
    }

=head4 RETURN 参数说明

    参数	        说明
    errcode	    返回码
    errmsg	    对返回码的文本描述内容
    userlist	成员列表
    userid	    成员UserID。企业邮帐号名，邮箱格式
    name	    成员名称
    department	成员所属部门id列表
    position	职位信息
    mobile	    手机号码
    tel	        座机号码
    extid	    编号
    gender	    性别。0表示未定义，1表示男性，2表示女性
    slaves	    别名列表
                1、Slaves上限为5个
                2、Slaves为邮箱格式
    cpwd_login	用户重新登录时是否重设密码, 登陆重设密码后，该标志位还原。0表示否，1表示是，缺省为0。

=cut

sub list {
    if ( @_ && $_[0] && $_[1] && $_[2] ) {
        my $access_token = $_[0];
        my $department_id = $_[1];
        my $fetch_child = $_[2];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/user/list?access_token=$access_token&department_id=$department_id&fetch_child=$fetch_child");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 batchcheck(access_token, hash);

批量检查账号

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10020>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"userlist": ["zhangsan@bjdev.com", "zhangsangroup@shdev.com"]
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userlist	    是	成员帐号，每次检查不得超过20个

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok",
        "list": [
            {"user":"zhangsan@bjdev.com", "type":1},
            {"user":"zhangsangroup@shdev.com", "type":3}
        ]
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    list	列表数据
    user	成员帐号
    type	帐号类型。-1:帐号号无效; 0:帐号名未被占用; 1:主帐号; 2:别名帐号; 3:邮件群组帐号

=cut

sub batchcheck {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/user/batchcheck?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
