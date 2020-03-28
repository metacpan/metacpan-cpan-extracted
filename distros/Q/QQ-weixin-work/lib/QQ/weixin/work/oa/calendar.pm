package QQ::weixin::work::oa::calendar;

=encoding utf8

=head1 Name

QQ::weixin::work::oa::calendar

=head1 DESCRIPTION

日历

=cut

use strict;
use base qw(QQ::weixin::work::oa);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.04';
our @EXPORT = qw/ add update get del /;

=head1 FUNCTION

=head2 add(access_token, hash);

创建日历

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/92618>

=head3 请求说明：

=head4 请求包结构体为：

    {
        "calendar" : {
            "organizer" : "userid1",
            "summary" : "test_summary",
            "color" : "#FF3030",
            "description" : "test_describe",
            "shares" : [
                {
                    "userid" : "userid2"
                },
                {
                    "userid" : "userid3"
                }
            ]
        }
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证。获取方法查看“获取access_token”
    calendar	是	日历信息
    organizer	是	指定的组织者userid。注意该字段指定后不可更新
    summary	是	日历标题。1 ~ 128 字符
    color	是	日历在终端上显示的颜色，RGB颜色编码16进制表示，例如：”#0000FF” 表示纯蓝色
    description	否	日历描述。0 ~ 512 字符
    shares	否	日历共享成员列表。最多2000人
    userid	是	日历共享成员的id

=head3 权限说明

=head3 RETURN 返回结果

    {
       "errcode": 0,
       "errmsg": "ok",
       "cal_id":"wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA"
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    cal_id	日历ID

=cut

sub add {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/calendar/add?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 update(access_token, hash);

更新日历

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/92619>

=head3 请求说明：

=head4 请求包体:

    {
        "calendar" : {
          "cal_id":"wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA",
          "summary" : "test_summary",
          "color" : "#FF3030",
          "description" : "test_describe_1",
          "shares" : [
              {
                  "userid" : "userid1"
              },
              {
                  "userid" : "userid2"
              }
          ]
        }
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    calendar	是	日历信息
    cal_id	是	日历ID
    summary	是	日历标题。1 ~ 128 字符
    color	是	日历颜色，RGB颜色编码16进制表示，例如：”#0000FF” 表示纯蓝色
    description	否	日历描述。0 ~ 512 字符
    shares	否	日历共享成员列表。最多2000人
    userid	是	日历共享成员的id

=head3 权限说明

注意, 不可更新组织者。

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

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/calendar/update?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token, hash);

获取日历

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/92621>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"cal_id_list": ["wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA"]
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    cal_id_list	是	日历ID列表。一次最多可获取1000条

=head3 权限说明

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok",
        "calendar_list": [
            {
                "cal_id": "wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA",
                "organizer": "userid1",
                "summary" : "test_summary",
                "color" : "#FF3030",
                "description": "test_describe_1",
                "shares": [
                    {
                        "userid": "userid2"
                    },
                    {
                        "userid": "userid1"
                    }
                ]
            }
        ]
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    calendar_list	日历列表
    cal_id	日历ID
    organizer	指定的组织者userid
    summary	日历标题。1 ~ 128 字符
    color	日历颜色，RGB颜色编码16进制表示，例如：”#0000FF” 表示纯蓝色
    description	日历描述。0 ~ 512 字符
    shares	日历共享成员列表。最多2000人
    userid	日历共享成员的id

=cut

sub get {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/calendar/get?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del(access_token, hash);

删除日历

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/92620>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"cal_id":"wcjgewCwAAqeJcPI1d8Pwbjt7nttzAAA"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    cal_id	是	日历ID

=head3 权限说明

=head3 RETURN 返回结果

    {
        "errcode": 0,
        "errmsg": "ok"
    }

=head3 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

=cut

sub del {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/oa/calendar/del?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
