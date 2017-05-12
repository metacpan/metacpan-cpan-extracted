# ABSTRACT: get novel / bbs content from website
package  Novel::Robot::Parser;

use strict;
use warnings;
use utf8;

use Novel::Robot::Browser;
use URI;
use Encode;
use Web::Scraper;

### {{{ data

our $VERSION = 0.29;

our %SITE_DOM_NAME = (
  'bbs.jjwxc.net'         => 'hjj',
  'www.kanunu8.com'       => 'kanunu',
  'm.xiaoxiaoshuwu.com'   => 'xiaoxiaoshuwu',
  'read.qidian.com'       => 'qidian',
  'tieba.baidu.com'       => 'tieba',
  'www.123yq.com'         => 'yesyq',
  'www.23us.com'          => 'dingdian',
  'www.23xs.cc'           => 'asxs',
  'www.biquge.tw'         => 'biquge',
  'www.71wx.net'          => 'qywx',
  'www.ddshu.net'         => 'ddshu',
  'www.hkslg520.com'      => 'hkslg',
  'www.jjwxc.net'         => 'jjwxc',
  'www.kanshuge.la'       => 'kanshuge',
  'www.kanunu8.com'       => 'kanunu',
  'www.luoqiu.com'        => 'luoqiu',
  'www.qqxs.cc'           => 'qqxs',
  'www.shunong.com'       => 'shunong',
  'www.snwx.com'          => 'snwx',
  'www.tadu.com'          => 'tadu',
  'www.ttzw.com'          => 'ttzw',
  'www.lwxs.com'          => 'lwxs',
  'www.yanqingji.com'     => 'yanqingji',
  'www.ybdu.com'          => 'ybdu',
  'www.yssm.org'          => 'yssm',
  'www.zhonghuawuxia.com' => 'zhonghuawuxia',
  'www.zilang.net'        => 'zilang',
  'www.bxwx9.org' => 'bxwx9', 
);

our %NULL_INDEX = (
  url          => '',
  book         => '',
  writer       => '',
  writer_url   => '',
  chapter_list => [],
  floor_list   => [],

  intro    => '',
  series   => '',
  progress => '',
  word_num => '',
);

our %NULL_CHAPTER = (
  content    => '',
  id         => 0,
  pid        => 0,
  time       => '',
  title      => '章节为空',
  url        => '',
  writer     => '',
  writer_say => '',
  abstract   => '',
  word_num   => '',
  type       => '',
);

### }}}

### init {{{
sub new {
  my ( $self, %opt ) = @_;

  $opt{site} = $self->detect_site( $opt{site} ) || 'jjwxc';
  my $module = "Novel::Robot::Parser::$opt{site}";

  my $browser = Novel::Robot::Browser->new( %opt );

  eval "require $module;";
  bless { browser => $browser, %opt }, $module;

}

sub detect_site {
  my ( $self, $url ) = @_;
  return $url unless ( $url =~ /^http/ );

  my ( $dom ) = $url =~ m#^.*?\/\/(.+?)/#;
  my $site = exists $SITE_DOM_NAME{$dom} ? $SITE_DOM_NAME{$dom} : 'unknown';

  return $site;
}
### }}}

### {{{ common
sub site_type { 'novel' }
sub charset   { 'cp936' }
sub base_url  { }

sub get_item_info {
  my ( $self, $url ) = @_;
  my $c = $self->{browser}->request_url( $url );
  my $r = $self->extract_elements(
    \$c,
    path => $self->can( "scrape_novel" )->(),
    sub  => $self->can( "parse_novel" ),
  );
  $r->{chapter_list} = $self->parse_novel_list( \$c, $r );
  $r->{chapter_num} = $self->update_url_list( $r->{chapter_list}, $url );
  return $r;
}

sub get_item_ref {
  my ( $self, $index_url, %o ) = @_;
  my $bt   = $self->site_type();
  my $name = "get_${bt}_ref";
  $self->$name( $index_url, %o );
}
### }}}

### {{{ novel
sub scrape_novel      { {} }
sub scrape_novel_item { {} }
sub scrape_novel_list { {} }

sub parse_novel {
  my ( $self, $h, $r ) = @_;

  for ( $r->{writer} ) {
    s/作\s*者：//;
    s/小说全集//;
  }

  for ( $r->{book}, $r->{title} ) {
    next unless $_;
    s/\s*最新章节\s*$//;
    s/全文阅读//;
    s/在线阅读//;
    s/^\s*《(.*)》\s*$/$1/;
  }

  return $r;
} ## end sub parse_novel

sub parse_novel_item {
  my ( $self, $h, $r ) = @_;
  $r->{$_} ||= $NULL_CHAPTER{$_} for keys( %NULL_CHAPTER );
  $self->tidy_content( $r );
  return $r;
}

