package QQ::weixin::work::hr;

=encoding utf8

=head1 Name

QQ::weixin::work::hr

=head1 DESCRIPTION

人事助手-花名册

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ get_fields get_staff_info update_staff_info /;

=head1 FUNCTION

=head2 get_fields(access_token);

获取员工字段配置
最后更新：2024/01/19

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99131>

=head3 请求说明：

通过这个接口获取员工字段配置信息

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证

=head4 权限说明：

=head3 RETURN 返回结果：

	{
		"errcode":0,
		"errmsg":"ok",
		"group_list":[
			{
				"group_id":1001,
				"group_name":"个人信息",
				"field_list":[
					{
						"fieldid":11001,
						"field_name":"姓名",
						"field_type":1,
						"is_must":true
					},
					{
						"fieldid":11002,
						"field_name":"别名",
						"field_type":1,
						"is_must":false
					}
				]
			},
			{
				"group_id":1002,
				"group_name":"在职信息",
				"field_list":[
					{
						"fieldid":12024,
						"field_name":"工号",
						"field_type":1,
						"is_must":true
					}
				]
			}
		]
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	    出错返回码，为0表示成功，非0表示调用失败
    errmsg	对返回码的文本描述内容
    group_list	字段组的配置信息，参考字段组配置信息说明
    
=head4 字段组配置信息说明：

	参数		说明
	group_id	字段组的id
	group_name	字段组的名称
	field_list	字段组所包含的所有字段信息，参考字段信息说明

=head4 字段信息说明：

	参数		说明
	field_id	字段的id
	field_name	字段的名称
	field_type	字段的类型，参考字段类型说明
	is_must	字段是否为必填

=head4 字段类型说明：

	参数	字段类型	对应获取/更新时字段类型
	1	文本类型	字符串类型 或 电话号码类型
	2	选项类型	32位非负整数类型
	3	时间类型	64位非负整数类型 或 64位整数类型
	4	图片类型	文件类型
	5	单个文件类型	文件类型
	6	多个文件类型	文件类型

=cut

sub get_fields {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/hr/get_fields?access_token=$access_token");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_staff_info(access_token, hash);

获取员工花名册信息
最后更新：2023/11/15

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99132>

=head3 请求说明：

通过这个接口获取指定员工的花名册信息
调用参数中的字段id信息可以通过获取员工字段配置接口获取

=head4 请求包结构体为：

	{
		"userid":"xxxxx",
		"get_all":false,
		"fieldids":[
			{
				"fieldid":11004,
				"sub_idx":0
			},
			{
				"fieldid":14001,
				"sud_idx":1
			}
		]
	}

=head4 参数说明：

	参数		必须		说明
	access_token	是	调用接口凭证
	userid	是	需要获取花名册信息的员工的userid
				该员工需要在调用应用的可见范围内，否则将返回错误码
	get_all	否	是否获取全部字段信息，不填时默认为否
	fieldids	否	需要获取的字段信息。
					参数get_all为否或不填时，此字段不能为空；
					参数get_all为是时，此字段填写的内容将被忽略
	fieldids.fieldid	是	需要获取的字段id
	fieldids.sub_idx	否	需要获取的字段下标。
							当需要获取的字段属于可重复的组(参考可重复字段组列表)时，需要指定获取组内第几组数据的字段信息，当需要获取的字段不属于可重复的组时，需要为0。
							不填时默认为0

=head4 可重复字段组列表：

	编号	名称
	1	教育经历
	2	工作经历
	3	家庭成员
	4	紧急联系人
	5	合同信息

=head4 权限说明：

=head3 RETURN 返回结果：

	{
		"errcode":0,
		"errmsg":"ok",
		"fieldinfo":[
			{
				"fieldid":11004,
				"sub_idx":0,
				"result":1,
				"value_type":3,
				"value_uint32":1
			},
			{
				"fieldid":11003,
				"sub_idx":0,
				"result":1,
				"value_type":5,
				"value_mobile":{
					"value_country_code":"xx",
					"value_mobile":"xxxxxxxxxx"
				}
			},
			{
				"fieldid":19001,
				"sub_idx":0,
				"result":1,
				"value_type":6,
				"value_file":{
					"media_id":["xxxxxx","xxxxxx"]
				}
			}
		]
	}

=head4 RETURN 参数说明：

	参数		说明
	errcode	返回码
	errmsg	对返回码的文本描述
	fieldinfo	获取到的字段信息，参考字段信息说明

=head4 字段信息说明：

	参数		说明
	fieldid	字段id
	sub_idx	下标
	result	查询结果，参考查询结果对照表
	value_type	字段值的类型，参考字段值类型对照表
	value_xxxxx	字段值的内容，根据不同的字段值类型，返回的这个字段的名称和类型也不同，参考字段值类型对照表

=head4 查询结果对照表：

	参数	结果
	1	成功
	2	失败
	3	字段未找到
	5	不支持获取的字段类型

=head4 字段值类型对照表：

	参数	字段类型	对应的内容字段名称	对应的内容字段类型
	1	字符串	value_string	字符串
	2	64位非负整数	value_uint64	非负整数
	3	32位非负整数	value_uint32	非负整数
	4	64位整数	value_int64	整数
	5	电话号码	value_mobile	参考电话号码类型字段结构
	6	文件	value_file	参考文件类型字段结构

=head4 电话号码类型字段结构：

	参数		说明
	value_country_code	字符串，表示电话号码的区号
	value_mobile	字符串，表示电话号码

=head4 文件类型字段结构：

	参数		说明
	media_id	列表，内容为字符串，可在获取临时素材接口下载对应文件

=cut

sub get_staff_info {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/hr/get_staff_info?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update_staff_info(access_token, hash);

更新员工花名册信息
最后更新：2024/01/04

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/99133>

=head3 请求说明：

通过这个接口更新指定员工的花名册信息
调用参数中的字段id信息可以通过获取员工字段配置接口获取
有一些字段不支持更新，参考不支持更新字段表

=head4 请求包结构体为：

	{
		"userid":"xxxxx",
		"update_items":[
			{
				"fieldid":11020,
				"sub_idx":0,
				"value_string":"xxxxx"
			},
			{
				"fieldid":17003,
				"sub_idx":1,
				"value_mobile":{
					"value_mobile_country_code":"xxx",
					"value_mobile":"xxxxxxxx"
				}
			}
		],
		"remove_items":[
			{
				"group_type":1,
				"sub_idx":1
			},
			{
				"group_type":1,
				"sub_idx":2
			}
		],
		"insert_items":[
			{
				"group_type":4,
				"item":[
					{
						"fieldid":17001,
						"sub_idx":0,
						"value_string":"孙悟空"
					},
					{
						"fieldid":17002,
						"sub_idx":0,
						"value_uint32":1
					},
					{
						"fieldid":17003,
						"sub_idx":0,
						"value_mobile":{
							"value_country_code":"xxx",
							"value_mobile":"xxxxxxxx"
						}
					},
					{
						"fieldid":17004,
						"sub_idx":0,
						"value_string":"娜美克星"
					}
				]
			}
		]
	}

=head4 参数说明：

	参数		必须		说明
	access_token	是	调用接口凭证
	userid	是	需要更新花名册信息的员工的userid
				该员工需要在调用应用的可见范围内，否则将返回错误码
	update_items	否	需要更新、增加或清空单个字段的内容，参考更新字段说明。
						有一些字段不支持更新，参考不支持更新字段表。
						这个字段和remove_items、insert_items字段不能全部为空
	remove_items	否	可重复的字段组(参考可重复字段组列表)中需要整组字段进行删除的字段组，参考删除字段说明。
						这个字段和update_items、insert_items字段不能全部为空
	insert_items	否	可重复的字段组(参考可重复字段组列表)中需要增加一组字段的字段组，参考增加字段说明。
						这个字段和update_items、remove_items字段不能全部为空

=head4 可重复字段组列表：

	编号	名称
	1	教育经历
	2	工作经历
	3	家庭成员
	4	紧急联系人
	5	合同信息

=head4 更新字段说明：

	参数		必须		说明
	fieldid	是	字段id
	sub_idx	否	可重复组中的字段下标，非可重复组中的字段时需要填0
	value_xxxxx	否	需要更新、增加或清空的员工信息字段内容。
					根据员工信息字段的类型，需要填写的这个字段的名称和类型也不同，参考字段值类型对照表。
					除了对应的字段外，在其他字段填写的内容将被忽略。

=head4 不支持更新字段表：

以字段id为准

	名称	字段id
	年龄	11006
	社会工龄	11012
	员工状态	12004
 
=head4 删除字段说明：

	参数		必须		说明
	group_type	是	需要删除的字段组类型，参考可重复字段组列表
	sub_idx	是	需要删除的是第几组字段

=head4 增加字段说明：

	参数		必须		说明
	group_type	是	需要增加的字段组类型，参考可重复字段组列表
	item	否	列表，需要增加的字段内容；
				填写要求与更新字段说明相同，但sub_idx字段的内容将被忽略；
				没有找到对应字段id的字段内容将被忽略。

=head4 字段值类型对照表：

	字段类型	对应的内容字段名称	对应的内容字段类型
	字符串	value_string	字符串
	64位非负整数	value_uint64	非负整数
	32位非负整数	value_uint32	非负整数
	64位整数	value_int64	整数
	电话号码	value_mobile	参考电话号码类型字段结构

=head4 电话号码类型字段结构：

	参数		说明
	value_country_code	字符串，表示电话号码的区号
	value_mobile	字符串，表示电话号码
					这个字段如果不填/填写空串，则视为整个电话号码字段传入为空

=head4 权限说明：

=head3 RETURN 返回结果：

	{
		"errcode":0,
		"errmsg":"ok",
		"update_results":[
			{
				"fieldid":11001,
				"sub_idx":0,
				"result":1
			}
		],
		"remove_results":[
			{
				"group_type":1,
				"sub_idx":20,
				"result":3
			}
		],
		"insert_result":[
			{
				"group_type":1,
				"idx":1,
				"result":4
			}
		]
	}

=head4 RETURN 参数说明：

	参数		说明
	errcode	返回码
	errmsg	对返回码的文本描述
	---	---
	update_results	更新字段的结果
	update_results.fieldid	尝试更新的字段id
	update_results.sub_idx	尝试更新的字段下标
	update_results.result	更新的结果，参考结果类型对照表
	---	---
	remove_results	删除字段组的结果
	remove_results.group_type	尝试删除的字段组类型
	remove_results.sub_idx	尝试删除的字段组下标
	remove_results.result	删除的结果，参考结果类型对照表
	---	---
	insert_results	增加字段组的结果
	insert_results.group_type	尝试增加的字段组类型
	insert_results.idx	尝试增加的字段组输入时的下标
	insert_results.result	增加的结果，参考结果类型对照表

=head4 结果类型对照表：

	参数	结果类型
	1	成功
	2	失败
	3	未找到的字段id/字段下标
	4	必填字段未填写/被清空
	5	不支持更新的字段类型

=cut

sub update_staff_info {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/hr/update_staff_info?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
