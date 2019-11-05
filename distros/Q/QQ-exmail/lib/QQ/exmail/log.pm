package QQ::exmail::log;

=encoding utf8

=head1 Name

QQ::exmail::log

=head1 DESCRIPTION

系统日志

=cut

use strict;
use base qw(QQ::exmail);
use Encode;
use LWP::UserAgent;
use JSON;
use utf8;

our $VERSION = '1.10';
our @EXPORT = qw/ mailstatus mail login batchjob operation /;

=head1 FUNCTION

=head2 mailstatus(access_token, hash);

查询邮件概况

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10027>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"domain": "gzdev.com",
    	"begin_date": "2016-10-01",
    	"end_date": "2016-10-07"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    domain	        是	域名
    begin_date	    是	开始日期。格式为2016-10-01
    end_date	    是	结束日期。格式为2016-10-07

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
    	"sendsum": 10,
    	"recvsum": 15
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    sendsum	发信总量
    recvsum	收信总量

=cut

sub mailstatus {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/log/mailstatus?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 mail(access_token, hash);

查询邮件

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10028>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"begin_date": "2016-10-01",
    	"end_date": "2016-10-07",
    	"mailtype": 1,
    	"userid":"zhangsanp@gzdev.com",
    	"subject":"test"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    begin_date	    是	开始日期。格式为2016-10-01
    end_date	    是	开始日期。格式为2016-10-07
    mailtype	    是	邮件类型。0:收信+发信 1:发信 2:收信
    userid	        否	筛选条件：指定成员帐号
    subject	        否	筛选条件：包含指定主题内容

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok", 
    	"list": [
    		{
    			"mailtype":1, 
    			"subject":"testLog", 
    			"sender":"zhangsanp@gzdev.com", 
    			"receiver": 
    			"lisi@gzdev.com", 
    			"time": 1475337600,
    			"status":3
    		}	
    	]
    }

=head4 RETURN 参数说明

    参数	        说明
    errcode	    返回码
    errmsg	    对返回码的文本描述内容
    list	    列表数据
    mailtype	邮件类型。1:发信 2:收信
    sender	    发信者
    receiver	收信者
    time	    时间（时间戳格式）
    status	    邮件状态
                0: 其他状态
                1: 发信中
                2: 被退信
                3: 发信成功
                4: 发信失败
                11: 收信被拦截
                12: 收信，邮件进入垃圾箱
                13: 收信成功，邮件在收件箱
                14: 收信成功，邮件在个人文件夹

=cut

sub mail {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/log/mail?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 login(access_token, hash);

查询成员登录

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10029>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"begin_date": "2016-10-01",
    	"end_date": "2016-10-07",
    	"mailtype": 1,
    	"userid":"zhangsanp@gzdev.com",
    	"subject":"test"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    userid	        是	成员UserID。企业邮帐号名，邮箱格式-10-01
    begin_date	    是	开始日期。格式为2016-10-01
    end_date	    是	结束日期。格式为2016-10-07

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok", 
    	"list": [
    		{ "time": 1475337600, "ip":"127.0.01", "type":1}	
    	]
    }

=head4 RETURN 参数说明

    参数	    说明
    errcode	返回码
    errmsg	对返回码的文本描述内容
    list	列表数据
    time	时间（时间戳格式）
    ip	    登录ip
    type	登录类型
            1：网页登录
            2：手机登录
            3：QQ邮箱App登录
            4：客户端登录:包括imap,pop,exchange
            5：其他登录方式

=cut

sub login {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/log/login?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 batchjob(access_token, hash);

查询批量任务

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10030>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"begin_date": "2016-10-01",
    	"end_date": "2016-10-07"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    begin_date	    是	开始日期。格式为2016-10-01
    end_date	    是	结束日期。格式为2016-10-07

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
    	"list": [
            {
    			"time": 1475337600,
    			"operator": "administrator",
    			"type": 1,
    			"status": 1
    		}
        ]
    }

=head4 RETURN 参数说明

    参数	        说明
    errcode	    返回码
    errmsg	    对返回码的文本描述内容
    list	    列表数据
    time	    时间（时间戳格式）
    operator	操作人员
    type	    操作类型
                1：群发邮件
                2：批量导入成员
                3：删除公告
                4：批量添加别名
                5：发布公告
                6：RTX帐号关联
                7：设置企业签名档
                8：取消企业签名档
                9：开通成员
                0：其他

=cut

sub batchjob {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/log/batchjob?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}

=head2 operation(access_token, hash);

查询操作记录

=head2 SYNOPSIS

L<https://exmail.qq.com/qy_mng_logic/doc#10031>

=head3 请求说明：

=head4 请求包结构体为：

    {
    	"type": 0,
    	"begin_date": "2016-10-01",
    	"end_date": "2016-10-07"
    }

=head4 参数说明：

    参数	            必须	说明
    access_token	是	调用接口凭证
    type	        是	类型
                    1：all
                    2：开放协议同步
                    3：编辑管理员帐号
                    4：设置分级管理员
                    5：编辑企业信息
                    6：收信黑名单设置
                    7：邮件转移设置
                    8：成员与群组管理
                    9：邮件备份管理
                    10：成员权限控制
    begin_date	    是	开始日期。格式为2016-10-01
    end_date	    是	结束日期。格式为2016-10-07

=head3 RETURN 返回结果

    {
    	"errcode": 0,
    	"errmsg": "ok",
    	"list": [
            {
            	"time": 1475337600,
            	"operator": "administrator",
            	"type": 19,
            	"operand": "zhangsanp@gzdev.com"
            }
        ]
    }

=head4 RETURN 参数说明

    参数	        说明
    errcode	    返回码
    errmsg	    对返回码的文本描述内容
    list	    列表数据
    time	    时间（时间戳格式）
    operator	操作人员
    type	    登录类型
                1：登录
                2：修改密码
                3：添加域名
                4：注销域名
                5：设置LOGO
                6：删除LOGO
                7：修改密保邮箱
                8：修改管理员邮箱
                9：发表公告
                10：群发邮件
                11：新增黑名单
                12：删除黑名单
                13：清空黑名单
                14：新增白名单
                15：删除白名单
                16：清空白名单
                17：新增域白名单
                18：删除域白名单
                19：新增用户
                20：删除用户
                21：启用用户
                22：禁用用户
                23：编辑用户
                24：编辑别名
                25：批量导入用户
                26：添加分级管理员
                27：删除分级管理员
                28：新增部门
                29：删除部门
                30：编辑部门
                31：移动部门
                32：新增邮件组
                33：删除邮件组
                34：编辑邮件组
                35：设置邮件备份
                36：邮件转移
                37：IP登录权限
                38：限制成员外发
                39：开启接口
                40：重新获取KEY
                41：停用接口
    operand	    关联数据
    remark	    备注信息：
                若type=20, remark=1表示帐号已还原

=cut

sub operation {
    if ( @_ && $_[0] && ref $_[1] eq 'HASH' ) {
        my $access_token = $_[0];
        my $json = $_[1];
        my $ua = LWP::UserAgent->new;
        $ua->timeout(30);
        $ua->env_proxy;

        my $response = $ua->post("https://api.exmail.qq.com/cgi-bin/log/operation?access_token=$access_token",Content => to_json($json,{allow_nonref=>1}),Content_type =>'application/json');
        if ($response->is_success) {
            return from_json($response->decoded_content,{utf8 => 1, allow_nonref => 1});
        }

    }
    return 0;
}


1;
__END__