sub parse_novel_list {
  my ( $self, $h, $r ) = @_;

  my $path_r = $self->scrape_novel_list();
  return [] unless ( $path_r );

  my $parse_novel = scraper {
    process $path_r->{path},
      'chapter_list[]' => {
      'title' => 'TEXT',
      'url'   => '@href'
      };
  };
  my $ref = $parse_novel->scrape( $h );

  my @chap = grep { exists $_->{url} and $_->{url} } @{ $ref->{chapter_list} };

  return \@chap unless ( $path_r->{sort} );

  my @sort_chap = sort { $a->{url} cmp $b->{url} } @chap;
  return \@sort_chap;
} ## end sub parse_novel_list

sub get_novel_ref {
  my ( $self, $index_url, %o ) = @_;
  if ( $index_url !~ /^https?:/ ) {
    return $self->parse_novel( $index_url, %o );
  }

  my ( $r, $floor_list ) = $self->{browser}->request_urls(
    $index_url,
    info_sub => sub {
      $self->extract_elements(
        @_,
        path => $self->can( "scrape_novel" )->(),
        sub  => $self->can( "parse_novel" ),
      );
    },
    content_sub  => sub { 
      $self->extract_elements(
        @_,
        path => $self->can( "scrape_novel_item" )->(),
        sub  => $self->can( "parse_novel_item" ),
      );
    },
    url_list_sub => sub { $self->can( "parse_novel_list" )->( $self, @_ ) },
    %o,
  );

  $r->{url}         = $index_url;
  $r->{chapter_num} = $self->update_url_list( $r->{chapter_list}, $r->{url} );
  $r->{floor_list}  = $floor_list unless ( exists $r->{floor_list} and @{ $r->{floor_list} } );

  $self->update_floor_list( $r, %o );
  $r->{writer_url} = $self->format_abs_url( $r->{writer_url}, $self->base_url );

  $r->{$_} ||= $NULL_INDEX{$_} for keys( %NULL_INDEX );
  $self->tidy_string( $r, $_ ) for qw/writer book/;

  return $r;
} ## end sub get_novel_ref

### }}}

### {{{ tiezi
sub get_tiezi_ref {
    my ( $self, $url, %o ) = @_;

    my ( $topic, $floor_list ) = $self->get_iterate_data( 'novel', $url, %o );

    $self->update_url_list( $floor_list, $self->base_url || $url );

    unshift @$floor_list, $topic if ( $topic->{content} );
    my %r = (
        %$topic,
        writer => $o{writer} || $topic->{writer}, 
        book       => $o{book} || $topic->{book} || $topic->{title},
        url        => $url,
        floor_list => $floor_list,
    );
    $self->update_floor_list( \%r, %o );

    return \%r;
} ## end sub get_tiezi_ref

sub get_iterate_data {
  my ( $self, $class, $url, %o ) = @_;
  my ( $title, $item_list ) = $self->{browser}->request_urls_iter(
    $url,

    #post_data     => $o{post_data},
    info_sub => sub {
      $self->extract_elements(
        @_,
        path => $self->can( "scrape_$class" )->(),
        sub  => $self->can( "parse_$class" ),
      );
    },
    content_sub  => sub { $self->can( "parse_${class}_item" )->( $self, @_ ) },
    url_list_sub => sub { $self->can( "parse_${class}_list" )->( $self, @_ ) },

    #min_page_num  => $o{"min_page_num"},
    #max_page_num  => $o{"max_page_num"},
    stop_sub => sub {
      my ( $info, $data_list, $i ) = @_;
      $self->{browser}->is_list_overflow( $data_list, $o{"max_item_num"} );
    },
    %o,
  );
} ## end sub get_iterate_data
### }}}

### {{{ board
sub scrape_board      { {} }
sub scrape_board_item { {} }
sub scrape_board_list { {} }

sub parse_board {
  my ( $self, $h, $r ) = @_;
  return $r;
}
sub parse_board_item { }
sub parse_board_list { }

sub get_board_ref {
  my ( $self, $url, %o ) = @_;

  my ( $topic, $item_list ) = $self->get_iterate_data( 'board', $url, %o );

  $self->update_url_list( $item_list, $url );

  return ( $topic, $item_list );
}
### }}}

### {{{ query
sub scrape_query      { {} }
sub scrape_query_item { {} }
sub scrape_query_list { {} }

sub parse_query {
  my ( $self, $h, $r ) = @_;
  return $r;
}
sub parse_query_item { }
sub parse_query_list { }

sub get_query_ref {
  my ( $self, $keyword, %o ) = @_;

  my ( $url, $post_data ) = $self->make_query_request( $keyword, %o );

  my ( $info, $item_list ) = $self->get_iterate_data( 'query', $url, %o, post_data => $post_data );

  $self->update_url_list( $item_list, $url );

  return ( $info, $item_list );
}

sub make_query_request { }

### }}}

### {{{ base

