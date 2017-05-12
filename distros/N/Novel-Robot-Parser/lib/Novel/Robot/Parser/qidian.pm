# ABSTRACT: 起点小说 http://read.qidian.com
package Novel::Robot::Parser::qidian;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';

use Web::Scraper;

sub base_url { 'http://read.qidian.com' }

sub charset { 'utf8' }

sub scrape_novel_list { { path => '//li[@itemprop="chapter"]//a[@itemprop="url"]'} }

sub parse_novel {

    my ( $self, $html_ref ) = @_;

    my $parse_novel = scraper {
          process_first '//div[@class="booktitle"]/h1' , 'book' => 'TEXT';
          process_first '//div[@class="booktitle"]//a' , 'writer' => 'TEXT', writer_url=>'@href';
    };

    my $ref = $parse_novel->scrape($html_ref);
    $ref->{book}=~s/\s*试玩得起点币.*//sg;

    return $ref;
} ## end sub parse_novel

sub parse_novel_item {

    my ( $self, $html_ref ) = @_;

    my $parse_novel_item = scraper {
        process_first '//div[@id="content"]//script', 'content_url' => '@src', 'content_charset' => '@charset';
        process_first '//span[@itemprop="headline"]', 'title'=> 'TEXT';
        process_first '//span[@itemprop="articleSection"]', 'book' => 'TEXT';
        process_first '//span[@class="info"]//i[2]', 'writer' => 'TEXT';
    };
    my $ref = $parse_novel_item->scrape($html_ref);
    $ref->{writer} ||='';
    
    my $c = $self->{browser}->request_url($ref->{content_url});
    $c=~s#^\s*document.write.*?'\s+##s;
    $c=~s#'\);\s*$##s;
    $c=~s#起点中文网 www.cmfu.com##sg;
    $c=~s#欢迎广大书友光临阅读，最新、最快、最火的连载作品尽在起点原创！##sg;
    $ref->{content} = $c;

    return $ref;
} ## end sub parse_novel_item

1;
