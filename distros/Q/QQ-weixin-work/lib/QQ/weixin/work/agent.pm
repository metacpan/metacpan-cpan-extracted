package QQ::weixin::work::agent;

=encoding utf8

=head1 Name

QQ::weixin::work::agent

=head1 DESCRIPTION

应用管理

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.04';
our @EXPORT = qw/ get list set /;

=head1 FUNCTION

=head2 get(access_token,agentid);

获取指定的应用详情

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90227>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    agentid	是	应用id

=head4 权限说明：

企业仅可获取当前凭证对应的应用；第三方仅可获取被授权的应用。

=head3 RETURN 返回结果：

    {
    	"errcode": 0,
    	"errmsg": "ok",
      "agentid": 1000005,
      "name": "HR助手",
      "square_logo_url":  "https://p.qlogo.cn/bizmail/FicwmI50icF8GH9ib7rUAYR5kicLTgP265naVFQKnleqSlRhiaBx7QA9u7Q/0",
      "description": "HR服务与员工自助平台",
      "allow_userinfos": {
        "user": [
             {"userid": "zhangshan"},
             {"userid": "lisi"}
             ]
           },
      "allow_partys": {
       "partyid": [1]
     },
     "allow_tags": {
       "tagid": [1,2,3]
     },
     "close": 0,
     "redirect_domain": "open.work.weixin.qq.com",
     "report_location_flag": 0,
     "isreportenter": 0,
     "home_url": "https://open.work.weixin.qq.com"
    }

=head4 RETURN 参数说明：

    参数	        说明
    errcode	    出错返回码，为0表示成功，非0表示调用失败
    errmsg	返回码提示语
    agentid	企业应用id
    name	企业应用名称
    square_logo_url	企业应用方形头像
    description	企业应用详情
    allow_userinfos	企业应用可见范围（人员），其中包括userid
    allow_partys	企业应用可见范围（部门）
    allow_tags	企业应用可见范围（标签）
    close	企业应用是否被停用
    redirect_domain	企业应用可信域名
    report_location_flag	企业应用是否打开地理位置上报 0：不上报；1：进入会话上报；
    isreportenter	是否上报用户进入应用事件。0：不接收；1：接收
    home_url	应用主页url

=cut

sub get {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $agentid = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/agent/get?access_token=$access_token&agentid=$agentid");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 list(access_token);

获取access_token对应的应用列表

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90227>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证

=head4 权限说明：

企业仅可获取当前凭证对应的应用；第三方仅可获取被授权的应用。

=head3 RETURN 返回结果：

    {
    	"errcode": 0,
    	"errmsg": "ok",
      "agentlist":[
          {
              "agentid": 1000005,
              "name": "HR助手",
              "square_logo_url": "https://p.qlogo.cn/bizmail/FicwmI50icF8GH9ib7rUAYR5kicLTgP265naVFQKnleqSlRhiaBx7QA9u7Q/0"
          }
      ]
    }

=head4 RETURN 参数说明：

    参数	        说明
    errcode	    出错返回码，为0表示成功，非0表示调用失败
    errmsg	返回码提示语
    agentlist	AgentItemArray	当前凭证可访问的应用列表

AgentItem 结构：

    参数	类型	说明
    agentid	Integer	企业应用id
    name	String	企业应用名称
    square_logo_url	String	企业应用方形头像url

=cut

sub list {
    if ( @_ && $_[0] ) {
        my $access_token = $_[0];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/agent/get?access_token=$access_token");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 set(access_token, hash);

设置应用

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90228>

=head3 请求说明：

=head4 请求包结构体为：

    {
      "agentid": 1000005,
      "report_location_flag": 0,
      "logo_mediaid": "j5Y8X5yocspvBHcgXMSS6z1Cn9RQKREEJr4ecgLHi4YHOYP-plvom-yD9zNI0vEl",
      "name": "财经助手",
      "description": "内部财经服务平台",
      "redirect_domain": "open.work.weixin.qq.com",
      "isreportenter": 0,
      "home_url": "https://open.work.weixin.qq.com"
    }

=head4 参数说明：

    参数	必须	说明
    access_token	是	调用接口凭证
    agentid	是	企业应用的id
    report_location_flag	否	企业应用是否打开地理位置上报 0：不上报；1：进入会话上报；
    logo_mediaid	否	企业应用头像的mediaid，通过素材管理接口上传图片获得mediaid，上传后会自动裁剪成方形和圆形两个头像
    name	否	企业应用名称，长度不超过32个utf8字符
    description	否	企业应用详情，长度为4至120个utf8字符
    redirect_domain	否	企业应用可信域名。注意：域名需通过所有权校验，否则jssdk功能将受限，此时返回错误码85005
    isreportenter	否	是否上报用户进入应用事件。0：不接收；1：接收。
    home_url	否	应用主页url。url必须以http或者https开头（为了提高安全性，建议使用https）。

=head3 权限说明

仅企业可调用，可设置当前凭证对应的应用；第三方不可调用。

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok"
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容

=cut

sub set {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/agent/set?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
