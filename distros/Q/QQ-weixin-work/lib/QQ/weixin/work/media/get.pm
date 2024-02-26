package QQ::weixin::work::media::get;

=encoding utf8

=head1 Name

QQ::weixin::work::media::get

=head1 DESCRIPTION

=cut

use strict;
use base qw(QQ::weixin::work::media);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ jssdk /;

=head1 FUNCTION

=head2 jssdk(access_token, media_id);

获取高清语音素材
最后更新：2017/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90255>

=head3 请求说明：

可以使用本接口获取从JSSDK的uploadVoice接口上传的临时语音素材，格式为speex，16K采样率。该音频比上文的临时素材获取接口（格式为amr，8K采样率）更加清晰，适合用作语音识别等对音质要求较高的业务。

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    media_id	是	媒体文件id，见上传临时素材，以及异步上传临时素材（超过20M需使用Range分块下载，且分块大小不超过20M，否则返回错误码830002）

=head4 权限说明：

仅企业微信2.4及以上版本支持。
完全公开，media_id在同一企业内所有应用之间可以共享。

=head3 RETURN 返回结果：

正确时返回（和普通的http下载相同，请根据http头做相应的处理）：

   HTTP/1.1 200 OK
   Connection: close
   Content-Type: voice/speex 
   Content-disposition: attachment; filename="XXX"
   Date: Sun, 06 Jan 2013 10:20:18 GMT
   Cache-Control: no-cache, must-revalidate
   Content-Length: 339721
   
   Xxxx

错误时返回（这里省略了HTTP首部）：

    {
    	"errcode": 40007,
    	"errmsg": "invalid media_id"
    }

=head4 RETURN 参数说明：

	参数	        说明
    errcode	    出错返回码
    errmsg	对返回码的文本描述内容

=cut

sub jssdk {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $media_id = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/media/get/jssdk?access_token=$access_token&media_id=$media_id");
        if ($response->is_success) {
            my $reply;
            $reply->{"content-type"} = $response->content_type;
            $reply->{filename} = $response->filename;
            $reply->{data} = $response->decoded_content;
            return $reply;
#            return $response->decoded_content;
        }

    }
    return 0;
}

1;
__END__
