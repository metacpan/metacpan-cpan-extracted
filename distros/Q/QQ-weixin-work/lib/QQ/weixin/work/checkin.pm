package QQ::weixin::work::checkin;

=encoding utf8

=head1 Name

QQ::weixin::work::checkin

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
our @EXPORT = qw/ get update /;

=head1 FUNCTION

=head2 getcheckindata(access_token, hash);

获取打卡数据

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90262>

=head3 请求说明：

=head4 请求包结构体为：

    {
      "opencheckindatatype": 3,
      "starttime": 1492617600,
      "endtime": 1492790400,
      "useridlist": ["james","paul"]
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    opencheckindatatype	是	打卡类型。1：上下班打卡；2：外出打卡；3：全部打卡
    starttime	是	获取打卡记录的开始时间。Unix时间戳
    endtime	是	获取打卡记录的结束时间。Unix时间戳
    useridlist	是	需要获取打卡记录的用户列表

=head3 权限说明

获取记录时间跨度不超过30天
用户列表不超过100个。若用户超过100个，请分批获取
有打卡记录即可获取打卡数据，与当前”打卡应用”是否开启无关

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
      "checkindata": [{
           "userid" : "james",
           "groupname" : "打卡一组",
           "checkin_type" : "上班打卡",
           "exception_type" : "地点异常",
           "checkin_time" : 1492617610,
           "location_title" : "依澜府",
           "location_detail" : "四川省成都市武侯区益州大道中段784号附近",
           "wifiname" : "办公一区",
           "notes" : "路上堵车，迟到了5分钟",
           "wifimac" : "3c:46:d8:0c:7a:70",
           "mediaids":["WWCISP_G8PYgRaOVHjXWUWFqchpBqqqUpGj0OyR9z6WTwhnMZGCPHxyviVstiv_2fTG8YOJq8L8zJT2T2OvTebANV-2MQ"]
       },{
           "userid" : "paul",
           "groupname" : "打卡二组",
           "checkin_type" : "外出打卡",
           "exception_type" : "时间异常",
           "checkin_time" : 1492617620,
           "location_title" : "重庆出口加工区",
           "location_detail" : "重庆市渝北区金渝大道101号金渝大道",
           "wifiname" : "办公室二区",
           "notes" : "",
           "wifimac" : "3c:46:d8:0c:7a:71",
           "mediaids":["WWCISP_G8PYgRaOVHjXWUWFqchpBqqqUpGj0OyR9z6WTwhnMZGCPHxyviVstiv_2fTG8YOJq8L8zJT2T2OvTebANV-2MQ"],
           "lat": 30547645,
           "lng": 104063236,
           "deviceid":"E5FA89F6-3926-4972-BE4F-4A7ACF4701E2"
       }]
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    userid	用户id
    groupname	打卡规则名称
    checkin_type	打卡类型。字符串，目前有：上班打卡，下班打卡，外出打卡
    exception_type	异常类型，字符串，包括：时间异常，地点异常，未打卡，wifi异常，非常用设备。如果有多个异常，以分号间隔
    checkin_time	打卡时间。Unix时间戳
    location_title	打卡地点title
    location_detail	打卡地点详情
    wifiname	打卡wifi名称
    notes	打卡备注
    wifimac	打卡的MAC地址/bssid
    mediaids	打卡的附件media_id，可使用media/get获取附件
    lat	位置打卡地点纬度，是实际纬度的1000000倍，与腾讯地图一致采用GCJ-02坐标系统标准
    lng	位置打卡地点经度，是实际经度的1000000倍，与腾讯地图一致采用GCJ-02坐标系统标准
    diviceid	打卡设备id

=cut

sub getcheckindata {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/checkin/getcheckindata?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getcheckinoption(access_token, hash);

获取打卡规则

=head2 SYNOPSIS

L<https://work.weixin.qq.com/api/doc/90000/90135/90263>

=head3 请求说明：

=head4 请求包结构体为：

    {
        "datetime": 1511971200,
        "useridlist": ["james","paul"]
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    datetime	是	需要获取规则的日期当天0点的Unix时间戳
    useridlist	是	需要获取打卡规则的用户列表

=head3 权限说明

用户列表不超过100个，若用户超过100个，请分批获取。
用户在不同日期的规则不一定相同，请按天获取。

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
      "info": [
          {
              "userid": "james",
              "group": {
                  "grouptype": 1,
                  "groupid": 69,
                  "checkindate": [
                      {
                          "workdays": [
                              1,
                              2,
                              3,
                              4,
                              5
                          ],
                          "checkintime": [
                              {
                                  "work_sec": 36000,
                                  "off_work_sec": 43200,
                                  "remind_work_sec": 35400,
                                  "remind_off_work_sec": 43200
                              },
                              {
                                  "work_sec": 50400,
                                  "off_work_sec": 72000,
                                  "remind_work_sec": 49800,
                                  "remind_off_work_sec": 72000
                              }
                          ],
                          "flex_time": 300000,
                          "noneed_offwork": true,
                          "limit_aheadtime": 10800000
                      }
                  ],
                  "spe_workdays": [
                      {
                          "timestamp": 1512144000,
                          "notes": "必须打卡的日期",
                          "checkintime": [
                              {
                                  "work_sec": 32400,
                                  "off_work_sec": 61200,
                                  "remind_work_sec": 31800,
                                  "remind_off_work_sec": 61200
                              }
                          ]
                      }
                  ],
                  "spe_offdays": [
                      {
                          "timestamp": 1512057600,
                          "notes": "不需要打卡的日期",
                          "checkintime": []
                      }
                  ],
                  "sync_holidays": true,
                  "groupname": "打卡规则1",
                  "need_photo": true,
                  "wifimac_infos": [
                      {
                          "wifiname": "Tencent-WiFi-1",
                          "wifimac": "c0:7b:bc:37:f8:d3",
                      },
                      {
                          "wifiname": "Tencent-WiFi-2",
                          "wifimac": "70:10:5c:7d:f6:d5",
                      }
                  ],
                  "note_can_use_local_pic": false,
                  "allow_checkin_offworkday": true,
                  "allow_apply_offworkday": true,
                  "loc_infos": [
                      {
                          "lat": 30547030,
                          "lng": 104062890,
                          "loc_title": "腾讯成都大厦",
                          "loc_detail": "四川省成都市武侯区高新南区天府三街",
                          "distance": 300
                      },
                      {
                          "lat": 23097490,
                          "lng": 113323750,
                          "loc_title": "T.I.T创意园",
                          "loc_detail": "广东省广州市海珠区新港中路397号",
                          "distance": 300
                      }
                  ]
              }
          }
      ]
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    userid	用户id
    grouptype	打卡规则类型。1：固定时间上下班；2：按班次上下班；3：自由上下班 。
    groupid	打卡规则id
    groupname	打卡规则名称
    checkindate	打卡时间
    workdays	工作日。若为固定时间上下班或自由上下班，则1到6分别表示星期一到星期六，0表示星期日；若为按班次上下班，则表示拉取班次的日期。
    work_sec	上班时间，表示为距离当天0点的秒数。
    off_work_sec	下班时间，表示为距离当天0点的秒数。
    remind_work_sec	上班提醒时间，表示为距离当天0点的秒数。
    remind_off_work_sec	下班提醒时间，表示为距离当天0点的秒数。
    flex_time	弹性时间（毫秒）
    noneed_offwork	下班不需要打卡
    limit_aheadtime	打卡时间限制（毫秒）
    spe_workdays	特殊日期
    timestamp	特殊日期具体时间
    notes	特殊日期备注
    allow_checkin_offworkday	是否非工作日允许打卡
    sync_holidays	是否同步法定节假日
    need_photo	是否打卡必须拍照
    note_can_use_local_pic	是否备注时允许上传本地图片
    allow_apply_offworkday	是否允许异常打卡时提交申请
    wifimac_infos	WiFi打卡地点信息
    wifiname	WiFi打卡地点名称
    wifimac	WiFi打卡地点MAC地址/bssid
    loc_infos	位置打卡地点信息
    lat	位置打卡地点纬度，是实际纬度的1000000倍，与腾讯地图一致采用GCJ-02坐标系统标准
    lng	位置打卡地点经度，是实际经度的1000000倍，与腾讯地图一致采用GCJ-02坐标系统标准
    loc_title	位置打卡地点名称
    loc_detail	位置打卡地点详情
    distance	允许打卡范围（米）

=cut

sub getcheckinoption {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/checkin/getcheckinoption?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
