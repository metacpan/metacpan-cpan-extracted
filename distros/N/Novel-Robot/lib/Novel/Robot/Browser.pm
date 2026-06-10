# ABSTRACT: get/post url, return unicode content, auto detect CJK charset
package Novel::Robot::Browser;

use strict;
use warnings;
use utf8;

our $VERSION = 0.23;

#use Data::Dumper;
#use Parallel::ForkManager;
#use Smart::Comments;

use Encode::Detect::CJK qw/detect/;
use Encode;
use File::Slurp qw/slurp/;
use HTTP::CookieJar;
use HTTP::Tiny;
use IO::Uncompress::Gunzip qw(gunzip);
use Term::ProgressBar;
use URI::Escape;
use URI;
use Firefox::Marionette();


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
  $opt{agent} ||= 'default';

  $opt{browser_agent}   ||= init_browser_agent( \%opt );

  bless {%opt}, __PACKAGE__;
}

sub init_browser_agent {
	my ( $o ) = @_;

	$o->{browser_headers}  ||= {};
	my %h = ( %DEFAULT_HEADER, %{$o->{browser_headers}} );

	my $cookie_jar = HTTP::CookieJar->new;
	my $agent = HTTP::Tiny->new(
		default_headers => \%h,
		cookie_jar      => $cookie_jar,
	);

	return $agent;
}

sub request_url {
	my ( $self, $url, $form ) = @_;
	return $DEFAULT_URL_CONTENT unless ( $url );

	### $url

	my $c;
	for my $i ( 1 .. $self->{retry} ) {
		if ( $self->{agent} eq 'firefox' ) {
			$c = $self->request_url_firefox($url);
		}elsif($self->{agent} eq 'chrome') {
			$c = $self->request_url_chrome($url);
		}else{
			$c = $self->request_url_tiny($url);
		}
		last if ( $c );
		sleep 2;
	}

	return $DEFAULT_URL_CONTENT unless($c);

	my $charset = detect( $c );
	$c = decode( $charset, $c, Encode::FB_XMLCREF );

	return $c;
}


sub request_url_firefox {
	my ($self, $url) = @_;
	my $firefox = Firefox::Marionette->new()->go($url);
	sleep 5;
	my $c = $firefox->html();
	return $c;
}

sub request_url_chrome {
	my ($self, $url) = @_;
	my $c = `chrome --no-sandbox --user-data-dir --headless --disable-gpu --dump-dom "$url" 2>/dev/null`;
	return $c;
}

sub request_url_tiny {
  my ( $self, $url, $form ) = @_;

  my $res;
  if ( $form ) {
	  $res = $self->{browser_agent}->request(
		  'POST', $url,
		  { content => $self->post_form_data( $form ),
			  headers => {
				  'content-type' => 'application/x-www-form-urlencoded',
			  },
		  } );
  } else {
	  $res = $self->{browser_agent}->get( $url );
  }

  
  return unless ( $res->{success} );

  my $content = $res->{content};


  my $html;
  if ( 
	  $res->{headers} 
		  and $res->{headers}{'content-encoding'}
		  and $res->{headers}{'content-encoding'} eq 'gzip' ) {
	  gunzip \$content => \$html, MultiStream => 1, Append => 1;
  }
  $content = $html || $content;


  return $content;
} ## end sub request_url_tiny

sub post_form_data {
  my ( $self, $form ) = @_;

  return $form unless ( ref( $form ) eq 'HASH' );

  my @params;
  while ( my ( $k, $v ) = each %$form ) {
    push @params, uri_escape( $k ) . "=" . uri_escape( $v );
  }

  my $post_str = join( "&", @params );
  return $post_str;
}

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
  $self->{browser_agent}{cookie_jar}->load_cookies( @jar );

  $cookie = join( "; ", map { "$_->[5]=$_->[6]" } @segment );

  #$self->{browser}{cookie_jar}{cookie} = $cookie;

  return $cookie;

} ## end sub read_moz_cookie

1;
