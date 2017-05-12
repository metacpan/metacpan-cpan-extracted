# ABSTRACT: http://www.snwx.com
package Novel::Robot::Parser::snwx;
use strict;
use warnings;
use utf8;
use base 'Novel::Robot::Parser';

sub base_url { 'http://www.snwx.com' }

sub scrape_novel_list { { path=>'//div[@id="list"]//a', sort=>1 } }

sub scrape_novel {
    return {
        book => { path => '//div[@class="infotitle"]//h1'}, 
        writer=>{ path => '//div[@class="infotitle"]//i'}, 
    };
}

sub parse_novel {
    my ( $self, $html_ref, $ref ) = @_;

    $ref->{writer}=~s/作者.*?\*//;
    $ref->{writer}=~s/\*//g;

    return $ref;
} ## end sub parse_novel

sub scrape_novel_item {
    return {
        title => { path => '//div[@class="bookname"]//h1'}, 
        content=>{ path => '//div[@id="BookText"]', extract => 'HTML' }, 
    };
}

1;
