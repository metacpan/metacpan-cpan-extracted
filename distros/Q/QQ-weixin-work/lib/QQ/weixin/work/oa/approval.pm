package QQ::weixin::work::oa::approval;

=encoding utf8

=head1 Name

QQ::weixin::work::oa::approval

=head1 DESCRIPTION

审批

=cut

use strict;
use base qw(QQ::weixin::work::oa);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ create_template update_template /;

=head1 FUNCTION

=head2 create_template(access_token, hash);

创建审批模板
最后更新：2024/01/16

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97437>

=head3 请求说明：

可以调用此接口创建审批模板。创建新模板后，管理后台及审批应用内将生成对应模板，并生效默认流程和规则配置。

=head4 请求包结构体为：

	{
		"template_name": [{
			"text": "我的api测试模版",
			"lang": "zh_CN"
		}],
		"template_content": {
			"controls": [{
				"property": {
					"control": "Text",
					"id": "Text-01",
					"title": [{
						"text": "控件名称",
						"lang": "zh_CN"
					}],
					"placeholder": [{
						"text": "控件说明",
						"lang": "zh_CN"
					}],
					"require": 0,
					"un_print": 1
				},
				"config":{
					
				}
			}]
		}
	}

=head4 参数说明：

	参数		必须		说明
	access_token	是	调用接口凭证
	template_name	是	模版名称数组
	└ text	是	模版名称。需满足以下条件：1-模版名称不得和现有模版名称重复；2-长度不得超过40个字符。
	└ lang	是	显示语言，中文：zh_CN（注意不是zh-CN）
	template_content	否	审批模版控件设置，由多个表单控件及其内容组成，其中包含需要对控件赋值的信息
	└ controls	否	控件数组，模版中可以设置多个控件类型，排列顺序和管理端展示的相同
	└└ property	是	控件的基础属性
	└└└ control	是	控件类型：Text-文本；Textarea-多行文本；Number-数字；Money-金额；Date-日期/日期+时间；Selector-单选/多选；；Contact-成员/部门；Tips-说明文字；File-附件；Table-明细；Location-位置；RelatedApproval-关联审批单；DateRange-时长；PhoneNumber-电话号码；Vacation-假期；Attendance-外出/出差/加班；BankAccount-收款账户 。以上为目前可支持的控件类型
	└└└ id	是	控件id。1-模版内控件id必须唯一；2-控件id格式：control-数字，如"Text-01"
	└└└ title	是	控件名称
	└└└└ text	是	控件名称。需满足以下条件：1-控件名称不得和现有控件名称重复；2-长度不得超过40个字符。
	└└└└ lang	是	显示语言，中文：zh_CN（注意不是zh-CN）
	└└└ placeholder	否	控件说明
	└└└└ text	否	控件说明。需满足以下条件：长度不得超过80个字符。
	└└└└ lang	否	显示语言，中文：zh_CN（注意不是zh-CN）；若text填写，则该项为必填
	└└└ require	否	控件是否必填。0-非必填；1-必填；默认为0
	└└└ un_print	否	控件是否可打印。0-可打印；1-不可打印；默认为0
	└└ config	是or否	控件配置。控件的类型不同，其中填的参数不相同，下方将为每一个控件配置进行详细说明

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「审批 - 可调用接口的应用」中
	代开发应用	具有「审批」权限
	第三方应用	暂不支持

1.第三方应用可以获取第三方应用添加的模板详情。
2.自建应用的Secret可获取企业自建模板的模板详情。
3.接口调用频率限制为600次/分钟。
注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

注意：
1. 当模板的控件为必填属性时，表单中对应的控件必须有值。
2. 一个模版中只能拥有一类假勤控件类型，Vacation-假期；Attendance-外出/出差/加班 均为假勤控件类型。

=head3 RETURN 返回结果

	{
		"errcode":0,
		"errmsg":"ok",
		"template_id":"C4RbNKm731MCFVgk6XLq1Rs9W4aNXPJV2mmXT4qGy"
	}

=head3 RETURN 参数说明

	参数		说明
	errcode	错误码，详情见错误码说明
	errmsg	错误码对应的错误信息提示
	template_id	模版创建成功后返回的模版id
	
=head3 附录：各控件config参数介绍

