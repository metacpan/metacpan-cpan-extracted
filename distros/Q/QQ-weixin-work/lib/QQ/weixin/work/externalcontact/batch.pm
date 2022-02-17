package QQ::weixin::work::externalcontact::batch;

=encoding utf8

=head1 Name

QQ::weixin::work::externalcontact::batch

=head1 DESCRIPTION

客户管理

=cut

use strict;
use base qw(QQ::weixin::work::externalcontact);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.06';
our @EXPORT = qw/ get_by_user /;

=head1 FUNCTION

=head2 get_by_user(access_token, hash);

批量获取客户详情

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/92994>

=head3 请求说明：

企业/第三方可通过此接口获取指定成员添加的客户信息列表。

=head4 请求包结构体为：

    {
	   "userid_list":
	   [
			"zhangsan",
			"lisi"
		],
	   "cursor":"",
	   "limit":100
	}

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
	userid_list	是	企业成员的userid列表，字符串类型，最多支持100个
	cursor	否	用于分页查询的游标，字符串类型，由上一次调用返回，首次调用可不填
	limit	否	返回的最大记录数，整型，最大值100，默认值50，超过最大值时取最大值

=head4 权限说明：

企业需要使用“客户联系”secret或配置到“可调用应用”列表中的自建应用secret所获取的accesstoken来调用（accesstoken如何获取？）；
第三方应用需具有“企业客户权限->客户基础信息”权限
第三方/自建应用调用此接口时，userid需要在相关应用的可见范围内。
规则组标签仅可通过“客户联系”获取。

=head3 RETURN 返回结果：

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "external_contact_list":
		[
			{
				"external_contact":
				{
					"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACHAAA",
					"name":"李四",
					"position":"Manager",
					"avatar":"http://p.qlogo.cn/bizmail/IcsdgagqefergqerhewSdage/0",
					"corp_name":"腾讯",
					"corp_full_name":"腾讯科技有限公司",
					"type":2,
					"gender":1,
					"unionid":"ozynqsulJFCZ2z1aYeS8h-nuasdAAA",
					"external_profile":
					{
					"external_attr":
					[
						{
						"type":0,
						"name":"文本名称",
						 "text":
							{
							"value":"文本"
							}
						},
						{
						"type":1,
						"name":"网页名称",
						"web":
						{
						  "url":"http://www.test.com",
						  "title":"标题"
						}
					},
					{
					  "type":2,
					  "name":"测试app",
					  "miniprogram":
					  {
						  "appid": "wx8bd80126147df384",
						  "pagepath": "/index",
						  "title": "my miniprogram"
					  }
					}
				  ]
				}
				},
				"follow_info":
				{
					"userid":"rocky",
					"remark":"李部长",
					"description":"对接采购事务",
					"createtime":1525779812,
					"tag_id":["etAJ2GCAAAXtWyujaWJHDDGi0mACHAAA"],
					"remark_corp_name":"腾讯科技",
					"remark_mobiles":
					[
						"13800000001",
						"13000000002"
					],
					"oper_userid":"rocky",
					"add_way":1
				}
			},
			{
				"external_contact":
				 {
					"external_userid":"woAJ2GCAAAXtWyujaWJHDDGi0mACHBBB",
					"name":"王五",
					"position":"Engineer",
					"avatar":"http://p.qlogo.cn/bizmail/IcsdgagqefergqerhewSdage/0",
					"corp_name":"腾讯",
					"corp_full_name":"腾讯科技有限公司",
					"type":2,
					"gender":1,
					"unionid":"ozynqsulJFCZ2asdaf8h-nuasdAAA"
				},
				"follow_info":
				{
					"userid":"lisi",
					"remark":"王助理",
					"description":"采购问题咨询",
					"createtime":1525881637,
					"tag_id":["etAJ2GCAAAXtWyujaWJHDDGi0mACHAAA","stJHDDGi0mAGi0mACHBBByujaW"],
					"state":"外联二维码1",
					"oper_userid":"woAJ2GCAAAd1asdasdjO4wKmE8AabjBBB",
					"add_way":3
				}
			}
		],
		"next_cursor":"r9FqSqsI8fgNbHLHE5QoCP50UIg2cFQbfma3l2QsmwI"
	}

=head4 RETURN 参数说明：

    参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	external_contact_list.external_contact	客户的基本信息，可以参考获取客户详情
	external_contact_list.follow_info	企业成员客户跟进信息，可以参考获取客户详情，但标签信息只会返回企业标签和规则组标签的tag_id，个人标签将不再返回
	next_cursor	分页游标，再下次请求时填写以获取之后分页的记录，如果已经没有更多的数据则返回空

=cut

sub get_by_user {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/externalcontact/batch/get_by_user?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
