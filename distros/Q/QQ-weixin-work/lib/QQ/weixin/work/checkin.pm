package QQ::weixin::work::checkin;

=encoding utf8

=head1 Name

QQ::weixin::work::checkin

=head1 DESCRIPTION

打卡

=cut

use strict;
use base qw(QQ::weixin::work);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '0.10';
our @EXPORT = qw/ getcorpcheckinoption getcheckinoption getcheckindata
				getcheckin_daydata getcheckin_monthdata
				getcheckinschedulist setcheckinschedulist
				punch_correction addcheckinuserface
				add_checkin_option update_checkin_option clear_checkin_option_array_field
				del_checkin_option /;

=head1 FUNCTION

=head2 getcorpcheckinoption(access_token, hash);

获取企业所有打卡规则
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93384>

=head3 请求说明：

自建应用、代开发应用可用此接口，获取企业内所有打卡规则。

=head4 请求包结构体为：

    {}

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证。必须使用打卡应用的Secret获取access_token，获取方式参考：文档-获取access_token

=head4 调用频率:

接口调用频率限制为60次/分钟。

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「打卡 - 可调用接口的应用」中
	代开发应用	具有「打卡」权限
	第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"group": [{
			"grouptype": 1,
			"groupid": 69,
			"checkindate": [{
				"workdays": [
					1,
					2,
					3,
					4,
					5
				],
				"checkintime": [{
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
				"noneed_offwork": true,
				"limit_aheadtime": 10800000,
				"flex_on_duty_time": 0,
				"flex_off_duty_time": 0,
			}],
			"spe_workdays": [{
				"timestamp": 1512144000,
				"notes": "必须打卡的日期",
				"checkintime": [{
					"work_sec": 32400,
					"off_work_sec": 61200,
					"remind_work_sec": 31800,
					"remind_off_work_sec": 61200
				}]
			}],
			"spe_offdays": [{
				"timestamp": 1512057600,
				"notes": "不需要打卡的日期",
				"checkintime": []
			}],
			"sync_holidays": true,
			"groupname": "打卡规则1",
			"need_photo": true,
			"wifimac_infos": [{
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
			"loc_infos": [{
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
			],
			"range": {
				"party_id": []
				"userid": ["icef", "LiJingZhong"]
				"tagid": [2]
			},
			"create_time": 1606204343,
			"white_users": ["canno"],
			"type": 0,
			"reporterinfo": {
				"reporters": [{
					"userid": "brant"
				}],
				"updatetime": 1606305508
			},
			"ot_info": {
				"type": 2,
				"allow_ot_workingday": true,
				"allow_ot_nonworkingday": false,
				"otcheckinfo": {
					"ot_workingday_time_start": 1800,
					"ot_workingday_time_min": 1800,
					"ot_workingday_time_max": 14400,
					"ot_nonworkingday_time_min": 1800,
					"ot_nonworkingday_time_max": 14400,
					"ot_workingday_restinfo": {
						"type": 2,
						"fix_time_rule": {
							"fix_time_begin_sec": 43200,
							"fix_time_end_sec": 46800
						},
						"cal_ottime_rule": {
							"items": [{
								"ot_time": 18000,
								"rest_time": 3600
							}]
						}
					},
					"ot_nonworkingday_restinfo": {
						"type": 2,
						"fix_time_rule": {
							"fix_time_begin_sec": 43200,
							"fix_time_end_sec": 46800
						},
						"cal_ottime_rule": {
							"items": [{
								"ot_time": 18000,
								"rest_time": 3600
							}]
						}
					},
					"ot_nonworkingday_spanday_time": 0
				},
				"uptime": 1606275664,
				"otapplyinfo": {
					"allow_ot_workingday": true "allow_ot_nonworkingday": true "uptime": 1606275664,
					"ot_workingday_restinfo": {
						"type": 2,
						"fix_time_rule": {
							"fix_time_begin_sec": 43200,
							"fix_time_end_sec": 46800
						},
						"cal_ottime_rule": {
							"items": [{
								"ot_time": 18000,
								"rest_time": 3600
							}]
						}
					},
					"ot_nonworkingday_restinfo": {
						"type": 2,
						"fix_time_rule": {
							"fix_time_begin_sec": 43200,
							"fix_time_end_sec": 46800
						},
						"cal_ottime_rule": {
							"items": [{
								"ot_time": 18000,
								"rest_time": 3600
							}]
						}
					},
					"ot_nonworkingday_spanday_time": 0
				}
			},
			"allow_apply_bk_cnt": -1,
			"option_out_range": 0,
			"create_userid": "gaogao",
			"use_face_detect": false,
			"allow_apply_bk_day_limit": -1,
			"update_userid": "sandy",
			"schedulelist": [{
				"schedule_id": 221,
				"schedule_name": "2",
				"time_section": [{
					"time_id": 1,
					"work_sec": 32400,
					"off_work_sec": 61200,
					"remind_work_sec": 31800,
					"remind_off_work_sec": 61200,
					"rest_begin_time": 43200,
					"rest_end_time": 46800,
					"allow_rest": false
				}],
				"limit_aheadtime": 14400000,
				"noneed_offwork": false,
				"limit_offtime": 14400,
				"flex_on_duty_time": 0,
				"flex_off_duty_time": 0,
				"allow_flex": false,
				"late_rule": {
					"allow_offwork_after_time": false,
					"timerules": [{
						"offwork_after_time": 3600,
						"onwork_flex_time": 3600
					}]
				},
				"max_allow_arrive_early": 0,
				"max_allow_arrive_late": 0
			}],
			"offwork_interval_time": 300
		}]
	}

=head4 RETURN 参数说明

	参数		类型		说明
	errcode	int32	错误码，详情见错误码说明
	errmsg	string	错误码对应的错误信息提示
	group	obj[]	企业规则信息列表
	group.grouptype	uint32	打卡规则类型，1：固定时间上下班；2：按班次上下班；3：自由上下班
	group.groupid	uint32	打卡规则id
	group.groupname	string	打卡规则名称
	group.checkindate	obj[]	打卡时间，当规则类型为排班时没有意义
	group.checkindate.workdays	uint32[]	工作日。若为固定时间上下班或自由上下班，则1到6分别表示星期一到星期六，0表示星期日
	group.checkindate.checkintime	uint32	工作日上下班打卡时间信息
	group.checkindate.checkintime.work_sec	uint32	上班时间，表示为距离当天0点的秒数。
	group.checkindate.checkintime.off_work_sec	uint32	下班时间，表示为距离当天0点的秒数。
	group.checkindate.checkintime.remind_work_sec	uint32	上班提醒时间，表示为距离当天0点的秒数。
	group.checkindate.checkintime.remind_off_work_sec	uint32	下班提醒时间，表示为距离当天0点的秒数。
	group.checkindate.noneed_offwork	bool	下班不需要打卡，true为下班不需要打卡，false为下班需要打卡
	group.checkindate.limit_aheadtime	uint32	打卡时间限制（毫秒）
	group.checkindate.flex_on_duty_time	int32	允许迟到时间（秒）
	group.checkindate.flex_off_duty_time	int32	允许早退时间（秒）
	group.spe_workdays	obj[]	特殊日期-必须打卡日期信息，timestamp表示具体时间
	group.spe_workdays.timestamp	uint32	特殊日期-必须打卡日期时间戳
	group.spe_workdays.notes	string	特殊日期备注
	group.spe_workdays.checkintime	obj[]	特殊日期-必须打卡日期-上下班打卡时间，内部参数同group.checkindate.checkintime
	group.spe_offdays	obj[]	特殊日期-不用打卡日期信息， timestamp表示具体时间
	group.spe_offdays.timestamp	uint32	特殊日期-不用打卡日期时间戳
	group.spe_offdays.notes	string	特殊日期备注
	group.sync_holidays	bool	是否同步法定节假日，true为同步，false为不同步，当前排班不支持
	group.need_photo	bool	是否打卡必须拍照，true为必须拍照，false为不必须拍照
	group.note_can_use_local_pic	bool	是否备注时允许上传本地图片，true为允许，false为不允许
	group.allow_checkin_offworkday	bool	是否非工作日允许打卡,true为允许，false为不允许
	group.allow_apply_offworkday	bool	是否允许提交补卡申请，true为允许，false为不允许
	group.wifimac_infos	obj[]	打卡地点-WiFi打卡信息
	group.wifimac_infos.wifiname	string	WiFi打卡地点名称
	group.wifimac_infos.wifimac	string	WiFi打卡地点MAC地址/bssid
	group.loc_infos	obj[]	打卡地点-位置打卡信息
	group.loc_infos.lat	int64	位置打卡地点纬度，是实际纬度的1000000倍，与腾讯地图一致采用GCJ-02坐标系统标准
	group.loc_infos.lng	int64	位置打卡地点经度，是实际经度的1000000倍，与腾讯地图一致采用GCJ-02坐标系统标准
	group.loc_infos.loc_title	string	位置打卡地点名称
	group.loc_infos.loc_detail	string	位置打卡地点详情
	group.loc_infos.distance	uint32	允许打卡范围（米）
	group.range	obj	打卡人员信息
	group.range.userid	string	打卡人员中，单个打卡人员节点的userid
	group.range.party_id	string[]	打卡人员中，部门节点的id
	group.range.tagid	uint32[]	打卡人员中，标签节点的标签id
	group.create_time	uint32	创建打卡规则时间，为unix时间戳
	group.white_users	string[]	打卡人员白名单，即不需要打卡人员，需要有设置白名单才能查看
	group.type	uint32	打卡方式，0:手机；2:智慧考勤机；3:手机+智慧考勤机
	group.reporterinfo	obj	汇报对象信息
	group.reporterinfo.reporters	obj[]	汇报对象，每个汇报人用userid表示
	group.reporterinfo.updatetime	uint32	汇报对象更新时间
	group.ot_info	obj	加班信息，相关信息需要设置后才能显示
	group.ot_info.type	int32	加班类型 0：以加班申请核算打卡记录（根据打卡记录和加班申请核算）,1：以打卡时间为准（根据打卡时间计算），2: 以加班申请审批为准（只根据加班申请计算）
	group.ot_info.allow_ot_workingday	bool	允许工作日加班，true为允许，false为不允许
	group.ot_info.allow_ot_nonworkingday	bool	允许非工作日加班，true为允许，flase为不允许
	group.ot_info.otcheckinfo	obj	以打卡时间为准-加班时长计算规则信息
	group.ot_info.otcheckinfo.ot_workingday_time_start	uint32	允许工作日加班-加班开始时间：下班后xx秒开始计算加班，距离最晚下班时间的秒数，例如，1800（30分钟 乘以 60秒），默认值30分钟
	group.ot_info.otcheckinfo.ot_workingday_time_min	uint32	允许工作日加班-最短加班时长：不足xx秒视为未加班，单位秒，默认值30分钟
	group.ot_info.otcheckinfo.ot_workingday_time_max	uint32	允许工作日加班-最长加班时长：超过则视为加班xx秒，单位秒，默认值240分钟
	group.ot_info.otcheckinfo.ot_nonworkingday_time_min	uint32	允许非工作日加班-最短加班时长：不足xx秒视为未加班，单位秒，默认值30分钟
	group.ot_info.otcheckinfo.ot_nonworkingday_time_max	uint32	允许非工作日加班-最长加班时长：超过则视为加班xx秒 单位秒，默认值240分钟
	group.ot_info.otcheckinfo.ot_nonworkingday_spanday_time	uint32	非工作日加班，跨天时间，距离当天00:00的秒数
	group.ot_info.otcheckinfo.ot_workingday_restinfo	obj	工作日加班-休息扣除配置信息
	uptime	uint32	更新时间 ｜
	group.ot_info.otcheckinfo.ot_workingday_restinfo.type	uint32	工作日加班-休息扣除类型：0-不开启扣除；1-指定休息时间扣除；2-按加班时长扣除休息时间
	group.ot_info.otcheckinfo.ot_workingday_restinfo.fix_time_rule	obj	工作日加班-指定休息时间配置信息，当group.ot_info.otcheckinfo.ot_workingday_restinfo.type为1时有意义
	group.ot_info.otcheckinfo.ot_workingday_restinfo.fix_time_rule.fix_time_begin_sec	uint32	工作日加班-指定休息时间的开始时间， 距离当天00:00的秒数
	group.ot_info.otcheckinfo.ot_workingday_restinfo.fix_time_rule.fix_time_end_sec	uint32	工作日加班-指定休息时间的结束时间， 距离当天00:00的秒数
	group.ot_info.otcheckinfo.ot_workingday_restinfo.cal_ottime_rule	obj	工作日加班-按加班时长扣除配置信息，当group.ot_info.otcheckinfo.ot_workingday_restinfo.type为2时有意义
	group.ot_info.otcheckinfo.ot_workingday_restinfo.cal_ottime_rule.items	obj	工作日加班-按加班时长扣除条件信息
	group.ot_info.otcheckinfo.ot_workingday_restinfo.cal_ottime_rule.items.ot_time	uint32	加班满-时长（秒）
	group.ot_info.otcheckinfo.ot_workingday_restinfo.cal_ottime_rule.items.rest_time	uint32	对应扣除-时长（秒）
	group.ot_info.otcheckinfo.ot_nonworkingday_restinfo	obj	非工作日加班-休息扣除配置信息，参数信息与group.ot_info.otcheckinfo.ot_workingday_restinfo一致
	otapplyinfo	obj	以加班申请核算打卡记录相关信息，根据加班申请核算加班时长，只有有设置相关信息时且以以加班申请核算打卡才有相关信息；内含参数释义基本同group.ot_info.otcheckinfo，但只包含加班休息扣除、跨天时间等参数
	group.allow_apply_bk_cnt	int32	每月最多补卡次数，默认-1表示不限制
	group.option_out_range	uint32	范围外打卡处理方式，0-视为范围外异常，默认值；1-视为正常外勤；2:不允许范围外打卡
	group.create_userid	string	规则创建人userid
	group.use_face_detect	bool	人脸识别打卡开关，true为启用，false为不启用
	group.allow_apply_bk_day_limit	int32	允许补卡时限，默认-1表示不限制。单位天
	group.update_userid	string	规则最近编辑人userid
	group.schedulelist	obj[]	排班信息，只有规则为按班次上下班打卡时才有该配置
	group.schedulelist.schedule_id	uint32	班次id
	group.schedulelist.schedule_name	string	班次名称
	group.schedulelist.time_section	obj[]	班次上下班时段信息
	group.schedulelist.time_section.time_id	uint32	时段id，为班次中某一堆上下班时间组合的id
	group.schedulelist.time_section.work_sec	uint32	上班时间，表示为距离当天0点的秒数。
	group.schedulelist.time_section.off_work_sec	uint32	下班时间，表示为距离当天0点的秒数。
	group.schedulelist.time_section.remind_work_sec	uint32	上班提醒时间，表示为距离当天0点的秒数。
	group.schedulelist.time_section.remind_off_work_sec	uint32	下班提醒时间，表示为距离当天0点的秒数。
	group.schedulelist.time_section.rest_begin_time	uint32	休息开始时间，仅单时段支持，距离0点的秒
	group.schedulelist.time_section.rest_end_time	uint32	休息结束时间，仅单时段支持，距离0点的秒
	group.schedulelist.time_section.allow_rest	bool	是否允许休息
	group.schedulelist.limit_aheadtime	uint32	允许提前打卡时间
	group.schedulelist.limit_offtime	uint32	下班xx秒后不允许打下班卡
	group.schedulelist.noneed_offwork	bool	下班不需要打卡
	group.schedulelist.allow_flex	bool	是否允许弹性时间
	group.schedulelist.flex_on_duty_time	uint32	允许迟到时间（秒）
	group.schedulelist.flex_off_duty_time	uint32	允许早退时间（秒）
	group.schedulelist.late_rule	obj	晚走晚到时间规则信息
	group.schedulelist.late_rule.allow_offwork_after_time	bool	是否允许超时下班（下班晚走次日晚到）允许时onwork_flex_time，offwork_after_time才有意义
	group.schedulelist.late_rule.timerules	obj[]	迟到规则时间
	group.schedulelist.late_rule.timerules.offwork_after_time	uint32	晚走的时间 距离最晚一个下班的时间单位：秒
	group.schedulelist.late_rule.timerules.onwork_flex_time	uint32	第二天第一个班次允许迟到的弹性时间单位：秒
	group.schedulelist.max_allow_arrive_early	uint32	最早可打卡时间限制
	group.schedulelist.max_allow_arrive_late	uint32	最晚可打卡时间限制，max_allow_arrive_early、max_allow_arrive_early与flex_on_duty_time、flex_off_duty_time互斥，当设置其中一组时，另一组数值置0
	group.offwork_interval_time	uint32	自由签到，上班打卡后xx秒可打下班卡
	group.buka_restriction	uint64	补卡指定异常类型，按比特位设置，大端模式，某位bit置位为1表示关闭某类型。从低到高四个比特位分别表示缺卡类型、迟到类型、早退类型、其他异常类型。为默认值0表示所有异常类型均允许补卡。

=cut

sub getcorpcheckinoption {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/checkin/getcorpcheckinoption?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getcheckinoption(access_token, hash);

获取员工打卡规则
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90263>

=head3 请求说明：

自建应用、第三方应用和代开发应用可使用此接口，获取可见范围内指定员工指定日期的打卡规则。

=head4 请求包结构体为：

    {
        "datetime": 1511971200,
        "useridlist": ["james","paul"]
    }

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证。必须使用打卡应用的Secret获取access_token，获取方式参考：文档-获取access_token
	datetime	是	需要获取规则的日期当天0点的Unix时间戳
	useridlist	是	需要获取打卡规则的用户列表

1. 用户列表不超过100个，若用户超过100个，请分批获取。
2. 用户在不同日期的规则不一定相同，请按天获取。

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「打卡 - 可调用接口的应用」中
	代开发应用	具有「打卡」权限
	第三方应用	具有「打卡」权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

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
							"limit_aheadtime": 10800000,
							"flex_on_duty_time":0,
							"flex_off_duty_time":0,
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
					],
					"schedulelist": [
							 {
										 "schedule_id":221,
										 "schedule_name":"2",
										 "time_section": [
												 {
														"time_id":1,
														"work_sec":32400,
														"off_work_sec":61200,
														"remind_work_sec":31800,
														"remind_off_work_sec":61200,
														"rest_begin_time":43200,
														"rest_end_time":46800,
														"allow_rest":false
												 }
										 ],
										  "limit_aheadtime":14400000,
										  "noneed_offwork":false,
										  "limit_offtime":14400,
										  "flex_on_duty_time":0,
										  "flex_off_duty_time":0,
										  "allow_flex":false,
										   "late_rule":
										   {
												 "allow_offwork_after_time":false,
												 "timerules":[
														 {
																 "offwork_after_time":3600,
																 "onwork_flex_time":3600
														}
												   ]
										  },
										  "max_allow_arrive_early":0,
										  "max_allow_arrive_late":0
							}
					 ]
				}
			}
		]
	}

