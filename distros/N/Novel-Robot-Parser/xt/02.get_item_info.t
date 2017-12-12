#!/usr/bin/perl
use lib '../lib';
use Novel::Robot::Parser;
use Test::More;
use Data::Dumper;
use Encode::Locale;
use Encode;

$| = 1;
binmode( STDIN,  ":encoding(console_in)" );
binmode( STDOUT, ":encoding(console_out)" );
binmode( STDERR, ":encoding(console_out)" );
use utf8;

my @check_site_conf = (
  { site            => 'default',
    index_url       => 'http://www.ybdu.com/xiaoshuo/13/13448/',
    chapter_url     => 'http://www.ybdu.com/xiaoshuo/13/13448/3626925.html',
    book            => '死人经',
    writer          => '冰临神下',
    chapter_title   => '杀手',
    chapter_content => '顶尖',
  },
  { site            => 'default',
    index_url       => 'http://www.piaotian.com/html/0/738/',
    chapter_url     => 'http://www.piaotian.com/html/0/738/360430.html',
    book            => '宰执天下',
    writer          => 'cuslaa',
    chapter_content => '从出租车跳上下来就直奔检票口',
  },
  { site            => 'default',
    index_url       => 'http://www.lwxs520.com/books/21/21457/index.html',
    chapter_url     => 'http://www.lwxs520.com/books/21/21457/4862903.html',
    book            => '天醒',
    writer          => '蝴蝶蓝',
    chapter_title   => '楔子',
    chapter_content => '我们要去哪',
  },
  { site            => 'default',
    index_url       => 'http://www.shunong.com/wx/8558/',
    chapter_url     => 'http://www.shunong.com/wx/8558/267184.html',
    book            => '青崖白鹿记',
    writer          => '沈璎璎',
    chapter_title   => '第1章',
    chapter_content => '树入天台石路新',
  },
  { site            => 'default',
    index_url       => 'http://www.lkshu.com/book/5/5979/',
    chapter_url     => 'http://www.lkshu.com/book/5/5979/3256742.html',
    book            => '拔魔',
    writer          => '冰临神下',
    chapter_title   => '少年',
    chapter_content => '小秋',
  },
  { site            => 'default',
    index_url       => 'http://www.tmetb.net/4/4541/',
    chapter_url     => 'http://www.tmetb.net/4/4541/956689.html',
    book            => '死人经',
    writer          => '冰临神下',
    chapter_title   => '杀手',
    chapter_content => '顶尖',
  },
  { site            => 'default',
    index_url       => 'http://www.23us.com/html/24/24469/',
    chapter_url     => 'http://www.23us.com/html/24/24469/15963965.html',
    book            => '死人经',
    writer          => '冰临神下',
    chapter_title   => '杀手',
    chapter_content => '顶尖',
  },
  { site            => 'default',
    index_url       => 'http://www.23xs.cc/book/169/index.html',
    chapter_url     => 'http://www.23xs.cc/book/169/85538.html',
    book            => '死人经',
    writer          => '冰临神下',
    chapter_title   => '杀手',
    chapter_content => '顶尖',
  },
  { site            => 'default',
    index_url       => 'http://www.luoqiu.com/read/3111/',
    chapter_url     => 'http://www.luoqiu.com/read/3111/555962.html',
    book            => '死人经',
    writer          => '冰临神下',
    chapter_title   => '杀手',
    chapter_content => '顶尖',
  },
  { site            => 'default',
    index_url       => 'http://www.kanshuge.la/files/article/html/48/48682/index.html',
    chapter_url     => 'http://www.kanshuge.la/files/article/html/48/48682/8438614.html',
    book            => '死人经',
    writer          => '冰临神下',
    chapter_title   => '杀手',
    chapter_content => '顶尖',
  },
  { site            => 'default',
    index_url       => 'http://www.hkslg.net/4/4205/index.html',
    chapter_url     => 'http://www.hkslg.net/4/4205/1074131.html',
    book            => '死人经',
    writer          => '冰临神下',
    chapter_title   => '杀手',
    chapter_content => '顶尖',
  },
  { site            => 'default',
    index_url       => 'http://www.71wx.net/xiaoshuo/36/36452/',
    chapter_url     => 'http://www.71wx.net/xiaoshuo/36/36452/5297096.shtml',
    book            => '死人经',
    writer          => '冰临神下',
    chapter_title   => '杀手',
    chapter_content => '顶尖',
  },
  #{ site            => 'default',
    #index_url       => 'http://www.tadu.com/book/catalogue/394959',
    #chapter_url     => 'http://www.tadu.com/book/394959/26793462/',
    #book            => '凰图',
    #writer          => '寐语者',
    #chapter_title   => '章目-楔子',
    #chapter_content => '南秦',
  #},
  { site            => 'default',
    index_url       => 'http://www.zhonghuawuxia.com/book/71',
    chapter_url     => 'http://www.zhonghuawuxia.com/chapter/2647',
    book            => '武林',
    writer          => '古龙',
    chapter_title   => '风雪',
    chapter_content => '怒雪威寒',
  },
  { site            => 'ddshu',
    index_url       => 'http://www.ddshu.net/html/1920/opf.html',
    chapter_url     => 'http://www.ddshu.net/1920_1050551.html',
    book            => '武林',
    writer          => '古龙',
    chapter_title   => '风雪',
    chapter_content => '怒雪威寒',
  },
  { site            => 'jjwxc',
    index_url       => 'http://www.jjwxc.net/onebook.php?novelid=14838',
    chapter_url     => 'http://m.jjwxc.net/book2/14838/1',
    writer          => '牵机',
    book            => '断情',
    chapter_title   => '序章',
    chapter_content => '大江',
  },
  { site            => 'kanunu8',
    index_url       => 'https://www.kanunu8.com/wuxia/201103/2337.html',
    chapter_url     => 'https://www.kanunu8.com/wuxia/201103/2337/68465.html',
    book            => '大唐',
    writer          => '黄易',
    chapter_title   => '相依为命',
    chapter_content => '宇文',
  },
  { site            => 'bearead',
    index_url       => 'https://www.bearead.com/reader.html?bid=b10097021&bookListNum=1',
    chapter_url     => { url => 'https://www.bearead.com/api/book/chapter/content', post_data => 'bid=b10097021&cid=354932' },
    book            => '苏旷',
    writer          => '飘灯',
    chapter_title   => '沽',
    chapter_content => '苏',
  },
);

