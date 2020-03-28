package QQ::weixin::work;

=pod

=encoding utf8

=head1 Name

QQ::weixin::work

=head1 DESCRIPTION

腾讯企业微信->服务端API接口文档

=head1 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90664>

服务端API开放了丰富的能力接口，开发者可以借助接口能力，实现企业服务及企业微信的集成。

支持的能力，通过目录导航可以快速预览，目录树按功能块聚合归类，如通讯录管理、消息推送等。

=head2 企业开发流程如下：

    1.获取企业微信的CorpID和CorpSecret：企业微信管理员通过启用应用，获取CorpID和CorpSecret

    2.开发对接相关接口：开发测试应用，对接企业微信接口

=head1 权限说明

每个应用有不同的secret，代表了对应用的不同权限

=cut

use strict;
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.04';
our @EXPORT = qw/ gettoken getcallbackip /;

=head1 FUNCTION

=head2 gettoken(corpid,corpsecrect);

获取ACCESS_TOKEN

=head3 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/91039>

=head3 参数说明

    参数          必须  说明
    corpid      是   企业ID，获取方式参考：术语说明-corpid L<https://work.weixin.qq.com/api/doc/90000/90135/91039#14953/corpid>
    corpsecret  是   应用的凭证密钥，获取方式参考：术语说明-secret L<https://work.weixin.qq.com/api/doc/90000/90135/91039#14953/secret>

=head3 RETURN 返回结果

  {
    "errcode": 0,
    "errmsg": "ok",
    "access_token": "accesstoken000001",
    "expires_in": 7200
  }

=head4 RETURN 参数说明

    参数              说明
    errcode	       出错返回码，为0表示成功，非0表示调用失败
    errmsg	       返回码提示语
    access_token	 获取到的凭证，最长为512字节
    expires_in	   凭证的有效时间（秒）

=head3 注意事项

  开发者需要缓存access_token，用于后续接口的调用（注意：不能频繁调用gettoken接口，否则会受到频率拦截）。当access_token失效或过期时，需要重新获取。

  access_token的有效期通过返回的expires_in来传达，正常情况下为7200秒（2小时），有效期内重复获取返回相同结果，过期后获取会返回新的access_token。

  由于企业微信每个应用的access_token是彼此独立的，所以进行缓存时需要区分应用来进行存储。

  access_token至少保留512字节的存储空间。

  企业微信可能会出于运营需要，提前使access_token失效，开发者应实现access_token失效时重新获取的逻辑。

=cut

sub gettoken {
    if ( @_ && $_[0] && $_[1] ) {
        my $corpid = $_[0];
        my $corpsecret = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$corpid&corpsecret=$corpsecret");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getcallbackip(corpid,corpsecrect);

获取企业微信服务器的ip段

=head3 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90930>

=head3 参数说明

    参数          必须  说明
    access_token	是	调用接口凭证

=head3 RETURN 返回结果

  {
    "ip_list":[
      "182.254.11.176",
      "182.254.78.66"
      ],
      "errcode":0,
      "errmsg":"ok"
  }

=head4 RETURN 参数说明

    参数       类型       说明
    ip_list	StringArray	企业微信回调的IP段
    errcode	int	错误码，0表示成功，非0表示调用失败
    errmsg	string	错误信息，调用失败会有相关的错误信息返回

=head3 注意事项

  若调用失败，会返回errcode及errmsg（判断是否调用失败，根据errcode存在并且值非0）

  根据errcode值非0，判断调用失败。以下是access_token过期的返回示例：

  {
    "ip_list":[],
    "errcode":42001,
    "errmsg":"access_token expired, hint: [1576065934_28_e0fae07666aa64636023c1fa7e8f49a4], from ip: 9.30.0.138, more info at https://open.work.weixin.qq.com/devtool/query?e=42001"
  }

=cut

sub getcallbackip {
    if ( @_ && $_[0] ) {
        my $access_token = $_[0];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/getcallbackip?access_token=$access_token");
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
