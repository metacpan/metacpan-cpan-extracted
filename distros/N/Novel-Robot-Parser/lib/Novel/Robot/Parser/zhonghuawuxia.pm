# ABSTRACT: zhonghuawuxia.pm http://www.zhonghuawuxia.com
package Novel::Robot::Parser::zhonghuawuxia;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';

sub base_url {  'http://www.zhonghuawuxia.com' }

sub scrape_novel { {
        writer => { path => '//div[@class="title"]', }, 
        book=>{ path => '//div[@class="title"]//b', }, 
    } }

sub scrape_novel_list { { path=>'//div[@class="index_area"]//ul//li//a' } }

sub parse_novel {
    my ( $self, $html_ref , $ref) = @_;

    ($ref->{writer})= $ref->{writer}=~m#.*作者(.+)$#;

    my ($book_id) = $$html_ref=~m#/bookinfo/(\d+)#s;
    $_->{url}=~s#/chapter/(\d+)$#/Public/js/$book_id/$1.js# for @{ $ref->{chapter_list} };

    return $ref;
} ## end sub parse_novel

sub parse_novel_item {
    my ( $self, $h ) = @_;
    $$h=~s#^.*?"##s;
    $$h=~s#"\)$##s;
    return { content => $$h };
} ## end sub parse_novel_item

1;
