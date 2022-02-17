package QQ::weixin::work::oa::journal;

=encoding utf8

=head1 Name

QQ::weixin::work::oa::journal

=head1 DESCRIPTION

日历

=cut

use strict;
use base qw(QQ::weixin::work::oa);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.06';
our @EXPORT = qw/ get_record_list get_record_detail get_stat_list /;

=head1 FUNCTION

=head2 get_record_list(access_token, hash);

批量获取汇报记录单号

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93393>

=head3 请求说明：

企业可通过access_token调用本接口，以获取企业一段时间内企业微信“汇报应用”汇报记录编号，支持按汇报表单ID、申请人、部门等条件筛选。

一次拉取调用最多拉取100个汇报记录，可以通过多次拉取的方式来满足需求，但调用频率不可超过600次/分。

表单ID的获取方式：
管理后台--汇报应用--某个汇报的内容设置页--点击“汇报名称”，即可获取

=head4 请求包结构体为：

    {
		"starttime": 1606230000,
		"endtime": 1606361304,
		"cursor": 0,
		"limit": 10,
		"filters": [
			{
				"key": "creator",
				"value": "kele"
			},
			{
				"key": "department",
				"value": "1"
			},
			{
				"key": "template_id",
				"value": "3TmALk1ogfgKiQE3e3jRwnTUhMTh8vca1N8zUVNUx"
			}
		]
	}

=head4 参数说明：

    参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	starttime	是	uint32	开始时间
	endtime	是	uint32	结束时间,开始时间和结束时间间隔不能超过一个月
	cursor	是	uint32	游标首次请求传0，非首次请求携带上一次请求返回的next_cursor
	limit	是	uint32	拉取条数
	filters	否	obj[]	过滤条件
	filters.key	否	string	-不多于256字节，creator指定汇报记录提单人；department指定提单人所在部门；template_id指定模板
	filters.value	否	string	-不多于256字节

=head3 权限说明

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"journaluuid_list": [
			"41eJejN57EJNzr8HrZfmKyCN7xwKw1qRxCZUxCVuo9fsWVMSKac6nk4q8rARTDaVNdg",
			"41eJejN57EJNzr8HrZfmKy7rmnZS5HGzpqUefyqCRhjdY9GWQQ6gcaNfaW6GPAdG5cg",
			"41eJejN57EJNzr8HrZfmKy2mkwnjMJPgE6UZfqnW5qMeZ1ag3qr1Amb98DbtVH89VJx",
			"41eJejN57EJNzr8HrZfmKyGXVp9cRByeSREpFtReMKpuAPYZYiCU4em8JKJNmCBYmxg",
			"41eJejN57EJNzr8HrZfmKy3NphvW9E8bYRTAMWcwo9oPhVEFv9cE2jUry8ZNsZYjuUx",
			"41eJejN57EJNzr8HrZfmKyDqJCnct6mYayM4tiEXGmoYmfUp1nDdNQSyxemtBHZa3ss",
			"41eJejN57EJNzr8HrZfmKyHr64ZdZa6JHYztDaS6hCmPMKtBN3YvD1FSFmauNU36Wxd",
			"41eJejN57EJNzr8HrZfmKyChHx58aDhGrvN7yKywBJs33yzUyqUF11sdBFcUBou2NQx",
			"41eJejN57EJNzr8HrZfmKy4w4AtPJyxQoGWmv7hnrZYwmdWVJQEhvgxT5mjEbC1xP43",
			"41eJejN57EJNzr8HrZfmKyFcSr1RLmAoBS7fnwiFcQJuVQfYZwcork67DZ36YFijmR2"
		],
		"next_cursor": 34,
		"endflag": 0
	}

=head3 RETURN 参数说明

    参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	journaluuid_list	string[]	汇报记录id列表
	next_cursor	uint32	下一次拉取游标
	endflag	uint32	0代表还有数据，1代表已无数据

=head3 错误说明：

	错误码	说明
	301065	无汇报应用数据拉取权限
	301066	请求参数错误
	301067	接口内部失败

=cut

sub get_record_list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/journal/get_record_list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_record_detail(access_token, hash);

获取汇报记录详情

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93394>

=head3 请求说明：

企业可通过access_token调用本接口，根据汇报记录单号查询企业微信“汇报应用”的汇报详情。

