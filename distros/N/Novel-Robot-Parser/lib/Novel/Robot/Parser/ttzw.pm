# ABSTRACT: 天天中文 http://www.ttzw.com
package Novel::Robot::Parser::ttzw;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';
use Web::Scraper;

sub base_url { 'http://www.ttzw.com' }

sub scrape_novel_list { { path=>'//div[@id="chapter_list"]//a' } }

sub scrape_novel { {
        book => { path => '//h1' }, 
        writer=>{ path => '//div[@class="pl40"]//b', extract => 'TEXT' }, 
    } }

sub parse_novel {

    my ( $self, $html_ref, $ref ) = @_;

    $ref->{chapter_list} = [
        grep { $_->{url}  and $_->{url}!~/\/$/ } @{ $ref->{chapter_list} }
    ];

    return $ref;
} ## end sub parse_novel

sub parse_novel_item {

    my ( $self, $html_ref ) = @_;

    my $parse_novel_item = scraper {
        process_first '//div[@id="text_area"]//script', 'content_url' => 'HTML';
        process_first '//div[@id="chapter_title"]', 'title'=> 'TEXT';
    };
    my $ref = $parse_novel_item->scrape($html_ref);

    ($ref->{content_url}) = $$html_ref=~/<script language="javascript">outputTxt\(.*?(\/.*?)"/s;
    $ref->{content} = ''; 

   if($ref->{content_url}){
       $ref->{content_url}= "http://r.xsjob.net:88/novel$ref->{content_url}";
       my $c = $self->{browser}->request_url($ref->{content_url});
       $c=~s#^\s*document.write.*?'\s*##s;
       $c=~s#'\);\s*$##s;
       $ref->{content} = $c;
   }

    return $ref;
} ## end sub parse_novel_item

1;
