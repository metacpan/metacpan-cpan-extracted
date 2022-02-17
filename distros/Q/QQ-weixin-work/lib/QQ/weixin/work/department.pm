package QQ::weixin::work::department;

=pod

=encoding utf8

=head1 Name

QQ::weixin::work::department

=head1 DESCRIPTION

通讯录管理->部门管理

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.06';
our @EXPORT = qw/ create update delete list simplelist get /;

=head1 FUNCTION

=head2 create(access_token, hash);

创建部门

=head3 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90205>

=head3 请求说明

=head4 请求包结构体为：

    {
       "name": "广州研发中心",
       "name_en": "RDGZ",
       "parentid": 1,
       "order": 1,
       "id": 2
    }

=head4 参数说明

    参数	            必须	说明
    access_token	是	调用接口凭证
    name	是	部门名称。长度限制为1~32个字符，字符不能包括\:?”<>｜
    name_en	否	英文名称，需要在管理后台开启多语言支持才能生效。长度限制为1~32个字符，字符不能包括\:?”<>｜
    parentid	是	父部门id，32位整型
    order	否	在父部门中的次序值。order值大的排序靠前。有效的值范围是[0, 2^32)
    id	否	部门id，32位整型，指定时必须大于1。若不填该参数，将自动生成id

=head3 权限说明

应用须拥有父部门的管理权限。

第三方仅通讯录应用可以调用。

注意，部门的最大层级为15层；部门总数不能超过3万个；每个部门下的节点不能超过3万个。建议保证创建的部门和对应部门成员是串行化处理。

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
    id	    创建的部门id

=cut