check_site($_) for @check_site_conf;
#check_site( $check_site_conf[0] );
done_testing;

sub check_site {
  my ( $r ) = @_;
  print "check: $r->{index_url}\n";
  my $xs = Novel::Robot::Parser->new( site => $r->{site} );

  my $index_ref = $xs->get_item_info( $r->{index_url} );

  #print Dumper($index_ref->{book});
  is( $index_ref->{book} =~ /$r->{book}/     ? 1 : 0, 1, "book" );
  is( $index_ref->{writer} =~ /$r->{writer}/ ? 1 : 0, 1, "writer" );

  #if ( ref( $r->{chapter_url} ) eq 'HASH' ) {
    #is( $index_ref->{chapter_list}[0]{url}, $r->{chapter_url}{url}, 'chapter_url' );
  #} else {
    #is( $index_ref->{chapter_list}[0]{url}, $r->{chapter_url}, 'chapter_url' );
  #}
  #is( $index_ref->{chapter_list}[0]{title} =~ /$r->{chapter_title}/ ? 1 : 0, 1, "chapter_title" );

  #print Dumper(@{$index_ref->{chapter_list}}[ 0 .. 3 ], "\n");

  my $html =
    ref( $r->{chapter_url} ) eq 'HASH'
    ? $xs->{browser}->request_url( $r->{chapter_url}{url}, $r->{chapter_url}{post_data} )
    : $xs->{browser}->request_url( $r->{chapter_url} );
  my $chapter_ref = $xs->extract_elements(
    \$html,
    path => $xs->scrape_novel_item(),
    sub  => $xs->can( 'parse_novel_item' ),
  );
  is( $chapter_ref->{content} =~ /$r->{chapter_content}/ ? 1 : 0, 1, 'chapter_content' );
  print join( ",", $index_ref->{book}, $index_ref->{writer}, $index_ref->{floor_list}[0]{title} ), "\n";

  #print $chapter_ref->{content},"\n";
  print "---------\n\n";
} ## end sub check_site
