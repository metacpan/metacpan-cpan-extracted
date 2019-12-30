#!/usr/bin/env perl

# CURRENTLY UNDER DEVELOMENT BY WENWU YAN <careline@126.com>
#----------------------------------------------------------------------------
# The Original Code is network Compare Code and related documentation
# distributed by WENWU YAN.
#
# Alternatively, the contents of this file may be used under the terms
# of the GNU General Public License (the "GPL"), in which case the
# provisions of GPL are applicable instead of those above.  If you wish
# to allow use of your version of this file only under the terms of the
# GPL and not to allow others to use your version of this file under the
# License, indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by the GPL.
# If you do not delete the provisions above, a recipient may use your
# version of this file under either the License or the GPL.
#----------------------------------------------------------------------------

use 5.012;
use warnings;
use Encode;
use Encode::CN;

use Carp;
use YAML;
use YAML::Dumper;
use Config::Tiny;
use Data::Dumper;
use Net::Compare;
use Spreadsheet::WriteExcel;

use POSIX qw'strftime';
use Cwd qw'cwd abs_path';
use File::Basename;
use File::Slurp;

#设置时间戳
my $time = strftime( "%Y%m%d", localtime() );

#获取当前脚本绝对路径
my $dir = dirname( abs_path($0) );

#指定系统路径分隔符
my $split = "\\";

#设置配置文件路径
my $config_ini = $dir . $split . "config.ini";

#巡检结果-标量
my $result;

#------------------------------------------------------------------------------
# 巡检脚本使用说明
#------------------------------------------------------------------------------
sub usage () {

    #使用说明打印
    say encode( "cp936",
        decode_utf8("\n$0 网络配置巡检工具使用说明：\n") );
    say encode(
        "cp936",
        decode_utf8(
            "\n1）本程序会自动捕捉当前目录下config.ini配置参数(如没有将自动生成样本)；\n"
        )
    );
    say encode(
        "cp936",
        decode_utf8(
            "\n2）其配置文件需要绑定待离线巡检的配置文件路径、报告输出路径及基线样本；\n"
        )
    );
    say encode(
        "cp936",
        decode_utf8(
            "\n3）基线样本支持严格匹配及模糊匹配两种工作模式，其中模糊匹配需使用正则表达式；\n"
        )
    );
    say encode(
        "cp936",
        decode_utf8(
            "\n4）模糊匹配正则表达式样例： ~ / regex match me /;\n"
        )
    );
    say encode(
        "cp936",
        decode_utf8(
            "\n使用过程中如有任何疑问，请联系carelin\@126\.com!\n"
        )
    );

    #配置文件初始化
    my $text = '#配置巡检目录文件夹
config_dir = config
report_dir = report
check_rule = rules

#巡检基线变量绑定
[rules]
NTP     =  ntp.line
SNMP    =  snmp.line
SSH     =  ssh.line
SYSLOG  =  syslog.line
VTY     =  vty.line
CONSOLE =  console.line
#AAA     =  aaa.line
SSH_ACL = ssh_acl.line
#OTHER   = other.line
SNMP_ACL   = snmp_acl.line
LOCAL_USER = local_user.line
';
    $text = encode( "cp936", decode_utf8("$text") );

    if ( not -f $config_ini ) {
        write_file( $config_ini, $text );
    }
    exit(-1);
}

#初始化配置文件
usage() unless -f $config_ini;
my $config = new Config::Tiny->read($config_ini);

#如果实例化成功则croak
croak encode( "cp936", decode_utf8("请检查配置文件是否存在") )
    unless $config;

#网络配置文件夹
my $config_dir = $dir . $split . $config->{"_"}{"config_dir"};

#基线检查文件夹
my $check_path = $dir . $split . $config->{"_"}{"check_rule"};

#报表输出文件夹
my $report_dir = $dir . $split . $config->{"_"}{"report_dir"};

#基线规则文件
my $rules = $config->{"rules"};
my @attr  = keys %{$rules};
my @files = grep {/\.cfg$|\.conf$|\.config$/} read_dir($config_dir);
my @rules = grep {/\.line$|\.txt$|\.conf|\.cfg$/} read_dir($check_path);

say Dumper @files . 2012;

#预检查目录文件夹是否为空，为空则退出后续动作
croak encode( "cp936",
    decode_utf8("检索到基线样本为空，请录入基线！") )
    unless @rules;

#预检查目录文件夹是否为空，为空则退出后续动作
croak encode(
    "cp936",
    decode_utf8(
        "检索到配置文件为空，请填充待巡检设备配置！")
) unless @files;