sub create {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/department/create?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update(access_token, hash);

更新部门

=head3 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90206>

=head3 请求说明：

=head4 请求包体（如果非必须的字段未指定，则不更新该字段）:

    {
       "id": 2,
       "name": "广州研发中心",
       "name_en": "RDGZ",
       "parentid": 1,
       "order": 1
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    id	            是	部门id
    name	否	部门名称。长度限制为1~32个字符，字符不能包括\:*?"<>｜
    name_en	否	英文名称，需要在管理后台开启多语言支持才能生效。长度限制为1~32个字符，字符不能包括\:*?"<>｜
    parentid	否	父部门id
    order	否	在父部门中的次序值。order值大的排序靠前。有效的值范围是[0, 2^32)

=head3 权限说明

应用须拥有指定部门的管理权限。如若要移动部门，需要有新父部门的管理权限。

第三方仅通讯录应用可以调用。

注意，部门的最大层级为15层；部门总数不能超过3万个；每个部门下的节点不能超过3万个。

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

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/department/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete(access_token, id);

删除部门

=head3 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90207>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    id	            是	部门id。（注：不能删除根部门；不能删除含有子部门、成员的部门）

=head4 权限说明

应用须拥有指定部门的管理权限。

第三方仅通讯录应用可以调用。

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

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/department/delete?access_token=$access_token&id=$id");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token, id);

获取部门列表

=head3 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90208>

=head3 请求说明：

注：该接口性能较低，建议换用获取子部门ID列表与获取单个部门详情

=head3 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    id	          否	部门id。获取指定部门及其下的子部门。 如果不填，默认获取全量组织架构

=head3 权限说明

只能拉取token对应的应用的权限范围内的部门列表

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "department": [
		   {
			   "id": 2,
			   "name": "广州研发中心",
			   "name_en": "RDGZ",
			   "department_leader":["zhangsan","lisi"],
			   "parentid": 1,
			   "order": 10
		   },
		   {
			   "id": 3,
			   "name": "邮箱产品部",
			   "name_en": "mail",
			   "department_leader":["lisi","wangwu"],
			   "parentid": 2,
			   "order": 40
		   }
	   ]
	}

=head4 RETURN 参数说明

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	department	部门列表数据。
	id	创建的部门id
	name	部门名称，代开发自建应用需要管理员授权才返回；此字段从2019年12月30日起，对新创建第三方应用不再返回，2020年6月30日起，对所有历史第三方应用不再返回name，返回的name字段使用id代替，后续第三方仅通讯录应用可获取，未返回名称的情况需要通过通讯录展示组件来展示部门名称
	name_en	英文名称，此字段从2019年12月30日起，对新创建第三方应用不再返回，2020年6月30日起，对所有历史第三方应用不再返回该字段
	department_leader	部门负责人的UserID；第三方仅通讯录应用可获取
	parentid	父部门id。根部门为1
	order	在父部门中的次序值。order值大的排序靠前。值范围是[0, 2^32)

=cut

sub list {
    if ( @_ && $_[0] ) {
        my $access_token = $_[0];
        my $id = $_[1] || 1;
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/department/list?access_token=$access_token&id=$id");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 simplelist(access_token, id);

获取子部门ID列表

=head3 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95350>

=head3 请求说明：

=head3 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    id	          否	部门id。获取指定部门及其下的子部门（以及子部门的子部门等等，递归）。 如果不填，默认获取全量组织架构

=head3 权限说明

	应用类型	权限说明
	第三方普通应用	若企业授权了“组织架构信息”权限，可获取企业所有部门id; 若未授权“组织架构信息”权限，只能拉取token对应的应用的权限范围内的部门列表
	第三方通讯录应用	可获取企业所有部门id
	代开发自建应用	只能拉取token对应的应用的权限范围内的部门列表
	普通自建应用	只能拉取token对应的应用的权限范围内的部门列表
	通讯录同步助手	可获取企业所有部门id

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "department_id": [
		   {
			   "id": 2,
			   "parentid": 1,
			   "order": 10
		   },
		   {
			   "id": 3,
			   "parentid": 2,
			   "order": 40
		   }
	   ]
	}

=head4 RETURN 参数说明

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	department_id	部门列表数据。
	id	创建的部门id
	parentid	父部门id。根部门为1。
	order	在父部门中的次序值。order值大的排序靠前。值范围是[0, 2^32)。

=cut

sub simplelist {
    if ( @_ && $_[0] ) {
        my $access_token = $_[0];
        my $id = $_[1] || 1;
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/department/simplelist?access_token=$access_token&id=$id");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token, id);

获取单个部门详情

=head3 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95351>

=head3 请求说明：

=head3 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    id	是	部门id。

=head3 权限说明

	应用类型	权限说明
	第三方普通应用	若企业授权了组织架构信息权限，可获取企业所有部门ID、部门负责人、父部门ID; 若未授权组织架构信息权限，只能拉取token对应的应用的可见范围内部门详情
	第三方通讯录应用	可获取企业所有部门详情
	代开发自建应用	只能拉取token对应的应用的权限范围内的部门详情
	普通自建应用	只能拉取token对应的应用的权限范围内的部门详情
	通讯录同步助手	可获取企业所有部门详情

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "department":
		   {
			   "id": 2,
			   "name": "广州研发中心",
			   "name_en": "RDGZ",
			   "department_leader":["zhangsan","lisi"],
			   "parentid": 1,
			   "order": 10
		   }
	}

=head4 RETURN 参数说明

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	department	部门详情。
	id	部门id
	name	部门名称，代开发自建应用需要管理员授权才返回；第三方不可获取，需要通过通讯录展示组件来展示部门名称
	name_en	部门英文名称，代开发自建应用需要管理员授权才返回；第三方不可获取，需要通过通讯录展示组件来展示部门名称
	department_leader	部门负责人的UserID，返回在应用可见范围内的部门负责人列表；第三方仅通讯录应用或者授权了“组织架构信息-应用可获取企业的部门组织架构信息-部门负责人”的第三方应用可获取
	parentid	父部门id。根部门为1。
	order	在父部门中的次序值。order值大的排序靠前。值范围是[0, 2^32)

=cut

sub get {
    if ( @_ && $_[0] ) {
        my $access_token = $_[0];
        my $id = $_[1] || 1;
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/department/get?access_token=$access_token&id=$id");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