=head4 RETURN 参数说明

	参数		类型		说明
	errcode	int32	错误码，详情见错误码说明
	errmsg	string	错误码对应的错误信息提示
	info	obj[]	返回的打卡规则列表
	userid	string	打卡人员userid
	group	obj	打卡规则相关信息
	group.grouptype	uint32	打卡规则类型。1：固定时间上下班；2：按班次上下班；3：自由上下班 。
	group.groupname	string	打卡规则名称
	groupid	uint32	打卡规则id
	group.checkindate	obj[]	打卡时间配置
	group.checkindate.workdays	uint32[]	工作日。若为固定时间上下班或自由上下班，则1到6分别表示星期一到星期六，0表示星期日；若为按班次上下班，则表示拉取班次的日期。
	group.checkindate.checkintime	obj[]	工作日上下班打卡时间信息
	group.checkindate.checkintime.work_sec	uint32	上班时间，表示为距离当天0点的秒数。
	group.checkindate.checkintime.off_work_sec	uint32	下班时间，表示为距离当天0点的秒数。
	group.checkindate.checkintime.remind_work_sec	uint32	上班提醒时间，表示为距离当天0点的秒数。
	group.checkindate.checkintime.remind_off_work_sec	uint32	下班提醒时间，表示为距离当天0点的秒数。
	group.checkindate.noneed_offwork	bool	下班不需要打卡，true为下班不需要打卡，false为下班需要打卡
	group.checkindate.limit_aheadtime	uint32	打卡时间限制（毫秒）
	group.checkindate.flex_time	uint32	弹性时间（毫秒）只有flex_on_duty_time，flex_off_duty_time不生效时（值为-1）才有意义
	group.checkindate.flex_on_duty_time	int32	允许迟到时间（秒），值为-1使用flex_time
	group.checkindate.flex_off_duty_time	int32	允许早退时间（秒），值为-1使用flex_time
	group.spe_workdays	obj[]	特殊日期-必须打卡日期，timestamp表示具体时间
	group.spe_workdays.timestamp	uint32	特殊日期-必须打卡日期时间戳
	group.spe_workdays.notes	string	特殊日期备注
	group.spe_workdays.checkintime	string	特殊日期打卡时间配置，参数同checkindate.checkintime
	group.spe_offdays	obj[]	特殊日期-不用打卡日期， timestamp表示具体时间
	group.spe_offdays.timestamp	uint32	特殊日期-不用打卡日期时间戳
	group.spe_offdays.notes	string	特殊日期备注
	group.sync_holidays	bool	是否同步法定节假日，true为同步，false为不同步，当前排班不支持
	group.need_photo	bool	是否打卡必须拍照，true为必须拍照，false为不必须拍照
	group.note_can_use_local_pic	bool	是否备注时允许上传本地图片，true为允许，false为不允许
	group.allow_checkin_offworkday	bool	是否非工作日允许打卡,true为允许，false为不允许
	group.allow_apply_offworkday	bool	是否允许提交补卡申请，true为允许，false为不允许
	group.wifimac_infos	obj[]	打卡地点-WiFi打卡信息
	group.wifimac_infos.wifiname	string	WiFi打卡地点名称
	group.wifimac_infos.wifimac	string	WiFi打卡地点MAC地址/bssid
	group.loc_infos	obj[]	打卡地点-位置打卡信息
	group.loc_infos.lat	int64	位置打卡地点纬度，是实际纬度的1000000倍，与腾讯地图一致采用GCJ-02坐标系统标准
	group.loc_infos.lng	int64	位置打卡地点经度，是实际经度的1000000倍，与腾讯地图一致采用GCJ-02坐标系统标准
	group.loc_infos.loc_title	string	位置打卡地点名称
	group.loc_infos.loc_detail	string	位置打卡地点详情
	group.loc_infos.distance	uint32	允许打卡范围（米）
	group.schedulelist	obj[]	排班信息，只有规则为按班次上下班打卡时才有该配置
	group.schedulelist.schedule_id	uint32	班次id
	group.schedulelist.schedule_name	string	班次名称
	group.schedulelist.time_section	obj[]	班次上下班时段信息
	group.schedulelist.time_section.time_id	uint32	时段id，为班次中某一堆上下班时间组合的id
	group.schedulelist.time_section.work_se	uint32	上班时间，表示为距离当天0点的秒数。
	group.schedulelist.time_section.offwork_sec	uint3	下班时间，表示为距离当天0点的秒数。
	group.schedulelist.time_section.remind_work_sec	uint32	上班提醒时间，表示为距离当天0点的秒数。
	group.schedulelist.time_section.remind_offwork_sec	uint32	下班提醒时间，表示为距离当天0点的秒数。
	group.schedulelist.time_section.rest_begin_time	uint32	休息开始时间，仅单时段支持，距离0点的秒
	group.schedulelist.time_section.rest_end_time	uint32	休息结束时间，仅单时段支持，距离0点的秒
	group.schedulelist.time_section.allow_rest	bool	是否允许休息
	group.schedulelist.limit_aheadtime	uint32	允许提前打卡时间
	group.schedulelist.limit_offtime	uint32	下班xx秒后不允许打下班卡
	group.schedulelist.noneed_offwork	bool	下班不需要打卡
	group.schedulelist.allow_flex	uint32	是否允许弹性时间
	group.schedulelist.flex_on_duty_time	uint32	允许迟到时间（秒），值为-1使用flex_time
	group.schedulelist.flex_off_duty_time	uint32	允许早退时间（秒），值为-1使用flex_time
	group.schedulelist.late_rule	obj	晚走晚到时间规则信息
	group.schedulelist.late_rule.allow_offwork_after_time	bool	是否允许超时下班（下班晚走次日晚到）允许时onwork_flex_time，offwork_after_time才有意义
	group.schedulelist.late_rule.timerules	obj[]	迟到规则时间
	group.schedulelist.late_rule.timerules.offwork_after_time	uint32	晚走的时间 距离最晚一个下班的时间单位：秒
	group.schedulelist.late_rule.timerules.onwork_flex_time	uint32	第二天第一个班次允许迟到的弹性时间单位：秒
	group.schedulelist.max_allow_arrive_early	uint32	最早可打卡时间限制
	group.schedulelist.max_allow_arrive_late	uint32	最晚可打卡时间限制，max_allow_arrive_early、max_allow_arrive_early与flex_on_duty_time、flex_off_duty_time互斥，当设置其中一组时，另一组数值置0
	group.buka_restriction	uint64	补卡指定异常类型，按比特位设置，大端模式，某位bit置位为1表示关闭某类型。从低到高四个比特位分别表示缺卡类型、迟到类型、早退类型、其他异常类型。为默认值0表示所有异常类型均允许补卡。

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

