package QQ::weixin::work::media;

=encoding utf8

=head1 Name

QQ::weixin::work::corp

=head1 DESCRIPTION

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.06';
our @EXPORT = qw/ get /;

=head1 FUNCTION

=head2 get(access_token, media_id);

获取临时素材

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90254>

=head3 请求说明：

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    media_id	是	媒体文件id, 见上传临时素材

=head4 权限说明：

完全公开，media_id在同一企业内所有应用之间可以共享。

=head3 RETURN 返回结果：

正确时返回（和普通的http下载相同，请根据http头做相应的处理）：

	HTTP/1.1 200 OK
	Connection: close
	Content-Type: image/jpeg 
	Content-disposition: attachment; filename="MEDIA_ID.jpg"
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

sub get {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $media_id = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->get("https://qyapi.weixin.qq.com/cgi-bin/media/get?access_token=$access_token&media_id=$media_id");
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