=head4 请求包结构体为：

    {
		"journaluuid": "41eJejN57EJNzr8HrZfmKyCN7xwKw1qRxCZUxCVuo9fsWVMSKac6nk4q8rARTDaVNdx"
	}

=head4 参数说明：

    参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	journaluuid	是	string	-不多于256字节

=head3 权限说明

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"info": {
			"journal_uuid": "41eJejN57EJNzr8HrZfmKyJZ6E3W9NQbr94x6QEA6MwvK2sVqFQNWy4BaF4Ptyzk26",
			"template_name": "今日工作汇报",
			"report_time": 1606365591,
			"submitter": {
				"userid": "LiQiJun"
			},
			"receivers": [
				{
					"userid": "LiQiJun"
				}
			],
			"readed_receivers": [
				{
					"userid": "LiQiJun"
				}
			],
			"apply_data": {
				"contents": [
					{
						"control": "Text",
						"id": "Text-1606365477123",
						"title": [
							{
								"text": "工作内容",
								"lang": "zh_CN"
							}
						],
						"value": {
							"text": "今日暂无工作",
							"tips": [],
							"members": [],
							"departments": [],
							"files": [],
							"children": [],
							"stat_field": [],
							"sum_field": [],
							"related_approval": [],
							"students": [],
							"classes": []
						}
					}
				]
			},
			"comments": [
				{
					"commentid": 6899287783354824502,
					"tocommentid": 0,
					"comment_userinfo": {
						"userid": "LiYiBo"
					},
					"content": "加油",
					"comment_time": 1606365615
				}
			]
		}
	}

=head3 RETURN 参数说明

    参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	info	obj	汇报详情
	info.journal_uuid	string	汇报记录id
	info.template_name	string	汇报表单名称
	info.template_id	string	汇报表单id
	info.report_time	int32	汇报时间
	info.submitter	obj	汇报提交者
	info.submitter.userid	string	汇报用户id
	info.receivers	obj[]	汇报接收对象
	info.receivers.userid	string	接收用户id
	info.readed_receivers	obj[]	已读用户
	info.readed_receivers.userid	string	已读用户id
	info.apply_data	obj	表单数据
	info.apply_data.contents	obj[]	表单字段列表
	info.apply_data.contents.control	string	控件类型：Text-文本；Textarea-多行文本；Number-数字；Money-金额；Date-日期/日期+时间；Selector-单选/多选；；Contact-成员/部门；Tips-说明文字；File-附件；Table-明细；DateRange-时长
	info.apply_data.contents.id	string	控件id
	info.apply_data.contents.title	obj	控件名称 ，若配置了多语言则会包含中英文的控件名称
	info.apply_data.contents.value	obj	控件值 ，包含了申请人在各种类型控件中输入的值，不同控件有不同的值，具体说明详见附录
	info.sys_journal_data	string	“汇报”模板数据，内容为富文本。“汇报”模板是一个特殊模板其表单不在apply_data中返回
	info.comments	obj[]	评论
	info.comments.commentid	uint64	评论id
	info.comments.tocommentid	uint64	评论回复id
	info.comments.comment_userinfo	obj	评论用户
	info.comments.comment_userinfo.userid	string	评论用户id
	info.comments.content	string	评论内容
	info.comments.comment_time	uint32	评论时间

=head3 错误说明：

	错误码	说明
	301065	无汇报应用数据拉取权限
	301066	请求参数错误
	301067	接口内部失败

=cut

