package QQ::weixin::work::media;

=encoding utf8

=head1 Name

QQ::weixin::work::media

=head1 DESCRIPTION

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ upload uploadimg get
				upload_by_url get_upload_by_url_result
				upload_attachment /;

=head1 FUNCTION

=head2 upload(access_token, type, media);

上传临时素材
最后更新：2021/10/26

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90253>
L<https://developer.work.weixin.qq.com/document/path/90389>

=head3 请求说明：

使用multipart/form-data POST上传文件， 文件标识名为"media"

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	type	是	媒体文件类型，分别有图片（image）、语音（voice）、视频（video），普通文件（file）
	media	是	媒体路径和文件名

=head4 权限说明：

素材上传得到media_id，该media_id仅三天内有效
media_id在同一企业内所有应用之间可以共享。

POST的请求包中，form-data中媒体文件标识，应包含有 filename、filelength、content-type等信息
filename标识文件展示的名称。比如，使用该media_id发消息时，展示的文件名由该字段控制

=head3 RETURN 返回结果：

请求示例：

POST https://qyapi.weixin.qq.com/cgi-bin/media/upload?access_token=accesstoken001&type=file HTTP/1.1
Content-Type: multipart/form-data; boundary=-------------------------acebdf13572468
Content-Length: 220

---------------------------acebdf13572468
Content-Disposition: form-data; name="media";filename="wework.txt"; filelength=6
Content-Type: application/octet-stream

mytext
---------------------------acebdf13572468--


返回数据：

	{
	   "errcode": 0,
	   "errmsg": ""，
	   "type": "image",
	   "media_id": "1G6nrLmr5EC3MMb_-zK1dDdzmd0p7cNliYu9V5w7o8K0",
	   "created_at": "1380000000"
	}


=head4 RETURN 参数说明：

	参数	        说明
    type	媒体文件类型，分别有图片（image）、语音（voice）、视频（video），普通文件(file)
	media_id	媒体文件上传后获取的唯一标识，3天内有效
	created_at	媒体文件上传时间戳

上传的媒体文件限制
所有文件size必须大于5个字节

图片（image）：10MB，支持JPG,PNG格式
语音（voice） ：2MB，播放长度不超过60s，仅支持AMR格式
视频（video） ：10MB，支持MP4格式
普通文件（file）：20MB

=cut

