package QQ::weixin::work::oa;

=encoding utf8

=head1 Name

QQ::weixin::work::oa

=head1 DESCRIPTION

审批

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ gettemplatedetail applyevent getapprovalinfo getapprovaldetail /;

=head1 FUNCTION

=head2 gettemplatedetail(access_token, hash);

获取审批模板详情
最后更新：2024/01/16

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/91982>

=head3 请求说明：

=head4 请求包结构体为：

    {
      "template_id" : "ZLqk8pcsAoXZ1eYa6vpAgfX28MPdYU3ayMaSPHaaa"
    }
    
较早时间创建的模板，id为类似“1910324946027731_1688852032423522_1808577376_15111111111”的数字串。

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证。必须使用审批应用或企业内自建应用的secret获取，获取方式参考：文档-获取access_token
    template_id	是	模板的唯一标识id。可在“获取审批单据详情”、“审批状态变化回调通知”中获得，也可在审批模板的模板编辑页面浏览器Url链接中获得。

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「审批 - 可调用接口的应用」中
	代开发应用	具有「审批」权限
	第三方应用	具有「审批」权限

1.第三方应用可以获取第三方应用添加的模板详情。
2.自建应用的Secret可获取企业自建模板的模板详情。
3.接口调用频率限制为600次/分钟。
注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"template_names": [
			{
				"text": "全字段",
				"lang": "zh_CN"
			}
		],
		"template_content": {
			"controls": [
				{
					"property": {
						"control": "Selector",
						"id": "Selector-15111111111",
						"title": [
							{
								"text": "单选控件",
								"lang": "zh_CN"
							}
						],
						"placeholder": [
							{
								"text": "这是单选控件的说明",
								"lang": "zh_CN"
							}
						],
						"require": 0,
						"un_print": 0
					},
					"config": {
						"selector": {
							"type": "single",
							"exp_type": 0,
							"options": [
								{
									"key": "option-15111111111",
									"value": [
										{
											"text": "选项1",
											"lang": "zh_CN"
										}
									]
								},
								{
									"key": "option-15222222222",
									"value": [
										{
											"text": "选项2",
											"lang": "zh_CN"
										}
									]
								}
							]
						}
					}
				}
			]
		}
	}

=head4 RETURN 参数说明

	参数		说明
	template_names	模板名称，若配置了多语言则会包含中英文的模板名称，默认为zh_CN中文
	template_content	模板控件信息
	└ controls	模板控件数组。模板详情由多个不同类型的控件组成，控件类型详细说明见附录。
	└ └ property	模板控件属性，包含了模板内控件的各种属性信息
	└ └ └ control	控件类型：Text-文本；Textarea-多行文本；Number-数字；Money-金额；Date-日期/日期+时间；Selector-单选/多选；Contact-成员/部门；Tips-说明文字；File-附件；Table-明细；Attendance-假勤控件；Vacation-请假控件；Location-位置；RelatedApproval-关联审批单；Formula-公式；DateRange-时长；BankAccount-收款账户
	└ └ └ id	控件id
	└ └ └ title	控件名称，若配置了多语言则会包含中英文的控件名称，默认为zh_CN中文
	└ └ └ placeholder	控件说明，向申请者展示的控件填写说明，若配置了多语言则会包含中英文的控件说明，默认为zh_CN中文
	└ └ └ require	是否必填：1-必填；0-非必填
	└ └ └ un_print	是否参与打印：1-不参与打印；0-参与打印
	└ └ config	模板控件配置，包含了部分控件类型的附加类型、属性，详见附录说明。目前有配置信息的控件类型有：Date-日期/日期+时间；Selector-单选/多选；Contact-成员/部门；Table-明细；Attendance-假勤组件（请假、外出、出差、加班）

=head4 附录

L<https://developer.work.weixin.qq.com/document/path/91982#附录>

=head4 RETURN 错误说明

	错误码	说明
	301025	参数错误，请求template_id非法
	301026	通用错误码，拉取审批模板内部接口失败

=cut