=head2 getcheckindata(access_token, hash);

获取打卡记录数据
最后更新：2023/12/18

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/90262>

=head3 请求说明：

应用可通过本接口，获取可见范围内员工指定时间段内的打卡记录数据。

=head4 请求包结构体为：

    {
      "opencheckindatatype": 3,
      "starttime": 1492617600,
      "endtime": 1492790400,
      "useridlist": ["james","paul"]
    }

=head4 参数说明：

	参数	            必须	说明
    access_token	是	调用接口凭证，获取方式参考：文档-获取access_token
	opencheckindatatype	是	打卡类型。1：上下班打卡；2：外出打卡；3：全部打卡
	starttime	是	获取打卡记录的开始时间。Unix时间戳
	endtime	是	获取打卡记录的结束时间。Unix时间戳
	useridlist	是	需要获取打卡记录的用户列表

1. 获取记录时间跨度不超过30天
2. 用户列表不超过100个。若用户超过100个，请分批获取
3. 有打卡记录即可获取打卡数据，与当前"打卡应用"是否开启无关
4. 标准打卡时间只对于固定排班和自定义排班两种类型有效
5. 接口调用频率限制为600次/分钟

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「打卡 - 可调用接口的应用」中
	代开发应用	具有「打卡」权限
	第三方应用	具有「打卡」权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

	{
	   "errcode":0,
	   "errmsg":"ok",
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
			"mediaids":["WWCISP_G8PYgRaOVHjXWUWFqchpBqqqUpGj0OyR9z6WTwhnMZGCPHxyviVstiv_2fTG8YOJq8L8zJT2T2OvTebANV-2MQ"],
			"sch_checkin_time" : 1492617610,
			"groupid" : 1,
			"schedule_id" : 0,
			"timeline_id" : 2
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
			"deviceid":"E5FA89F6-3926-4972-BE4F-4A7ACF4701E2",
			"sch_checkin_time" : 1492617610,
			"groupid" : 2,
			"schedule_id" : 3,
			"timeline_id" : 1
		}]
	}