sub upload {
    if ( @_ && $_[0] && $_[1] && $_[2] ) {
        my $access_token = $_[0];
        my $type = $_[1];
        my $file = $_[2];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/media/upload?access_token=$access_token&type=$type",[media => [$file]],Content_Type => 'multipart/form-data');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 uploadimg(access_token, media);

上传图片
最后更新：2022/01/20

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90256>

=head3 请求说明：

使用multipart/form-data POST上传文件

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	media	是	路径和文件名

=head4 权限说明：

上传图片得到图片URL，该URL永久有效
返回的图片URL，仅能用于图文消息正文中的图片展示，或者给客户发送欢迎语等；若用于非企业微信环境下的页面，图片将被屏蔽。
每个企业每月最多可上传3000张图片，每天最多可上传1000张图片

POST的请求包中，form-data中媒体文件标识，应包含有 filename、content-type等信息

=head3 RETURN 返回结果：

=head4 请求示例：

---------------------------acebdf13572468
Content-Disposition: form-data; name="fieldNameHere"; filename="20180103195745.png"
Content-Type: image/png
Content-Length: 220

<@INCLUDE *C:\Users\abelzhu\Pictures\企业微信截图_20180103195745.png*@>
---------------------------acebdf13572468--


=head4 返回数据：

	{
	   "errcode": 0,
	   "errmsg": ""，
	   "url" : "http://p.qpic.cn/pic_wework/3474110808/7a7c8471673ff0f178f63447935d35a5c1247a7f31d9c060/0"
	}


=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	url	上传后得到的图片URL。永久有效

上传的图片大小限制
图片文件大小应在 5B ~ 2MB 之间

=cut

sub uploadimg {
    if ( @_ && $_[0] && $_[1] ) {
        my $access_token = $_[0];
        my $file = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/media/uploadimg?access_token=$access_token",[media => [$file]],Content_Type => 'multipart/form-data');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get(access_token, media_id);

获取临时素材
最后更新：2022/12/26

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90254>

=head3 请求说明：

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    media_id	是	媒体文件id，见上传临时素材，以及异步上传临时素材（超过20M需使用Range分块下载，且分块大小不超过20M，否则返回错误码830002）

=head4 权限说明：

完全公开，media_id在同一企业内所有应用之间可以共享。
media_id有效期只有3天，注意要及时获取，以免过期。

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

=head2 异步上传临时素材

最后更新：2022/12/14

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/96219>

=head3 请求说明：

为了满足临时素材的大文件诉求（最高支持200M），支持指定文件的CDN链接（必须支持Range分块下载），由企微微信后台异步下载和处理，处理完成后回调通知任务完成，再通过接口主动查询任务结果。

跟普通临时素材一样，media_id仅三天内有效，media_id在同一企业内应用之间可以共享。

=head3 使用场景说明

跟上传临时素材拿到的media_id使用场景是不通用的，目前适配的接口如下：

	接口		适用场景值(scene)		说明
	获取临时素材	所有	若文件大小超过20M，必须使用Range分块下载且分块大小不超过20M，否则返回错误830002
	入群欢迎语素材管理	1	添加素材、编辑素材兼容video和file两种素材类型使用；
						获取素材返回的media_id类型则跟添加/编辑时的media_id类型对应

=head2 upload_by_url(access_token, type, media);

生成异步上传任务

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/96219#生成异步上传任务>

=head3 请求说明：

=head4 请求包结构体为：

	{
		"scene": 1,
		"type": "video",
		"filename": "video.mp4",
		"url": "https://xxxx",
		"md5": "MD5"
	}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	scene	uint32	是	场景值。1-客户联系入群欢迎语素材（目前仅支持1）。
						注意：每个场景值有对应的使用范围，详见上面的「使用场景说明」
	type	string	是	媒体文件类型。目前仅支持video-视频，file-普通文件
						不超过32字节。
	filename	string	是	文件名，标识文件展示的名称。比如，使用该media_id发消息时，展示的文件名由该字段控制。
							不超过128字节。
	url	string	是	文件cdn url。url要求支持Range分块下载
					不超过1024字节。
					如果为腾讯云cos链接，则需要设置为「公有读」权限。
	md5	string	是	文件md5。对比从url下载下来的文件md5是否一致。
					不超过32字节。

=head4 权限说明：

客户联系权限

=head4 上传的媒体文件限制

所有文件size必须大于5个字节

图片（image）：暂不支持
语音（voice） ：暂不支持
视频（video） ：200MB，仅支持MP4格式
普通文件（file）：200MB

=head3 RETURN 返回结果：

	{
	   "errcode": 0,
	   "errmsg": "ok",
	   "jobid": "jobid"
	}

=head4 RETURN 参数说明：

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    jobid	任务id。可通过此jobid查询结果

=cut

sub upload_by_url {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/media/upload_by_url?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 get_upload_by_url_result(access_token, type, media);

查询异步任务结果

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/96219#查询异步任务结果>

=head3 请求说明：

=head4 请求包结构体为：

	{
		"jobid": "JOBID"
	}


=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	jobid	string	是	任务id。最长为128字节，60分钟内有效

=head4 权限说明：

客户联系权限

=head3 RETURN 返回结果：

	{
		"errcode": 0,
		"errmsg": "ok",
		"status": 2,
		"detail": {
			"errcode": 0,
			"errmsg": "ok",
			"media_id": "3*1*G6nrLmr5EC3MMb_-zK1dDdzmd0p7cNliYu9V5w7o8K0",
			"created_at": "1380000000"
		}
	}

=head4 RETURN 参数说明：

	参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    status	string	任务状态。1-处理中，2-完成，3-异常失败
	detail	obj	结果明细
	detail.errcode	int32	任务失败返回码。当status为3时返回非0，其他返回0
	detail.errmsg	string	任务失败错误码描述
	detail.media_id	string	媒体文件上传后获取的唯一标识，3天内有效。当status为2时返回。
	detail.created_at	string	媒体文件创建的时间戳。当status为2时返回。

=head4 任务结果常见错误码列表（detail.errcode）

	错误码	错误说明	排查方法
	830001	url非法	确认url是否支持Range分块下载
	830003	url下载数据失败	确认url本身是否能正常访问
	45001	文件大小超过限制	确认文件在5字节~200M范围内
	301019	文件MD5不匹配	确认url对应的文件内容md5，跟所填的md5参数是否一致

=cut

sub get_upload_by_url_result {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/media/get_upload_by_url_result?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 upload_attachment(access_token, type, attachment_type, media);

上传附件资源
最后更新：2023/12/01

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95098>

=head3 请求说明：

使用multipart/form-data POST上传文件， 文件标识名为"media"

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
	media_type	是	媒体文件类型，分别有图片（image）、视频（video）、普通文件（file）
	attachment_type	是	附件类型，不同的附件类型用于不同的场景。1：朋友圈；2:商品图册

=head4 权限说明：

素材上传得到media_id，该media_id仅三天内有效
media_id在同一企业内所有应用之间可以共享。

注：朋友圈附件类型：如果是客户端jsapi或者小程序接口使用，仅支持企业微信客户端版本在4.0.2及以上版本使用。不然可能显示异常。

POST的请求包中，form-data中媒体文件标识，应包含有 filename、filelength、content-type等信息
filename标识文件展示的名称。比如，使用该media_id发消息时，展示的文件名由该字段控制
朋友圈附件类型，仅支持图片与视频

权限说明:
调用接口的应用需要满足如下的权限：

	应用类型	权限要求
	自建应用	配置到「客户联系 可调用接口的应用」中
	代开发应用	具有「企业客户」权限
	第三方应用	具有「企业客户」权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 请求示例：

	POST https://qyapi.weixin.qq.com/cgi-bin/media/upload_attachment?access_token=accesstoken001&media_type=TYPE&attachment_type=1  HTTP/1.1
	Content-Type: multipart/form-data; boundary=-------------------------acebdf13572468
	Content-Length: 220

	---------------------------acebdf13572468
	Content-Disposition: form-data; name="media";filename="wework.txt"; filelength=6
	Content-Type: application/octet-stream

	mytext
	---------------------------acebdf13572468--


=head3 返回数据：

	{
	   "errcode": 0,
	   "errmsg": ""，
	   "type": "image",
	   "media_id": "1G6nrLmr5EC3MMb_-zK1dDdzmd0p7cNliYu9V5w7o8K0",
	   "created_at": "1380000000"
	}


=head4 RETURN 参数说明：

	参数	        说明
    type	媒体文件类型，分别有图片（image）、语音（voice）、视频（video），普通文件(file)
	media_id	媒体文件上传后获取的唯一标识，3天内有效
	created_at	媒体文件上传时间戳

=head4 上传的媒体文件限制

所有文件size必须大于5个字节

图片（image）：10MB，支持JPG,PNG格式
语音（voice） ：2MB，播放长度不超过60s，仅支持AMR格式
视频（video） ：10MB，支持MP4格式
普通文件（file）：20MB

=cut

sub upload_attachment {
    if ( @_ && $_[0] && $_[1] && $_[2] && $_[3] ) {
        my $access_token = $_[0];
        my $media_type = $_[1];
        my $attachment_type = $_[2];
        my $file = $_[3];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/media/upload_attachment?access_token=$access_token&media_type=$media_type&attachment_type=$attachment_type",[media => [$file]],Content_Type => 'multipart/form-data');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