#------------------------------------------------------------------------------
# 设备配置巡检
#------------------------------------------------------------------------------
sub conf_parser {

    #检查相关文件夹是否存在，不存在则新建
    mkdir $config_dir unless -d $config_dir;
    mkdir $check_path unless -d $check_path;
    mkdir $report_dir unless -d $report_dir;

    say encode(
        "cp936",
        decode_utf8(
            "\n程序正进行网络配置基线比对，请稍等 ... ....\n"
        )
    );

    #遍历待进行基线检查的网络配置文件
    foreach my $cfg (@files) {
        my $filename = $config_dir . $split . $cfg;

        #配置比对结果变量
        my $ret;
        foreach my $rule (@attr) {

            #拼接规则文件名
            my $rule_name = $check_path . $split . $rules->{$rule};

            #开始基线巡检
            if ($rule_name) {
                $ret = compare( $rule_name, $filename );

                #获取当前基线检查结果
                $result->{$cfg}{$rule} = $ret;
            }
            else {
                croak encode(
                    "cp936",
                    decode_utf8(
                        "基线文件 $rule 不存在，请检查！")
                );
            }
        }
    }

    #返回巡检结果
    my $yaml = encode( "cp936", decode_utf8("基线比对记录文件.yml") );
    YAML::DumpFile( $report_dir . $split . $yaml, $result );
    return $result;
}

#------------------------------------------------------------------------------
# 巡检结果写入EXCEL表格
#------------------------------------------------------------------------------
sub write_excel {

    #接收巡检结果
    my $result = shift;

    #创建基线巡检xls
    my $excel = encode( "cp936", decode_utf8("基线巡检报表-$time") );
    my $workbook
        = Spreadsheet::WriteExcel->new(
        $report_dir . $split . $excel . '.xls' );

    #新建sheet表单
    my $worksheet
        = $workbook->add_worksheet( decode_utf8("基线巡检-$time") );

    #创建格式
    my $format = $workbook->add_format();
    $format->set_bold();
    $format->set_color('blue');
    $format->set_bg_color('red');
    $format->set_size(18);
    $format->set_border(1);
    $format->set_align('center');
    $format->set_valign('vcenter');

    my $format_1 = $workbook->add_format();
    $format_1->set_size(12);
    $format_1->set_border(1);
    $format_1->set_align('center');
    $format_1->set_valign('vcenter');

    my $format_2 = $workbook->add_format();
    $format_2->set_size(12);
    $format_2->set_align('center');
    $format_2->set_valign('vcenter');

    my $format_3 = $workbook->add_format();
    $format_3->set_size(12);
    $format_3->set_color('yellow');
    $format_3->set_bg_color('gray');
    $format_3->set_align('center');
    $format_3->set_valign('vcenter');

    #设置sheet列宽格式
    my $length = scalar( keys %{$rules} );
    $worksheet->set_column( 0, $length + 1, 30, $format_2 );

    #写入数据到sheet
    $worksheet->write_row(
        0, 0,
        [   decode_utf8("网络设备名"), @attr,
            decode_utf8("基线检查得分")
        ],
        $format
    );

    my ( $ret, $rev );
    my $row = 0;
    my $check_failed;

    for my $host ( keys %{$result} ) {
        $row++;
        my $score;

        #通过基线检查项计数器
        foreach ( keys %{ $result->{$host} } ) {
            my $check_ret = $result->{$host}{$_}{"status"};
            ++$score if $check_ret eq "PASS";
        }

        #计算基线巡检得分
        my $origin_score = 0;
        $origin_score = ( $score / $length ) * 100 if $score;
        my $munge_score = sprintf "%.2f", $origin_score;
        $result->{$host}{"score"} = $munge_score;

        #重写Host文件名
        my $munge_host = $host =~ s/(.*)\.cfg/$1/r;
        my @munge_host = map { $result->{$host}{$_}{"status"} } @attr;

        #写入基线比对结果到EXCEL ROW
        my $host_attr = [ $munge_host, @munge_host, $munge_score ];
        $worksheet->set_row( $row, 22.5 );

        #设置基线巡检合规率，偏离基线过大则标黄
        if ( $munge_score < 85 ) {
            $check_failed->{$host} = $result->{$host};
            $worksheet->write_row( $row, 0, $host_attr, $format_3 );
        }
        else {
            $worksheet->write_row( $row, 0, $host_attr, $format_1 );
        }
    }

    #计算合规率
    my $count_fail  = scalar( keys %{$check_failed} );
    my $count_total = scalar @files;
    my $ratio       = ( 1 - $count_fail / $count_total ) * 100;

    #设置精确度
    my $munge_ratio = sprintf "%.2f", $ratio;

    #返回巡检结果
    my $yaml = encode( "cp936", decode_utf8("基线不达标.yml") );
    YAML::DumpFile( $report_dir . $split . $yaml, $check_failed );

    #打印巡检结果
    say encode(
        "cp936",
        decode_utf8(
            "\n当前共巡检 $count_total 台网络设备，配置检查达标率占比为 [$munge_ratio\%]；\n"
        )
    ) if $ratio;
    say encode(
        "cp936",
        decode_utf8(
            "\n其中有 $count_fail 基线检查不达标，详见巡检报表；\n"
        )
    ) if $ratio;
    say encode(
        "cp936",
        decode_utf8(
            "\n网络配置基线检查已分析完毕，自动生成的报表仅供参考！\n"
        )
    );
    say encode(
        "cp936",
        decode_utf8(
            "\n如遇到软件bug，请联系careline\@126\.com！\n")
    );
}

my $ret = conf_parser();
write_excel($ret);
