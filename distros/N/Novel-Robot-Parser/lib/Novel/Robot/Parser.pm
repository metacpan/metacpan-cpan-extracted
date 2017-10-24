# ABSTRACT: get novel / bbs content from website
package  Novel::Robot::Parser;

use strict;
use warnings;
use utf8;

use Novel::Robot::Browser;
use URI;
use Encode;
use Web::Scraper;
use HTML::TreeBuilder;
use Data::Dumper;

### {{{ data

our $VERSION = 0.30;

our %SITE_DOM_NAME = (
  'bbs.jjwxc.net'   => 'hjj',
  'www.jjwxc.net'   => 'jjwxc',
  'tieba.baidu.com' => 'tieba',

  'www.bearead.com' => 'bearead',
  'www.ddshu.net'   => 'ddshu',
  'www.kanunu8.com' => 'kanunu8',
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
  title      => '',
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

  $opt{site} = $self->detect_site( $opt{site} );

  my $module = "Novel::Robot::Parser::$opt{site}";
  eval "require $module;";

  my $browser = Novel::Robot::Browser->new( %opt );
  bless { browser => $browser, %opt }, $module;
}

sub detect_site {
  my ( $self, $url ) = @_;
  return $url unless ( $url =~ /^http/ );

  my ( $dom ) = $url =~ m#^.*?\/\/(.+?)/#;
  my $site = exists $SITE_DOM_NAME{$dom} ? $SITE_DOM_NAME{$dom} : 'default';

  return $site;
}
### }}}

### {{{ common
sub site_type { 'novel' }
sub charset   { 'cp936' }
sub base_url  { }

