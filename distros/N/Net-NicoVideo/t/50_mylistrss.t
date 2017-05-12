use strict;
use warnings;
use utf8;

use Test::More;

use HTTP::Response;
use Encode;
use Net::NicoVideo::Response::MylistRSS;

local $/ = undef;
my $res = Net::NicoVideo::Response::MylistRSS->new(
            HTTP::Response->parse(Encode::encode('utf8', <DATA>)));
isa_ok( $res, 'Net::NicoVideo::Response::MylistRSS' );

my $rss = $res->parsed_content;
is( scalar $rss->get_item, 4, 'get_item' );

is( $rss->title, 'マイリスト 初音ミク曲　-最近の投稿-‐ニコニコ動画', 'channel title');
is( $rss->description, '■新着チェック、マイページから→user/hoge'."\n", 'channel description');
is( $rss->pubDate, '2012-03-06T00:03:19+09:00', 'channel pubDate');
is( $rss->copyright, '(c) niwango, inc. All rights reserved.', 'channel copyright');
is( $rss->link, 'http://www.nicovideo.jp/mylist/0000001', 'channel link');
is( $rss->language, 'ja', 'channel language');
is( $rss->image, undef, 'channel image');
is( $rss->get('atom:link@href'), 'http://www.nicovideo.jp/mylist/0000001?rss=2.0', 'channel atom:link@href');

my $item = $rss->get_item(2);
is( $item->title, '【初音ミク】change【オリジナル曲】', 'item title');
is( $item->description, '<p class="nico-memo">空海月</p><p class="nico-thumbnail"><img alt="【初音ミク】change【オリジナル曲】" src="http://tn-skr1.smilevideo.jp/smile?i=17086028" width="94" height="70" border="0"/></p><p class="nico-description">空海月です、こんにちは。いつもは結構キラキラだと思うんですが、今回はちょっとストイックなミクノでやってみました。やるせないような、悲しいような感じで曲は終わってますが、その苦しみから今度は自分の力でchangeしていく姿を思い描いて書いています。この素敵なイラストはPIAPROの咲那さんのものになります！http://piapro.jp/t/Kf-gマイリスト：mylist/20097259twitter始めました：@solakurage聴いてくれてありがとうm(_ _)m</p><p class="nico-info"><small><strong class="nico-info-length">4:23</strong>｜<strong class="nico-info-date">2012年02月26日 19：17：31</strong> 投稿</small></p>', 'item description');
is( $item->pubDate, '2012-03-04T10:14:00+09:00', 'item pubDate');
is( $item->category, undef, 'item category');
is( $item->author, undef, 'item author');
is( $item->guid, 'tag:nicovideo.jp,2012-02-26:/watch/1330251452', 'item guid');
is( $item->get('guid@isPermaLink'), 'false', 'item guid@isPermaLink');
is( $item->link, 'http://www.nicovideo.jp/watch/sm17086028', 'item link');


done_testing();
1;
__DATA__
HTTP/1.1 200 OK
Date: Tue, 06 Mar 2012 15:13:23 GMT
Server: Apache
x-niconico-authflag: 0
Vary: Accept-Encoding
Connection: close
Content-Type: application/rss+xml; charset=utf-8
Content-Language: ja

<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0"
     xmlns:dc="http://purl.org/dc/elements/1.1/"
     xmlns:atom="http://www.w3.org/2005/Atom">

  <channel>

    <title>マイリスト 初音ミク曲　-最近の投稿-‐ニコニコ動画</title>
    <link>http://www.nicovideo.jp/mylist/0000001</link>
    <atom:link rel="self" type="application/rss+xml" href="http://www.nicovideo.jp/mylist/0000001?rss=2.0"/>
    <description>■新着チェック、マイページから→user/hoge
