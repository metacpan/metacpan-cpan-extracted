#!/usr/bin/perl
use lib '../lib';
use Novel::Robot::Parser;
use Test::More ;
use Data::Dumper;
use utf8;

# { dingdian
my $xs = Novel::Robot::Parser->new( site=> 'dingdian' );
my $index_url = 'http://www.23us.com/html/0/202/';
my $chapter_url = 'http://www.23us.com/html/0/202/15973286.html';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^全职高手/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '蝴蝶蓝', 'writer');
is($index_ref->{chapter_list}[0]{url}, $chapter_url, 'chapter_url');

my $html = $xs->{browser}->request_url( $chapter_url );
my $chapter_ref = $xs->extract_elements(
    \$html,
    path => $xs->scrape_novel_item(),
    sub  => $xs->can( 'parse_novel_item' ),
);
is($chapter_ref->{title}=~/被驱逐/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/灵巧/ ? 1 : 0, 1 , 'chapter_content');
# }

done_testing;
exit;

# { kanunu
my $xs = Novel::Robot::Parser->new( site=> 'kanunu' );
#my $index_url = 'http://www.kanunu8.com/book/4559/';
#my $chapter_url = 'http://www.kanunu8.com/book/4559/62299.html';
my $index_url = 'http://www.kanunu8.com/wuxia/201103/2337.html';
my $chapter_url = 'http://www.kanunu8.com/wuxia/201103/2337/68465.html';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^武林/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '古龙', 'writer');
is($index_ref->{chapter_list}[0]{url}, $chapter_url, 'chapter_url');
print Dumper($index_ref);

my $html = $xs->{browser}->request_url( $chapter_url );
my $chapter_ref = $xs->extract_elements(
    \$html,
    path => $xs->scrape_novel_item(),
    sub  => $xs->can( 'parse_novel_item' ),
);
is($chapter_ref->{title}=~/风雪/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/怒雪威寒/ ? 1 : 0, 1 , 'chapter_content');
# }
 exit;

# { asxs
my $xs = Novel::Robot::Parser->new( site=> 'asxs' );
my $index_url = 'http://www.23xs.cc/book/169/index.html';
my $chapter_url = 'http://www.23xs.cc/book/169/85538.html';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^死人经/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '冰临神下', 'writer');
is($chapter_url,$index_ref->{chapter_list}[0]{url} , 'chapter_url');
#print $index_ref->{chapter_list}[0]{url},"\n";

my $html = $xs->{browser}->request_url( $chapter_url );
my $chapter_ref = $xs->extract_elements(
    \$html,
    path => $xs->scrape_novel_item(),
    sub  => $xs->can( 'parse_novel_item' ),
);
is($chapter_ref->{title}=~/杀手/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/顶尖/ ? 1 : 0, 1 , 'chapter_content');
# }


# { lwxs 
my $xs = Novel::Robot::Parser->new( site=> 'lwxs' );
my $index_url = 'http://www.lwxs.com/shu/5/5242/';
my $chapter_url = 'http://www.lwxs.com/shu/5/5242/2023834.html';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^慢慢/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '绝世小白', 'writer');
is($index_ref->{chapter_list}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}=~/引仙台/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/甲/ ? 1 : 0, 1 , 'chapter_content');
# }
#
# { lwxs 
my $xs = Novel::Robot::Parser->new( site=> 'lwxs' );
my $index_url = 'http://www.lwxs.com/shu/5/5242/';
my $chapter_url = 'http://www.lwxs.com/shu/5/5242/2023834.html';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^慢慢/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '绝世小白', 'writer');
is($index_ref->{chapter_list}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}=~/引仙台/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/甲/ ? 1 : 0, 1 , 'chapter_content');
# }

# { shunong 
my $xs = Novel::Robot::Parser->new( site=> 'shunong' );
my $index_url = 'http://www.shunong.com/wx/8558/';
my $chapter_url = 'http://www.shunong.com/wx/8558/267184.html';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^青崖白鹿记$/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '沈璎璎', 'writer');
is($index_ref->{chapter_list}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}=~/^第1章$/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/树入天台石路新/ ? 1 : 0, 1 , 'chapter_content');
# }

