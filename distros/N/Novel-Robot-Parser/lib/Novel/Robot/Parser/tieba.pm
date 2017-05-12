# ABSTRACT: http:://tieba.baidu.com
package Novel::Robot::Parser::tieba;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';

use HTML::Entities;
use Web::Scraper;

sub base_url { 'http://tieba.baidu.com' }

sub charset { 'utf8' }

sub site_type { 'tiezi' }

sub scrape_novel {
  { title  => { path => '//h3' },
    writer => { path => '//li[@class="d_name"]' },
  };
}

sub parse_novel_item {
  my ( $self, $h ) = @_;

  my $parse_query = scraper {
    process '//div[contains(@class,"l_post ")]',
      'floors[]' => scraper {
      process '.',                                               'info'   => '@data-field';
      process_first '//h1[@class="core_title_txt"]',             'title'  => 'TEXT';
      process_first '//li[@class="d_name"]',                     'writer' => 'TEXT';
      process_first '//div[contains(@class,"d_post_content ")]', content  => 'HTML';
      };
  };
  my $ref = $parse_query->scrape( $h );

  my @floors;
  for my $f ( @{ $ref->{floors} } ) {
    next unless ( $f->{content} );
    $f->{writer} ||= 'unknown';
    if ( $f->{info} ) {
      my $x = decode_entities( $f->{info} );
      ( $f->{id} )   = $x =~ /"post_no":(\d+),/s;
      ( $f->{time} ) = $x =~ /"date":"(.+?)",/s;
      delete( $f->{info} );
    }
    push @floors, $f;
  }
  return \@floors;
} ## end sub parse_novel_item

sub parse_novel_list {
    my ( $self, $h ) = @_;
    my $parse_query = scraper {
        process_first '//link[@rel="canonical"]',   'base' => '@href';
        process_first '//li[@class="l_reply_num"]', 'page' => 'TEXT';
    };
    my $ref      = $parse_query->scrape( $h );
    my ( $page ) = $ref->{page} =~ /共(\d+)页/s;
    my @urls     = map { "$ref->{base}?pn=$_" } ( 2 .. $page );
    return \@urls;
}

1;
