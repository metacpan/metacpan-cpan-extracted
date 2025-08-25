# ABSTRACT: get novel / bbs content from website
package  Novel::Robot::Parser;

use strict;
use warnings;
use utf8;

#use Data::Dumper;
use Encode;
use HTML::TreeBuilder;
use URI;
use Web::Scraper;

use Novel::Robot::Browser;
#use Smart::Comments;

our $VERSION = 0.32;


our %SITE_DOM_NAME = (
  'bbs.jjwxc.net'   => 'hjj',
  'www.jjwxc.net'   => 'jjwxc',
  'm.jjwxc.net'   => 'jjwxc',
  'tieba.baidu.com' => 'tieba',

  'www.ddshu.net'    => 'ddshu',
  'www.kanunu8.com'  => 'kanunu8',
);

our %NULL_INDEX = (
  url        => '',
  book       => '',
  writer     => '',
  writer_url => '',
  item_list  => [],

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


sub new {
  my ( $self, %opt ) = @_;

  $opt{site} = $self->detect_site( $opt{site} );

  my $module = "Novel::Robot::Parser::$opt{site}";
  eval "require $module;";

  my $browser = Novel::Robot::Browser->new( %opt );
  bless { browser => $browser, %opt }, $module;
}

sub domain { }

sub detect_domain {
  my ( $self, $url ) = @_;
  return ( $url, $url ) unless ( $url =~ /^https?:/ );

  my ( $dom ) = $url =~ m#^.*?\/\/(.+?)(?:/|$)#;

  my $base_dom = $dom;
  $base_dom =~ s/^[^.]+\.//;
  $base_dom = $base_dom =~ /\./ ? $base_dom : $dom;
  return ( $dom, $base_dom );
}

sub detect_site {
  my ( $self, $s ) = @_;

  if ( $s and $s =~ /^https?:/ ) {
    my ( $dom ) = $s =~ m#^.*?\/\/(.+?)/#;
    return $SITE_DOM_NAME{$dom} if ( exists $SITE_DOM_NAME{$dom} );
    return 'default';
  }

  if($s and -f $s){
    my ( $suffix ) = $s =~ m#\.([^.]+)$#;
    return 'txt' if(lc($suffix) eq 'txt');
    return 'default';
  }

  return $s;
}

sub site_type { 'novel' }
sub charset   { 'cp936' }
sub base_url  { }

sub generate_novel_url {
  my ( $self, $index_url, @args ) = @_;
  return ( $index_url, @args );
}



sub get_novel_info {
  my ( $self,  $url )       = @_;
  my ( $i_url, $post_data ) = $self->generate_novel_url( $url );
  my $c = $self->{browser}->request_url( $i_url, $post_data );

  my $r = $self->extract_elements(
    \$c,
    path => $self->scrape_novel(),
    sub  => $self->can( "parse_novel" ),
  );
  $r->{url} = $i_url;
  $r->{item_list} = $self->parse_item_list( \$c, $r );
  ( $r->{item_list}, $r->{item_num} ) = $self->update_item_list( $r->{item_list}, $url );
  return $r;
}

sub get_novel_ref {
  my ( $self, $index_url, %o ) = @_;

  return $self->get_tiezi_ref( $index_url, %o ) if ( $self->site_type() eq 'tiezi' );

  my ( $r, $item_list, $max_item_num );
  if ( $index_url !~ /^https?:/ ) {
    $r = $self->parse_novel( $index_url, %o );
  } else {
    my ( $i_url, $post_data ) = $self->generate_novel_url( $index_url );

    ( $r, $item_list ) = $self->{browser}->request_url_whole(
      $i_url,
      post_data => $post_data,
      info_sub  => sub {
        $self->extract_elements(
          @_,
          path => $self->scrape_novel(),
          sub  => $self->can( "parse_novel" ),
        );
      },
      item_list_sub => sub { $self->can( "parse_item_list" )->( $self, @_ ) },
      item_sub      => sub {
        $self->extract_elements(
          @_,
          path => $self->scrape_novel_item(),
          sub  => $self->can( "parse_novel_item" ),
        );
      },
      %o,
    );

    $r->{url}       = $index_url;
    $r->{item_list} = $item_list || [];

    #$r->{item_num}  = $max_item_num || undef;
  } ## end else [ if ( $index_url !~ /^https?:/)]

  ( $r->{item_list}, $r->{item_num} ) = $self->update_item_list( $r->{item_list}, $index_url );
  $self->filter_item_list( $r, %o );
  $r->{writer_url} = $self->format_abs_url( $r->{writer_url}, $index_url );

  for my $k ( qw/writer book/ ) {
    $r->{$k} = $o{$k} if ( exists $o{$k} );
  }
  $r->{$_} ||= $NULL_INDEX{$_} for keys( %NULL_INDEX );
  $r->{$_} = $self->tidy_string( $r->{$_} ) for qw/writer book/;

  return $r;
} ## end sub get_novel_ref

sub scrape_novel {
  my ( $self ) = @_;
  my $r = {};
  push @{$r->{book}}, { path => $self->{book_path} } if ( exists $self->{book_path} );
  push @{$r->{book}}, { regex => $self->{book_regex} } if ( exists $self->{book_regex} );
  push @{$r->{writer}}, { path => $self->{writer_path} } if ( exists $self->{writer_path} );
  push @{$r->{writer}}, { regex => $self->{writer_regex} } if ( exists $self->{writer_regex} );
  return $r;
}

sub parse_novel {
  my ( $self, $h, $r ) = @_;

  $r->{book} ||= $self->scrape_element_try(
    $h,
    [ { path  => '//meta[@name="og:novel:book_name"]',     extract => '@content' },
      { path  => '//meta[@property="og:novel:book_name"]', extract => '@content' },
      { path  => '//meta[@property="og:title"]',           extract => '@content' },
      { path  => '//div[@id="title"]', },
      { path  => '//div[@class="title"]', },
      { regex => qr#<title>[^<]+?([^,<]+?)全文阅读,#si, },
      { regex => qr#<title>[^<]*?《([^,<]+?)》#si, },
      { regex => qr#<title>[^<]+?,([^,<]+?)最新章节#si, },
      { path  => '//h1', },
      { path  => '//h2', },
    ],
    sub => $self->can( "tidy_writer_book" ),
  );

  $r->{writer} ||= $self->scrape_element_try(
    $h,
    [ { path => '//meta[@name="author"]', extract => '@content' },

      { path  => '//meta[@name="og:novel:author"]',     extract => '@content' },
      { path  => '//meta[@property="og:novel:author"]', extract => '@content' },
      { path  => '//*[@class="author"]', },
      { path  => '//*[@class="writer"]', },
      { regex => qr#<span>作者：</span>([^<]+)#si, },
      { regex => qr#作者：<span>([^<]+)</span>#si, },
      { regex => qr#<(?:em|i|h3|h2|span)>作者：([^<]+)</(?:em|i|h3|h2|span)>#si, },
      { regex => qr#作者：(?:<span>)?<a[^>]*>([^<]+)</a>#si, },
      { regex => qr#<p>作(?:&nbsp;|\s)*者：([^<]+)</p>#si, },
      { regex => qr#作者：([^<]+?) 发布时间：#s, },
      { regex => qr#content="([^"]+?)最新著作#s, },
      { regex => qr#<title>[^<,]+?最新章节\(([^<,]+?)\),#si, },
      { regex => qr#<title>[^<,]+?作者：([^<,]+?)_#si, },
      { regex => qr#content="[^"]+?,([^",]+?)作品#s, },
    ],
    sub => $self->can( "tidy_writer_book" ),
  );

  $r->{$_} = $self->tidy_writer_book( $r->{$_} ) for qw/writer book title/;

  return $r;
} ## end sub parse_novel

sub scrape_item_list {
  my ( $self ) = @_;
  my $r = {};
  $r->{path} = $self->{item_list_path} if ( exists $self->{item_list_path} );
  return $r;
}

sub parse_item_list {
  my ( $self, $h, $r ) = @_;

  return $r->{item_list} if ( exists $r->{item_list} );

  my $path_r = $self->scrape_item_list();

  return $self->guess_item_list( $h ) unless ( exists $path_r->{path} );

  my $parse_novel = scraper {
    process $path_r->{path},
      'item_list[]' => {
      'title' => 'TEXT',
      'url'   => '@href'
      };
  };
  my $ref = $parse_novel->scrape( $h );

  my @chap = grep { exists $_->{url} and $_->{url} } @{ $ref->{item_list} };

  if ( $path_r->{sort} ) {
    @chap = sort { $a->{url} cmp $b->{url} } @chap;
  }

  return \@chap;
} ## end sub parse_item_list

sub guess_item_list {
  my ( $self, $h, %opt ) = @_;

  my $new_h = $$h;
  $new_h=~s#<dt>[^<]+最新\d+章节</dt>.+?<dt>#<dt>#s;

  my $tree = HTML::TreeBuilder->new();
  $tree->parse( $new_h );

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

  my $res_arr;
  my $title_regex =
    qr/引子|楔子|内容简介|正文|序言|文案|第\s*[０１２３４５６７８９零○〇一二三四五六七八九十百千\d]+\s*(章|节)|(^[0-9]+)/;
  my $chap_num_regex = qr/(^|\/)\d+(\.html)?$/;
  for my $arr ( @out_links ) {
    my $x = $arr->[0];
    my $y = $arr->[1];
    my $z = $arr->[-1];

    $res_arr = $arr if ( $opt{chapter_url_regex}   and $x->{url}   =~ /$opt{chapter_url_regex}/ );
    $res_arr = $arr if ( $opt{chapter_title_regex} and $x->{title} =~ /$opt{chapter_title_regex}/ );
    $res_arr = $arr
      if ( ($x and $x->{title} =~ /$title_regex/) or ( $y and $y->{title} =~ /$title_regex/ ) or ( $z and $z->{title} =~ /$title_regex/ ) );
    $res_arr = $arr if ( ( $x->{url} =~ /$chap_num_regex/ or $z->{url} =~ /$chap_num_regex/ ) and scalar( @$arr ) > 50 );

    #$res_arr= $arr if( ($x->{url}=~/\/?\d+$/ or $z->{url}=~/\/?\d+$/) and scalar(@$arr)>50);
    last if ( $res_arr );
  }

  #remove not chapter url
  while ( 1 ) {
    my $x = $res_arr->[0];
    my $y = $res_arr->[ int( $#$res_arr / 2 ) ];
    if ( defined $y->{title} and $y->{title} =~ /$title_regex/ and defined $y->{url} and $y->{url} =~ /\.html$/ and $x->{url} !~ /\.html$/ ) {
      shift( @$res_arr );
    } elsif ( defined $y->{title} and $y->{title} =~ /$title_regex/ and defined $y->{url} and $y->{url} =~ /$chap_num_regex/ and $x->{url} !~ /$chap_num_regex/ ) {
      shift( @$res_arr );
    } else {
      last;
    }
  }

  #sort chapter url
  if ( $res_arr and defined $res_arr->[0]{url} and $res_arr->[0]{url} =~ /$chap_num_regex/ ) {
    my $trim_sub    = sub { my $s = $_[0]; $s =~ s/^.+\///; $s =~ s/\.html$//; return $s };
    my @sort_arr;
    if($opt{sort_chapter_url}){
        @sort_arr = sort { $trim_sub->( $a->{url} ) <=> $trim_sub->( $b->{url} ) } grep { $_->{url} =~ /$chap_num_regex/ } @$res_arr;
    }else{
        @sort_arr = @$res_arr;
    }
    my @s           = map { $trim_sub->( $_->{url} ) } @sort_arr;
    my $random_sort = 0;
    for my $i ( 0 .. $#s - 1 ) {
      $random_sort = 1 if ( $s[$i] > $s[ $i + 1 ] );
      last if ( $random_sort );
    }
    return \@sort_arr if ( $random_sort == 0 );
  }

  return $res_arr || [];
} ## end sub guess_item_list

sub scrape_novel_item {
  my ( $self ) = @_;
  my $r = {};
  push @{$r->{content}}, { path => $self->{content_path}, extract => 'HTML' } if( exists $self->{content_path} );
  push @{$r->{content}}, { regex => $self->{content_regex} } if( exists $self->{content_regex} );
  push @{$r->{content}}, (
      { path => '//div[@class="novel_content"]' }, 
      { path => '//div[@id="content"]' }, 
  );
  return $r;
}

sub parse_novel_item {
  my ( $self, $h, $r ) = @_;

  $r = $self->guess_novel_item( $h ) unless ( $r->{content} );
  $r->{$_} ||= $NULL_CHAPTER{$_} for keys( %NULL_CHAPTER );
  $r->{content} = $self->tidy_content( $r->{content} );

  my $next_url = $self->scrape_element_try($h, [ 
          { path => '//a[@id="next_url"]', extract =>'@href' }, 
          { path  => '//a[contains(text(),"下一页")]',           extract => '@href' },
      ]);
  if($next_url){
      $r->{next_url} = $next_url;
  }

  return $r;
}

sub guess_novel_item {
  my ( $self, $h, %opt ) = @_;

  $$h =~ s#<!--.+?-->##sg;
  $$h =~ s#<script[^>]*>[^<]*</script>##isg;

  my $tree = HTML::TreeBuilder->new();
  $tree->parse( $$h );

  my @links = $tree->look_down( 'text', undef );
  for my $x ( @links ) {
    $x = { content => $x->as_HTML( '<>&' ) };
    $self->calc_content_wordnum( $x );
  }
  my @out_links = sort { $b->{word_num} <=> $a->{word_num} } @links;

  my $no_next_r;
  for my $r ( @out_links ) {
    next if ( $r->{content} =~ m#</(style|head|body|html)>#s );
    next if ( $r->{content} =~ m#^\s*<div id="footer">#s );
    next if ( $r->{content} =~ /(上|下)一(章|页|篇)/s );
    next if ( $r->{content} =~ m#</h(2|1)>#s );
    next if ( $r->{content} =~ m#All rights reserved#s );
    next if ( $r->{content} =~ m#(.+?</a>){5,}#s );

    $no_next_r = $r;
    last;
  }

  #my @grep_next_r = grep { $_->{content} =~ /(上|下)一(章|页|篇)\w{0,20}$/s and $_->{word_num} > 50 } @out_links;
  my @grep_next_r = grep { $_->{content} =~ /(上|下)一(章|页|篇)/s 
          and $_->{word_num} > 50 
  } @out_links;

  my $cc   = $no_next_r->{content};
  my $cc_n = $cc =~ s/(\n|<p[^>]*>|<br[^>]*>)//sg;
  return $no_next_r if ( ( $cc_n > 5 and $no_next_r->{word_num} > 50) or !@grep_next_r );

  return $grep_next_r[-1] || {};
} ## end sub guess_novel_item


sub get_page_ref {
    my ( $self, $url, %o ) = @_;
    my $class = 'novel';

    my ( $c ) = $self->{browser}->request_url_simple($url);
    my $r = $self->{site} ne 'default' ?  $self->extract_item($c) : $self->guess_novel_item( \$c );
    $r->{content} = $self->tidy_content( $r->{content} );

    my $page= {
        writer => $o{writer}, 
        book => $o{book}, 
        url => $url, 
        item_list => [ $r ], 
    };

    return $page;
}

sub get_tiezi_ref {
  my ( $self, $url, %o ) = @_;

  my $class = 'novel';
  my ( $topic, $item_list ) = $self->{browser}->request_url_whole(
    $url,

    #post_data     => $o{post_data},
    info_sub => sub {
      $self->extract_elements(
        @_,
        path => $self->can( "scrape_$class" )->( $self ),
        sub  => $self->can( "parse_$class" ),
      );
    },
    item_list_sub => sub { $self->can( "parse_${class}_item" )->( $self, @_ ) },
    page_list_sub => sub { $self->can( "parse_${class}_list" )->( $self, @_ ) },

    #min_page_num  => $o{"min_page_num"},
    #max_page_num  => $o{"max_page_num"},
    stop_sub => sub {
      my ( $info, $data_list, $i ) = @_;
      $self->{browser}->is_list_overflow( $data_list, $o{"max_item_num"} );
    },
    %o,
  );

  $item_list = $self->update_item_list( $item_list, $url );

  unshift @$item_list, $topic if ( $topic->{content} );
  my %r = (
    %$topic,
    writer => $o{writer} || $topic->{writer},
    book   => $o{book}   || $topic->{book} || $topic->{title},
    url       => $url,
    item_list => $item_list,
  );
  $self->filter_item_list( \%r, %o );

  return \%r;
} ## end sub get_tiezi_ref


sub get_iterate_ref {
  my ( $self, $url, %o ) = @_;
  my ( $info, $item_list ) = $self->{browser}->request_url_whole(
    $url,
    post_data => $o{post_data},
    info_sub  => sub {
      $self->extract_elements(
        @_,
        path => {},
        sub  => sub { my ( $self, $html_ref, $r ) = @_; return $r; },
      );
    },
    item_sub      => sub { my ( $self, $html_ref ) = @_; return {}; },
    item_list_sub => sub { my ( $self, $html_ref ) = @_; return []; },

    #min_page_num  => $o{"min_page_num"},
    #max_page_num  => $o{"max_page_num"},
    stop_sub => sub {
      my ( $info, $data_list, $i ) = @_;
      $self->{browser}->is_list_overflow( $data_list, $o{"max_item_num"} );
    },
    %o,
  );

  $info->{item_list} = $self->update_item_list( $item_list, $url );

  return $info;
} ## end sub get_iterate_ref



sub update_item_list {
  my ( $self, $arr, $base_url ) = @_;

  my %rem;
  for my $chap (@$arr){
      $chap = { url => $chap || '' } if ( ref( $chap ) ne 'HASH' );
      if ( $chap->{url} ) {
          $chap->{url} = $self->format_abs_url( $chap->{url}, $base_url );
          $rem{ $chap->{url} }++;
      }
  }

  my $i = 0;
  my @res;
  for my $chap ( @$arr ) {
      if($chap->{url} and $rem{ $chap->{url} }>1){
          $rem{$chap->{url}}--;
      }else{
          ++$i;
          $chap->{pid} //= $i;               #page id
          $chap->{id}  //= $i;               #item id
          $chap->{content} //= '';
          push @res, $chap  unless($chap->{content}=~m#正在手打中#s);
      }
  }

  while(@res and $res[-1]{content}=~m#正在手打中#s ){
      pop @res;
  }

  #$i = $arr->[-1]{id} if ( $#$arr >= 0 and exists $arr->[-1]{id} and $arr->[-1]{id} > $i );
  return wantarray ? ( \@res, $i ) : \@res;
} ## end sub update_item_list

sub format_abs_url {
  my ( $self, $url, $base_url ) = @_;
  return $url unless ( $base_url );
  return $url unless ( $base_url =~ /^https?:/ );
  my $abs_url = URI->new_abs( $url, $base_url )->as_string;
}

sub extract_elements {
  my ( $self, $h, %o ) = @_;
  $o{path} ||= {};

  my $r = {};
  while ( my ( $xk, $xr ) = each %{ $o{path} } ) {
    $r->{$xk} = $self->scrape_element_try( $h, $xr );
  }
  $r = $o{sub}->( $self, $h, $r ) if ( $o{sub} );
  return $r;
}

sub scrape_element_try {
  my ( $self, $h, $r_list, %o ) = @_;
  my $c;
  for my $path_or_regex ( @$r_list ) {
    $c = $self->scrape_element( $h, $path_or_regex );
    next unless ( $c );
    $c = $o{sub}->( $self, $c ) if ( exists $o{sub} );
    next unless ( $c );
    return $c;
  }
  return;
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

sub filter_item_list {
  my ( $self, $r, %o ) = @_;

  my $flist = $r->{item_list};

  #$r->{item_num} //= $flist->[-1]{id} // scalar( @$flist );

  $flist->[$_]{content} = $self->tidy_content( $flist->[$_]{content} ) for ( 0 .. $#$flist );

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

  $flist = [ grep { defined $_->{content} and $_->{content} =~ /\S/s } @$flist ];

  $r->{item_list} = $flist || [];

  return $self;
} ## end sub filter_item_list

sub calc_content_wordnum {
  my ( $self, $f ) = @_;
  return if ( $f->{word_num} );
  my $wd = $f->{content} || '';
  $wd =~ s/<[^>]+>//gs;
  $wd =~ s/\s+//sg;
  $f->{word_num} = $wd =~ s/\S//gs;
  return $f;
}

sub tidy_writer_book {
  my ( $self, $c ) = @_;
  return unless ( defined $c );
  for ( $c ) {
    s/作\s*者：//;
    s/^\s*作者-\s*//;
    s/小说全集//;
    s/作品全集//;
    s/专栏//;
    s/^.*版权属于作者([^,]+)$/$1/;
    s/\s*最新章节\s*$//;
    s/全文阅读//;
    s/在线阅读//;
    s/全集下载//;
    s/章节目录//;
    s/^\s*《(.*)》\s*$/$1/;
    s/^\s+|\s+$//g;
    s/\s+//g;
  }
  return $c;
} ## end sub tidy_writer_book

sub tidy_content {
  my ( $self, $c ) = @_;
  for ( $c ) {
    last unless ( $c );
    s###sg;
    s#　#\n#sg;
    s#\s{5,}#\n#sg;
    s#<script(\s+[^>]+\>|\>)[^<]*</script>##sg;
    s#\s*\<[^>]+?\>#\n#sg;
    s{\n+}{\n}sg;
    s{\s*(\S.*?)\s*\n}{\n<p>$1</p>}sg;
    s#\s+上一章\s+.+?下一章.+$##s;
    s#[^\n]+加入书签[^\n]+##s;
  }
  return $c;
}

sub tidy_string {
  my ( $self, $c ) = @_;
  $c ||= '';
  for ( $c ) {
    s/^\s+|\s+$//gs;
    s/[\*\/\\\[\(\)]+//g;
    s/[[:punct:]]//sg;
    s/[\]\s+\/\\]/-/g;
  }

  return $c;
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

sub encode_cjk_for_url {
  my ( $self, $key ) = @_;
  my $b = uc( unpack( "H*", encode( $self->charset(), $key ) ) );
  $b =~ s/(..)/%$1/g;
  return $b;
}

sub get_query_ref {
    my ( $self, $keyword, %o ) = @_;
    my ($url, $post_data) = $self->make_query_request($keyword, %o);
    my $r = $self->get_iterate_ref($url, 
        post_data => $post_data, 
        info_sub => sub { return { title => "query: $keyword"} }, 
        page_list_sub => sub { $self->can( "parse_query_list" )->( $self, @_ ) },
        item_list_sub => sub { $self->can( "parse_query_item" )->( $self, @_ ) },
        %o,
    );
    return $r;
}

sub get_board_ref {
    my ( $self, $board_url, %o ) = @_;
    my $r = $self->get_iterate_ref(
        $board_url, 
        info_sub => sub { $self->extract_elements( @_, sub => $self->can( "parse_board" ),); }, 
        item_list_sub => sub { $self->can( "parse_board_item" )->( $self, @_ ) },
        %o,
    );
    return $r;
}

1;

