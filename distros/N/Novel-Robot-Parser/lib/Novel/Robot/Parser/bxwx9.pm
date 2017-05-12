# ABSTRACT: http://www.bxwx9.org
package Novel::Robot::Parser::bxwx9;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';

sub base_url { 'http://www.bxwx9.org' }

sub scrape_novel_list {
    { path=> '//div[@id="TabCss"]//dd//a'}
}

sub scrape_novel {
    return {
        book => { path => '//div[@id="title"]' }, 
        writer=>{ path => '//div[@id="info"]//a' }, 
    };
}

sub scrape_novel_item {
    return {
        title => { path => '//div[@id="title"]' }, 
        content=>{ path => '//div[@id="content"]', extract => 'HTML' }, 
    };
}


1;
