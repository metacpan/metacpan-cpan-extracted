# ABSTRACT: get/post url, return unicode content, auto detect CJK charset
package Novel::Robot::Browser;

use strict;
use warnings;
use utf8;

our $VERSION = 0.22;

#use Data::Dumper;

use Encode::Detect::CJK qw/detect/;
use Encode;
use File::Slurp qw/slurp/;
use HTTP::CookieJar;
use HTTP::Tiny;
use IO::Uncompress::Gunzip qw(gunzip);
#use Parallel::ForkManager;
use Term::ProgressBar;
use URI::Escape;
use URI;

our $DEFAULT_URL_CONTENT = '';
our %DEFAULT_HEADER      = (
  'Accept'          => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Charset'  => 'gb2312,utf-8;q=0.7,*;q=0.7',
  'Accept-Encoding' => "gzip",
  'Accept-Language' => 'zh,zh-cn;q=0.8,en-us;q=0.5,en;q=0.3',
  'Connection'      => 'keep-alive',
  #'User-Agent'      => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:29.0) Gecko/20100101 Firefox/29.0',
  'User-Agent'      => 'User-Agent: MQQBrowser/26 Mozilla/5.0 (Linux; U; Android 2.3.7; zh-cn; MB200 Build/GRJ22; CyanogenMod-7) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1', 
  'DNT'             => 1,
);

sub new {
  my ( $self, %opt ) = @_;
  $opt{retry}           ||= 5;
  $opt{max_process_num} ||= 5;
  $opt{browser}         ||= _init_browser( $opt{browser_headers} );
  $opt{use_chrome}      ||= 0;
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

sub request_url_whole {
  my ( $self, $url, %o ) = @_;

  my $html = $self->request_url( $url, $o{post_data} );

  my $info      = $o{info_sub}->( \$html )     || {};
  my $data_list = $o{item_list} || $o{item_list_sub}->( \$html ) || [];

  my $i = 1;
  unless ( $o{stop_sub} and $o{stop_sub}->( $info, $data_list, $i, %o ) or defined $o{item_list}) {
    $data_list = [] if ( $o{min_page_num} and $o{min_page_num} > 1 );
    my $page_list = exists $o{page_list_sub} ? $o{page_list_sub}->( \$html ) : undef;
    while ( 1 ) {
      $i++;
      my $u = 
        $page_list ?  $page_list->[ $i - 2 ] : 
        ( exists $o{next_page_sub} ? $o{next_page_sub}->( $url, $i, \$html ) : undef );
      last unless ( $u );
      next if ( $o{min_page_num} and $i < $o{min_page_num} );
      last if ( $o{max_page_num} and $i > $o{max_page_num} );


      my ( $u_url, $u_post_data ) = ref( $u ) eq 'HASH' ? @{$u}{qw/url post_data/} : ( $u, undef );
      my $c = $self->request_url( $u_url, $u_post_data );
      my $fs = $o{item_list_sub}->( \$c );
      last unless ( $fs );

      push @$data_list, @$fs;
      last if ( $o{stop_sub} and $o{stop_sub}->( $info, $data_list, $i, %o ) );
    }
  } ## end unless ( $o{stop_sub} and ...)

  #lofter倒序
  if ( $o{reverse_item_list} ){
      $data_list = [ reverse @$data_list ];
      my $max_id = $data_list->[0]{id};
      if($max_id){
          $_->{id} = $max_id - $_->{id} +1 for(@$data_list);
      }
  }
  $info->{item_num} = ( $#$data_list >= 0 and exists $data_list->[-1]{id} ) ? $data_list->[-1]{id} : ( scalar( @$data_list ) || $i );

  if ( $o{item_sub} ) {
    my $item_id = 0;
    print "\n\n" if ( $o{progress} );
    my $progress;
    $progress = Term::ProgressBar->new( { count => scalar(@$data_list) } ) if ( $o{progress} );

    for my $i ( 0 .. $#$data_list ) {
      my $r = $data_list->[$i];
      $r->{id} //= ++$item_id;
      $r->{url} = URI->new_abs( $r->{url}, $url )->as_string;
      next unless ( $self->is_item_in_range( $r->{id}, $o{min_item_num}, $o{max_item_num} ) );
      if(exists $o{back_index}){
          last if($i + $o{back_index} > $#$data_list);
      }

      if($r->{url}){
          my $c = $self->request_url( $r->{url}, $r->{post_data} );
          my $temp_r = $o{item_sub}->( \$c );
          $r->{$_} //= $temp_r->{$_} for keys(%$temp_r);
      }else{
          $r = $o{item_sub}->( $r );
      }

      my $next_url = URI->new_abs( $data_list->[$i+1]->{url}, $url )->as_string;
      while($r->{next_url}){
          $r->{next_url} = URI->new_abs( $r->{next_url}, $url )->as_string;
          if($r->{next_url} ne $next_url){
              my $c = $self->request_url( $r->{next_url}, $r->{post_data} );
              my $temp_r = $o{item_sub}->( \$c );
              $r->{content} .= "\n\n".$temp_r->{content};
              last unless(exists $temp_r->{next_url});
              $r->{next_url} = $temp_r->{next_url};
          }else{
              last;
          }
      }

           $progress->update( $item_id ) if ( $o{progress} );
    }

   $progress->update( scalar(@$data_list) ) if ( $o{progress} ); 
  }
  print "\n\n" if ( $o{progress} );
  return ( $info, $data_list );
} ## end sub request_url_whole

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

  my $item_num = scalar( @$r );
  my $id        = $r->[-1]{id} // $item_num;

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
      { content => $self->format_post_content( $form ),
        headers => {
          'content-type' => 'application/x-www-form-urlencoded',
        },
      } );
  } elsif ( $self->{use_chrome} ) {
    $res->{content} = `chrome --no-sandbox --user-data-dir --headless --disable-gpu --dump-dom "$url" 2>/dev/null`;
    $res->{success} = 1;
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


  @segment = grep { defined $_->[6] and $_->[6] =~ /\S/ } @segment;

  my @jar = map { "$_->[5]=$_->[6]; Domain=$_->[0]; Path=$_->[2]; Expiry=$_->[4]" } @segment;
  $self->{browser}{cookie_jar}->load_cookies( @jar );

  $cookie = join( "; ", map { "$_->[5]=$_->[6]" } @segment );

  #$self->{browser}{cookie_jar}{cookie} = $cookie;

  return $cookie;

} ## end sub read_moz_cookie

1;