sub get_item_info {
  my ( $self,  $url )       = @_;
  my ( $i_url, $post_data ) = $self->generate_novel_url( $url );
  my $c = $self->{browser}->request_url( $i_url, $post_data );
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
sub scrape_novel_list { }

sub generate_novel_url {
  my ( $self, $index_url, @args ) = @_;
  return ( $index_url, @args );
}

sub guess_novel {
  my ( $self, $h, $r ) = @_;

  #print $$h, "\n";
  $r->{book} ||= $self->scrape_element( $h, { path => '//meta[@name="og:novel:book_name"]',     extract => '@content' } );
  $r->{book} ||= $self->scrape_element( $h, { path => '//meta[@property="og:novel:book_name"]', extract => '@content' } );
  $r->{book} ||= $self->scrape_element( $h, { path => '//meta[@property="og:title"]',           extract => '@content' } );
  $r->{book} ||= $self->scrape_element( $h, { path => '//h1',                                   extract => 'TEXT' } );
  $r->{book} ||= $self->scrape_element( $h, { path => '//h2',                                   extract => 'TEXT' } );
  $r->{book} ||= $self->scrape_element( $h, { path => '//div[@id="title"]',                     extract => 'TEXT' } );
  $r->{book} ||= $self->scrape_element( $h, { path => '//div[@class="title"]',                  extract => 'TEXT' } );
  $r->{book} = $self->tidy_writer_book( $r->{book} );

  #print "$r->{book},\n";
  unless ( $r->{book} ) {
    my ( $b_title )  = $$h =~ m#<title>.*?([^,]+?)全文阅读,#si;
    my ( $b_title2 ) = $$h =~ m#<title>[^<]+?《([^<]+?)》#si;

    #print "b_title2: $b_title2\n";
    $r->{book} = $b_title || $b_title2;
  }

  $r->{writer} ||= $self->scrape_element( $h, { path => '//meta[@name="author"]',              extract => '@content' } );
  $r->{writer} ||= $self->scrape_element( $h, { path => '//meta[@name="og:novel:author"]',     extract => '@content' } );
  $r->{writer} ||= $self->scrape_element( $h, { path => '//meta[@property="og:novel:author"]', extract => '@content' } );
  $r->{writer} ||= $self->scrape_element( $h, { path => '//*[@class="author"]',                extract => 'TEXT' } );
  $r->{writer} ||= $self->scrape_element( $h, { path => '//*[@class="writer"]',                extract => 'TEXT' } );
  unless ( $r->{writer} ) {
    my ( $w_span )   = $$h =~ m#<span>作者：</span>([^<]+)#si;
    my ( $w_span_2 ) = $$h =~ m#作者：<span>([^<]+)</span>#si;
    my ( $w_em )     = $$h =~ m#<(?:em|i|h3|span)>作者：([^<]+)</(?:em|i|h3|span)>#si;
    my ( $w_a )      = $$h =~ m#作者：(?:<span>)?<a[^>]*>([^<]+)</a>#si;
    my ( $w_p )      = $$h =~ m#<p>作(?:&nbsp;|\s)*者：([^<]+)</p>#si;
    my ( $w_title )  = $$h =~ m#<title>[^,]+?最新章节\((.+?)\),#si;
    my ( $w_con )    = $$h =~ m#content="([^"]+?)最新著作#s;
    my ( $w_pub )    = $$h =~ m#作者：([^<]+?) 发布时间：#s;
    $r->{writer} = $w_span || $w_span_2 || $w_em || $w_a || $w_p || $w_title || $w_con || $w_pub;
  }

  #print "$r->{writer}, $r->{book}\n";

  return $r;
} ## end sub guess_novel

sub parse_novel {
  my ( $self, $h, $r ) = @_;

  $r = $self->guess_novel( $h, $r ) unless ( $r->{writer} and $r->{book} );
  for my $k ( qw/writer book title/ ) {
    next unless ( defined $r->{$k} );
    $r->{$k} = $self->tidy_writer_book( $r->{$k} );
  }

  #for ( $r->{writer} ) {
  #s/作\s*者：//;
  #s/^\s*作者-\s*//;
  #s/小说全集//;
  #s/作品全集//;
  #s/^.*版权属于作者([^,]+)$/$1/;
  #s/^\s+|\s+$//g;
  #}

  #for ( $r->{book}, $r->{title} ) {
  #next unless $_;
  #s/\s*最新章节\s*$//;
  #s/全文阅读//;
  #s/在线阅读//;
  #s/全集下载//;
  #s/章节目录//;
  #s/^\s*《(.*)》\s*$/$1/;
  #s/^\s+|\s+$//g;
  #}

  return $r;
} ## end sub parse_novel

sub tidy_writer_book {
  my ( $self, $c ) = @_;
  return unless ( defined $c );
  for ( $c ) {
    s/作\s*者：//;
    s/^\s*作者-\s*//;
    s/小说全集//;
    s/作品全集//;
    s/^.*版权属于作者([^,]+)$/$1/;
    s/\s*最新章节\s*$//;
    s/全文阅读//;
    s/在线阅读//;
    s/全集下载//;
    s/章节目录//;
    s/^\s*《(.*)》\s*$/$1/;
    s/^\s+|\s+$//g;
  }
  return $c;
} ## end sub tidy_writer_book

sub parse_novel_item {
  my ( $self, $h, $r ) = @_;

  $r = $self->guess_novel_item( $h ) unless ( $r->{content} );
  $r->{$_} ||= $NULL_CHAPTER{$_} for keys( %NULL_CHAPTER );
  $self->tidy_content( $r );
  return $r;
}

sub guess_novel_item {
  my ( $self, $h, %opt ) = @_;

  $$h =~ s#<script[^>]+>[^<]+</script>##sg;

  my $tree = HTML::TreeBuilder->new();
  $tree->parse( $$h );

  my @links = $tree->look_down( 'text', undef );
  for my $x ( @links ) {

    #my @href = $x->look_down('_tag', 'a');
    $x = { content => $x->as_HTML( '<>&' ) };
  }

  #print Dumper($links[0]);

  my @out_links = sort { length( $b->{content} ) <=> length( $a->{content} ) } @links;
  $self->calc_content_wordnum( $_ ) for @out_links;

  #print "$_->{content}\n------------\n" for @out_links;

  my $no_next_r;
  for my $r ( @out_links ) {

    #next if($r->{href_cnt}>5);
    next if ( $r->{content} =~ m#</(style|head|body|html)>#s );
    next if ( $r->{content} =~ m#^<div id="footer">#s );
    next if ( $r->{content} =~ /(上|下)一(章|页|篇)/s );
    next if ( $r->{content} =~ m#</h(2|1)>#s );
    next if ( $r->{content} =~ m#(.+?</a>){5,}#s );

    #print $r->{content}, "\n-----------------\n";
    $no_next_r = $r;
    last;
  }

  my @grep_next_r = grep { $_->{content} =~ /(上|下)一(章|页|篇)/s and $_->{word_num} > 50 } @out_links;
  return $no_next_r if ( $no_next_r->{word_num} > 50 or !@grep_next_r );

  return $grep_next_r[-1] || {};
} ## end sub guess_novel_item

sub parse_novel_list {
  my ( $self, $h, $r ) = @_;

  return $r->{chapter_list} if ( exists $r->{chapter_list} );

  my $path_r = $self->scrape_novel_list();
  return $self->guess_novel_list( $h ) unless ( $path_r );

  my $parse_novel = scraper {
    process $path_r->{path},
      'chapter_list[]' => {
      'title' => 'TEXT',
      'url'   => '@href'
      };
  };
  my $ref = $parse_novel->scrape( $h );

  my @chap = grep { exists $_->{url} and $_->{url} } @{ $ref->{chapter_list} };

  if ( $path_r->{sort} ) {
    @chap = sort { $a->{url} cmp $b->{url} } @chap;
  }

  return \@chap;
} ## end sub parse_novel_list

sub guess_novel_list {
  my ( $self, $h, %opt ) = @_;

  my $tree = HTML::TreeBuilder->new();
  $tree->parse( $$h );

  my @links = $tree->look_down( '_tag', 'a' );
  @links = grep { $_->attr( 'href' ) } @links;
  for my $x ( @links ) {
    my $up_url = $x->attr( 'href' );
    $up_url =~ s#/[^/]+/?$#/#;
    $up_url = '.' if ( $up_url !~ m#/# );

    $x = { parent => $up_url, depth => $x->depth(), url => $x->attr( 'href' ), title => $x->as_text() };
  }

  my @out_links;
  my @temp_arr = ( $links[0] );
  my $parent   = $links[0]{parent};
  my $depth    = $links[0]{depth};
  for ( my $i = 1 ; $i <= $#links ; $i++ ) {
    if ( $depth == $links[$i]{depth} and $parent eq $links[$i]{parent} ) {
      push @temp_arr, $links[$i];
    } else {
      push @out_links, [@temp_arr];
      @temp_arr = ( $links[$i] );
      $depth    = $links[$i]{depth};
      $parent   = $links[$i]{parent};
    }
  }

  push @out_links, \@temp_arr if ( @temp_arr );

  @out_links = sort { scalar( @$b ) <=> scalar( @$a ) } @out_links;

  #print Dumper(\@out_links);

  my $res_arr;
  my $title_regex =
    qr/引子|楔子|内容简介|正文|序言|文案|第\s*[０１２３４５６７８９零○〇一二三四五六七八九十百千\d]+\s*(章|节)|(^[0-9]+)/;
  my $chap_num_regex = qr/(^|\/)\d+(\.html)?$/;
  for my $arr ( @out_links ) {
    my $x = $arr->[0];
    my $y = $arr->[1];
    my $z = $arr->[-1];

    #print "$y->{title}, $y->{url}\n";
    #print Dumper($arr->[0], $arr->[1], $arr->[-1]);

    $res_arr = $arr if ( $opt{chapter_url_regex}   and $x->{url} =~ /$opt{chapter_url_regex}/ );
    $res_arr = $arr if ( $opt{chapter_title_regex} and $x->{title} =~ /$opt{chapter_title_regex}/ );
    $res_arr = $arr
      if ( $x->{title} =~ /$title_regex/ or ( $y and $y->{title} =~ /$title_regex/ ) or ( $z and $z->{title} =~ /$title_regex/ ) );
    $res_arr = $arr if ( ( $x->{url} =~ /$chap_num_regex/ or $z->{url} =~ /$chap_num_regex/ ) and scalar( @$arr ) > 50 );

    #$res_arr= $arr if( ($x->{url}=~/\/?\d+$/ or $z->{url}=~/\/?\d+$/) and scalar(@$arr)>50);
    last if ( $res_arr );
  }

  #print Dumper($res_arr);

  #remove not chapter url
  while ( 1 ) {
    my $x = $res_arr->[0];
    my $y = $res_arr->[ int( $#$res_arr / 2 ) ];
    if ( $y->{title} =~ /$title_regex/ and $y->{url} =~ /\.html$/ and $x->{url} !~ /\.html$/ ) {
      shift( @$res_arr );
    } elsif ( $y->{title} =~ /$title_regex/ and $y->{url} =~ /$chap_num_regex/ and $x->{url} !~ /$chap_num_regex/ ) {
      shift( @$res_arr );
    } else {
      last;
    }
  }

  #sort chapter url
  if ( $res_arr and $res_arr->[0]{url} =~ /$chap_num_regex/ ) {
    my $trim_sub = sub { my $s = $_[0]; $s =~ s/^.+\///; $s =~ s/\.html$//; return $s };
    my @sort_arr = sort { $trim_sub->( $a->{url} ) <=> $trim_sub->( $b->{url} ) } grep { $_->{url} =~ /$chap_num_regex/ } @$res_arr;
    my @s = map { $trim_sub->( $_->{url} ) } @sort_arr;
    my $random_sort = 0;
    for my $i ( 0 .. $#s - 1 ) {
      $random_sort = 1 if ( $s[$i] > $s[ $i + 1 ] );
      last if ( $random_sort );
    }
    return \@sort_arr if ( $random_sort == 0 );
  }

  return $res_arr || [];
} ## end sub guess_novel_list

sub get_novel_ref {
  my ( $self, $index_url, %o ) = @_;

  my ( $r, $floor_list );
  if ( $index_url !~ /^https?:/ ) {
    $r = $self->parse_novel( $index_url, %o );
  } else {
    my ( $i_url, $post_data ) = $self->generate_novel_url( $index_url );

    ( $r, $floor_list ) = $self->{browser}->request_urls(
      $i_url,
      post_data => $post_data,
      info_sub  => sub {
        $self->extract_elements(
          @_,
          path => $self->can( "scrape_novel" )->(),
          sub  => $self->can( "parse_novel" ),
        );
      },
      content_sub => sub {
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
  } ## end else [ if ( $index_url !~ /^https?:/)]

  $self->update_floor_list( $r, %o );
  $r->{writer_url} = $self->format_abs_url( $r->{writer_url}, $index_url );

  $r->{$_} ||= $NULL_INDEX{$_} for keys( %NULL_INDEX );
  $self->tidy_string( $r, $_ ) for qw/writer book/;

  return $r;
} ## end sub get_novel_ref

### }}}

### {{{ tiezi
sub get_tiezi_ref {
  my ( $self, $url, %o ) = @_;

  my ( $topic, $floor_list ) = $self->get_iterate_data( 'novel', $url, %o );

  $self->update_url_list( $floor_list, $url );

  unshift @$floor_list, $topic if ( $topic->{content} );
  my %r = (
    %$topic,
    writer => $o{writer} || $topic->{writer},
    book => $o{book} || $topic->{book} || $topic->{title},
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
  $r->{chapter_num} //= scalar( @$flist );

  for my $i ( 0 .. $#$flist ) {
    $self->tidy_content( $flist->[$i] );
    $flist->[$i]{id} ||= $r->{chapter_list}[$i]{id} || ( $i + 1 );
    $flist->[$i]{title} = $r->{chapter_list}[ $flist->[$i]{id} - 1 ]{title} || $flist->[$i]{title} || ' ';
  }

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

  $r->{floor_list} = $flist || [];

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
    s/[\]\s+\/\\]/-/g;
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