=head4 RETURN 参数说明

	参数	    说明
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
	deviceid	打卡设备id
	sch_checkin_time	标准打卡时间，指此次打卡时间对应的标准上班时间或标准下班时间
	groupid	规则id，表示打卡记录所属规则的id
	schedule_id	班次id，表示打卡记录所属规则中，所属班次的id
	timeline_id	时段id，表示打卡记录所属规则中，某一班次中的某一时段的id，如上下班时间为9:00-12:00、13:00-18:00的班次中，9:00-12:00为其中一组时段

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

=head2 getcheckin_daydata(access_token, hash);

获取打卡日报数据
最后更新：2023/12/18

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93374>

=head3 请求说明：

企业可通过具有调用权限的应用，获取应用可见范围内指定员工指定日期内的打卡日报统计数据。

=head4 请求包结构体为：

    {
		"starttime": 1599062400,
		"endtime": 1599062400,
		"useridlist": [
			"ZhangSan"
		]
	}

=head4 参数说明：

	参数		必须		类型		说明
	access_token	是	string	调用接口凭证，获取方式参考：文档-获取access_token。
	starttime	是	uint32	获取日报的开始时间。0点Unix时间戳
	endtime	是	uint32	获取日报的结束时间。0点Unix时间戳
	useridlist	是	string[]	获取日报的userid列表。
								单个userid不少于1字节，不多于64字节
								可填充个数：1 ~ 100

=head4 调用频率:

