# ABSTRACT: http:://www.lofter.com
package Novel::Robot::Parser::lofter;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';

#use HTML::Entities;
use Encode;
use Web::Scraper;

sub charset { 'utf8' }

sub site_type { 'tiezi' }

sub extract_content {
  my ( $self, $book, $h ) = @_;
  my $r = scraper {
    process '//ul[@class="m-list"]//li',
      'artical[]' => { url => 'HTML', };
    process '//h2//a',
      'chapter[]' => {
      title => 'TEXT',
      url   => '@href'
      };
    process '//a[@class="title"]',
      'chap[]' => {
      title => 'TEXT',
      url   => '@href'
      };
  };
  my $res_r = $r->scrape( $h );
  my $chap_r =
      ( $res_r->{artical} and @{ $res_r->{artical} } ) ? $res_r->{artical}
    : ( $res_r->{chapter} and @{ $res_r->{chapter} } ) ? $res_r->{chapter}
    : ( $res_r->{chap}    and @{ $res_r->{chap} } )    ? $res_r->{chap}
    :                                                    undef;
  return unless ( $chap_r and @$chap_r );
  if ( $res_r->{artical} ) {
    ( $_->{title} ) = $_->{url} =~ m#<strong>(.+?)</strong>#s for @$chap_r;
    ( $_->{url} )   = $_->{url} =~ m#<a href="([^"]+)">#s     for @$chap_r;
  }
  my @chap_t = grep { $_->{url} =~ m#/post/# } @$chap_r;

  return unless ( @chap_t );
  my @chap_tidy = grep { $_->{title} =~ /$book/i } @chap_t;
  return \@chap_tidy;
} ## end sub extract_content

sub gen_next_url {
  my ( $self, $start_u, $i, $h ) = @_;
  return "$start_u&page=$i";
}

sub extract_item {
  my ( $self, $r ) = @_;

  my $c = $self->{browser}->request_url( $r->{url} );
  my $s = scraper {
    process '//div[starts-with(@class,"m-post ")]',
      'content' => 'HTML';
    process '//div[@class="txtcont"]',  'cont1' => 'HTML';
    process '//div[@class="content"]',  'cont2' => 'HTML';
    process '//div[@class="postdesc"]', 'cont3' => 'HTML';
    process '//div[@class="article"]',  'cont4' => 'HTML';
  };
  my $res = $s->scrape( \$c );
  $r->{content} = $res->{content} || $res->{cont1} || $res->{cont2} || $res->{cont3} || $res->{cont4};
  return $r;
}

sub get_tiezi_ref {
    my ( $self, $w_b, %opt ) = @_;

    my $base_url = "http://$opt{writer}.lofter.com";
    my $b = uc( unpack( "H*", encode( "utf8", $opt{book} ) ) );
    $b =~ s/(..)/%$1/g;
    my $url = "$base_url/search/?q=$b";

    my ( $info, $floor_list ) = $self->{browser}->request_urls_iter(
        $url,
        verbose              => 1,
        %opt, 
        reverse_content_list => 1,
        info_sub             => sub { { writer => $opt{writer}, book => $opt{book}, title => $opt{book} } },
        content_sub => sub { $self->extract_content( $opt{book}, @_ ) },
        stop_sub    => sub { return; },
        next_url_sub => sub { $self->gen_next_url( @_ ) },
        item_sub     => sub { $self->extract_item( @_ ) },
    );

    $info->{url}        = $url;
    $info->{floor_list} = $floor_list;
    print "last_chapter_id : $info->{floor_list}[-1]{id}\n";
    return $info;
} ## end sub get_tiezi_ref

1;