sub gettemplatedetail {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/gettemplatedetail?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 applyevent(access_token, hash);

提交审批申请
最后更新：2024/01/15

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/91853>

=head3 请求说明：

=head4 请求包结构体为：

	{
		"creator_userid": "WangXiaoMing",
		"template_id": "3Tka1eD6v6JfzhDMqPd3aMkFdxqtJMc2ZRioeFXkaaa",
		"use_template_approver":0,
		"choose_department":2,
		"approver": [
			{
				"attr": 2,
				"userid": ["WuJunJie","WangXiaoMing"]
			},
			{
				"attr": 1,
				"userid": ["LiuXiaoGang"]
			}
		],
		"notifyer":[ "WuJunJie","WangXiaoMing" ],
		"notify_type" : 1,
		"apply_data": {
			 "contents": [
					{
						"control": "Text",
						"id": "Text-15111111111",
						"value": {
							"text": "文本填写的内容"
						}
					}
				]
		},
		"summary_list": [
			{
				"summary_info": [{
					"text": "摘要第1行",
					"lang": "zh_CN"
				}]
			},
			{
				"summary_info": [{
					"text": "摘要第2行",
					"lang": "zh_CN"
				}]
			},
			{
				"summary_info": [{
					"text": "摘要第3行",
					"lang": "zh_CN"
				}]
			}
		]
	}

=head4 参数说明：

	参数		必须		说明
	access_token	是	调用接口凭证(https://work.weixin.qq.com/api/doc#90000/90135/91039 "文档")
	creator_userid	是	申请人userid，此审批申请将以此员工身份提交，申请人需在应用可见范围内
	template_id	是	模板id。可在“获取审批申请详情”、“审批状态变化回调通知”中获得，也可在审批模板的模板编辑页面链接中获得。暂不支持通过接口提交[打卡补卡][调班]模板审批单。
	use_template_approver	是	审批人模式：0-通过接口指定审批人、抄送人（此时approver、notifyer等参数可用）; 1-使用此模板在管理后台设置的审批流程(需要保证审批流程中没有“申请人自选”节点)，支持条件审批。默认为0
	choose_department	否	提单者提单部门id，不填默认为主部门
	approver	是	审批流程信息，用于指定审批申请的审批流程，支持单人审批、多人会签、多人或签，可能有多个审批节点，仅use_template_approver为0时生效。
	└ userid	是	审批节点审批人userid列表，若为多人会签、多人或签，需填写每个人的userid
	└ attr	是	节点审批方式：1-或签；2-会签，仅在节点为多人审批时有效
	notifyer	否	抄送人节点userid列表，仅use_template_approver为0时生效。
	notify_type	否	抄送方式：1-提单时抄送（默认值）； 2-单据通过后抄送；3-提单和单据通过后抄送。仅use_template_approver为0时生效。
	apply_data	是	审批申请数据，可定义审批申请中各个控件的值，其中必填项必须有值，选填项可为空，数据结构同“获取审批申请详情”接口返回值中同名参数“apply_data”
	└ contents	是	审批申请详情，由多个表单控件及其内容组成，其中包含需要对控件赋值的信息
	└ └ control	是	控件类型：Text-文本；Textarea-多行文本；Number-数字；Money-金额；Date-日期/日期+时间；Selector-单选/多选；；Contact-成员/部门；Tips-说明文字；File-附件；Table-明细；Location-位置；RelatedApproval-关联审批单；Formula-公式；DateRange-时长；
	└ └ id	是	控件id：控件的唯一id，可通过“获取审批模板详情”接口获取
	└ └ value	是	控件值 ，需在此为申请人在各个控件中填写内容不同控件有不同的赋值参数，具体说明详见附录。模板配置的控件属性为必填时，对应value值需要有值。
	summary_list	是	摘要信息，用于显示在审批通知卡片、审批列表的摘要信息，最多3行
	└ summary_info	是	摘要行信息，用于定义某一行摘要显示的内容
	└ └ text	是	摘要行显示文字，用于记录列表和消息通知的显示，不要超过20个字符
	└ └ lang	是	摘要行显示语言，中文：zh_CN（注意不是zh-CN），英文：en。

接口频率限制 600次/分钟
当模板的控件为必填属性时，表单中对应的控件必须有值。

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「审批 - 可调用接口的应用」中
	代开发应用	具有「审批」权限
	第三方应用	具有「审批」权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "sp_no": "202001010001"
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	错误码，详情见错误码说明
	errmsg	错误码对应的错误信息提示
	sp_no	表单提交成功后，返回的表单编号

=head4 附录：各控件apply_data/contents/value参数介绍

L<https://developer.work.weixin.qq.com/document/path/91853#附录：各控件apply-datacontentsvalue参数介绍>

=head4 RETURN 错误说明

	错误码	说明
	301055	无审批应用权限,或者提单者不在审批应用/自建应用的可见范围
	301056	审批应用已停用
	301025	提交审批单请求参数错误
	301057 	通用错误码，提交审批单内部接口失败

=cut

sub applyevent {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/applyevent?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getapprovalinfo(access_token, hash);

批量获取审批单号
最后更新：2024/02/07

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/91816>

=head3 请求说明：

通过本接口可以获取企业一段时间内企业微信“审批应用”单据的审批编号，支持按模板类型、申请人、部门、申请单审批状态等条件筛选。
自建应用调用此接口，需在“管理后台-应用管理-审批-API-审批数据权限”中，授权应用允许提交审批单据。

一次拉取调用最多拉取100个审批记录，可以通过多次拉取的方式来满足需求，但调用频率不可超过600次/分。

推荐使用此接口获取审批数据，旧接口后续将不再维护。

=head4 请求包结构体为：

	{
		"starttime" : "1569546000",
		"endtime" : "1569718800",
		"new_cursor" : "" ,
		"size" : 100 ,
		"filters" : [
			{
				"key": "template_id",
				"value": "ZLqk8pcsAoaXZ1eY56vpAgfX28MPdYU3ayMaSPHaaa"
			},
			{
				"key" : "creator",
				"value" : "WuJunJie"
			},
			{
				"key" : "department",
				"value" : "1"
			},       
			{
				"key" : "sp_status",
				"value" : "1"
			}     
		]
	}

=head4 参数说明：

	参数		必须		说明
	access_token	是	调用接口凭证。必须使用审批应用或企业内自建应用的secret获取，获取方式参考：文档-获取access_token
	starttime	是	审批单提交的时间范围，开始时间，UNix时间戳
	endtime	是	审批单提交的时间范围，结束时间，Unix时间戳
	new_cursor	是	分页查询游标，默认为空串，后续使用返回的new_next_cursor进行分页拉取
	size	是	一次请求拉取审批单数量，默认值为100，上限值为100。若accesstoken为自建应用，仅允许获取在应用可见范围内申请人提交的表单，返回的sp_no_list个数可能和size不一致，开发者需用next_cursor判断表单记录是否拉取完
	filters	否	筛选条件，可对批量拉取的审批申请设置约束条件，支持设置多个条件
	└ key	否	筛选类型，包括：
				template_id - 模板类型/模板id；
				creator - 申请人；
				department - 审批单提单者所在部门；
				sp_status - 审批状态;
				record_type - 审批单类型属性，1-请假；2-打卡补卡；3-出差；4-外出；5-加班； 6- 调班；7-会议室预定；8-退款审批；9-红包报销审批
				注意:
				1、仅“部门”支持同时配置多个筛选条件。
				2、不同类型的筛选条件之间为“与”的关系，同类型筛选条件之间为“或”的关系
				3、record_type筛选类型仅支持2021/05/31以后新提交的审批单，历史单不支持表单类型属性过滤
	└ value	否	筛选值，对应为：template_id-模板id；creator-申请人userid ；department-所在部门id；sp_status-审批单状态（1-审批中；2-已通过；3-已驳回；4-已撤销；6-通过后撤销；7-已删除；10-已支付）

1 接口频率限制 600次/分钟
2 请求的参数endtime需要大于startime， 起始时间跨度不能超过31天；
3 老的分页游标字段cursor和next_cursor待废弃，请开发者使用新字段new_cursor和new_next_cursor。


=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「审批 - 可调用接口的应用」中
	代开发应用	具有「审批」权限
	第三方应用	具有「审批」权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"sp_no_list": [
			"201909270001",
			"201909270002",
			"201909270003"
		]
	}

=head4 RETURN 参数说明

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    sp_no_list	审批单号列表，包含满足条件的审批申请
    next_cursor	后续请求查询的游标，当返回结果没有该字段时表示审批单已经拉取完

=head4 RETURN 错误说明

	错误码	说明
	301055	无审批应用数据拉取权限
	301025	请求参数错误
	301026	批量拉取审批单内部接口失败

=cut

sub getapprovalinfo {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/getapprovalinfo?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getapprovaldetail(access_token, hash);

获取审批申请详情
最后更新：2024/01/16

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/91983>

=head3 请求说明：

=head4 请求包结构体为：

    {
      "sp_no" : 201909270001
    }

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证。必须使用审批应用或企业内自建应用的secret获取，获取方式参考：文档-获取access_token
    sp_no	是	审批单编号。

接口频率限制 600次/分钟

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「审批 - 可调用接口的应用」中
	代开发应用	具有「审批」权限
	第三方应用	具有「审批」权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"info": {
			"sp_no": "201909270002",
			"sp_name": "全字段",
			"sp_status": 1,
			"template_id": "Bs5KJ2NT4ncf4ZygaE8MB3779yUW8nsMaJd3mmE9v",
			"apply_time": 1569584428,
			"applyer": {
				"userid": "WuJunJie",
				"partyid": "2"
			},
			"sp_record": [{
				"sp_status": 1,
				"approverattr": 1,
				"details": [{
						"approver": {
							"userid": "WuJunJie"
						},
						"speech": "",
						"sp_status": 1,
						"sptime": 0,
						"media_id": []
					},
					{
						"approver": {
							"userid": "WangXiaoMing"
						},
						"speech": "",
						"sp_status": 1,
						"sptime": 0,
						"media_id": []
					}
				]
			}],
			"notifyer": [{
				"userid": "LiuXiaoGang"
			}],
			"apply_data": {
				"contents": [{
					"control": "Text",
					"id": "Text-15111111111",
					"title": [{
						"text": "文本控件",
						"lang": "zh_CN"
					}],
					"value": {
						"text": "文本填写的内容",
						"tips": [],
						"members": [],
						"departments": [],
						"files": [],
						"children": [],
						"stat_field": []
					}
				}]
			},
			"comments": [{
				"commentUserInfo": {
					"userid": "WuJunJie"
				},
				"commenttime": 1569584111,
				"commentcontent": "这是备注信息",
				"commentid": "6741314136717778040",
				"media_id": [
					"WWCISP_Xa1dXIyC9VC2vGTXyBjUXh4GQ31G-a7jilEjFjkYBfncSJv0kM1cZAIXULWbbtosVqA7hprZIUkl4GP0DYZKDrIay9vCzeQelmmHiczwfn80v51EtuNouzBhUBTWo9oQIIzsSftjaVmd4EC_dj5-rayfDl6yIIRdoUs1V_Gz6Pi3yH37ELOgLNAPYUSJpA6V190Xunl7b0s5K5XC9c7eX5vlJek38rB_a2K-kMFMiM1mHDqnltoPa_NT9QynXuHi"
				]
			}]
		}
	}

=head4 RETURN 参数说明

	参数		说明
	sp_no	审批编号
	sp_name	审批申请类型名称（审批模板名称）
	sp_status	申请单状态：1-审批中；2-已通过；3-已驳回；4-已撤销；6-通过后撤销；7-已删除；10-已支付
	template_id	审批模板id。可在“获取审批申请详情”、“审批状态变化回调通知”中获得，也可在审批模板的模板编辑页面链接中获得。
	apply_time	审批申请提交时间,Unix时间戳
	applyer	申请人信息
	└ userid	申请人userid
	└ partyid	申请人所在部门id
	sp_record	审批流程信息，可能有多个审批节点。
	└ sp_status	审批节点状态：1-审批中；2-已同意；3-已驳回；4-已转审；11-已退回；12-已加签；13-已同意并加签
	└ approverattr	节点审批方式：1-或签；2-会签
	└ details	审批节点详情,一个审批节点有多个审批人
	└ └ approver	分支审批人
	└ └ └ userid	分支审批人userid
	└ └ speech	审批意见
	└ └ sp_status	分支审批人审批状态：1-审批中；2-已同意；3-已驳回；4-已转审；11-已退回；12-已加签；13-已同意并加签
	└ └ sptime	节点分支审批人审批操作时间戳，0表示未操作
	└ └ media_id	节点分支审批人审批意见附件，media_id具体使用请参考：文档-获取临时素材
	notifyer	抄送信息，可能有多个抄送节点
	└ userid	节点抄送人userid
	apply_data	审批申请数据
	└ contents	审批申请详情，由多个表单控件及其内容组成
	└ └ control	控件类型：Text-文本；Textarea-多行文本；Number-数字；Money-金额；Date-日期/日期+时间；Selector-单选/多选；；Contact-成员/部门；Tips-说明文字；File-附件；Table-明细；Attendance-假勤；Vacation-请假；PunchCorrection-补卡;DateRange-时长
	└ └ id	控件id
	└ └ title	控件名称 ，若配置了多语言则会包含中英文的控件名称
	└ └ value	控件值 ，包含了申请人在各种类型控件中输入的值，不同控件有不同的值，具体说明详见附录
	└ └ hidden	控件隐藏标识，为1表示控件被隐藏
	comments	审批申请备注信息，可能有多个备注节点
	└ commentUserInfo	备注人信息
	└ └ userid	备注人userid
	└ commenttime	备注提交时间戳，Unix时间戳
	└ commentcontent	备注文本内容
	└ commentid	备注id
	└ media_id	备注附件id，可能有多个，media_id具体使用请参考：文档-获取临时素材

=head4 附录：各控件apply_data/contents/value参数介绍

L<https://developer.work.weixin.qq.com/document/path/91983#附录：各控件apply-datacontentsvalue参数介绍>

=head4 RETURN 错误说明

	错误码	说明
	301055	无审批应用数据拉取权限
	301025	请求参数错误
	301026	拉取审批申请详情内部接口失败

=cut

sub getapprovaldetail {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/getapprovaldetail?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}



1;
__END__