接口调用频率限制为100次/分钟。

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「打卡 - 可调用接口的应用」中
	代开发应用	具有「打卡」权限
	第三方应用	具有「打卡」权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

	{
		"errcode":0,
		"errmsg":"ok",
		"datas":[
			{
				"base_info":{
					"date":1599062400,
					"record_type":1,
					"name":"张三",
					"name_ex":"Three Zhang",
					"departs_name":"有家企业/realempty;有家企业;有家企业/部门A4",
					"acctid":"ZhangSan",
					"rule_info":{
						"groupid":10,
						"groupname":"规则测试",
						"scheduleid":0,
						"schedulename":"",
						"checkintime":[
							{
								"work_sec":38760,
								"off_work_sec":38880
							}
						]
					},
					"day_type":0
				},
				"summary_info":{
					"checkin_count":2,
					"regular_work_sec":31,
					"standard_work_sec":120,
					"earliest_time":38827,
					"lastest_time":38858
				},
				"holiday_infos":[
					{
						"sp_description":{
							"data":[
								{
									"lang":"zh_CN",
									"text":"09/03 10:00~09/03 10:01"
								}
							]
						},
						"sp_number":"202009030002",
						"sp_title":{
							"data":[
								{
									"lang":"zh_CN",
									"text":"请假0.1小时"
								}
							]
						}
					},
					{
						"sp_description":{
							"data":[
								{
									"lang":"zh_CN",
									"text":"08/25 14:37~09/10 14:37"
								}
							]
						},
						"sp_number":"202008270004",
						"sp_title":{
							"data":[
								{
									"lang":"zh_CN",
									"text":"加班17.0小时"
								}
							]
						}
					}
				],
				"exception_infos":[
					{
						"count":1,
						"duration":60,
						"exception":1
					},
					{
						"count":1,
						"duration":60,
						"exception":2
					}
				],
				"ot_info":{
					"ot_status":1,
					"ot_duration":3600,
					"exception_duration":[],
					"workday_over_as_money": 54000
				},
				"sp_items":[
					{
						"count":1,
						"duration":360,
						"time_type":0,
						"type":1,
						"vacation_id":2,
						"name":"年假",
					},
					{
						"count":0,
						"duration":0,
						"time_type":0,
						"type":100,
						"vacation_id":0，
						"name":"外勤次数"
					}
				]
			}
		]
	}

=head4 RETURN 参数说明

	参数		类型		说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	datas	obj[]	日报数据列表
	datas.base_info	obj	基础信息
	datas.base_info.date	uint32	日报日期
	datas.base_info.record_type	uint32	记录类型：1-固定上下班；2-外出（此报表中不会出现外出打卡数据）；3-按班次上下班；4-自由签到；5-加班；7-无规则
	datas.base_info.name	string	打卡人员姓名
	datas.base_info.name_ex	string	打卡人员别名
	datas.base_info.departs_name	string	打卡人员所在部门，会显示所有所在部门
	datas.base_info.acctid	string	打卡人员账号，即userid
	datas.base_info.rule_info	obj	打卡人员所属规则信息
	datas.base_info.rule_info.groupid	int32	所属规则的id
	datas.base_info.rule_info.groupname	string	打卡规则名
	datas.base_info.rule_info.scheduleid	int32	当日所属班次id，仅按班次上下班才有值，显示在打卡日报-班次列
	datas.base_info.rule_info.schedulename	string	当日所属班次名称，仅按班次上下班才有值，显示在打卡日报-班次列
	datas.base_info.rule_info.checkintime	obj[]	当日打卡时间，仅固定上下班规则有值，显示在打卡日报-班次列
	datas.base_info.rule_info.checkintime.work_sec	uint32	上班时间，为距离0点的时间差
	datas.base_info.rule_info.checkintime.off_work_sec	uint32	下班时间，为距离0点的时间差
	datas.base_info.day_type	uint32	日报类型：0-工作日日报；1-休息日日报
	datas.summary_info	obj	汇总信息
	datas.summary_info.checkin_count	int32	当日打卡次数
	datas.summary_info.regular_work_sec	int32	当日实际工作时长，单位：秒
	datas.summary_info.standard_work_sec	int32	当日标准工作时长，单位：秒
	datas.summary_info.earliest_time	int32	当日最早打卡时间
	datas.summary_info.lastest_time	int32	当日最晚打卡时间
	datas.holiday_infos	obj[]	假勤相关信息
	datas.holiday_infos.sp_number	string	假勤申请id，即当日关联的假勤审批单id
	datas.holiday_infos.sp_title	obj	假勤信息摘要-标题信息
	datas.holiday_infos.sp_title.data	obj[]	多种语言描述，目前只有中文一种
	datas.holiday_infos.sp_title.data.text	string	假勤信息摘要-标题文本
	datas.holiday_infos.sp_title.data.lang	string	语言类型："zh_CN"
	datas.holiday_infos.sp_description	obj	假勤信息摘要-描述信息
	datas.holiday_infos.sp_description.data	obj[]	多种语言描述，目前只有中文一种
	datas.holiday_infos.sp_description.data.text	string	假勤信息摘要-描述文本
	datas.holiday_infos.sp_description.data.lang	string	语言类型："zh_CN"
	datas.exception_infos	obj[]	校准状态信息
	datas.exception_infos.exception	uint32	校准状态类型：1-迟到；2-早退；3-缺卡；4-旷工；5-地点异常；6-设备异常
	datas.exception_infos.count	int32	当日此异常的次数
	datas.exception_infos.duration	int32	当日此异常的时长（迟到/早退/旷工才有值）
	datas.ot_info	obj	加班信息
	datas.ot_info.ot_status	uint32	状态：0-无加班；1-正常；2-缺时长
	datas.ot_info.ot_duration	uint32	加班时长
	datas.ot_info.exception_duration	uint32[]	ot_status为2下，加班不足的时长
	datas.ot_info.workday_over_as_vacation	int32	工作日加班记为调休，单位秒
	datas.ot_info.workday_over_as_money	int32	工作日加班记为加班费，单位秒
	datas.ot_info.restday_over_as_vacation	int32	休息日加班记为调休，单位秒
	datas.ot_info.restday_over_as_money	int32	休息日加班记为加班费，单位秒
	datas.ot_info.holiday_over_as_vacation	int32	节假日加班记为调休，单位秒
	datas.ot_info.holiday_over_as_money	int32	节假日加班记为加班费，单位秒
	datas.sp_items	obj[]	假勤统计信息
	datas.sp_items.type	uint32	类型：1-请假；2-补卡；3-出差；4-外出；100-外勤
	datas.sp_items.vacation_id	uint32	具体请假类型，当type为1请假时，具体的请假类型id，可通过审批相关接口获取假期详情
	datas.sp_items.count	uint32	当日假勤次数
	datas.sp_items.duration	uint32	当日假勤时长秒数，时长单位为天直接除以86400即为天数，单位为小时直接除以3600即为小时数
	datas.sp_items.time_type	uint32	时长单位：0-按天 1-按小时
	datas.sp_items.name	string	统计项名称

=cut