sub get_record_detail {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/journal/get_record_detail?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_stat_list(access_token, hash);

获取汇报统计数据

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93395>

=head3 请求说明：

企业可通过access_token调用本接口，根据汇报表单id查询企业微信“汇报应用”的汇报统计汇总信息。该接口只能拉取到已经汇总的统计数据，对于尚未完成汇总的周期不会返回。

=head4 请求包结构体为：

    {
		"template_id": "3TmALk1ogfgKiQE3e3jRwnTUhMTh8vca1N8zUVNUx",
		"starttime": 1604160000,
		"endtime": 1606363092
	}

=head4 参数说明：

    参数	必须	类型	说明
	access_token	是	string	调用接口凭证
	template_id	是	string	汇报表单id,不多于256字节
	starttime	是	uint64	开始时间
	endtime	是	uint64	结束时间，时间区间最大长度为一年

=head3 权限说明

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok",
		"stat_list": [
			{
				"template_id": "3TmALk1ogfgKiQE3e3jRwnTUhMTh8vca1N8zUVNU",
				"template_name": "日报",
				"report_range": {
					"user_list": [
						{
							"userid": "user1"
						}
					],
					"party_list": [
						{
							"open_partyid": "1"
						}
					],
					"tag_list": []
				},
				"white_range": {
					"user_list": [],
					"party_list": [],
					"tag_list": []
				},
				"receivers": {
					"user_list": [
						{
							"userid": "user3"
						}
					],
					"tag_list": [],
					"leader_list": []
				},
				"cycle_begin_time": 1606147200,
				"cycle_end_time": 1606233600,
				"stat_begin_time": 1606147200,
				"stat_end_time": 1606230000,
				"report_list": [
					{
						"user": {
							"userid": "user2"
						},
						"itemlist": [
							{
								"journaluuid": "4U9abSUrpY78VNxeNNv3J5TW5e9VLj8cDymH9py1Efpuj5X8QCDQx3stKr69pia3UL8auRjrCMsiRjgzL8mvKnff",
								"reporttime": 1606218548,
								"flag": 0
							}
						]
					}
				],
				"unreport_list": [
					{
						"user": {
							"userid": "user1"
						},
						"itemlist": [
							{
								"journaluuid": "",
								"reporttime": 1606147200,
								"flag": 0
							}
						]
					},
					{
						"user": {
							"userid": "user3"
						},
						"itemlist": [
							{
								"journaluuid": "",
								"reporttime": 1606147200,
								"flag": 0
							}
						]
					}
				],
				"report_type": 2
			}
		]
	}

=head3 RETURN 参数说明

    参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	stat_list	obj[]	统计数据列表
	stat_list.template_id	string	汇报表单id
	stat_list.template_name	string	汇报表单名称
	stat_list.report_range	obj	汇报人员范围
	stat_list.report_range.user_list	obj[]	指定人集合
	stat_list.report_range.user_list.userid	string	用户id
	stat_list.report_range.party_list	obj[]	指定部门集合
	stat_list.report_range.party_list.open_partyid	string	部门id
	stat_list.report_range.tag_list	obj[]	指定标签集合
	stat_list.report_range.tag_list.open_tagid	string	标签id
	stat_list.white_range	obj	白名单集合
	stat_list.white_range.user_list	obj[]	指定人集合
	stat_list.white_range.user_list.userid	string	用户id
	stat_list.white_range.party_list	obj[]	指定部门集合
	stat_list.white_range.party_list.open_partyid	string	部门id
	stat_list.white_range.tag_list	obj[]	指定标签集合
	stat_list.white_range.tag_list.open_tagid	string	标签id
	stat_list.receivers	obj	固定汇报对象
	stat_list.receivers.user_list	obj[]	指定人集合
	stat_list.receivers.user_list.userid	string	用户id
	stat_list.receivers.tag_list	obj[]	指定标签集合
	stat_list.receivers.tag_list.open_tagid	string	标签id
	stat_list.receivers.leader_list	obj[]	指定上级集合
	stat_list.receivers.leader_list.level	uint64	上级级别从1开始
	stat_list.cycle_begin_time	uint64	周期开始时间
	stat_list.cycle_end_time	uint64	周期结束时间
	stat_list.stat_begin_time	uint64	统计开始时间
	stat_list.stat_end_time	uint64	统计结束时间
	stat_list.report_list	obj[]	已汇报用户列表
	stat_list.report_list.user	obj	汇报用户
	stat_list.report_list.user.userid	string	用户id
	stat_list.report_list.itemlist	obj[]	汇报记录列表
	stat_list.report_list.itemlist.journaluuid	string	汇报记录id
	stat_list.report_list.itemlist.reporttime	uint32	汇报时间
	stat_list.report_list.itemlist.flag	uint32	是否迟交，1迟交;0非迟交
	stat_list.unreport_list	obj[]	未汇报用户列表
	stat_list.unreport_list.user	obj	未汇报用户
	stat_list.unreport_list.user.userid	string	用户id
	stat_list.report_type	uint32	汇报方式：2按日汇报; 3按周汇报; 4按月汇报

=head3 错误说明：

	错误码	说明
	301065	无汇报应用数据拉取权限
	301066	请求参数错误
	301067	接口内部失败

=cut

sub get_stat_list {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/journal/get_stat_list?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
