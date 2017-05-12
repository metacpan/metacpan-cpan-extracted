##Mojo-Ecrawler

 Mojo-Ecrawler(易爬) - A easy html page crawler.
 

## INSTALLATION 安装

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install
 Or you can sample using cpan tool (用perl包管理工具安装):
   
       cpanm Mojo::Ecrawler

## SYNOPSIS 使用方法
 
    use Mojo::Ecrawler;
 
    $lurl='http://www.oschina.net';
    $re1="div.TodayNews";#范围特征
    $re2="li a";#内容行特征
 
    my $pcontent=geturlcontent($lurl);
    my $pcout1=getdiv($pcontent,$re1,$re2);
    print $pcout1;

## Result 结果展示

###抓取oschina资讯部分的实例

    阿里巴巴向 Apache 基金会捐赠移动开发框架 Weex  /news/80036/alibaba-donate-weex-to-apache-foundation
    雅虎第二次大规模数据泄露 超过 10 亿帐户被盗  /news/80033/yahoo-data-leaked-twice
    众包平台上线“店铺”功能，打造用户的服务品牌  https://my.oschina.net/u/3109498/blog/806241
    2016 OSC 源创会年终盛典全部视频奉上，干货满满  https://my.oschina.net/osccreate/blog/805923
    JavaScript 的开源功能插件和框架集锦  https://my.oschina.net/u/2903254/blog/806029
    OSC 高手问答 —— 关于 OpenStack 运维部署  https://www.oschina.net/question/2720166_2213030
    每日一博 | Java 压缩算法性能比较  https://my.oschina.net/OutOfMemory/blog/805427
    协作翻译 | 前端优化：9 个技巧，提高 Web 性能  https://www.oschina.net/translate/front-end-optimization
    码云项目推荐 | 基于 Java 的持久层框架 tangyuan  https://git.oschina.net/xsonorg/tangyuan
    OSS-Fuzz —— Google 模糊测试服务  /p/oss-fuzz
    OSChina 周四乱弹 —— 梦见个女子，不让抱  https://my.oschina.net/xxiaobian/blog/806116
    斯坦福大学 NLP 组开放神经机器翻译代码库  /news/80014/stanford-nlp-open-neural-machine-translation-code
    ....


##SUPPORT AND DOCUMENTATION 

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Mojo::Ecrawler

You can also look for information at:

###RT, CPAN's request tracker (report bugs here)

      http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojo-Ecrawler

###AnnoCPAN, Annotated CPAN documentation
   
     http://annocpan.org/dist/Mojo-Ecrawler

###CPAN Ratings
        http://cpanratings.perl.org/d/Mojo-Ecrawler

###Search CPAN
        http://search.cpan.org/dist/Mojo-Ecrawler/
    
###Git repo

[github] (https://github.com/bollwarm/Mojo-Ecrawler.git)

[oschina] (https://git.oschina.net/ijz/Mojo-Ecrawler.git)

##LICENSE AND COPYRIGHT

Copyright (C) 2016 ORANGE

This program is released under the following license: Perl