sub update_url_list {
  my ( $self, $arr, $base_url ) = @_;

  my $i = 0;
  for my $chap ( @$arr ) {
    $chap = { url => $chap || '' } if ( ref( $chap ) ne 'HASH' );
    $self->format_abs_url( $chap, $base_url );

    ++$i;
    $chap->{pid} //= $i;
    $chap->{id}  //= $i;
  }
  return $i;
}

sub format_abs_url {
  my ( $self, $chap, $base_url ) = @_;
  $base_url ||= $self->base_url();
  return $chap if ( !$chap or !$base_url or $base_url !~ /^http/ );

  if ( ref( $chap ) eq 'HASH' ) {
    $chap->{url} = URI->new_abs( $chap->{url}, $base_url )->as_string;
  } else {
    $chap = URI->new_abs( $chap, $base_url )->as_string;
  }

  return $chap;
}

sub extract_elements {
  my ( $self, $h, %o ) = @_;
  $o{path} ||= {};

  my $r = {};
  while ( my ( $xk, $xr ) = each %{ $o{path} } ) {
    $r->{$xk} = $self->scrape_element( $h, $xr );
  }
  $r = $o{sub}->( $self, $h, $r ) if ( $o{sub} );
  return $r;
}

sub scrape_element {
  my ( $self, $h, $o ) = @_;
  return $self->extract_regex_element( $h, $o->{regex} ) if ( $o->{regex} );
  return $o->{sub}->( $h ) unless ( $o->{path} );

  $o->{extract} ||= 'TEXT';

  my $parse = $o->{is_list}
    ? scraper { process $o->{path},       'data[]' => $o->{extract}; }
    : scraper { process_first $o->{path}, 'data'   => $o->{extract}; };
  my $r = $parse->scrape( $h );
  return unless ( defined $r->{data} );

  return $r->{data} unless ( $o->{sub} );
  return $o->{sub}->( $r->{data} );
}

sub extract_regex_element {
  my ( $self, $h, $reg ) = @_;
  my ( $d ) = $$h =~ m#$reg#s;
  return $d;
}

sub update_floor_list {
    my ( $self, $r, %o ) = @_;

    my $flist = $r->{floor_list};
    $r->{raw_floor_num} = scalar( @$flist );
    $flist->[$_]{id} //= $_ + 1 for ( 0 .. $#$flist );
    $flist->[$_]{title} //= $r->{chapter_list}[$_]{title} || ' ' for ( 0 .. $#$flist );

    $flist = [ grep { $self->{browser}->is_item_in_range( $_->{id}, $o{min_item_num}, $o{max_item_num} ) } @$flist ];

    $self->calc_content_wordnum( $_ ) for @$flist;

    $flist = [ grep { $_->{word_num} >= $o{min_content_word_num} } @$flist ]
    if ( $o{min_content_word_num} );

    $flist = [ grep { $_->{writer} eq $r->{writer} } @$flist ]
    if ( $o{only_poster} );

    $flist = [ grep { $_->{content} =~ /$o{grep_content}/s } @$flist ]
    if ( $o{grep_content} );

    $flist = [ grep { $_->{content} !~ /$o{filter_content}/s } @$flist ]
    if ( $o{filter_content} );

    $r->{floor_list} = $flist;

    return $self;
} ## end sub update_floor_list

sub calc_content_wordnum {
  my ( $self, $f ) = @_;
  return if ( $f->{word_num} );
  my $wd = $f->{content} || '';
  $wd =~ s/<[^>]+>//gs;
  $wd =~ s/\s+//sg;
  $f->{word_num} = $wd =~ s/\S//gs;
  return $f;
}

sub tidy_string {
  my ( $self, $r, $k ) = @_;
  $r->{$k} ||= '';

  for ( $r->{$k} ) {
    s/^\s+|\s+$//gs;
    s/[\*\/\\\[\(\)]+//g;
    s/[[:punct:]]//sg;
    s/[\]\s+]/-/g;
  }

  $r;
}

sub tidy_content {
  my ( $self, $r ) = @_;
  for ( $r->{content} ) {
    s###sg;
    s#<script(\s+[^>]+\>|\>)[^<]*</script>##sg;
    s#\s*\<[^>]+?\>#\n#sg;
    s{\n\n\n*}{\n}sg;
    s{\s*(\S.*?)\s*\n}{\n<p>$1</p>}sg;
  }
  return $r;
}

sub get_inner_html {
  my ( $self, $h ) = @_;

  return '' unless ( $h );

  my $head_i = index( $h, '>' );
  substr( $h, 0, $head_i + 1 ) = '';

  my $tail_i = rindex( $h, '<' );
  substr( $h, $tail_i ) = '';

  return $h;
}

sub unescape_js {
  my ( $self, $s ) = @_;
  $s =~ s/%u([0-9a-f]{4})/chr(hex($1))/eigs;
  $s =~ s/%([0-9a-f]{2})/chr(hex($1))/eigs;
  return $s;
}

### }}}

1;

