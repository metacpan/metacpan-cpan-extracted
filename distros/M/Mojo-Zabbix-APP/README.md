## Mojo-Zabbix-APP

The application of Mojo-Zabbix module。
Get data from zabbix data include host，items, Triggers and warns and so on.

## 中文介绍
 
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

## more,更多实例见 

   example/example.pl

## INSTALLATION

You can easyly install this modue use perl packages like cpanm

       cpanm Mojo::Mojo::APP

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Mojo::Zabbix::APP

You can also look for information at:

### RT, CPAN's request tracker (report bugs here)
  
      http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojo-Zabbix-APP

### AnnoCPAN, Annotated CPAN documentation
   
     http://annocpan.org/dist/Mojo-Zabbix-APP

###  CPAN Ratings
        http://cpanratings.perl.org/d/Mojo-Zabbix-APP
### Search CPAN
        http://search.cpan.org/dist/Mojo-Zabbix-APP/
### GitHub
       https://github.com/bollwarm/Mojo-Zabbix-APP
### Oschina
       https://git.oschina.net/ijz/Mojo-Zabbix-APP 


## License

This software is copyright (c) 2016 by oragnge.

This is free software; you can redistribute it and/or modify
 it under the same terms as the Perl 5 programming language system itself
