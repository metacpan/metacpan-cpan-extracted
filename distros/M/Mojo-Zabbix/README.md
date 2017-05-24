##  Mojo::Zabbix 

  IT is a  simple perl wrapper of Zabbix API. We build only authentication 
and request methods and few helper methods to simplify calling methods 
such ascreate/get/update/delete/exists. 

## 中文介绍

   Mojo::Zabix - 是对zabbix api函数的简单打包，以便更易于用perl脚本进行
访问操作zabbix。目前仅支持认证和请求方法，可以用其进行create/get
/update/delete/exists方法调用，见例子。本模块基于Mojo::useragent，结果
可以用Mojo:DOM进行处理和内容提取。
   本模块依赖Mojo，建议使用cpan包安装 cpanm Mojo::Zabbix

###The more details ,please visting the Zabbix API documentation pages .

    - [Zabbix API Wiki](http://www.zabbix.org/)
    - [Zabbix 1.8 API](http://www.zabbix.com/documentation/1.8/api)
    - [Zabbix 2.0 API](http://www.zabbix.com/documentation/2.0/)
    - [Zabbix 2.2 API](https://www.zabbix.com/documentation/2.2/)
    - [Zabbix 3.0 API](https://www.zabbix.com/documentation/3.0/)
    - [Zabbix 3.2 API](https://www.zabbix.com/documentation/3.2/)
    - [Zabbix 3.4 API](https://www.zabbix.com/documentation/3.4/)

### Test

The module is compatible and tested with Zabbix less version 3.0

本模块目前仅在3.0以前的模块下测试，3.0下基本可以使用，3.0可以使用，但是未严格测试

## Example

     use Mojo::Zabbix;

     my $z = Net::Zabbix->new(
	url => "https://server/zabbix/", 
	username => 'user', 
	password => 'pass',
	verify_ssl => 0,
	debug => 1,
	trace => 0,
     );

     my $r = $z->get("host", {
            filter => undef,
            search => {
            host => "test",
        },
     }
     );

#### A example for print the zabbix api version 打印zabbix服务器版本.

    print $z->get("apiinfo.version",)->{result},"\n";

#### A example for get the new warn message of triggerid 打印新警告触发器.

      print getTriggers($z);
      sub getTriggers {
        my $z=shift;
        my $ysterday=localtime(time()-24*3600);
        my $r = $z->get("trigger", {
                filter => {value => 1,
                           lastChangeSince => "$ysterday",
                  'withUnacknowledgedEvents'=>1,
                },
                output => ["","triggerid","description","priority"],
               sortfield =>"priority",
                sortorder => "DESC",
                expandData=>"host",

         },
         );
         my $result;
         my $host=$r->{'result'};
         for (@$host){
           $result.="$_->{'host'}:".$_->{'description'}."\n" ;
         }

        return $result;
      }


## The result all 结果示意: 

    xxx.xxx.xx.55: {HOST.CONN}服务器的84端口down
    xxx.xxx.xx.55: {HOST.CONN}服务器的81端口down
    xxx.xxx.xx.55: {HOST.CONN}服务器的82端口down
    xxx.xxx.xx.55.9: {HOST.CONN}服务器的80端口down
    xxx.xxx.xx.12: {HOST.NAME} 服务器负载较高，请及时查看
    xxx.xxx.xx.124: 磁盘sdb利用率超过95%，当前值为{ITEM.LASTVALUE}
    xxx.xxx.xx.44: 磁盘sdb利用率超过95%，当前值为{ITEM.LASTVALUE}
    xxx.xxx.xx.45: 磁盘sdb利用率超过95%，当前值为{ITEM.LASTVALUE}
    xxx.xxx.xx.33: 磁盘sdb利用率超过95%，当前值为{ITEM.LASTVALUE}
    xxx.xxx.xx.56: 磁盘sda利用率超过95%，当前值为{ITEM.LASTVALUE}
    xxx.xxx.xx.57: 磁盘sda利用率超过95%，当前值为{ITEM.LASTVALUE}


## 基于本模块的，通过webqq或者webwx实时获取hosts监控数据的实例

    XX_10.2.7.20_
    实时数据:
    
    ESTABLISHED链接 - { connections.status[ESTABLISHED] } : 9
    SYN链接 - { connections.status[SYN] } : 0
    网卡$1的出口流量 - { net.if.out[bond0] } : 5176
    负载 - { system.cpu.load[,avg1] } : 0.000000
    $1剩余inode百分比 - { vfs.fs.inode[/,pfree] } : 99.788211
    $1的剩余百分比 - { vfs.fs.size[/,pfree] } : 99.269724
    可用内存 - { vm.memory.size[available] } : 261874798592
    内存利用率 - { vm.memory.size[pused] } : 4.720467
    内存总空间 - { vm.memory.size[total] } : 270763327488
    
## Mojo-Zabbix-APP

The application of Mojo-Zabbix module。
Get data from zabbix data include host，items, Triggers and warns and so on.

   是Mojo::Zabix模块的应用模块，对zabbix api常见模块进行打包
可以方便的获取zabbix信息，目前包括zabbix版本，主机列表，监控列表，触发器，警告
等，可以根据需求提供更多的操作。

### Example

     use Mojo::Zabbix::APP;

     my @myzinfo = <DATA>; ##(get zabbix info from __DATA__ )

#### Define for debug and traceing processe infomaition。（打开调试和跟踪）

    my $DEBUG=0;
    my $TRACE=0;

#### 定义zabbix服务器

    my @myzinfo = ('test1  http://test1/zabbix    testuser pass');

 @可以定义为多行数据，格式按照这种，一个zabbix 服务地址一个

    for (@myzinfo) {
     next if /^#/;
     next if /^\s*$/;
     my ( $name, $url,$user, $pass ) = split;
     print "\n$name\n";
     my $z;

     eval { $z = initZ( $url,$user,$pss ); };

     if ($@) {

        print "Error $@!\n";
 
     } else {
         ## Print the version of zabbix api. 打印zabbix 版本 
        
         pVersion($z);
       ## Print all host lists。 获取所有的主机列表
        print  getAllhost($z);
       ## Print warning info of Triggers。打印取得的所有触发器告警信息
        pTriggers($z);
       
       ## Print the history data of given items, default for past 24 hours.
       ## 打印给定时间段的item历史数据，如果默认不给时间默认为过去24小时内的
       pHitems($z);

     }

    }


## 结果展示

    name

    Warning info of Triggers

    2016-10-19 23:29:57  : 192.168.1.* : {HOST.NAME}上的80端口关闭
    2016-10-19 22:58:28  : 192.168.2.* : 系统目录/etc/sysconfig/发生变化
    2016-10-19 22:24:32  : 192.168.3.* : 系统目录/etc/init.d/发生变化
    2016-10-19 19:12:53  : 192.168.3.* : 磁盘sda IO利用率超过95%
    2016-10-19 18:03:03  : 192.168.4.* : Too many processes on {HOST.NAME}


## More,更多说明

wo can add the program to crontab  and gain the result for mail
or some Im tool.

我们可以通过cron定时调用程序获得结果，也可以通过IM工具（qq，微信，
目前有个webqq（https://github.com/sjdy521/Mojo-Webqq）的插件,交互
性获取监控数据。


## Git repo
 
[github] (https://github.com/bollwarm/Mojo-Zabbix)
[oschina] (https://git.oschina.net/ijz/Mojo-Zabbix.git) 

## AUTHOR
 
mail to orange: <bollwarm@ijz.me>
[web|blog](http://ijz.me)

## License

This software is copyright (c) 2016 by oragnge.

This is free software; you can redistribute it and/or modify
 it under the same terms as the Perl 5 programming language system itself..

