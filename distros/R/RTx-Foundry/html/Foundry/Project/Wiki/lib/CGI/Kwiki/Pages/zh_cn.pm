package CGI::Kwiki::Pages::zh_cn;
$VERSION = '0.01';
use strict;
use base 'CGI::Kwiki::Pages';

sub data {
    my $self = shift;
    return '' unless $] >= 5.008;
    $self->use_utf8(1);
    binmode(DATA, ':utf8');
    join '', map { s/^\^=/=/; $_ } <DATA>;
}

1;

__DATA__

=head1 NAME 

CGI::Kwiki::Pages::zh_cn - Default pages for Traditional Chinese

=head1 DESCRIPTION

See installed kwiki pages for more information.

=head1 AUTHOR

Jedi Lin <jedi@idej.org>

=head1 COPYRIGHT

Copyright (c) 2003. Jedi Lin. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__布莱恩英格森__
"Ingy" 布莱恩英格森 (Brian Ingerson) 是 Perl 狂热份子，同时也是 [CPAN http://search.cpan.org/author/INGY/] 模块的作者之一。他所撰写的模块，包括了你正在使用的 Wiki 系统，也就是 CGI::Kwiki 。

他的梦想是看到所有使用 /灵巧程序语言/ (Perl, Python, PHP, Ruby) 的社群都合作无间。他正试著以下列的方法来达成这个梦想:

* [YAML http://www.yaml.org]
* [FreePAN http://www.freepan.org]
* [FIT http://fit.freepan.org]
* [Moss http://moss.freepan.org]

你可以透过下列的管道联络到他:
* ingy@cpan.org
* irc://irc.freenode.net/kwiki
__首页__
*恭喜*! 你已经建立起一个新的 _快纪_ 站台了.

现在你所看到的是 *预设的* 首页. 你应该 /马上/ 就修改这一页的内容.

请按底下的编辑按钮.

你也可以在 config.yaml 档案里新增一个[快纪标帜图片]，这张图片将会出现在每一页的左上方.
----
如果你现在就需要关于快纪用法的协助，请查看[快纪说明索引].
__关于快纪__
CGI::Kwiki 是一个简单但强大的 Wiki 环境，这是用 Perl 撰写而成、并以 CPAN 模块的形式散布的套件。这套系统是由[布莱恩英格森]所写的.

*你所使用的 CGI::Kwiki 版本是 [#.#]* 
  - 有某些更新

0.17 版的变更:
  - 开始支持 RCS 了!!!
  - 修改了判断 Wiki 链接的正规表示式，让它能够处理链接里的 '_' 字符
  - 把 html 和 css 模版都清理了一轮（多谢 AdamTrickett ）
  - 支持 template/local/ 目录
  - 新增了编辑用的登入按钮
  - 在导览列加入了部落格
  - 从本地时间改成国际标准时
  - 在近期更新页面中加入了时间

0.16 版的变更:
  - 能够使用页面隐私权（公开、保护、私人）
  - 支持管理者登入
  - 快纪部落格终于实现了
  - 网址能够使用大写字母的扩展名了 (.GIF)
  - 以空自串搜寻的时候会显示站台索引（感谢 JoergBraukhoff ）
  - 在搜寻结果页面里，会以 'Search' 来当作 page_id 。
  - 在方刮号 ([) 前面的惊叹号 (!) 会让应该要产生的格式规则失效。
  - 抵抗浏览器快取（感谢 JoergBraukhoff ）
  - 现在支持 htaccess 的 $ENV{REMOTE_USER} （感谢 Pardus ）


0.15 版的变更:
  - 页面名称支持万国码 (unicode) 字符层级了
  - 搜寻功能现在会搜寻页面名称了
  - 搜寻功能现在用 Perl 重写过了，而不再继续用 grep 来搜寻
  - Cookies 的有效时间将能跨越联机期间的限制
  - 现在也可以用 ftp:// 和 irc:// 链接
  - 现在也让你能从旧的页面直接建立新的
  - 损毁的 Wiki 链接会用 <strike> 加上删除线
  - 加底线的文字格式不会对链接产生效果
  - 现在可以用像是 KWiki 这样的 Wiki 链接
  - 支持 <H4> <H5> 和 <H6>
  - 安装的时候可以选择回复出厂预设值或祇进行升级安装
  - 在 $CGI::Kwiki::VERSION 里新增了 [#.#] 格式

0.14 版的变更:
  - 跟 mod_perl 一起运作
  - 偏好设定生效了。
  - 支持页面的诠释数据。
  - 最近更新会显示出谁最后编辑了页面。
  - 几乎所有不是 perl 的内容现在都写到合适的档案里了。
    像是 Javascript, CSS 之类的。
    这会让这套系统更容易维护及延展。
  - 支持 mailto 链接和内嵌程序码。
  - 加入了 https 链接。这得感谢 GregSchueler 。
  - ':' 可以用于页面名称了。这是由 JamesFitzGibbon 所建议的。
  - 修正了由 MikeArms 所回报的 Javascript 瑕疵。
  - 修正了 CGI 参数中的安全性漏洞。这是由 TimSweetman 所回报的。
  - HeikkiLehvaslaiho 修正了由于 Emacs 所产生的人为瑕疵
  - 清掉了多馀的 <p> 卷标。这是由 HolgerSchurig 所回报的
__备份快纪__
快纪 (Kwiki) 能够备份每一次的页面变更，所以你可以很轻易地就把每一个页面回复成早先的版本。目前唯一的备份模块是 CGI::Kwiki::Backup::Rcs ，这个模块使用 RCS 来备份。大致上任何当前的 Unix 系统里都可以找到 RCS 。

[备份快纪]预设并不会启用。如果你要启用这个功能的话，请编辑你的 config.yaml 档案，然后加入这一列：

    backup_class: CGI::Kwiki::Backup::Rcs
__快纪部落格__
[快纪部落格]让你能把任何的 Wiki 页面都转为部落格页面。在这之前你得先启用[快纪隐私权]功能，而且也必须先以站台管理者身份登入才行。

请点选[这里 http:blog.cgi]来看看[快纪部落格]功能是否已经运作无误了。
__自订快纪__
基本上整个快纪站台有三个不同的自订层级。以下让我们从最简单的开始讨论：

^=== 修改组态档案

^=== 修改模版/CSS

在你的快纪安装目录理会有两个子目录，它们包含著控制你网页样式呈现的档案：

* [=template]
* [=css]

你可以任意地修改这些 html 和 css 档案。最好的作法是先把这些档案复制到 [=local/template] 和 [=local/css] 目录里再进行修改。这么一来你对这些档案的变更就不会被日后执行 [=kwiki-install --upgrade] 时所覆盖

^=== 修改 Perl 程序码
__快纪功能__
CGI::Kwiki 的整体设计目标是保持 /简明/ 和 /扩展性/。

就算如此，快纪还是内建了一些几乎其它 Wiki 所没有的强大功能：

* [快纪隐私权]
* [快纪投影片展示]
* [快纪部落格]
* [快纪姊妹站]
* [快纪热键]
* [快纪订做]
* [快纪简明文件]

每一项功能都以分离的外挂类别来实做。这样才能让每一件事都保持 _简明_ 和 _扩展性_。
__快纪订做__
*可能下一版才会做出来*

CGI::Kwiki 能够用来做出 Test::FIT 的测试档案，直接用 Perl 模块来无痛测试。这将会是 Perl 里最受欢迎的模块测试方法。（等著看吧！）
__快纪文字格式模块__
CGI::Kwiki::Formatter 是用来把所有的 Wiki 文字格式转换成 html 的模块。这玩意儿需要很好的文件。有朝一日也许会写完...
__快纪文字格式语法__
这一页描述了快纪所使用的 Wiki 标记语言。
----
^= 第一层标题 (H1) =
  = 第一层标题 (H1) =
----
^== 第二层标题 (H2) ==
  == 第二层标题 (H2) ==
----
^=== 第三层标题 (H3) ===
  === 第三层标题 (H3) ===
----
^==== 第四层标题 (H4)
  ==== 第四层标题 (H4)
----
^===== 第五层标题 (H5)
  ===== 第五层标题 (H5)
----
^====== 第六层标题 (H6)
  ====== 第六层标题 (H6)
----
页面里所有的水平线都是由四个以上的破折号所做出来的：
  ----
----
段落是以空白列来分开的。

就像这样。这里就是另一段。
  段落是以空白列来分开的。

  就像这样。这里就是另一段。
----
*粗体字*、/斜体字/、_文字加底线_。
  *粗体字*、/斜体字/、_文字加底线_。
/*合并使用粗体跟斜体*/
  /*合并使用粗体跟斜体*/
内嵌程序码，像是 [=/etc/passwd] 或 [=CGI::Kwiki]
  内嵌程序码，像是 [=/etc/passwd] 或 [=CGI::Kwiki]
----
WikiLinks 是由两个以上的 /大小写混写字/ 连写而成的。
  WikiLinks 是由两个以上的 /大小写混写字/ 连写而成的。
外部链接以 http:// 来开头，像是 http://www.freepan.org
  外部链接以 http:// 来开头，像是 http://www.freepan.org
强制的 Wiki [链接]是以方括号包住的字符串。
  强制的 Wiki [链接]是以方括号包住的字符串。
带有名称的 http 链接是把文字包进 http:// 链接里，像是 [FreePAN http://www.freepan.org 站台]
  带有名称的 http 链接是把文字包进 http:// 链接里，像是 [FreePAN http://www.freepan.org 站台]
在前面放上一个 '!' 就会使得像 !WordsShouldNotMakeAWikiLink 这样的东西不要被转换成链接。
  在前面放上一个 '!' 就会使得像 !WordsShouldNotMakeAWikiLink 这样的东西不要被转换成链接。
至于 !http://foobar.com 也一样
  至于 !http://foobar.com 也一样
邮寄链接就祇要写成像 foo@bar.com 这样的邮件地址即可。
  邮寄链接就祇要写成像 foo@bar.com 这样的邮件地址即可。
----
指向图片的链接就会把图片显示出来：

http://www.google.com/images/logo.gif
  http://www.google.com/images/logo.gif
----
为编号的清单就以一个 '* ' 来开头。星号的数量会决定该项目的深度：
* foo
* bar
** boom
** bam
* baz
  * foo
  * bar
  ** boom
  ** bam
  * baz
----
编号的清单就以一个 '0 ' （零）作为开头：
0 foo
0 bar
00 boom
00 bam
0 baz
  0 foo
  0 bar
  00 boom
  00 bam
  0 baz
----
你也可以混用这两种清单：
* 今天:
00 吃冰
00 赌马
* 明天:
00 吃更多冰
00 赌另一匹马
  * 今天:
  00 吃冰
  00 买马
  * 明天:
  00 吃更多冰
  00 买更多马
----
任何不是从该列第一个字开始撰写的内容，都会被当作预先排版文字处理。
      foo   bar
       x     y
       1     2
----
你可以把任何的 Wiki 文字变成批注，就祇需要让那一列以 '# ' 开头即可。这么一来就会把其后的文字通通转为 html 批注：
# These lines have been 
# commented out
  # These lines have been 
  # commented out
----
简单的表格：
|        | Dick   | Jane |
| 身高 | 72"    | 65"  |
| 体重 | 130lbs | 150lbs |
  |        | Dick   | Jane |
  | 身高 | 72"    | 65"  |
  | 体重 | 130lbs | 150lbs |
----
多列或含有复杂数据的表格：
| <<END | <<END |
这项数据是垂直的 | bars |
END
# 这是一些 Perl 程序码：
sub foo {
    print "我要快纪!\n"
}
END
| foo | <<MSG |
如你所见，我们正在使用
Perl 的即席文件语法。
MSG
  | <<END | <<END |
  这项数据是垂直的 | bars |
  END
  # 这是一些 Perl 程序码：
  sub foo {
      print "我要快纪!\n"
  }
  END
  | foo | <<MSG |
  如你所见，我们正在使用
  Perl 的即席文件语法。
  MSG
__快纪说明索引__
CGI::Kwiki 是一套简单但强大的 Wiki 环境；它是由[布莱恩英格森]用 Perl 撰写而成的，并以 CPAN 模块的形式加以散布。

^=== 快纪基础

* [安装快纪]
* [升级快纪]
* [快纪功能]
* [快纪文字格式语法]
* [快纪导览]

^=== CGI::Kwiki 开发

* [关于快纪]
* [快纪待办]
* [已知的快纪瑕疵]

^=== 组态快纪站台

* [自订快纪]
* [备份快纪]

^=== CGI::Kwiki 类别/模块文件

* [快纪模块]
* [快纪驱动模块]
* [快纪组态模块]
* [快纪YAML组态模块]
* [快纪文字格式模块]
* [快纪数据库模块]
* [快纪描述数据模块]
* [快纪显示模块]
* [快纪编辑模块]
* [快纪模版模块]
* [快纪CGI模块]
* [快纪Cookie模块]
* [快纪搜寻模块]
* [快纪更动模块]
* [快纪偏好模块]
* [快纪新建模块]
* [快纪页面模块]
* [快纪样式模块]
* [快纪脚本模块]
* [快纪Javascript模块]
* [快纪投影片模块]
__快纪热键__
*快要写出来了*

快纪定义了一些特别的按键，你在任何时候都可以使用这些热键，用来辅助[快纪导览]的功能：

* t - 最上层页面
* r - 最近更动
* 空格键 - 下一个最新的页面
* e - 编辑
* s - 储存
* p - 预览
* h - [快纪说明索引]
* ? - [快纪热键]
* ! - 随机的快纪页面
* $ - 捐钱给快纪计画
__安装快纪__
^== 安装快纪站台 ==

瞬间就可以把快纪装起来。

首先：
* 从 [CPAN http://search.cpan.org/search?query=cgi-kwiki&mode=dist] 下载及安装 CGI::Kwiki 模块
* 跑一份 Apache 网页服务器。

其次：
* 在你的 Apache 的 cgi-bin 目录里再新增一个目录。
* 进入这个目录然后执行：

  kwiki-install

第三：
* 把你的网页浏览器祇到这个新的路径去。
* 贺！现在你在几秒内就设定好 Kwiki 了！
----

^== Apache 组态 ==

以下是一段 Apache 组态范例，可能可以帮上忙。

  Alias /kwiki/ /home/ingy/kwiki/
  <Directory /home/ingy/kwiki/>
      Order allow,deny
      Allow from all
      AllowOverride None
      Options ExecCGI
      AddHandler cgi-script .cgi
  </Directory>

请依你的实际需要加以调整。

^== 同时参见： ==
* [升级快纪]
* [快纪ModPerl]
* [快纪FastCGI]
* [快纪隐私权]
* [备份快纪]
__已知的快纪瑕疵__
请参照： [快纪待办]
__快纪标帜图片__
所谓的标帜图片有点像是快纪「手臂上的毛皮」。当你要识别你的快纪时会非常有用，尤其是当你要从其它 Wiki 站台中识别的时候更是如此。

在快纪的预设格式中，当你的图片尺寸是 90x90 图素的时候会最好看。你也应该准备另一份缩小成 50x50 图素版本的图片。这个图片会用于[快纪姊妹站]里，连结到你的站台。
__快纪ModPerl__
Apache 的 mod_perl 让 Perl 应用程序在重度使用的时候也能够跑得更快更好。搭配 mod_perl 使用快纪可以说是小意思。

首先你得有一份编译时就选择要支持 mod_perl 的 Apache 服务器。这方面的信息请见 http://perl.apache.org 。

然后按照一般的[安装快纪]步骤来安装。

最后在你的 Apache 组态设定档里加上这些东西：

  Alias /kwiki/ /home/ingy/kwiki/
  <Directory /home/ingy/kwiki/>
      Order allow,deny
      Allow from all
      AllowOverride None
      Options None
      SetHandler perl-script
      PerlHandler CGI::Kwiki
  </Directory>
  <Directory /home/ingy/kwiki/css/>
      Order allow,deny
      Allow from all
      AllowOverride None
      Options None
      SetHandler none
  </Directory>
  <Directory /home/ingy/kwiki/javascript/>
      Order allow,deny
      Allow from all
      AllowOverride None
      Options None
      SetHandler none
  </Directory>

这样就行了！你马上就可以体会到 *效能暴增* 的快感。

你可以在任何时候把标准的 CGI 安装转移到 mod_perl 。
__快纪FastCGI__
要加快 Perl 应用程序的执行效能，除了 mod_perl 之外，FastCGI 也是个不错的选择。

请先将 Apache 服务器与 FastCGI 以及 mod_fastcgi 编译在一起。这方面的信息，请参考 http://www.fastcgi.com/。

然后按照一般的[安装快纪]步骤来安装。

最后在 Apache 组态设定档里加上这些东西 (以具名虚拟服务器来达成)：

  <VirtualHost *>
    ServerName kwiki.yourhost.name
    DocumentRoot /usr/local/www/data/kwiki
  
    AddHandler fastcgi-script cgi
    DirectoryIndex index.cgi
  
    <Location />
      Options ExecCGI
    </Location>
  </VirtualHost>

这样就行了！你马上就可以体会到 *效能暴增* 的快感。

你可以在任何时候把标准的 CGI 安装转移到 FastCGI。
__快纪导览__
* 使用每一页最上方的[最近更动 http://index.cgi?RecentChanges」链接，就可以找到最近才被编辑过的页面。
* *搜寻* 对话盒可以让你指定字符串进行快纪页面的全文检索。
* 用[快纪热键]就可以在快纪的页面间轻易移动。
__快纪简明文件__
*快做出来了*

KwikiFormatterModule 可以用来建立 POD 和额外的 HTML 档。这对于 Perl 模块作者来说相当之赞。

理论上来说，所有的文件和 Perl 模块的测试都可以在快纪内部完成。事实上[布莱恩英格森]已经开始在做这件事了。

相关的细节都还在调整中。
__快纪隐私权__
快纪允许网站的管理者为每一页都设定一个隐私权层级。一共有三个隐私权层级：

* 公开 ─ 任何人都可以阅读及编辑该页面。
* 保护 ─ 任何人都可以阅读该页面，但是祇有管理者才能够加以编辑。
* 私人 ─ 祇有管理者才能够阅读或编辑该页面。

在预设的情况下，所有的页面都是公开的。
----
^=== 安装
你得另外开启这个隐私权功能。这个功能预设并不会安装；要开启这个功能就祇需要在你安装快纪的目录中，下这一个指令就行了：

    kwiki-install --privacy
----
^=== 服务器组态设定

同时你也需要修改你的网页服务器组态设定，来让 [=admin.cgi] 程序受到鉴定架构的保护。以下这个范例就是你搭配 Apache 时，你可能会用到的设定：

    Alias /kwiki/ /home/ingy/kwiki/
    <Directory /home/ingy/kwiki/>
        Order allow,deny
        Allow from all
        AllowOverride None
        Options ExecCGI
        AddHandler cgi-script .cgi
        <Files admin.cgi>
            Require user admin
            AuthType Basic
            AuthName Restricted
            AuthUserFile /home/ingy/kwiki/passwd
        </Files>
    </Directory>

同时你还得设定管理者口令。如果你在用的是 Apache 的话，就祇需要键入：

    htpasswd -bc passwd admin foo

这个指令会把 [=admin] 的口令设定成 [=foo] 。

----

^=== 管理

如果你打算登入成站台管理者的话，请不要连到 [index.cgi http:index.cgi] ，请连到 [admin.cgi http:admin.cgi] 。如果一切都设定妥当的话，此时你应该会被询问口令。

请在使用者名称输入 [=admin] ，然后在口令输入 [=foo] （或任何你所设定的口令）。

一旦你登入之后，就应该能够在编辑页面的时候，一并设定它们的隐私权层级了。
__快纪私人页面__
你所按下的链接指到一个私人页面。

请按[http:admin.cgi 这里]来登入。

请参照： [快纪隐私权]
__快纪姊妹站__
*下一版就会有了*。

姊妹站是一种在你和其它你所指定的 Wiki 站台间，提供临时连结的方法。

更多信息请见 http://c2.com/cgi/wiki?AboutSisterSites 。
__快纪投影片展示__
CGI::Kwiki 内建了一个像 !PowerPoint 的投影片展示功能。试试看吧。

*请按这里开始投影片展示*:
[&SLIDESHOW_SELECTOR]
----
[&title 快纪投影片展示功能简介]
^== 欢迎来到快纪投影片范例 ==
* 你可以按下空格键来换到下一张投影片
* 你也可以在投影片上点击来继续前进
----
^== 它如何运作 ==
* 你可以把所有的投影片都建立在一个 Wiki 页面里
* 投影片间以一条水平线隔开
----
^== 控制 ==
[&img http://www.google.com/images/logo.gif]
这是一张图片，摆在这儿祇是好玩罢了。
* 按下空格键跳到下一张投影片
* 按下退格键 (backspace) 回到前一张投影片
* 按下 '1' 从头开始
* 按下 'q' 结束
----
^== 调整 ==
* 你应该适切地调整你的字型
* Mozilla 也可以用 <ctl>+ 和 <ctl>-
* 临时再机动调整吧
----
[&lf]
[&subtitle 动画]
^== 逐列显示动画
* 这张投影片
* 一次祇会
* 显示
* 一列
----
[&lf]
^== 更多动画
* 这张投影片也是一次
* 祇会显示一列
----
[&subtitle]
[&bgcolor red]
^== Bugs ==
* 一切在 Mozilla 和 IE 上都运作良好
* 有些浏览器似乎对于按键事件不会有正确的反应。
** 不过无论如何你还是可以用退格键 (backspace) 或删除键 (delete) 来回到前一张投影片。
----
[&bgcolor]
^== 显示源码 ==
* 以下是一些 Javascript 程序码:
    function changeSlide(i) {
        var myForm = document.getElementsByTagName("form")[0];
        var myNum = myForm.getElementsByTagName("input")[0];
        i = i * 1;
        myVal = myNum.value * 1;
        myNum.value = myVal + i;
        myForm.submit();
    }
* 以下是一些 Perl 程序码:
    sub process {
        my ($self) = @_;
        return $self->cgi->size ? $self->open_window 
                                : $self->slide;
    }
----
^== 结束 ==
__快纪待办__
同时参照：[已知的快纪瑕疵]

加入这些功能：
* [快纪姊妹站]
* 页面别名
* 页面重新命名/还原成出厂预设值
* 显示更新版差异
* 支持 [=local/javascript] 和 [=local/css]
__升级快纪__
^== 升级快纪站台 ==

一旦你新增了新的 CGI::Kwiki 模块后，就祇要 cd 进旧的快纪目录，然后用这个指令来重新安装即可：

  kwiki-install --upgrade

这个指令会把组态档案跟被修改过的页面外，所有的档案都加以升级。另外还有其她的升级选项：

  --reinstall  - 所有的档案都升级，也包括了组态档案。
  --config     - 升级组态档案。你将会移师所有本地端的设定！
  --scripts    - 祇升级 cgi 脚本。
  --pages      - 祇升级预设的快纪页面，除非该页面已被使用者变更过了。
  --template   - 祇升级模版。
  --javascript - 祇升级 javascript 。
  --style      - 祇升级 css 样式表。
__快纪使用者名称__
你真的该认真考虑到[偏好设定 http:index.cgi?action=prefs]输入使用者名称。这会让快纪能够保持追踪谁变更了甚么页面。这个使用者名称将会显示在[最近更动 http:index.cgi?RecentChanges]页面里。

使用者名称会被储存在 cookie 里，所以就算你结束这个联机期间也应该还会被保留住。如果你在用公用机器的话，你就应该在离开前清除掉这里的使用者名称。

在预设的情况下，快纪会在你设定使用者名称时，要求你先建立一个关于你自己的页面。所以如果引的名字的是路人甲的话，你就应该先建立一个叫[路人甲]的页面，然后在那一页里稍微描述一下你自己。接著你就能够到[偏好设定 http:index.cgi?action=prefs]里设定你的使用者名称了。