L<https://developer.work.weixin.qq.com/document/path/97437#附录：各控件config数介绍>

=head4 错误说明

	错误码	说明
	301088	无审批应用权限
	301086	审批控件参数错误
	301087	企业模版数超过上限
	620004	服务器内部错误
	-1	未知错误

=cut

sub create_template {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/approval/create_template?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update_template(access_token, hash);

更新审批模板
最后更新：2024/01/16

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/97438>

=head3 请求说明：

可调用本接口更新审批模板。更新模板后，管理后台及审批应用内将更新原模板的内容，已配置的审批流程和规则不变。

=head4 请求包结构体为：

	{
		"template_id": "C4RbNKm731MCFVgk6XLq1Rs9W4aNXPJV2mmXT4qGy",
		"template_name": [{
			"text": "我的api测试模版",
			"lang": "zh_CN"
		}],
		"template_content": {
			"controls": [{
				"property": {
					"control": "Text",
					"id": "Text-01",
					"title": [{
						"text": "控件名称",
						"lang": "zh_CN"
					}],
					"placeholder": [{
						"text": "控件说明",
						"lang": "zh_CN"
					}],
					"require": 0,
					"un_print": 1
				},
				"config":{
					
				}
			}]
		}
	}

=head4 参数说明：

	参数		必须		说明
	access_token	是	调用接口凭证。必须使用审批应用或企业内自建应用的secret获取，获取方式参考：文档-获取access_token
	template_id	是	模版id
	template_name	是	模版名称数组
	└ text	是	模版名称。需满足以下条件：1-模版名称不得和现有模版名称重复；2-长度不得超过40个字符。
	└ lang	是	显示语言，中文：zh_CN（注意不是zh-CN）
	template_content	否	审批模版控件设置，由多个表单控件及其内容组成，其中包含需要对控件赋值的信息
	└ controls	否	控件数组，模版中可以设置多个控件类型，排列顺序和管理端展示的相同
	└└ property	是	控件的基础属性
	└└└ control	是	控件类型：Text-文本；Textarea-多行文本；Number-数字；Money-金额；Date-日期/日期+时间；Selector-单选/多选；；Contact-成员/部门；Tips-说明文字；File-附件；Table-明细；Location-位置；RelatedApproval-关联审批单；DateRange-时长；PhoneNumber-电话号码；Vacation-假期；Attendance-外出/出差/加班；BankAccount-收款账户。以上为目前可支持的控件类型
	└└└ id	是	控件id。1-模版内控件id必须唯一；2-控件id格式：control-数字，如"Text-01"
	└└└ title	是	控件名称
	└└└└ text	是	控件名称。需满足以下条件：1-控件名称不得和现有控件名称重复；2-长度不得超过40个字符。
	└└└└ lang	是	显示语言，中文：zh_CN（注意不是zh-CN）
	└└└ placeholder	否	控件说明
	└└└└ text	否	控件说明。需满足以下条件：长度不得超过80个字符。
	└└└└ lang	否	显示语言，中文：zh_CN（注意不是zh-CN）；若text填写，则该项为必填
	└└└ require	否	控件是否必填。0-非必填；1-必填；默认为0
	└└└ un_print	否	控件是否可打印。0-可打印；1-不可打印；默认为0
	└└ config	是or否	控件配置。控件的类型不同，其中填的参数不相同，下方将为每一个控件配置进行详细说明
 
注意：
1. 当模板的控件为必填属性时，表单中对应的控件必须有值。
2. 一个模版中只能拥有一类假勤控件类型，Vacation-假期；Attendance-外出/出差/加班 均为假勤控件类型。

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「审批 - 可调用接口的应用」中
	代开发应用	具有「审批」权限
	第三方应用	暂不支持

仅能更新自身应用模板
注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok"
	}

=head3 RETURN 参数说明

	参数		类型		说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=head3 附录：各控件config参数介绍

L<https://developer.work.weixin.qq.com/document/path/97438#附录：各控件config数介绍>

=head3 错误说明：

	错误码	说明
	301088	无审批应用权限
	301086	审批控件参数错误
	301087	企业模版数超过上限
	620004	服务器内部错误
	-1	未知错误

=cut

sub update_template {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/approval/update_template?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
