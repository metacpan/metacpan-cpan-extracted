# ABSTRACT: get/post url, return unicode content, auto detect CJK charset
package Novel::Robot::Browser;

use strict;
use warnings;
use utf8;

our $VERSION = 0.22;

#use Novel::Robot::Browser::CookieJar;
use HTTP::CookieJar;
use Data::Dumper;

use File::Slurp qw/slurp/;
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

  #my $cookie_jar = Novel::Robot::Browser::CookieJar->new();
  my $cookie_jar = HTTP::CookieJar->new;

  my $http = HTTP::Tiny->new(
    default_headers => \%h,
    cookie_jar      => $cookie_jar,
  );

  return $http;
}

sub request_urls {

  my ( $self, $url, %o ) = @_;

  my $html = $self->request_url( $url, $o{post_data} );
  my $info = $o{info_sub}->( \$html ) || {};
  $info->{url} = $url;

  my $url_list =
      exists $info->{url_list} ? $info->{url_list}
    : defined $o{url_list_sub} ? $o{url_list_sub}->( \$html, $info )
    :                            [];

  my $cnt          = 0;
  my $url_list_num = scalar( @$url_list );
  my $progress;
  $progress = Term::ProgressBar->new( { count => $url_list_num } ) if ( $o{verbose} );

  my @result;
  my $item_id = 0;
  for my $i ( 0 .. $#$url_list ) {
    my $r = $url_list->[$i];
    $r = { url => $r || '' } if ( ref( $r ) ne 'HASH' );
    $r->{url} = URI->new_abs( $r->{url}, $url )->as_string;
    $r->{id} //= $i + 1;

    next if ( $o{min_item_num} and $r->{id} < $o{min_item_num} );
    last if ( $o{max_item_num} and $r->{id} > $o{max_item_num} );

    my $h = $self->request_url( $r->{url}, $r->{post_data} );
    my $c = \$h;

    my $cr = exists $o{content_sub} ? $o{content_sub}->( $c ) : ( $c );
    $cr->{$_} ||= $r->{$_} for keys( %$r );
    push @result, $cr;

    $cnt = $i;
    $progress->update( $cnt ) if ( $o{verbose} );
  } ## end for my $i ( 0 .. $#$url_list)

  $progress->update( $url_list_num ) if ( $o{verbose} );

  return ( $info, \@result, $url_list_num );
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
  $info->{floor_num} = $data_list->[-1]{id} || scalar( @$data_list ) || $i;

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

  return $form unless ( ref( $form ) eq 'HASH' );

  my @params;
  while ( my ( $k, $v ) = each %$form ) {
    push @params, uri_escape( $k ) . "=" . uri_escape( $v );
  }

  my $post_str = join( "&", @params );
  return $post_str;
}

sub request_url_simple {
  my ( $self, $url, $form ) = @_;

  my $res;
  if ( $form ) {
    $res = $self->{browser}->request(
      'POST', $url,
      { content => $self->format_post_content( $form ) , 
        headers => {
            'content-type' => 'application/x-www-form-urlencoded', 
        }, 
      } );
  } else {
    $res = $self->{browser}->get( $url );
  }
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

sub read_moz_cookie {
  my ( $self, $cookie, $dom ) = @_;

  my @segment;
  if ( -f $cookie and $cookie =~ /\.sqlite$/ ) {  # firefox sqlite3
    my $sqlite3_cookie =
      `sqlite3 "$cookie" "select host,isSecure,path,isHttpOnly,expiry,name,value from moz_cookies where baseDomain='$dom'"`;
    @segment = map { [ split /\|/ ] } split /\n/, $sqlite3_cookie;
  } elsif ( -f $cookie and $cookie =~ /\.txt$/ ) {  # Netscape HTTP Cookie File
    my @ck = slurp( $cookie );
    @segment = grep { $_->[0] and $_->[0] =~ /(^|\.)\Q$dom\E$/ } map { [ split /\s+/ ] } @ck;
  } else {                             # cookie string : name1=value1; name2=value2
    my @ck = split /;\s*/, $cookie;
    @segment = map { my @c = split /=/; [ $dom, undef, '/', undef, 0, $c[0], $c[1] ] } @ck;
  }
  #print Dumper(\@segment);

  @segment = grep { defined $_->[6] and $_->[6]=~/\S/ } @segment;

  my @jar = map { "$_->[5]=$_->[6]; Domain=$_->[0]; Path=$_->[2]; Expiry=$_->[4]" } @segment;
  $self->{browser}{cookie_jar}->load_cookies( @jar );

  $cookie = join( "; ", map { "$_->[5]=$_->[6]" } @segment );
  #$self->{browser}{cookie_jar}{cookie} = $cookie;

  return $cookie;

} ## end sub read_moz_cookie

1;
