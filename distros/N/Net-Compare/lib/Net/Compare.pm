package Net::Compare;

use strict;
use warnings;
use File::Slurp;

use Exporter;
use parent 'Exporter';

our $VERSION = '0.04';
our @EXPORT  = qw "compare catch_cmd";

sub usage () {
    say "\n网络配置基线巡检模块使用说明：\n";
    say "\n加载模块后，需传入compare函数（基线配置路径，设备运行配置路径）\n";
    say "\n加载模块后，需传入catch_cmd函数（待捕捉的命令行，巡检输出）\n";
    say '\n使用过程如有任何疑问，请联系careline@126.com\n';
    exit(-1);
}

#------------------------------------------------------------------
# 网络配置基线巡检功能函数
#------------------------------------------------------------------
sub compare {
    my $line   = shift;
    my $config = shift;

    unless ( $line && $config ) {
        &usage();
    }

    #处理属组元素换行符\n
    my @line   = map {s/\n//r} read_file($line);
    my @config = map {s/\n//r} read_file($config);

    #------------------------------------------------------------------
    # 重新组合包含代码块的基线检查
    #------------------------------------------------------------------
    #重新组合运行配置项
    my @ret       = ();
    my $check_ret = 0;

    #检查基线命令行是否为代码块
    my $cli_code = ( grep {/^\s+[^(\+no|\~|\!|\#)]/} @line ) ? 1 : 0;
    if ($cli_code) {
        foreach my $cli (@config) {

            #命中基线首行并设置代码块状态码
            if ( $cli eq $line[0] ) {

                #将代码块内代码添加到属组中
                push @ret, $cli;
                $check_ret = 1;
            }

            #匹配到全局代码行及时结束
            elsif ( $check_ret && $cli =~ /^(\S)/ ) {

                #改写代码块状态
                $check_ret = 0;
                last;
            }

            #将代码块内命令行重组,去除收尾空白字符
            elsif ($check_ret) {
                $cli =~ s/^\s+//;
                $cli =~ s/^\s*$//;
                $cli =~ s/\s+$//;
                next unless $cli;

                #将代码块内代码添加到属组中
                push @ret, $cli if $cli;
            }
        }
    }

    #------------------------------------------------------------------
    # 基线命中检查逻辑
    #------------------------------------------------------------------
    my ( $regex, $result, $report );
    $report->{"cli_code"} = $cli_code;

    foreach my $cmd (@line) {

        #将代码块内命令行重组,去除收尾空白字符
        $cmd =~ s/^\s+//;
        $cmd =~ s/^\s*$//;
        $cmd =~ s/\s+$//;
        next unless $cmd;

        #策略比对结果数据结构
        $report->{"same"} ||= [];
        $report->{"diff"} ||= [];

        #跳过描述性命令行
        if ( $cmd =~ /^\s*(\!|\#).*/ ) {
            next;
        }

        #捕捉模糊匹配命令行
        elsif ( $cmd =~ /^\s*\~\s*\/(?<matched>.*)\// ) {
            $regex = $+{matched};

            if ( scalar @ret ) {
                my $is_matched = 0;
                foreach my $line (@ret) {
                    if ( $line =~ /$regex/ ) {
                        push @{ $report->{"same"} }, $line;
                        $is_matched = 1;
                        last;
                    }
                }

                #遍历元素仍未匹配则不存在该基线
                push @{ $report->{"diff"} }, $cmd unless $is_matched;
            }
            else {
                my $is_matched = 0;
                foreach my $line (@config) {
                    $line =~ s/^\s+//;
                    $line =~ s/^\s*$//;
                    $line =~ s/\s+$//;

                    if ( $line =~ /$regex/ ) {
                        push @{ $report->{"same"} }, $line;
                        $is_matched = 1;
                        last;
                    }
                }

                #遍历元素仍未匹配则不存在该基线
                push @{ $report->{"diff"} }, $cmd unless $is_matched;
            }
        }

        #捕捉需要排除比对的命令
        elsif ( $cmd =~ /^\s*\+no\s+\/(?<exclude>.*)\/$/ ) {
            $regex = $+{exclude};
            next;
        }

        #比对配置是否完全匹配
        else {
            if ( scalar @ret ) {
                my $is_matched = 0;
                foreach my $line (@ret) {
                    if ( $cmd eq $line ) {
                        push @{ $report->{"same"} }, $line;
                        $is_matched = 1;
                        last;
                    }
                }
                push @{ $report->{"diff"} }, $cmd unless $is_matched;
            }
            else {
                my $is_matched = 0;
                foreach my $line (@config) {
                    $line =~ s/^\s+//;
                    $line =~ s/^\s*$//;
                    $line =~ s/\s+$//;
                    if ( $cmd eq $line ) {
                        push @{ $report->{"same"} }, $line;
                        $is_matched = 1;
                        last;
                    }
                }
                push @{ $report->{"diff"} }, $cmd unless $is_matched;
            }
        }
    }

    #输出报告结果
    $report->{"status"}
        = ( scalar @{ $report->{"diff"} } > 0 ) ? "FAIL" : "PASS";
    return $report;
}

#------------------------------------------------------------------
# 网络配置基线巡检-捕捉命令行输出
#------------------------------------------------------------------
sub catch_cmd {

    #状态巡检命令输入
    my $cmd = shift;

    #状态巡检命令输出
    my $config = shift;

    #检查入参是否完整
    unless ( $cmd && $config ) {
        &usage();
    }

    #将命令行转数组
    my @config = map { $_ = s/\n//r } read_file($config);

    #检验是否命中规则
    my $hit_cmd = ( grep {/$cmd\s?$/} @config ) ? 1 : 0;

    #如果未命中命令行则跳出函数
    return unless $hit_cmd;

    #巡检命令行命中计数器
    my ( $result, $hit_count );

    #遍历状态巡检输出
    foreach my $cli (@config) {

        #跳转空白行
        next unless $cli;

        #命中CLI后将配置写入并设置状态
        if ( $cli =~ /$cmd\s?$/ ) {

            #将命中文本写入
            push @{$result}, $cli;
            $hit_count = 1;

        }

        #匹配到描述性分隔符退出遍历
        elsif ( $hit_count && $cli =~ /^(\<(.*)\>|\[.*\])/ ) {

            #改写命中状态
            $hit_count = 0;

            #跳出循环
            last;
        }

        #将非空文本写入
        elsif ($hit_count) {

            #将非空文本写入
            push @{$result}, $cli;
        }
    }

    #返回结果
    return $result;
}

1;
