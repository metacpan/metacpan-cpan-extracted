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
    my $pcout1=getdiv($pcontent,$re1,$re2,1);
    print $pcout1;

## Result 结果展示

###抓取oschina资讯部分的实例

    perl example/oschinanews.pl

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

###抓取百度招聘

     perl example/baiduzhaopin.pl PHP

     PHP初级程序员(上海智...  http://www.lagou.com/jobs/2529492.html?utm_source=m_cf_seo_ald_zhw
     拉勾网
     2016-12-20
     无锡
     上海智来网络科技有限公司
     4000-6000元
     <span class="discription-item"><b>职位描述：</b></span>岗位职责：1、根据公司战略发展需要，参与建设并运营公司旗下的品牌（云教育平台）；负责公司网站PHP相关功能开发；2、负责程序模块的设计、编码；负责撰写所属模块开发文档；3、协助业务部门进行数据挖掘；根据策划需求，按时完成设计与开发；4、根据...
     <span><b>招聘人数：</b>4人</span><span><b>经验：</b>不限</span><span><b>学历：</b>大专</span>
     
     PHP程序员  http://wx.58.com/tech/27865925177271x.shtml?utm_source=baidu&utm_medium=open&utm_campaign=baidu-open-zhaopin
     58同城
     2016-12-19
     北塘区
     无锡智润网络科技有限公司
     面议
     <span class="discription-item"><b>职位描述：</b></span>职位要求：1.有无相关工作经验均可，面试通过后有老员工带领提供岗前培训；2.有志于从事高薪IT行业；3.喜欢计算机，互联网，IT等行业， 想获得一份长期稳定且有发展前景的工作；4.能尽快入职者；5.年龄18-28岁，超龄勿扰。工作时间：9:...
     <span><b>招聘人数：</b>人</span><span><b>经验：</b>不限</span><span><b>学历：</b>不限</span>
     
     PHP程序员(绩效奖金)  http://www.kanzhun.com/job/1314340926.html?sid=aladingzb
     看准网
     2016-12-20
     江阴市
     淘江阴（江阴九澄网购电子商务有限...
     8000-10000/月
     <span class="discription-item"><b>职位描述：</b></span>&lt;br&gt;
                                                     1、精通PHP MySQL开发，熟悉Ajax、JavaScript、 Flash、CSS、Html；&lt;br&gt;2、精通关系数据库MySQL，熟悉SQL语言，并掌握windows环境下开发经验；&amp;l...

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

