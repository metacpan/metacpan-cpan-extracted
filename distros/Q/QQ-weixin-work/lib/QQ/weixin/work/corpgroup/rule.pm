package QQ::weixin::work::corpgroup::rule;

=encoding utf8

=head1 Name

QQ::weixin::work::corpgroup::rule

=head1 DESCRIPTION

上下游规则

=cut

use strict;
use base qw(QQ::weixin::work::corpgroup);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ list_ids delete_rule get_rule_info add_rule modify_rule /;

=head1 FUNCTION

=head2 list_ids(access_token, hash);

获取对接规则id列表
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95631>

=head3 请求说明：

上下游系统应用可通过该接口获取企业上下游规则id列表

=head4 请求包结构体为：

	{
	   "chain_id":"Chxxxxxx"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    chain_id	是	上下游id

=head4 权限说明：

调用的应用需要满足如下的权限，仅适用于上下游中创建空间的主企业调用。

应用类型	权限要求
自建应用	配置到「上下游- 可调用接口的应用」中
注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果：

	{
	   "errcode": 0,
	   "errmsg": "ok",
	   "rule_ids": [1,2]
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	    出错返回码，为0表示成功，非0表示调用失败
    errmsg	对返回码的文本描述内容
    rule_ids	上下游关系规则的id

=cut

sub list_ids {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/rule/list_ids?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 delete_rule(access_token, hash);

删除对接规则
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95632>

=head3 请求说明：

上下游系统应用可通过该接口删除企业上下游规则

=head4 请求包结构体为：

	{
	   "chain_id":"Chxxxxxx",
	   "rule_id":1
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    chain_id	是	上下游id
    rule_id	是	上下游规则id

=head4 权限说明：

调用的应用需要满足如下的权限，仅适用于上下游中创建空间的主企业调用。操作的规则对应的企业成员和部门都需要在应用的可见范围内。

应用类型	权限要求
自建应用	配置到「上下游- 可调用接口的应用」中
注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果：

	{
	   "errcode": 0,
	   "errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	    返回码
    errmsg	对返回码的文本描述内容

=cut

sub delete_rule {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/rule/delete_rule?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_rule_info(access_token, hash);

获取对接规则详情
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95633>

=head3 请求说明：

上下游系统应用可通过该接口获取企业上下游规则详情

=head4 请求包结构体为：

	{
	   "chain_id":"Chxxxxxx",
	   "rule_id":1
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    chain_id	是	上下游id
    rule_id	是	上下游规则id

=head4 权限说明：

调用的应用需要满足如下的权限，仅适用于上下游中创建空间的主企业调用。操作的规则对应的企业用户和部门都需要在应用的可见范围内。

应用类型	权限要求
自建应用	配置到「上下游- 可调用接口的应用」中
注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果：

	{
	   "errcode": 0,
	   "errmsg": "ok",
	   "rule_info": {
		  "owner_corp_range": {
			 "departmentids": ["departmentid1", "departmentid2"],
			 "userids": ["userid1","userid2"]
		  },
		  "member_corp_range": {
			 "groupids": ["groupid1", "groupid2"],
			 "corpids": ["corpid1","corpid2"]
		  }
	   }
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	    返回码
    errmsg	对返回码的文本描述内容
    rule_info	上下游关系规则的详情
	rule_info.owner_corp_range	上游企业的对接人规则（下游企业可以看到并联系的成员或部门）
	rule_info.owner_corp_range.departmentids	部门id
	rule_info.owner_corp_range.userids	用户id
	rule_info.member_corp_range	下游企业规则范围
	rule_info.member_corp_range.groupids	分组id
	rule_info.member_corp_range.corpids	企业id

=cut

sub get_rule_info {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/rule/get_rule_info?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 add_rule(access_token, hash);

新增对接规则
最后更新：2023/12/07

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95634>

=head3 请求说明：

上下游系统应用可通过该接口新增一条对接规则。
注意：新增和更新上下游对接规则的接口每天最多调用1000次

=head4 请求包结构体为：

	{
	   "chain_id":"Chxxxxxx",
	   "rule_info": {
		  "owner_corp_range": {
			 "departmentids": ["departmentid1", "departmentid2"],
			 "userids": ["userid1","userid2"]
		  },
		  "member_corp_range": {
			 "groupids": ["groupid1", "groupid2"],
			 "corpids": ["corpid1","corpid2"]
		  }
	   }
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    chain_id	是	上下游id
    rule_info	是	上下游关系规则的详情
	rule_info.owner_corp_range	是	上游企业的对接人规则（下游企业可以看到并联系的成员或部门）
	rule_info.owner_corp_range.departmentids	否	部门id，部门id和用户id两个必选填一个
	rule_info.owner_corp_range.userids	否	用户id，部门id和用户id两个必选填一个
	rule_info.member_corp_range	是	下游企业规则范围
	rule_info.member_corp_range.groupids	否	分组id，分组id和企业id两个必选填一个
	rule_info.member_corp_range.corpids	否	企业id，分组id和企业id两个必选填一个

=head4 权限说明：

调用的应用需要满足如下的权限，仅适用于上下游中创建空间的主企业调用。操作的规则对应的企业用户和部门都需要在应用的可见范围内。

应用类型	权限要求
自建应用	配置到「上下游- 可调用接口的应用」中
注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情


=head3 RETURN 返回结果：

	{
	   "errcode": 0,
	   "errmsg": "ok",
	   "rule_id": 1
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	    返回码
    errmsg	对返回码的文本描述内容
    rule_id	上下游规则id

=cut

sub add_rule {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/rule/add_rule?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 modify_rule(access_token, hash);

更新对接规则
最后更新：2023/12/07

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95635>

=head3 请求说明：

上下游系统应用可通过该接口修改一条对接规则。
注意：新增和更新上下游对接规则的接口每天最多调用1000次

=head4 请求包结构体为：

	{
	   "chain_id":"Chxxxxxx",
	   "rule_id": 1,
	   "rule_info": {
		  "owner_corp_range": {
			 "departmentids": ["departmentid1", "departmentid2"],
			 "userids": ["userid1","userid2"]
		  },
		  "member_corp_range": {
			 "groupids": ["groupid1", "groupid2"],
			 "corpids": ["corpid1","corpid2"]
		  }
	   }
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    chain_id	是	上下游id
    rule_id	是	上下游规则id
    rule_info	是	上下游关系规则的详情
	rule_info.owner_corp_range	是	上游企业的对接人规则（下游企业可以看到并联系的成员或部门）
	rule_info.owner_corp_range.departmentids	否	部门id，部门id和用户id两个必选填一个
	rule_info.owner_corp_range.userids	否	用户id，部门id和用户id两个必选填一个
	rule_info.member_corp_range	是	下游企业规则范围
	rule_info.member_corp_range.groupids	否	分组id，分组id和企业id两个必选填一个
	rule_info.member_corp_range.corpids	否	企业id，分组id和企业id两个必选填一个

=head4 权限说明：

调用的应用需要满足如下的权限，仅适用于上下游中创建空间的主企业调用。操作的规则对应的企业成员和部门都需要在应用的可见范围内。

应用类型	权限要求
自建应用	配置到「上下游- 可调用接口的应用」中
注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果：

	{
	   "errcode": 0,
	   "errmsg": "ok"
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	    返回码
    errmsg	对返回码的文本描述内容

=cut

sub modify_rule {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/corpgroup/rule/modify_rule?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
