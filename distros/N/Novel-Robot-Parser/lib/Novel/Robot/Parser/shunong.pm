# ABSTRACT: http://www.shunong.com
package Novel::Robot::Parser::shunong;
use strict;
use warnings;
use utf8;
use base 'Novel::Robot::Parser';

sub base_url { 'http://www.shunong.com' }

sub scrape_novel_list { { path => '//div[@class="book_list"]//a' } }

sub scrape_novel {
    return {
        book => { path => '//h1'}, 
        writer=>{ path => '//div[@class="infos"]//span'}, 
    };
}

sub scrape_novel_item {
    return {
        title => { path => '//h1'}, 
        content=>{ path => '//div[@id="htmlContent"]', extract=> 'HTML' }, 
    };
}

sub parse_novel_item {
    my ( $self, $html_ref, $ref ) = @_;
    $ref->{content}=~s#<a href="http://www.jidubook.com/".+?</a>##sg;
    $ref->{content}=~s#<a href="http://www.shunong.com/".+?</a>##sg;
    return $ref;
} ## end sub parse_novel_item

1;
