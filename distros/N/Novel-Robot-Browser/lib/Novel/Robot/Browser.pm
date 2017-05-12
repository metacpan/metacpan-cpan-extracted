# ABSTRACT: get/post url, return unicode content, auto detect CJK charset
package Novel::Robot::Browser;

use strict;
use warnings;
use utf8;

our $VERSION = 0.20;

use Encode::Detect::CJK qw/detect/;
use Encode;
use HTTP::Tiny;
use Parallel::ForkManager;
use Term::ProgressBar;
use IO::Uncompress::Gunzip qw(gunzip);
use URI::Escape;
use URI;

our $DEFAULT_URL_CONTENT = '';
our %DEFAULT_HEADER      = (
  'Accept'          => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Charset'  => 'gb2312,utf-8;q=0.7,*;q=0.7',
  'Accept-Encoding' => "gzip",
  'Accept-Language' => 'zh,zh-cn;q=0.8,en-us;q=0.5,en;q=0.3',
  'Connection'      => 'keep-alive',
  'User-Agent'      => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:29.0) Gecko/20100101 Firefox/29.0',
  'DNT'             => 1,
);

sub new {
  my ( $self, %opt ) = @_;
  $opt{retry}           ||= 5;
  $opt{max_process_num} ||= 5;
  $opt{browser}         ||= _init_browser( $opt{browser_headers} );
  bless {%opt}, __PACKAGE__;
}

sub _init_browser {
  my ( $headers ) = @_;

  $headers ||= {};
  my %h = ( %DEFAULT_HEADER, %$headers );

  my $http = HTTP::Tiny->new( default_headers => \%h, );

  return $http;
}

sub request_urls {

  my ( $self, $url, %o ) = @_;

  my $html = $self->request_url( $url, $o{post_data} );
  my $info = $o{info_sub}->( \$html ) || {};
  $info->{url} = $url;

  my $url_list = $o{url_list_sub} ? $o{url_list_sub}->( \$html ) : [];

  #my $arr = $o{select_url_sub} ? $o{select_url_sub}->( $url_list ) : $url_list;

  my $cnt = 0;
  my $progress;
  $progress = Term::ProgressBar->new( { count => scalar( @$url_list ) } ) if ( $o{verbose} );

  my @result;
  for my $i ( 0 .. $#$url_list ) {
    my $r = $url_list->[$i];
    $r = { url => $r || '' } if ( ref( $r ) ne 'HASH' );
    $r->{url} = URI->new_abs( $r->{url}, $url )->as_string;

    my $j = exists $r->{id} ? $r->{id} : ( $i + 1 );
    next if ( $o{min_item_num} and $j < $o{min_item_num} );
    last if ( $o{max_item_num} and $j > $o{max_item_num} );

    my $h = $self->request_url( $r->{url}, $r->{post_data} );
    my $c = \$h;

    my @res = exists $o{content_sub} ? $o{content_sub}->( $c ) : ( $c );
    my $item_id = $j;
    $_->{id} //= $item_id++ for @res;
    push @result, $#res == 0 ? $res[0] : \@res;

    $cnt = $i;
    $progress->update( $cnt ) if ( $o{verbose} );
  } ## end for my $i ( 0 .. $#$url_list)

  $progress->update( scalar( @$url_list ) ) if ( $o{verbose} );

  $info->{chapter_list} = $url_list;

  return ( $info, \@result );
} ## end sub request_urls

sub request_urls_iter {
  my ( $self, $url, %o ) = @_;

  my $html = $self->request_url( $url, $o{post_data} );
  print "novel_url: $url\n" if ( $o{verbose} );

  my $info      = $o{info_sub}->( \$html )    || {};
  my $data_list = $o{content_sub}->( \$html ) || [];

  my $i = 1;
  unless ( $o{stop_sub} and $o{stop_sub}->( $info, $data_list, $i, %o ) ) {
    $data_list = [] if ( $o{min_page_num} and $o{min_page_num} > 1 );
    my $url_list = exists $o{next_url_sub} ? [] : $o{url_list_sub}->( \$html );
    while ( 1 ) {
      $i++;
      my $u = $url_list->[ $i - 2 ] || ( $o{next_url_sub} ? $o{next_url_sub}->( $url, $i, \$html ) : undef );
      last unless ( $u );
      next if ( $o{min_page_num} and $i < $o{min_page_num} );
      last if ( $o{max_page_num} and $i > $o{max_page_num} );

      my ( $u_url, $u_post_data ) = ref( $u ) eq 'HASH' ? @{$u}{qw/url post_data/} : ( $u, undef );
      my $c = $self->request_url( $u_url, $u_post_data );
      print "content_url: $u_url\n" if ( $o{verbose} );
      my $fs = $o{content_sub}->( \$c );
      last unless ( $fs );

      push @$data_list, @$fs;
      last if ( $o{stop_sub} and $o{stop_sub}->( $info, $data_list, $i, %o ) );
    }
  } ## end unless ( $o{stop_sub} and ...)

  $data_list = [ reverse @$data_list ] if ( $o{reverse_content_list} );  #lofter倒序

  if ( $o{item_sub} ) {
    my $item_id = 0;
    for my $r ( @$data_list ) {
      $r->{id} //= ++$item_id;
      next unless ( $self->is_item_in_range( $r->{id}, $o{min_item_num}, $o{max_item_num} ) );

      print "item_url: $r->{url}\n" if ( $o{verbose} );
      $r = $o{item_sub}->( $r );
    }
  }
  return ( $info, $data_list );
} ## end sub request_urls_iter

sub is_item_in_range {
    my ( $self, $id, $min, $max ) = @_;
    return 1 unless ( $id );
    return 0 if ( $min and $id < $min );
    return 0 if ( $max and $id > $max );
    return 1;
}

sub is_list_overflow {
    my ( $self, $r, $max ) = @_;

    return unless ( $max );

    my $floor_num = scalar( @$r );
    my $id = $r->[-1]{id} // $floor_num;

    return if ( $id < $max );

    $#{$r} = $max - 1;
    return 1;
}


sub request_url {
  my ( $self, $url, $form ) = @_;
  return $DEFAULT_URL_CONTENT unless ( $url );

  my $c;
  for my $i ( 1 .. $self->{retry} ) {
    eval { $c = $self->request_url_simple( $url, $form ); };
    last if ( $c );
    sleep 2;
  }

  return $c || $DEFAULT_URL_CONTENT;
}

sub format_post_content {
  my ( $self, $form ) = @_;

  my @params;
  while ( my ( $k, $v ) = each %$form ) {
    push @params, uri_escape( $k ) . "=" . uri_escape( $v );
  }

  my $post_str = join( "&", @params );
  return $post_str;
}

sub request_url_simple {
  my ( $self, $url, $form ) = @_;

  my $res = $form
    ? $self->{browser}->request(
    'POST', $url,
    { content => $self->format_post_content( $form ),
      headers => {
        %DEFAULT_HEADER,
        'content-type' => 'application/x-www-form-urlencoded'
      },
    } )
    : $self->{browser}->get( $url );
  return $DEFAULT_URL_CONTENT unless ( $res->{success} );

  my $html;
  my $content = $res->{content};
  if (  $res->{headers}{'content-encoding'}
    and $res->{headers}{'content-encoding'} eq 'gzip' ) {
    gunzip \$content => \$html, MultiStream => 1, Append => 1;
  }

  my $charset = detect( $html || $content );
  my $r = decode( $charset, $html || $content, Encode::FB_XMLCREF );

  return $r || $DEFAULT_URL_CONTENT;
} ## end sub request_url_simple

1;
