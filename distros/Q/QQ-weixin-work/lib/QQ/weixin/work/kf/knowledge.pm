package QQ::weixin::work::kf::knowledge;

=encoding utf8

=head1 Name

QQ::weixin::work::kf::knowledge

=head1 DESCRIPTION

=cut

use strict;
use base qw(QQ::weixin::work::kf);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ add_group del_group mod_group list_group
				add_intent del_intent mod_intent list_intent /;

=head1 FUNCTION

=head2 知识库分组管理
最后更新：2023/11/30

=head3 请求说明：

通过分组管理接口，可操作企业管理后台-微信客服-机器人-知识库的分组数据。

相关的约束条件跟管理后台一致：

分组名不能重复
全部分组数上限为100

=head4 权限说明:

调用的应用需要满足如下的权限

应用类型	权限要求
自建应用	配置到「 微信客服- 可调用接口的应用」中
第三方应用	暂不支持
代开发自建应用	暂不支持
注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head2 add_group(access_token, hash);

添加分组

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95971#添加分组>

=head3 请求说明：

可通过此接口创建新的知识库分组。

=head4 请求包结构体为：

	{
		"name": "分组名"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	调用接口凭证
	name	stirng	是	分组名。不超过12个字

=head3 权限说明

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"group_id" "GROUP_ID"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	group_id	string	分组ID

=cut

sub add_group {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/knowledge/add_group?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del_group(access_token, hash);

删除分组

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95971#删除分组>

=head3 请求说明：

可通过此接口删除已有的知识库分组，但不能删除系统创建的默认分组。

=head4 请求包结构体为：

	{
		"group_id": "GROUP_ID"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	调用接口凭证
	group_id	string	是	分组ID

=head3 权限说明

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述

=cut

sub del_group {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/knowledge/del_group?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 mod_group(access_token, hash);

修改分组

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95971#修改分组>

=head3 请求说明：

可通过此接口修改已有的知识库分组，但不能修改系统创建的默认分组。

=head4 请求包结构体为：

	{
		"group_id": "GROUP_ID"，
		"name": "分组名"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	调用接口凭证
	group_id	string	是	分组ID
	name	stirng	是	分组名。不超过12个字

=head3 权限说明

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述

=cut

sub mod_group {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/knowledge/mod_group?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list_group(access_token, hash);

获取分组列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95971#获取分组列表>

=head3 请求说明：

可通过此接口分页获取所有的知识库分组。

=head4 请求包结构体为：

	{
		"cursor": "CURSOR"，
		"limit": 100,
		"group_id": "GROUP_ID"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	调用接口凭证
	cursor	string	否	上一次调用时返回的next_cursor，第一次拉取可以不填
	limit	uint32	否	每次拉取的数据量，默认值500，最大值为1000
	group_id	string	否	分组ID。可指定拉取特定的分组

=head3 权限说明

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"next_cursor": "NEXT_CURSOR",
		"has_more"：1,
		"group_list": [
			{
				"group_id": "GROUP_ID",
				"name": "NAME",
				"is_default": 1
			}, {
				"group_id": "GROUP_ID",
				"name": "NAME",
				"is_default": 0
			}
		]
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	next_cursor	string	分页游标，再下次请求时填写以获取之后分页的记录
	has_more	uint32	是否还有更多数据。0-没有 1-有
	group_list	obj[]	分组列表
	group_list[].group_id	string	分组ID
	group_list[].name	string	分组名
	group_list[].is_default	uint32	是否为默认分组。0-否 1-是。默认分组为系统自动创建，不可修改/删除

=cut

sub list_group {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/knowledge/list_group?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 知识库问答管理
最后更新：2023/11/30

=head3 请求说明：

通过问答管理接口，可操作企业管理后台-微信客服-机器人-知识库的问答数据。

相关的约束条件跟管理后台一致：

不同分组的问题不能重复
单个分组的问答数上限为200

=head4 权限说明:

调用的应用需要满足如下的权限

应用类型	权限要求
自建应用	配置到「 微信客服- 可调用接口的应用」中
第三方应用	暂不支持
代开发自建应用	暂不支持
注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head2 add_intent(access_token, hash);

添加问答

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95972#添加问答>

=head3 请求说明：

可通过此接口创建新的知识库问答。

=head4 请求包结构体为：

	{
		"group_id": "GROUP_ID",
		"question": {
			"text": {
				"content": "主问题"
			}
		}, 
		"similar_questions": {
			"items": [
				{
					"text": {
						"content": "相似问题1"
					}
				}, 
				{
					"text": {
						"content": "相似问题2"
					}
				}
			]
		}, 
		"answers": [
			{
				"text": {
					"content": "问题的回复"
				}, 
				"attachments": [
					{
						"msgtype": "image", 
						"image": {
							"media_id": "MEDIA_ID"
						}
					}
				]
			}
		]
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	调用接口凭证
	group_id	string	是	分组ID
	question	obj	是	主问题
	question.text	obj	是	主问题文本
	question.text.content	string	是	主问题文本内容。不超过200个字
	similar_questions	obj	否	相似问题
	similar_questions.items	obj[]	否	相似问题列表。最多支持100个
	similar_questions.items[].text	obj	是	相似问题文本
	similar_questions.items[].text.content	string	是	相似问题文本内容。不超过200个字
	answers	obj[]	是	回答列表。目前仅支持1个
	answers[].text	obj	是	回答文本
	answers[].text.content	string	是	回答文本内容。不超过500个字
	answers[].attachments	obj[]	否	回答附件列表。最多支持4个
	answers[].attachments[].*	obj	是	回答附件。具体见附录-问答附件类型

=head3 权限说明

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"intent_id": "INTENT_ID"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	intent_id	string	问答ID

=cut

sub add_intent {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/knowledge/add_intent?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del_intent(access_token, hash);

删除问答

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95972#删除问答>

=head3 请求说明：

可通过此接口删除已有的知识库问答。

=head4 请求包结构体为：

	{
		"intent_id": "INTENT_ID"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	调用接口凭证
	intent_id	string	是	问答ID

=head3 权限说明

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述

=cut

sub del_intent {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/knowledge/del_intent?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 mod_intent(access_token, hash);

修改问答

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95972#修改问答>

=head3 请求说明：

可通过此接口修改已有的知识库问答。
question/similar_questions/answers这三部分可以按需更新，但更新的每一部分是覆盖写，需要传完整的字段。

=head4 请求包结构体为：

	{
		"intent_id": "INTENT_ID", 
		"question": {
			"text": {
				"content": "主问题"
			}
		}, 
		"similar_questions": {
			"items": [
				{
					"text": {
						"content": "相似问题1"
					}
				}, 
				{
					"text": {
						"content": "相似问题2"
					}
				}
			]
		}, 
		"answers": [
			{
				"text": {
					"content": "问题的回复"
				}, 
				"attachments": [
					{
						"msgtype": "image", 
						"image": {
							"media_id": "MEDIA_ID"
						}
					}
				]
			}
		]
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	调用接口凭证
	intent_id	string	是	问答ID
	question	obj	否	主问题
	question.text	obj	否	主问题文本
	question.text.content	string	是	主问题文本内容
	similar_questions	obj	否	相似问题
	similar_questions.items	obj[]	否	相似问题列表。最多支持100个
	similar_questions.items[].text	obj	是	相似问题文本
	similar_questions.items[].text.content	string	是	相似问题文本内容
	answers	obj[]	否	回答列表。目前仅支持1个
	answers[].text	obj	是	回答文本
	answers[].text.content	string	是	回答文本内容
	answers[].attachments	obj[]	否	回答附件列表。最多支持4个
	answers[].attachments[].*	obj	是	回答附件。具体见附录-问答附件类型

=head3 权限说明

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述

=cut

sub mod_intent {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/knowledge/mod_intent?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list_intent(access_token, hash);

获取问答列表

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95972#获取问答列表>

=head3 请求说明：

可通过此接口分页获取的知识库问答详情列表。

=head4 请求包结构体为：

	{
		"cursor": "CURSOR"，
		"limit": 100,
		"group_id": "GROUP_ID",
		"intent_id": "INTENT_ID"
	}

=head4 参数说明：

	参数	必须	类型	说明
	access_token	是	调用接口凭证
	cursor	string	否	上一次调用时返回的next_cursor，第一次拉取可以不填
	limit	uint32	否	每次拉取的数据量，默认值500，最大值为1000
	group_id	string	否	分组ID。可指定拉取特定分组下的问答
	intent_id	string	否	问答ID。可指定拉取特定的问答

=head3 权限说明

=head3 RETURN 返回结果

	{
		"errcode": 0, 
		"errmsg": "ok", 
		"next_cursor": "NEXT_CURSOR", 
		"has_more": 1, 
		"intent_list": [
			{
				"group_id": "GROUP_ID", 
				"intent_id": "INTENT_ID", 
				"question": {
					"text": {
						"content": "主问题"
					}, 
					"similar_questions": {
						"items": [
							{
								"text": {
									"content": "相似问题1"
								}
							}, 
							{
								"text": {
									"content": "相似问题2"
								}
							}
						]
					}, 
					"answers": [
						{
							"text": {
								"content": "问题的回复"
							}, 
							"attachments": [
								{
									"msgtype": "image", 
									"image": {
										"name": "图片（仅返回名字）.jpg"
									}
								}
							]
						}
					]
				}
			}
		]
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int	返回码
	errmsg	string	错误码描述
	next_cursor	string	分页游标，再下次请求时填写以获取之后分页的记录
	has_more	uint32	是否还有更多数据。0-没有 1-有
	intent_list	obj[]	问答摘要列表
	intent_list[].group_id	string	分组ID
	intent_list[].intent_id	string	问答ID
	intent_list[].question	obj	主问题
	intent_list[].question.text	obj	主问题文本
	intent_list[].question.text.content	string	主问题文本内容
	intent_list[].similar_questions	obj	相似问题
	intent_list[].similar_questions.items	obj[]	相似问题列表。最多支持100个
	intent_list[].similar_questions.items[].text	obj	相似问题文本
	intent_list[].similar_questions.items[].text.content	string	相似问题文本内容
	intent_list[].answers	obj[]	回答列表。目前仅支持1个
	intent_list[].answers[].text	obj	回答文本
	intent_list[].answers[].text.content	string	回答文本内容
	intent_list[].answers[].attachments	obj[]	回答附件列表。最多支持4个
	intent_list[].answers[].attachments[].*	obj	回答附件。具体见附录-问答附件类型

=cut

sub list_intent {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/kf/knowledge/list_intent?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
