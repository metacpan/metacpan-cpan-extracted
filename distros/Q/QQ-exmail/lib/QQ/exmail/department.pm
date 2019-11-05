package QQ::exmail::department;

=pod

=encoding utf8

=head1 Name

QQ::exmail::department

=head1 DESCRIPTION

通讯录管理->管理部门

=cut

use strict;
use base qw(QQ::exmail);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '1.10';
our @EXPORT = qw/ create update delete list search /;

=head1 FUNCTION

=head2 create(access_token, hash);

创建部门

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10008>

=head3 请求说明

=head4 请求包结构体为：

    {
       "name": "广州研发中心",
       "parentid": 1,
       "order": 0
    }

=head4 参数说明

    参数	            必须	说明
    access_token	是	调用接口凭证
    name	        是	部门名称。长度限制为1~64个字节，字符不能包括\:*?"<>｜
    parentid	    是	父部门id。id为1可表示根部门
    order	        否	在父部门中的次序值。order值小的排序靠前，1-10000为保留值，若使用保留值，将被强制重置为0。

=head3 权限说明

系统应用须拥有父部门的管理权限。

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "created",
       "id": 2
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    id	    创建的部门id。id为64位整型数

=cut

sub create {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/department/create?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update(access_token, hash);

更新部门

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10009>

=head3 请求说明：

=head4 请求包结构体为（如果非必须的字段未指定，则不更新该字段之前的设置值）:

    {
       "id": 2,
       "name": "广州研发中心",
       "parentid": 1,
       "order": 0
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    id	            是	部门id
    name	        否	更新的部门名称。长度限制为1~64个字节，字符不能包括\:*?"<>｜。修改部门名称时指定该参数
    parentid	    否	父部门id。id为1可表示根部门
    order	        否	在父部门中的次序值。order值小的排序靠前，1-10000为保留值，若使用保留值，将被强制重置为0。

=head3 权限说明

    系统应用须拥有指定部门的管理权限。

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

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/department/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete(access_token, id);

删除部门  

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10010>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    id	            是	部门id。（注：不能删除根部门；不能删除含有子部门、成员的部门）

=head4 权限说明

    系统应用须拥有指定部门的管理权限。

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
        my $id = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/department/delete?access_token=$access_token&id=$id");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token, id);

获取部门列表  

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10011>

=head3 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    id	            否	部门id。获取指定部门及其下的子部门。id为1时可获取根部门下的子部门。

=head3 权限说明

系统应用须拥有指定部门的查看权限。

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "ok",
       "department": [{
               "id": 2,
               "name": "广州研发中心",
               "parentid": 1,
               "order": 10
           },
           {
               "id": 3
               "name": "邮箱产品部",
               "parentid": 2,
               "order": 40
           }
        ]
    }

=head4 RETURN 参数说明

    参数	        说明
    errcode	    返回码
    errmsg	    对返回码的文本描述内容
    department	部门列表数据。以部门的order字段从小到大排列
    id	        部门id
    name	    部门名称
    parentid	父部门id。
    order	    在父部门中的次序值。order值小的排序靠前

=cut

sub list {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $id = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://api.exmail.qq.com/cgi-bin/department/list?access_token=$access_token&id=$id");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 search(access_token, hash);

查找部门  

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10012>

=head3 请求说明：

=head4 请求包结构体为：

    {
       "name": "邮箱产品部",
       "fuzzy": 0,
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    name	        否	查找的部门名字，必须合法
    fuzzy	        否	1/0：是否模糊匹配

=head3 权限说明

系统应用须拥有指定部门的查看权限。

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "ok",
       "department": [
           {
               "id": 3
               "name": "邮箱产品部",
               "parentid": 2,
               "order": 40,
               "path":"广州研发中心/邮箱产品部"
           },
           {
               "id": 10
               "name": "邮箱产品部",
               "parentid": 6,
               "order": 40,
               "path":"深圳研发中心/邮箱产品部"
           }
       ]
    }

=head4 RETURN 参数说明

    参数	        说明
    errcode	    返回码
    errmsg	    对返回码的文本描述内容
    department	部门列表数据。以部门的order字段从小到大排列
    id	        部门id
    name	    部门名称
    parentid	父部门id。根部门为0
    order	    在父部门中的次序值。order值小的排序靠前。
    path	    部门路径，部门用’/ ’作分割符

=cut

sub search {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/department/search?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