</description>
    <pubDate>Tue, 06 Mar 2012 00:03:19 +0900</pubDate>
    <lastBuildDate>Tue, 06 Mar 2012 00:03:19 +0900</lastBuildDate>
    <generator>ニコニコ動画</generator>
    <dc:creator>パールモジュールのテスト</dc:creator>
    <language>ja</language>
    <copyright>(c) niwango, inc. All rights reserved.</copyright>
    <docs>http://blogs.law.harvard.edu/tech/rss</docs>


    <item>
      <title>【初音ミクAppend】光の咲く庭で【オリジナル】</title>
      <link>http://www.nicovideo.jp/watch/sm17080687</link>
      <guid isPermaLink="false">tag:nicovideo.jp,2012-02-26:/watch/1330204149</guid>
      <pubDate>Sun, 26 Feb 2012 11:45:01 +0900</pubDate>
      <description><![CDATA[<p class="nico-memo">natsumeg</p><p class="nico-thumbnail"><img alt="【初音ミクAppend】光の咲く庭で【オリジナル】" src="http://tn-skr4.smilevideo.jp/smile?i=17080687" width="94" height="70" border="0"/></p><p class="nico-description">優しいけど、どこかやりきれなく切ない感じ、そんな時ってあると思います。natsumegです。素敵なイラストはpiaproから、かさか様のをお借りして使用させていただきました。http://piapro.jp/kasakaマイリス mylist/25633181コミュ co1198797twitter @natsumeg_よろしくお願いします。ヘッドホン推奨。</p><p class="nico-info"><small><strong class="nico-info-length">4:11</strong>｜<strong class="nico-info-date">2012年02月26日 06：09：09</strong> 投稿</small></p>]]></description>
    </item>

    <item>
      <title>【初音ミク】WiTH【オリジナル曲】</title>
      <link>http://www.nicovideo.jp/watch/nm17081231</link>
      <guid isPermaLink="false">tag:nicovideo.jp,2012-02-26:/watch/1330212835</guid>
      <pubDate>Sun, 04 Mar 2012 10:05:11 +0900</pubDate>
      <description><![CDATA[<p class="nico-memo">aquascape</p><p class="nico-thumbnail"><img alt="【初音ミク】WiTH【オリジナル曲】" src="http://tn-skr4.smilevideo.jp/smile?i=17081231" width="94" height="70" border="0"/></p><p class="nico-description">すっかりおそくなっちゃいました、Eos略してEver out symphoniaです！aquascapeによるEos第5弾、ボカロver投稿です！冬をテーマにしたテクノポップチューン！きいてね♪（*´ω｀*）code : Eos-005_VLyric & Music & Arrenge : aquascapeSong : Miku HatsuneIllust : Minaduki　http://www.pixiv.net/member.php?id=3601878Material Photo : http://www.ashinari.com/オリジナルverはコチラ！→nm16838120Produced by Ever out symphoniaWebsite : http://www.everoutsym.comTwitter : http://twitter.com/#!/everoutsymMylist : mylist/247266701st : nm15745619 nm15702611 | 2nd : nm15937075 nm16041034 | 3rd : nm16309819 nm16117860 | 4t : nm16423945 nm16563498</p><p class="nico-info"><small><strong class="nico-info-length">5:10</strong>｜<strong class="nico-info-date">2012年02月26日 08：33：55</strong> 投稿</small></p>]]></description>
    </item>

    <item>
      <title>【初音ミク】change【オリジナル曲】</title>
      <link>http://www.nicovideo.jp/watch/sm17086028</link>
      <guid isPermaLink="false">tag:nicovideo.jp,2012-02-26:/watch/1330251452</guid>
      <pubDate>Sun, 04 Mar 2012 10:14:00 +0900</pubDate>
      <description><![CDATA[<p class="nico-memo">空海月</p><p class="nico-thumbnail"><img alt="【初音ミク】change【オリジナル曲】" src="http://tn-skr1.smilevideo.jp/smile?i=17086028" width="94" height="70" border="0"/></p><p class="nico-description">空海月です、こんにちは。いつもは結構キラキラだと思うんですが、今回はちょっとストイックなミクノでやってみました。やるせないような、悲しいような感じで曲は終わってますが、その苦しみから今度は自分の力でchangeしていく姿を思い描いて書いています。この素敵なイラストはPIAPROの咲那さんのものになります！http://piapro.jp/t/Kf-gマイリスト：mylist/20097259twitter始めました：@solakurage聴いてくれてありがとうm(_ _)m</p><p class="nico-info"><small><strong class="nico-info-length">4:23</strong>｜<strong class="nico-info-date">2012年02月26日 19：17：31</strong> 投稿</small></p>]]></description>
    </item>

    <item>
      <title>【初音ミクAppend】虹の彼方に【オリジナル曲PV】</title>
      <link>http://www.nicovideo.jp/watch/sm17097710</link>
      <guid isPermaLink="false">tag:nicovideo.jp,2012-02-27:/watch/1330350639</guid>
      <pubDate>Tue, 28 Feb 2012 23:02:41 +0900</pubDate>
      <description><![CDATA[<p class="nico-memo">くど</p><p class="nico-thumbnail"><img alt="【初音ミクAppend】虹の彼方に【オリジナル曲PV】" src="http://tn-skr3.smilevideo.jp/smile?i=17097710" width="94" height="70" border="0"/></p><p class="nico-description">■こんばんは。くどです。オズの魔法使いにちょっとだけ引っ掛けて、ラブソングを作ってみました。■詞・曲・動画　くど■イラスト　たくちゃ様　http://www.pixiv.net/member.php?id=759848■素材をお借りしました。　ロジックP様 nc10611　- 桜 空 -様 nc40106　（写真素材「空 見 人」http://www.niconicommons.jp/user/996939）　漆烏様　　http://piapro.jp/t/IRm2　　http://piapro.jp/t/E0lh■カラオケをピアプロにアップしました。　http://piapro.jp/kyuushokuくど　mylist/29940387TwitterID kudopixel</p><p class="nico-info"><small><strong class="nico-info-length">4:09</strong>｜<strong class="nico-info-date">2012年02月27日 22：50：39</strong> 投稿</small></p>]]></description>
    </item>

  </channel>

</rss>