sub getcheckin_daydata {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/checkin/getcheckin_daydata?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getcheckin_monthdata(access_token, hash);

获取打卡月报数据
最后更新：2023/12/18

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93387>

=head3 请求说明：

企业可通过具有调用权限的应用，获取应用可见范围内指定员工指定日期内的打卡月报统计数据。

=head4 请求包结构体为：

    {
		"starttime": 1599062400,
		"endtime": 1599408000,
		"useridlist": [
			"ZhangSan"
		]
	}

=head4 参数说明：

	参数		必须		类型		说明
	access_token	是	string	调用接口凭证，使用自建应用的Secret获取access_token，获取方式参考：文档-获取access_token
	starttime	是	uint32	获取月报的开始时间。0点Unix时间戳
	endtime	是	uint32	获取月报的结束时间。0点Unix时间戳
	useridlist	是	string[]	-
								不少于1字节
								不多于64字节
								可填充个数：1 ~ 100

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「打卡 - 可调用接口的应用」中
	代开发应用	具有「打卡」权限
	第三方应用	具有「打卡」权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head4 调用频率:

接口调用频率限制为60次/分钟。

=head3 RETURN 返回结果

	{
		"errcode": 0,
		"errmsg": "ok",
		"datas": [
			{
				"base_info": {
					"record_type": 1,
					"name": "张三",
					"name_ex": "Three Zhang",
					"departs_name": "有家企业/realempty;有家企业;有家企业/部门A4",
					"rule_info": {
						"groupid": 10,
						"groupname": "规则测试",
					},
					"acctid": "ZhangSan"
				},
				"summary_info":{
					"except_days":3,
					"regular_work_sec":31,
					"standard_work_sec":29040,
					"work_days":3
				},
				"exception_infos":[
					{
						"count":2,
						"duration":28920,
						"exception":4
					},
					{
						"count":1,
						"duration":60,
						"exception":1
					},
					{
						"count":1,
						"duration":60,
						"exception":2
					}
				],
				"sp_items":[
					{
						"count":0,
						"duration":0,
						"time_type":0,
						"type":100,
						"vacation_id":0，
						"name": "外勤次数"
					},
					{
						"count":1,
						"duration":0,
						"time_type":0,
						"type":1,
						"vacation_id":2,
						"name": "年假"
					}
				],
				"overwork_info": {
					"workday_over_sec": 54000,
					"restdays_over_sec": 205560,
					"workdays_over_as_vacation": 0,
					"workdays_over_as_money": 54000,
					"restdays_over_as_vacation": 0,
					"restdays_over_as_money": 172800,
					"holidays_over_as_vacation": 0,
					"holidays_over_as_money": 0
				}
			}
		]
	}

=head4 RETURN 参数说明

	参数		类型		说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	datas	obj[]	月报数据列表
	datas.base_info	obj	基础信息
	datas.base_info.record_type	uint32	记录类型：1-固定上下班；2-外出（此报表中不会出现外出打卡数据）；3-按班次上下班；4-自由签到；5-加班；7-无规则
	datas.base_info.name	string	打卡人员姓名
	datas.base_info.name_ex	string	打卡人员别名
	datas.base_info.departs_name	string	打卡人员所在部门，会显示所有所在部门
	datas.base_info.acctid	string	打卡人员账号，即userid
	datas.base_info.rule_info	obj	打卡人员所属规则信息
	datas.base_info.rule_info.groupid	int32	所属规则的id
	datas.base_info.rule_info.groupname	string	打卡规则名
	datas.summary_info	obj	汇总信息
	datas.summary_info.work_days	int32	应打卡天数
	datas.summary_info.regular_days	int32	正常天数
	datas.summary_info.except_days	int32	异常天数
	datas.summary_info.regular_work_sec	int32	实际工作时长，为统计周期每日实际工作时长之和, 单位: 秒
	datas.summary_info.standard_work_sec	int32	标准工作时长，为统计周期每日标准工作时长之和, 单位: 秒
	datas.exception_infos	obj[]	异常状态统计信息
	datas.exception_infos.exception	uint32	异常类型：1-迟到；2-早退；3-缺卡；4-旷工；5-地点异常；6-设备异常
	datas.exception_infos.count	int32	异常次数，为统计周期内每日此异常次数之和
	datas.exception_infos.duration	int32	异常时长（迟到/早退/旷工才有值），为统计周期内每日此异常时长之和
	datas.sp_items	obj[]	假勤统计信息
	datas.sp_items.type	uint32	假勤类型：1-请假；2-补卡；3-出差；4-外出；100-外勤
	datas.sp_items.vacation_id	uint32	具体请假类型，当type为1请假时，具体的请假类型id，可通过审批相关接口获取假期详情
	datas.sp_items.count	uint32	假勤次数，为统计周期内每日此假勤发生次数之和
	datas.sp_items.duration	uint32	假勤时长，为统计周期内每日此假勤发生时长之和，时长单位为天直接除以86400即为天数，单位为小时直接除以3600即为小时数
	datas.sp_items.time_type	uint32	时长单位：0-按天 1-按小时
	datas.sp_items.name	string	统计项名称
	datas.overwork_info	obj	加班情况
	datas.overwork_info.workday_over_sec	int32	工作日加班时长
	datas.overwork_info.holidays_over_sec	int32	节假日加班时长
	datas.overwork_info.restdays_over_sec	int32	休息日加班时长
	datas.overwork_info.workdays_over_as_vacation	int32	工作日加班记为调休，单位秒
	datas.overwork_info.workdays_over_as_money	int32	工作日加班记为加班费，单位秒
	datas.overwork_info.restdays_over_as_vacation	int32	休息日加班记为调休，单位秒
	datas.overwork_info.restdays_over_as_money	int32	休息日加班记为加班费，单位秒
	datas.overwork_info.holidays_over_as_vacation	int32	节假日加班记为调休，单位秒
	datas.overwork_info.holidays_over_as_money	int32	节假日加班记为加班费，单位秒

=cut

sub getcheckin_monthdata {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/checkin/getcheckin_monthdata?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 getcheckinschedulist(access_token, hash);

获取打卡人员排班信息
最后更新：2023/12/18

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93380>

=head3 请求说明：

应用可通过此接口，获取应用可见范围内、打卡规则为“按班次上下班”规则的指定员工指定时间段内的排班信息。

=head4 请求包结构体为：

    {
		"starttime": 1492617600,
		"endtime": 1492790400,
		"useridlist": [
			"james",
			"paul"
		]
	}

=head4 参数说明：

	参数		必须		类型		说明
	access_token	是	string	调用接口凭证，获取方式参考：文档-获取access_token
	useridlist	是	string[]	需要获取排班信息的用户列表（不超过100个）
	starttime	是	uint32	获取排班信息的开始时间。Unix时间戳
	endtime	是	uint32	获取排班信息的结束时间。Unix时间戳（与starttime跨度不超过一个月）

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「打卡 - 可调用接口的应用」中
	代开发应用	具有「打卡」权限
	第三方应用	具有「打卡」权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head4 调用频率:

接口调用频率限制为60次/分钟。

=head3 RETURN 返回结果

	{
		"schedule_list":[
			{
				"userid":"james",
				"yearmonth":202011,
				"groupid":11,
				"groupname":"排班",
				"schedule":{
					"scheduleList":[
						{
							"day":25,
							"schedule_info":{
								"schedule_id":229,
								"schedule_name":"早班",
								"time_section":[
									{
										"id":1,
										"work_sec":32400,
										"off_work_sec":43200,
										"remind_work_sec":32400,                                         "remind_off_work_sec":43200
									}
								]
							}
						},
						{
							"day":26,
							"schedule_info":{
								"schedule_id":171,
								"schedule_name":"晚班",
								"time_section":[
									{
										"id":2,
										"work_sec":64800,
										"off_work_sec":79200,
										"remind_work_sec":64800,
										"remind_off_work_sec":79200
									}
								]
							}
						},
						{
							"day":30,
							"schedule_info":{
								"schedule_id":0,
								"schedule_name":"休息",
								"time_section":[

								]
							}
						}
					]
				}
			}
		],
		"errcode":0,
		"errmsg":"ok"
	}

=head4 RETURN 参数说明

	参数		类型		说明
	errcode	int32	返回码
	errmsg	string	错误码描述
	schedule_list	obj[]	排班表信息
	schedule_list.userid	string	打卡人员userid
	schedule_list.yearmonth	uint32	排班表月份，格式为年月，如202011
	schedule_list.groupid	uint32	打卡规则id
	schedule_list.groupname	string	打卡规则名
	schedule_list.schedule	obj	个人排班信息
	schedule_list.schedule.scheduleList	obj[]	个人排班表信息
	schedule_list.schedule.scheduleList.day	uint32	排班日期，为表示当月第几天的数字
	schedule_list.schedule.scheduleList.schedule_info	obj	个人当日排班信息
	schedule_list.schedule.scheduleList.schedule_info.schedule_id	uint32	当日安排班次id，班次id也可在打卡规则中查询获得
	schedule_list.schedule.scheduleList.schedule_info.schedule_name	string	班次名称
	schedule_list.schedule.scheduleList.schedule_info.time_section	obj[]	班次上下班时段信息
	schedule_list.schedule.scheduleList.schedule_info.time_section.id	uint32	时段id，为班次中某一堆上下班时间组合的id
	schedule_list.schedule.scheduleList.schedule_info.time_section.work_sec	uint32	上班时间。距当天00:00的秒数
	schedule_list.schedule.scheduleList.schedule_info.time_section.off_work_sec	uint32	下班时间。距当天00:00的秒数
	schedule_list.schedule.scheduleList.schedule_info.time_section.remind_work_sec	uint32	上班提醒时间。距当天00:00的秒数
	schedule_list.schedule.scheduleList.schedule_info.time_section.remind_off_work_sec	uint32	下班提醒时间。距当天00:00的秒数

=head4 RETURN 错误说明

	错误码	说明
	301021	userid错误
	301070	系统错误，请稍后再试
	301075	输入参数错误

=cut

sub getcheckinschedulist {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/checkin/getcheckinschedulist?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 setcheckinschedulist(access_token, hash);

为打卡人员排班
最后更新：2023/12/18

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93385>

=head3 请求说明：

企业可通过具有调用权限的应用，为打卡规则为“按班次上下班”规则的指定员工排班。

=head4 请求包结构体为：

    {
		"groupid": 226,
		"items": [
			{
				"userid": "james",
				"day": 5,
				"schedule_id": 234
			}
		],
		"yearmonth": 202012
	}

=head4 参数说明：

	参数		必须		说明
	access_token	是	调用接口凭证。获取方式参考：文档-获取access_token
	items	是	排班表信息
	groupid	是	打卡规则的规则id，可通过“获取打卡规则”、“获取打卡数据”、“获取打卡人员排班信息”等相关接口获取
	userid	是	打卡人员userid
	day	是	要设置的天日期，取值在1-31之间。联合yearmonth组成唯一日期 比如20201205
	schedule_id	是	对应groupid规则下的班次id，通过预先拉取规则信息获取，0代表休息
	yearmonth	是	排班表月份，格式为年月，如202011

=head3 权限说明

仅支持为打卡规则为“按班次上下班”

	应用类型	权限要求
	自建应用	配置到「打卡 - 可调用接口的应用」中
	代开发应用	具有「打卡」权限
	第三方应用	具有「打卡」权限

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head4 调用频率:

接口调用频率限制为60次/分钟。

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=cut

sub setcheckinschedulist {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/checkin/setcheckinschedulist?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 punch_correction(access_token, hash);

为打卡人员补卡
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/95803>

=head3 请求说明：

=head4 请求包结构体为：

	{
	   "userid": "zhangsan",
	   "schedule_date_time": 1654444800,
	   "schedule_checkin_time": 32400,
	   "checkin_time": 1654486827,
	   "remark": "备注信息"
	}

=head4 参数说明：

	参数		类型		是否必须		说明
	access_token	string	是	调用接口凭证
	userid	string	是	需要补卡的成员userid
	schedule_date_time	uint32	是	应打卡日期，为当天0点的Unix时间戳。
	schedule_checkin_time	uint32	否	应打卡时间点，相对应打卡日期0点的偏移秒数，如9点整则为32400。可通过获取员工打卡规则获取对应的规则打卡时间点，如work_sec/off_work_sec。
										对于没有规则对应的打卡时间点，如休息日打卡、无规则打卡、自由上下班，该参数不用填。
	checkin_time	uint32	是	实际打卡时间，Unix时间戳。相对于schedule_checkin_time的实际打卡时间，具体可以表现为正常/迟到/早退
	remark	string	否	备注信息
						不超过512字节

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「打卡 - 可调用接口的应用」中
	代开发应用	暂不支持
	第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情 

=head4 调用频率:

接口调用频率限制为600次/分钟

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

	参数	类型	说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=cut

sub punch_correction {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/checkin/punch_correction?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 addcheckinuserface(access_token, hash);

录入打卡人员人脸信息
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93378>

=head3 请求说明：

企业可通过自建应用，为企业打卡人员录入人脸信息，人脸信息仅用于人脸打卡。

=head4 请求包结构体为：

    {
		"userid": "james",
		"userface": "PLACE_HOLDER"
	}

=head4 参数说明：

	参数		必须		类型		说明
	access_token	是	string	调用接口凭证，获取方式参考：文档-获取access_token
	userid	否	string	需要录入的用户id
	userface	否	string	需要录入的人脸图片数据，需要将图片数据base64处理后填入，对已录入的人脸会进行更新处理

注意：对于已有人脸的用户，使用此接口将使用传入的人脸覆盖原有人脸，请谨慎操作。

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「打卡 - 可调用接口的应用」中
	代开发应用	暂不支持
	第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head4 调用频率:

接口调用频率限制为10次/分钟。

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

	参数		类型		说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=head4 RETURN 错误说明

	错误码	说明
	301021	输入参数错误
	301069	输入userid无对应成员
	301070	系统错误，请稍后再试
	301071	企业内有其他人员有相似人脸，此情况下人脸仍然会录入成功
	301072	人脸图像数据错误请更换图片

=cut

sub addcheckinuserface {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/checkin/addcheckinuserface?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 Name

管理打卡规则
最后更新：2023/11/30

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98041>

=head2 add_checkin_option(access_token, hash);

创建打卡规则

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98041#创建打卡规则>

=head3 请求说明：

企业可通过自建应用或授权的代开发应用，为企业添加打卡规则。

=head4 请求包结构体为：

	{
		"effective_now": true,
		"group": {
			"grouptype": 1,
			"groupname": "打卡规则1",
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
							"time_id": 1,
							"work_sec": 36000,
							"off_work_sec": 43200,
							"remind_work_sec": 35400,
							"remind_off_work_sec": 43200,
							"earliest_work_sec": 35040,
							"latest_work_sec": 37020,
							"earliest_off_work_sec": 43140,
							"latest_off_work_sec": 43800
						}
					],
					"flex_on_duty_time": 0,
					"flex_off_duty_time": 0
				}
			],
			"sync_holidays": true,
			"need_photo": true,
			"note_can_use_local_pic": false,
			"wifimac_infos": [
				{
					"wifiname": "Tencent-WiFi-1",
					"wifimac": "c0:7b:bc:37:f8:d3"
				}
			],
			"allow_checkin_offworkday": true,
			"allow_apply_offworkday": true,
			"loc_infos": [
				{
					"lat": 30547030,
					"lng": 104062890,
					"loc_title": "腾讯成都大厦",
					"loc_detail": "四川省成都市武侯区高新南区天府三街",
					"distance": 300
				}
			],
			"range": {
				"party_id": [],
				"userid": [
					"xiaoxioa"
				],
				"tagid": []
			},
			"white_users": [
				"xiaoxioa"
			],
			"type": 0,
			"reporterinfo": {
				"reporters": [
					{
						"userid": "xiaoxioa"
					}
				]
			},
			"ot_info_v2": {
				"workdayconf": {
					"allow_ot": true,
					"type": 0
				}
			},
			"allow_apply_bk_cnt": -1,
			"option_out_range": 0,
			"use_face_detect": true,
			"allow_apply_bk_day_limit": -1,
			"open_face_live_detect": true,
			"buka_limit_next_month": -1,
			"sync_out_checkin": true,
			"buka_remind": {
				"open_remind": true,
				"buka_remind_day": 28,
				"buka_remind_month": 0
			},
			"buka_restriction":0
		}
	}

=head4 参数说明：

	参数		是否必填		说明
	access_token	是	调用接口凭证。自建应用或代开发应用的access_token
	group	视情况而定	打卡规则详细定义，具体见打卡规则字段说明
	effective_now	否	是否立即生效, 默认为false

注意：
1.创建打卡规则时，groupid无需传入，该字段会被忽略。
2.附常见错误信息列表

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「打卡 - 可调用接口的应用」中
	代开发应用	具有「打卡」权限
	第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

	参数		类型		说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=cut

sub add_checkin_option {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/checkin/add_checkin_option?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 获取打卡规则

同获取企业所有打卡规则

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/93384>

=head2 update_checkin_option(access_token, hash);

修改打卡规则

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98041#修改打卡规则>

=head3 请求说明：

企业可通过自建应用或授权的代开发应用，修改该应用为企业创建的打卡规则。

=head4 请求包结构体为：

	{
		"effective_now": true,
		"group": {
			"groupid": 1,
			"grouptype": 1,
			"groupname": "打卡规则1",
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
							"time_id": 1,
							"work_sec": 36000,
							"off_work_sec": 43200,
							"remind_work_sec": 35400,
							"remind_off_work_sec": 43200,
							"earliest_work_sec": 35040,
							"latest_work_sec": 37020,
							"earliest_off_work_sec": 43140,
							"latest_off_work_sec": 43800
						}
					],
					"flex_on_duty_time": 0,
					"flex_off_duty_time": 0
				}
			],
			"sync_holidays": true,
			"need_photo": true,
			"note_can_use_local_pic": false,
			"wifimac_infos": [
				{
					"wifiname": "Tencent-WiFi-1",
					"wifimac": "c0:7b:bc:37:f8:d3"
				}
			],
			"allow_checkin_offworkday": true,
			"allow_apply_offworkday": true,
			"loc_infos": [
				{
					"lat": 30547030,
					"lng": 104062890,
					"loc_title": "腾讯成都大厦",
					"loc_detail": "四川省成都市武侯区高新南区天府三街",
					"distance": 300
				}
			],
			"range": {
				"party_id": [],
				"userid": [
					"xiaoxioa"
				],
				"tagid": []
			},
			"white_users": [
				"xiaoxioa"
			],
			"type": 0,
			"reporterinfo": {
				"reporters": [
					{
						"userid": "xiaoxioa"
					}
				]
			},
			"ot_info_v2": {
				"workdayconf": {
					"allow_ot": true,
					"type": 0
				}
			},
			"allow_apply_bk_cnt": -1,
			"option_out_range": 0,
			"use_face_detect": true,
			"allow_apply_bk_day_limit": -1,
			"open_face_live_detect": true,
			"buka_limit_next_month": -1,
			"sync_out_checkin": true,
			"buka_remind": {
				"open_remind": true,
				"buka_remind_day": 28,
				"buka_remind_month": 0
			}
		}
	}

