package QQ::weixin::work::dial;

=encoding utf8

=head1 Name

QQ::weixin::work::dial

=head1 DESCRIPTION

公费电话

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ get_dial_record /;

=head1 FUNCTION

=head2 get_dial_record(access_token, hash);

获取公费电话拨打记录
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93662>

=head3 请求说明：

企业可通过此接口，按时间范围拉取成功接通的公费电话拨打记录。

=head4 请求包结构体为：

    {
       "start_time": 1536508800,
       "end_time": 1536940800,
       "offset": 0,
       "limit": 100
    }

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证
    start_time	否	查询的起始时间戳
    end_time	否	查询的结束时间戳
    offset	否	分页查询的偏移量
    limit	否	分页查询的每页大小,默认为100条，如该参数大于100则按100处理

请注意，查询的时间范围为[start_time,end_time]，即前后均为闭区间。在两个参数都指定了的情况下，结束时间不得小于开始时间，开始时间也不得早于当前时间，否则会返回600018错误码(无效的起止时间)。
受限于网络传输，起止时间的最大跨度为30天，如超过30天，则以结束时间为基准向前取30天进行查询。
如果未指定起止时间，则默认查询最近30天范围内数据。

=head4 权限说明：

	应用类型	权限要求
	自建应用	配置到「公费电话 - 可调用接口的应用」中
	代开发应用	暂不支持
	第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果：

    {
	   "errcode": 0,
	   "errmsg": "ok",
	   "record":[
			{
				"call_time":1536508800,
				"total_duration":10,
				"call_type":1,
				"caller":
				{
					"userid":"tony",
					"duration":10
				},
				"callee":[
				{
					"phone":138000800,
					"duration":10
				}
				]
			},
			{
				"call_time":1536940800,
				"total_duration":20,
				"call_type":2,
				"caller":
				{
					"userid":"tony",
					"duration":10
				},
				"callee":[
					{
						"phone":138000800,
						"duration":5
					},
					{
						"userid":"tom",
						"duration":5
					}
				]
			}
	   ]
	}

=head4 RETURN 参数说明：

	参数	        说明
    errcode	返回码
	errmsg	对返回码的文本描述内容
	record.call_time	拨出时间
	record.total_duration	总通话时长，单位为分钟
	record.call_type	通话类型，1-单人通话 2-多人通话
	record.caller.userid	主叫用户的userid
	record.caller.duration	主叫用户的通话时长
	record.callee.userid	被叫用户的userid，当被叫用户为企业内用户时返回
	record.callee.phone	被叫用户的号码，当被叫用户为外部用户时返回
	record.callee.duration	被叫用户的通话时长

应用可见范围外用户相关的record会被过滤掉，不会返回
通话类型为单人通话时，总通话时长等于单人通话时长，通话类型为多人通话时，总通话时长等于包括主叫用户在内的每个接入用户的通话时长之和。

=cut

sub get_dial_record {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/dial/get_dial_record?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
