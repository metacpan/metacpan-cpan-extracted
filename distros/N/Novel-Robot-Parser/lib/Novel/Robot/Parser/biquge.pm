# ABSTRACT: http://www.biquge.tw
package Novel::Robot::Parser::biquge;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';

sub base_url { 'http://www.biquge.tw' }

sub charset { 'utf8' }

sub scrape_novel {
    my ($self) = @_;
    return {
        writer => { regex => '<meta property="og:novel:author" content="(.+?)"/>', }, 
        book=>{ regex=>'<meta property="og:title" content="(.+?)"/>', }, 
    };
}

sub scrape_novel_list { { path => '//div[@id="list"]//dd//a' } }

sub scrape_novel_item {
    return {
        title => { path => '//h1' }, 
        content=>{ path => '//div[@id="content"]', extract => 'HTML' }, 
    };
}

1;