=head4 参数说明：

	参数		是否必填		说明
	access_token	是	调用接口凭证。自建应用或代开发应用的access_token
	group	视情况而定	打卡规则详细定义，具体见打卡规则字段说明
	effective_now	否	是否立即生效, 默认false

注意：
1.修改打卡规则时，groupid须传入，否则会报错。
2.打卡规则仅可由该规则的创建应用修改。
3.group定义存在多层结构体嵌套，对于group.*一级的字段：
 a.若该字段为数组且调用端无传入或传入空元素数组，则理解为不更新该数组字段；
 b.若该字段为数组且调用端有传入，理解为覆盖该数组字段( 即清空原有数组，保留传入的数组 )；
 c.若该字段非数组且调用端有传入，理解为覆盖该字段，及递归的所有字段；
 d.若该字段非数组且调用端无传入，理解为不更新该字段。
4.若想清空group.*一级的字段:
 a.若该字段为数组，可以使用清空规则数组元素接口；
 b.若该字段非数组，则直接传入空元素即可；
5.附常见错误信息列表。

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「打卡 - 可调用接口的应用」中
	代开发应用	具有「打卡」权限
	第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

	参数		类型		说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=cut

sub update_checkin_option {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/checkin/update_checkin_option?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 clear_checkin_option_array_field(access_token, hash);

清空打卡规则数组元素

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98041#清空打卡规则数组元素>

=head3 请求说明：

企业可通过自建应用或授权的代开发应用，修改该应用为企业创建的打卡规则。

=head4 请求包结构体为：

	{
	  "groupid":1,
	  "clear_field":[1,2,3],
	  "effective_now":true
	}

=head4 参数说明：

	参数		是否必填		说明
	access_token	是	调用接口凭证。自建应用或代开发应用的access_token
	groupid	是	打卡规则id
	clear_field	是	清空的字段标识：
					1-清空spe_workdays字段; 2-清空spe_offdays字段; 3-清空wifimac_infos字段; 4-清空loc_infos字段( wifimac_infos和loc_infos不可同时为空 )
	effective_now	否	是否立即生效，默认false

1.打卡规则仅可由该规则的创建应用修改。

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「打卡 - 可调用接口的应用」中
	代开发应用	具有「打卡」权限
	第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

	参数		类型		说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=cut

sub clear_checkin_option_array_field {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/checkin/clear_checkin_option_array_field?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 del_checkin_option(access_token, hash);

删除打卡规则

=head2 SYNOPSIS

L<https://developer.work.weixin.qq.com/document/path/98041#删除打卡规则>

=head3 请求说明：

企业可通过自建应用或授权的代开发应用，删除该应用为企业创建的打卡规则。

=head4 请求包结构体为：

	{
		"groupid":1,
		"effective_now":true
	}

=head4 参数说明：

	参数		是否必填		说明
	access_token	是	调用接口凭证。自建应用或代开发应用的access_token
	groupid	是	删除的打卡规则id
	effective_now	否	是否立即生效，默认false

1.打卡规则仅可由该规则的创建应用删除。

=head3 权限说明

	应用类型	权限要求
	自建应用	配置到「打卡 - 可调用接口的应用」中
	代开发应用	具有「打卡」权限
	第三方应用	暂不支持

注： 从2023年12月1日0点起，不再支持通过系统应用secret调用接口，存量企业暂不受影响 查看详情

=head3 RETURN 返回结果

    {
		"errcode": 0,
		"errmsg": "ok"
	}

=head4 RETURN 参数说明

	参数		类型		说明
	errcode	int32	返回码
	errmsg	string	错误码描述

=head3 打卡规则字段说明

L<https://developer.work.weixin.qq.com/document/path/98041#打卡规则字段说明>

=head3 错误信息列表

L<https://developer.work.weixin.qq.com/document/path/98041#错误信息列表>

=cut

sub del_checkin_option {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://qyapi.weixin.qq.com/cgi-bin/checkin/del_checkin_option?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

1;
__END__