# { luoqiu 
my $xs = Novel::Robot::Parser->new( site=> 'luoqiu' );
my $index_url = 'http://www.luoqiu.com/read/3111/';
my $chapter_url = 'http://www.luoqiu.com/read/3111/555962.html';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^死人经/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '冰临神下', 'writer');
is($index_ref->{chapter_list}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}=~/杀手/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/顶尖/ ? 1 : 0, 1 , 'chapter_content');
# }


# { kanshuge 
my $xs = Novel::Robot::Parser->new( site=> 'kanshuge' );
my $index_url = 'http://www.kanshuge.la/files/article/html/48/48682/index.html';
my $chapter_url = 'http://www.kanshuge.la/files/article/html/48/48682/8438614.html';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^死人经/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '冰临神下', 'writer');
is($index_ref->{chapter_list}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}=~/杀手/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/顶尖/ ? 1 : 0, 1 , 'chapter_content');
# }

# { jjwxc
my $xs = Novel::Robot::Parser->new( site=> 'jjwxc' );
my $index_url = 'http://www.jjwxc.net/onebook.php?novelid=14838';
my $chapter_url = 'http://m.jjwxc.net/book2/14838/1';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^断情/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '牵机', 'writer');
is($index_ref->{chapter_list}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}=~/序章/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/大江之东/ ? 1 : 0, 1 , 'chapter_content');
# }

# { hkslg 
my $xs = Novel::Robot::Parser->new( site=> 'hkslg' );
my $index_url = 'http://www.hkslg520.com/4/4205/index.html';
my $chapter_url = 'http://www.hkslg520.com/4/4205/1074131.html';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^死人经/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '冰临神下', 'writer');
is($index_ref->{chapter_list}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}=~/杀手/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/顶尖/ ? 1 : 0, 1 , 'chapter_content');
# }

# { ddshu
my $xs = Novel::Robot::Parser->new( site=> 'ddshu' );
my $index_url = 'http://www.ddshu.net/html/1920/index.html';
my $chapter_url = 'http://www.ddshu.net/1920_1050551.html';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^武林/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '古龙', 'writer');
is($index_ref->{chapter_list}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}=~/风雪/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/怒雪威寒/ ? 1 : 0, 1 , 'chapter_content');
# }

# { qywx
my $xs = Novel::Robot::Parser->new( site=> 'qywx' );
my $index_url = 'http://www.71wx.net/xiaoshuo/36/36452/';
my $chapter_url = 'http://www.71wx.net/xiaoshuo/36/36452/5297096.shtml';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^死人经/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '冰临神下', 'writer');
is($index_ref->{chapter_list}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}=~/杀手/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/顶尖/ ? 1 : 0, 1 , 'chapter_content');
# }

# { biquge
my $xs = Novel::Robot::Parser->new( site=> 'biquge' );
my $index_url = 'http://www.biquge.tw/74_74259/';
my $chapter_url = 'http://www.biquge.tw/74_74259/3817727.html';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^月西女传/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '水草二十三', 'writer');
is($index_ref->{chapter_list}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}=~/楔子/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/为妖者/ ? 1 : 0, 1 , 'chapter_content');
# }


# { asxs
my $xs = Novel::Robot::Parser->new( site=> 'asxs' );
my $index_url = 'http://www.23xs.cc/book/169/index.html';
my $chapter_url = 'http://www.23xs.cc/book/169/85538.html';

my $index_ref = $xs->get_item_info($index_url);
is($index_ref->{book}=~/^死人经/ ? 1 : 0, 1,'book');
is($index_ref->{writer}, '冰临神下', 'writer');
is($index_ref->{chapter_list}[0]{url}, $chapter_url, 'chapter_url');

my $chapter_ref = $xs->get_chapter_ref($chapter_url);
is($chapter_ref->{title}=~/杀手/ ? 1 : 0, 1 , 'chapter_title');
is($chapter_ref->{content}=~/顶尖/ ? 1 : 0, 1 , 'chapter_content');
# }


done_testing;
