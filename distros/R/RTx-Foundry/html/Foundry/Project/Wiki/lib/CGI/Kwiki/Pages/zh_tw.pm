package CGI::Kwiki::Pages::zh_tw;
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

CGI::Kwiki::Pages::zh_tw - Default pages for Traditional Chinese

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

__布萊恩英格森__
"Ingy" 布萊恩英格森 (Brian Ingerson) 是 Perl 狂熱份子，同時也是 [CPAN http://search.cpan.org/author/INGY/] 模組的作者之一。他所撰寫的模組，包括了妳正在使用的 Wiki 系統，也就是 CGI::Kwiki 。

他的夢想是看到所有使用 /靈巧程式語言/ (Perl, Python, PHP, Ruby) 的社群都合作無間。他正試著以下列的方法來達成這個夢想:

* [YAML http://www.yaml.org]
* [FreePAN http://www.freepan.org]
* [FIT http://fit.freepan.org]
* [Moss http://moss.freepan.org]

妳可以透過下列的管道聯絡到他:
* ingy@cpan.org
* irc://irc.freenode.net/kwiki
__首頁__
*恭喜*! 你已經建立起一個新的 _快紀_ 站台了.

現在妳所看到的是 *預設的* 首頁. 妳應該 /馬上/ 就修改這一頁的內容.

請按底下的編輯按鈕.

妳也可以在 config.yaml 檔案裡新增一個[快紀標幟圖片]，這張圖片將會出現在每一頁的左上方.
----
如果妳現在就需要關於快紀用法的協助，請查看[快紀說明索引].
__關於快紀__
CGI::Kwiki 是一個簡單但強大的 Wiki 環境，這是用 Perl 撰寫而成、並以 CPAN 模組的形式散佈的套件。這套系統是由[布萊恩英格森]所寫的.

*妳所使用的 CGI::Kwiki 版本是 [#.#]* 
  - 有某些更新

0.17 版的變更:
  - 開始支援 RCS 了!!!
  - 修改了判斷 Wiki 鏈結的正規表示式，讓它能夠處理鏈結裡的 '_' 字符
  - 把 html 和 css 模版都清理了一輪（多謝 AdamTrickett ）
  - 支援 template/local/ 目錄
  - 新增了編輯用的登入按鈕
  - 在導覽列加入了部落格
  - 從本地時間改成國際標準時
  - 在近期更新頁面中加入了時間

0.16 版的變更:
  - 能夠使用頁面隱私權（公開、保護、私人）
  - 支援管理者登入
  - 快紀部落格終於實現了
  - 網址能夠使用大寫字母的副檔名了 (.GIF)
  - 以空自串搜尋的時候會顯示站台索引（感謝 JoergBraukhoff ）
  - 在搜尋結果頁面裡，會以 'Search' 來當作 page_id 。
  - 在方刮號 ([) 前面的驚嘆號 (!) 會讓應該要產生的格式規則失效。
  - 抵抗瀏覽器快取（感謝 JoergBraukhoff ）
  - 現在支援 htaccess 的 $ENV{REMOTE_USER} （感謝 Pardus ）


0.15 版的變更:
  - 頁面名稱支援萬國碼 (unicode) 字符層級了
  - 搜尋功能現在會搜尋頁面名稱了
  - 搜尋功能現在用 Perl 重寫過了，而不再繼續用 grep 來搜尋
  - Cookies 的有效時間將能跨越連線期間的限制
  - 現在也可以用 ftp:// 和 irc:// 鏈結
  - 現在也讓妳能從舊的頁面直接建立新的
  - 損毀的 Wiki 鏈結會用 <strike> 加上刪除線
  - 加底線的文字格式不會對鏈結產生效果
  - 現在可以用像是 KWiki 這樣的 Wiki 鏈結
  - 支援 <H4> <H5> 和 <H6>
  - 安裝的時候可以選擇回復出廠預設值或祇進行升級安裝
  - 在 $CGI::Kwiki::VERSION 裡新增了 [#.#] 格式

0.14 版的變更:
  - 跟 mod_perl 一起運作
  - 偏好設定生效了。
  - 支援頁面的詮釋資料。
  - 最近更新會顯示出誰最後編輯了頁面。
  - 幾乎所有不是 perl 的內容現在都寫到合適的檔案裡了。
    像是 Javascript, CSS 之類的。
    這會讓這套系統更容易維護及延展。
  - 支援 mailto 鏈結和內嵌程式碼。
  - 加入了 https 鏈結。這得感謝 GregSchueler 。
  - ':' 可以用於頁面名稱了。這是由 JamesFitzGibbon 所建議的。
  - 修正了由 MikeArms 所回報的 Javascript 瑕疵。
  - 修正了 CGI 參數中的安全性漏洞。這是由 TimSweetman 所回報的。
  - HeikkiLehvaslaiho 修正了由於 Emacs 所產生的人為瑕疵
  - 清掉了多餘的 <p> 標籤。這是由 HolgerSchurig 所回報的
__備份快紀__
快紀 (Kwiki) 能夠備份每一次的頁面變更，所以妳可以很輕易地就把每一個頁面回復成早先的版本。目前唯一的備份模組是 CGI::Kwiki::Backup::Rcs ，這個模組使用 RCS 來備份。大致上任何當前的 Unix 系統裡都可以找到 RCS 。

[備份快紀]預設並不會啟用。如果妳要啟用這個功能的話，請編輯妳的 config.yaml 檔案，然後加入這一列：

    backup_class: CGI::Kwiki::Backup::Rcs
__快紀部落格__
[快紀部落格]讓妳能把任何的 Wiki 頁面都轉為部落格頁面。在這之前妳得先啟用[快紀隱私權]功能，而且也必須先以站台管理者身份登入纔行。

請點選[這裡 http:blog.cgi]來看看[快紀部落格]功能是否已經運作無誤了。
__自訂快紀__
基本上整個快紀站台有三個不同的自訂層級。以下讓我們從最簡單的開始討論：

^=== 修改組態檔案

^=== 修改模版/CSS

在妳的快紀安裝目錄理會有兩個子目錄，它們包含著控制妳網頁樣式呈現的檔案：

* [=template]
* [=css]

你可以任意地修改這些 html 和 css 檔案。最好的作法是先把這些檔案複製到 [=local/template] 和 [=local/css] 目錄裡再進行修改。這麼一來妳對這些檔案的變更就不會被日後執行 [=kwiki-install --upgrade] 時所覆蓋

^=== 修改 Perl 程式碼
__快紀功能__
CGI::Kwiki 的整體設計目標是保持 /簡明/ 和 /擴展性/。

就算如此，快紀還是內建了一些幾乎其他 Wiki 所沒有的強大功能：

* [快紀隱私權]
* [快紀投影片展示]
* [快紀部落格]
* [快紀姊妹站]
* [快紀熱鍵]
* [快紀訂做]
* [快紀簡明文件]

每一項功能都以分離的外掛類別來實做。這樣纔能讓每一件事都保持 _簡明_ 和 _擴展性_。
__快紀訂做__
*可能下一版纔會做出來*

CGI::Kwiki 能夠用來做出 Test::FIT 的測試檔案，直接用 Perl 模組來無痛測試。這將會是 Perl 裡最受歡迎的模組測試方法。（等著看吧！）
__快紀文字格式模組__
CGI::Kwiki::Formatter 是用來把所有的 Wiki 文字格式轉換成 html 的模組。這玩意兒需要很好的文件。有朝一日也許會寫完...
__快紀文字格式語法__
這一頁描述了快紀所使用的 Wiki 標記語言。
----
^= 第一層標題 (H1) =
  = 第一層標題 (H1) =
----
^== 第二層標題 (H2) ==
  == 第二層標題 (H2) ==
----
^=== 第三層標題 (H3) ===
  === 第三層標題 (H3) ===
----
^==== 第四層標題 (H4)
  ==== 第四層標題 (H4)
----
^===== 第五層標題 (H5)
  ===== 第五層標題 (H5)
----
^====== 第六層標題 (H6)
  ====== 第六層標題 (H6)
----
頁面裡所有的水平線都是由四個以上的破折號所做出來的：
  ----
----
段落是以空白列來分開的。

就像這樣。這裡就是另一段。
  段落是以空白列來分開的。

  就像這樣。這裡就是另一段。
----
*粗體字*、/斜體字/、_文字加底線_。
  *粗體字*、/斜體字/、_文字加底線_。
/*合併使用粗體跟斜體*/
  /*合併使用粗體跟斜體*/
內嵌程式碼，像是 [=/etc/passwd] 或 [=CGI::Kwiki]
  內嵌程式碼，像是 [=/etc/passwd] 或 [=CGI::Kwiki]
----
WikiLinks 是由兩個以上的 /大小寫混寫字/ 連寫而成的。
  WikiLinks 是由兩個以上的 /大小寫混寫字/ 連寫而成的。
外部鏈結以 http:// 來開頭，像是 http://www.freepan.org
  外部鏈結以 http:// 來開頭，像是 http://www.freepan.org
強制的 Wiki [鏈結]是以方括號包住的字串。
  強制的 Wiki [鏈結]是以方括號包住的字串。
帶有名稱的 http 鏈結是把文字包進 http:// 鏈結裡，像是 [FreePAN http://www.freepan.org 站台]
  帶有名稱的 http 鏈結是把文字包進 http:// 鏈結裡，像是 [FreePAN http://www.freepan.org 站台]
在前面放上一個 '!' 就會使得像 !WordsShouldNotMakeAWikiLink 這樣的東西不要被轉換成鏈結。
  在前面放上一個 '!' 就會使得像 !WordsShouldNotMakeAWikiLink 這樣的東西不要被轉換成鏈結。
至於 !http://foobar.com 也一樣
  至於 !http://foobar.com 也一樣
郵寄鏈結就祇要寫成像 foo@bar.com 這樣的郵件地址即可。
  郵寄鏈結就祇要寫成像 foo@bar.com 這樣的郵件地址即可。
----
指向圖片的鏈結就會把圖片顯示出來：

http://www.google.com/images/logo.gif
  http://www.google.com/images/logo.gif
----
為編號的清單就以一個 '* ' 來開頭。星號的數量會決定該項目的深度：
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
編號的清單就以一個 '0 ' （零）作為開頭：
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
妳也可以混用這兩種清單：
* 今天:
00 喫冰
00 賭馬
* 明天:
00 喫更多冰
00 賭另一匹馬
  * 今天:
  00 喫冰
  00 買馬
  * 明天:
  00 喫更多冰
  00 買更多馬
----
任何不是從該列第一個字開始撰寫的內容，都會被當作預先排版文字處理。
      foo   bar
       x     y
       1     2
----
妳可以把任何的 Wiki 文字變成註解，就祇需要讓那一列以 '# ' 開頭即可。這麼一來就會把其後的文字通通轉為 html 註解：
# These lines have been 
# commented out
  # These lines have been 
  # commented out
----
簡單的表格：
|        | Dick   | Jane |
| 身高 | 72"    | 65"  |
| 體重 | 130lbs | 150lbs |
  |        | Dick   | Jane |
  | 身高 | 72"    | 65"  |
  | 體重 | 130lbs | 150lbs |
----
多列或含有複雜資料的表格：
| <<END | <<END |
這項資料是垂直的 | bars |
END
# 這是一些 Perl 程式碼：
sub foo {
    print "我要快紀!\n"
}
END
| foo | <<MSG |
如妳所見，我們正在使用
Perl 的即席文件語法。
MSG
  | <<END | <<END |
  這項資料是垂直的 | bars |
  END
  # 這是一些 Perl 程式碼：
  sub foo {
      print "我要快紀!\n"
  }
  END
  | foo | <<MSG |
  如妳所見，我們正在使用
  Perl 的即席文件語法。
  MSG
__快紀說明索引__
CGI::Kwiki 是一套簡單但強大的 Wiki 環境；它是由[布萊恩英格森]用 Perl 撰寫而成的，並以 CPAN 模組的形式加以散佈。

^=== 快紀基礎

* [安裝快紀]
* [升級快紀]
* [快紀功能]
* [快紀文字格式語法]
* [快紀導覽]

^=== CGI::Kwiki 開發

* [關於快紀]
* [快紀待辦]
* [已知的快紀瑕疵]

^=== 組態快紀站台

* [自訂快紀]
* [備份快紀]

^=== CGI::Kwiki 類別/模組文件

* [快紀模組]
* [快紀驅動模組]
* [快紀組態模組]
* [快紀YAML組態模組]
* [快紀文字格式模組]
* [快紀資料庫模組]
* [快紀描述資料模組]
* [快紀顯示模組]
* [快紀編輯模組]
* [快紀模版模組]
* [快紀CGI模組]
* [快紀Cookie模組]
* [快紀搜尋模組]
* [快紀更動模組]
* [快紀偏好模組]
* [快紀新建模組]
* [快紀頁面模組]
* [快紀樣式模組]
* [快紀腳本模組]
* [快紀Javascript模組]
* [快紀投影片模組]
__快紀熱鍵__
*快要寫出來了*

快紀定義了一些特別的按鍵，妳在任何時候都可以使用這些熱鍵，用來輔助[快紀導覽]的功能：

* t - 最上層頁面
* r - 最近更動
* 空白鍵 - 下一個最新的頁面
* e - 編輯
* s - 儲存
* p - 預覽
* h - [快紀說明索引]
* ? - [快紀熱鍵]
* ! - 隨機的快紀頁面
* $ - 捐錢給快紀計畫
__安裝快紀__
^== 安裝快紀站台 ==

瞬間就可以把快紀裝起來。

首先：
* 從 [CPAN http://search.cpan.org/search?query=cgi-kwiki&mode=dist] 下載及安裝 CGI::Kwiki 模組
* 跑一份 Apache 網頁伺服器。

其次：
* 在妳的 Apache 的 cgi-bin 目錄裡再新增一個目錄。
* 進入這個目錄然後執行：

  kwiki-install

第三：
* 把妳的網頁瀏覽器祇到這個新的路徑去。
* 賀！現在你在幾秒內就設定好 Kwiki 了！
----

^== Apache 組態 ==

以下是一段 Apache 組態範例，可能可以幫上忙。

  Alias /kwiki/ /home/ingy/kwiki/
  <Directory /home/ingy/kwiki/>
      Order allow,deny
      Allow from all
      AllowOverride None
      Options ExecCGI
      AddHandler cgi-script .cgi
  </Directory>

請依妳的實際需要加以調整。

^== 同時參見： ==
* [升級快紀]
* [快紀ModPerl]
* [快紀FastCGI]
* [快紀隱私權]
* [備份快紀]
__已知的快紀瑕疵__
請參照： [快紀待辦]
__快紀標幟圖片__
所謂的標幟圖片有點像是快紀「手臂上的毛皮」。當妳要識別妳的快紀時會非常有用，尤其是當妳要從其他 Wiki 站台中識別的時候更是如此。

在快紀的預設格式中，當妳的圖片尺寸是 90x90 圖素的時候會最好看。妳也應該準備另一份縮小成 50x50 圖素版本的圖片。這個圖片會用於[快紀姊妹站]裡，連結到妳的站台。
__快紀ModPerl__
Apache 的 mod_perl 讓 Perl 應用程式在重度使用的時候也能夠跑得更快更好。搭配 mod_perl 使用快紀可以說是小意思。

首先妳得有一份編譯時就選擇要支援 mod_perl 的 Apache 伺服器。這方面的資訊請見 http://perl.apache.org 。

然後按照一般的[安裝快紀]步驟來安裝。

最後在妳的 Apache 組態設定檔裡加上這些東西：

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

這樣就行了！妳馬上就可以體會到 *效能暴增* 的快感。

你可以在任何時候把標準的 CGI 安裝轉移到 mod_perl 。
__快紀FastCGI__
要加快 Perl 應用程式的執行效能，除了 mod_perl 之外，FastCGI 也是個不錯的選擇。

請先將 Apache 伺服器與 FastCGI 以及 mod_fastcgi 編譯在一起。這方面的資訊，請參考 http://www.fastcgi.com/。

然後按照一般的[安裝快紀]步驟來安裝。

最後在 Apache 組態設定檔裡加上這些東西 (以具名虛擬伺服器來達成)：

  <VirtualHost *>
    ServerName kwiki.yourhost.name
    DocumentRoot /usr/local/www/data/kwiki
  
    AddHandler fastcgi-script cgi
    DirectoryIndex index.cgi
  
    <Location />
      Options ExecCGI
    </Location>
  </VirtualHost>

這樣就行了！妳馬上就可以體會到 *效能暴增* 的快感。

你可以在任何時候把標準的 CGI 安裝轉移到 FastCGI。
__快紀導覽__
* 使用每一頁最上方的[最近更動 http://index.cgi?RecentChanges」鏈結，就可以找到最近纔被編輯過的頁面。
* *搜尋* 對話盒可以讓妳指定字串進行快紀頁面的全文檢索。
* 用[快紀熱鍵]就可以在快紀的頁面間輕易移動。
__快紀簡明文件__
*快做出來了*

KwikiFormatterModule 可以用來建立 POD 和額外的 HTML 檔。這對於 Perl 模組作者來說相當之讚。

理論上來說，所有的文件和 Perl 模組的測試都可以在快紀內部完成。事實上[布萊恩英格森]已經開始在做這件事了。

相關的細節都還在調整中。
__快紀隱私權__
快紀允許網站的管理者為每一頁都設定一個隱私權層級。一共有三個隱私權層級：

* 公開 ─ 任何人都可以閱讀及編輯該頁面。
* 保護 ─ 任何人都可以閱讀該頁面，但是祇有管理者纔能夠加以編輯。
* 私人 ─ 祇有管理者纔能夠閱讀或編輯該頁面。

在預設的情況下，所有的頁面都是公開的。
----
^=== 安裝
妳得另外開啟這個隱私權功能。這個功能預設並不會安裝；要開啟這個功能就祇需要在妳安裝快紀的目錄中，下這一個指令就行了：

    kwiki-install --privacy
----
^=== 伺服器組態設定

同時妳也需要修改妳的網頁伺服器組態設定，來讓 [=admin.cgi] 程式受到鑑定架構的保護。以下這個範例就是妳搭配 Apache 時，妳可能會用到的設定：

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

同時妳還得設定管理者密碼。如果妳在用的是 Apache 的話，就祇需要鍵入：

    htpasswd -bc passwd admin foo

這個指令會把 [=admin] 的密碼設定成 [=foo] 。

----

^=== 管理

如果妳打算登入成站台管理者的話，請不要連到 [index.cgi http:index.cgi] ，請連到 [admin.cgi http:admin.cgi] 。如果一切都設定妥當的話，此時你應該會被詢問密碼。

請在使用者名稱輸入 [=admin] ，然後在密碼輸入 [=foo] （或任何妳所設定的密碼）。

一旦妳登入之後，就應該能夠在編輯頁面的時候，一併設定它們的隱私權層級了。
__快紀私人頁面__
妳所按下的鏈結指到一個私人頁面。

請按[http:admin.cgi 這裡]來登入。

請參照： [快紀隱私權]
__快紀姊妹站__
*下一版就會有了*。

姊妹站是一種在妳和其他妳所指定的 Wiki 站台間，提供臨時連結的方法。

更多資訊請見 http://c2.com/cgi/wiki?AboutSisterSites 。
__快紀投影片展示__
CGI::Kwiki 內建了一個像 !PowerPoint 的投影片展示功能。試試看吧。

*請按這裡開始投影片展示*:
[&SLIDESHOW_SELECTOR]
----
[&title 快紀投影片展示功能簡介]
^== 歡迎來到快紀投影片範例 ==
* 你可以按下空白鍵來換到下一張投影片
* 妳也可以在投影片上點擊來繼續前進
----
^== 它如何運作 ==
* 你可以把所有的投影片都建立在一個 Wiki 頁面裡
* 投影片間以一條水平線隔開
----
^== 控制 ==
[&img http://www.google.com/images/logo.gif]
這是一張圖片，擺在這兒祇是好玩罷了。
* 按下空白鍵跳到下一張投影片
* 按下退格鍵 (backspace) 回到前一張投影片
* 按下 '1' 從頭開始
* 按下 'q' 結束
----
^== 調整 ==
* 妳應該適切地調整妳的字型
* Mozilla 也可以用 <ctl>+ 和 <ctl>-
* 臨時再機動調整吧
----
[&lf]
[&subtitle 動畫]
^== 逐列顯示動畫
* 這張投影片
* 一次祇會
* 顯示
* 一列
----
[&lf]
^== 更多動畫
* 這張投影片也是一次
* 祇會顯示一列
----
[&subtitle]
[&bgcolor red]
^== Bugs ==
* 一切在 Mozilla 和 IE 上都運作良好
* 有些瀏覽器似乎對於按鍵事件不會有正確的反應。
** 不過無論如何妳還是可以用退格鍵 (backspace) 或刪除鍵 (delete) 來回到前一張投影片。
----
[&bgcolor]
^== 顯示源碼 ==
* 以下是一些 Javascript 程式碼:
    function changeSlide(i) {
        var myForm = document.getElementsByTagName("form")[0];
        var myNum = myForm.getElementsByTagName("input")[0];
        i = i * 1;
        myVal = myNum.value * 1;
        myNum.value = myVal + i;
        myForm.submit();
    }
* 以下是一些 Perl 程式碼:
    sub process {
        my ($self) = @_;
        return $self->cgi->size ? $self->open_window 
                                : $self->slide;
    }
----
^== 結束 ==
__快紀待辦__
同時參照：[已知的快紀瑕疵]

加入這些功能：
* [快紀姊妹站]
* 頁面別名
* 頁面重新命名/還原成出廠預設值
* 顯示更新版差異
* 支援 [=local/javascript] 和 [=local/css]
__升級快紀__
^== 升級快紀站台 ==

一旦妳新增了新的 CGI::Kwiki 模組後，就祇要 cd 進舊的快紀目錄，然後用這個指令來重新安裝即可：

  kwiki-install --upgrade

這個指令會把組態檔案跟被修改過的頁面外，所有的檔案都加以升級。另外還有其她的升級選項：

  --reinstall  - 所有的檔案都升級，也包括了組態檔案。
  --config     - 升級組態檔案。妳將會移師所有本地端的設定！
  --scripts    - 祇升級 cgi 腳本。
  --pages      - 祇升級預設的快紀頁面，除非該頁面已被使用者變更過了。
  --template   - 祇升級模版。
  --javascript - 祇升級 javascript 。
  --style      - 祇升級 css 樣式表。
__快紀使用者名稱__
妳真的該認真考慮到[偏好設定 http:index.cgi?action=prefs]輸入使用者名稱。這會讓快紀能夠保持追蹤誰變更了甚麼頁面。這個使用者名稱將會顯示在[最近更動 http:index.cgi?RecentChanges]頁面裡。

使用者名稱會被儲存在 cookie 裡，所以就算妳結束這個連線期間也應該還會被保留住。如果妳在用公用機器的話，妳就應該在離開前清除掉這裡的使用者名稱。

在預設的情況下，快紀會在妳設定使用者名稱時，要求你先建立一個關於妳自己的頁面。所以如果引的名字的是路人甲的話，妳就應該先建立一個叫[路人甲]的頁面，然後在那一頁裡稍微描述一下妳自己。接著妳就能夠到[偏好設定 http:index.cgi?action=prefs]裡設定妳的使用者名稱了。

