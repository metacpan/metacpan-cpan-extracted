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

sub domain { 'lofter.com' }

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

sub gen_next_search_url {
  my ( $self, $start_u, $i, $h ) = @_;
  return "$start_u&page=$i";
}

sub gen_next_tag_url {
  my ( $self, $start_u, $i, $h ) = @_;
  return "$start_u?page=$i";
}

sub extract_item {
  my ( $self, $c ) = @_;
  #my $c = $self->{browser}->request_url( $r->{url} );
  my $r = {};
  $r->{content} = $self->scrape_element_try($c, [
          { path =>  '//div[starts-with(@class,"m-post")]', 'extract' => 'HTML' },
          { path =>  '//div[@class="txtcont"]',  'extract' => 'HTML' },
          { path =>  '//div[@class="content"]',  'extract' => 'HTML' },
          { path =>  '//div[@class="postdesc"]', 'extract' => 'HTML' },
          { path =>  '//div[@class="article"]',  'extract' => 'HTML' },
          { path =>  '//div[@class="post-ctc"]',  'extract' => 'HTML' },
      ]);
  return $r;
}

sub get_tiezi_ref {
    my ( $self, $w_b, %opt ) = @_;

    my $base_url = "http://$opt{writer}.lofter.com";
    my $b = uc( unpack( "H*", encode( "utf8", $opt{book} ) ) );
    $b =~ s/(..)/%$1/g;

    my %iter_opt = (
        verbose              => 1,
        %opt, 
        reverse_item_list => 1,
        info_sub             => sub { { writer => $opt{writer}, book => $opt{book}, title => $opt{book} } },
        item_list_sub => sub { $self->extract_content( $opt{book}, @_ ) },
        stop_sub    => sub { return; },
        #item_sub     => sub { $self->extract_item( @_ ) },
    );

    my $url = "$base_url/search/?q=$b";
    my $next_search_sub = sub { $self->gen_next_search_url( @_ ) };
    my ( $info, $item_list ) = $self->{browser}->request_url_whole(
        $url,
        %iter_opt, 
        next_page_sub => $next_search_sub, 
    );

    my $tag_url = "$base_url/tag/$b";
    my $next_tag_sub =  sub { $self->gen_next_tag_url( @_ ) };
    my ( $tag_info, $tag_item_list ) = $self->{browser}->request_url_whole(
        $tag_url,
        %iter_opt, 
        next_page_sub => $next_tag_sub,
    );
    
    my ($final_url, $next_page_sub, $final_item_list) = $#$tag_item_list>$#$item_list ?
    ($tag_url, $next_tag_sub, $tag_item_list) : ($url, $next_search_sub, $item_list);

    my ( $final_info, $dst_item_list ) = $self->{browser}->request_url_whole(
        $final_url,
        %iter_opt, 
        item_list => $final_item_list, 
        next_page_sub => $next_page_sub,
        item_sub     => sub { $self->extract_item( @_ ) },
        reverse_item_list => 0, 
    );

    $final_info->{url}        = $final_url;
    $final_info->{item_list} = $dst_item_list;
    $self->filter_item_list($final_info);
    #print "last_chapter_id : $info->{item_list}[-1]{id}\n";
    return $final_info;
} ## end sub get_tiezi_ref

1;
