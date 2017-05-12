# ABSTRACT: http://www.23us.com
package Novel::Robot::Parser::dingdian;
use strict;
use warnings;
use utf8;
use base 'Novel::Robot::Parser';

sub base_url { 'http://www.23us.com' }

sub scrape_novel { {
        writer => { regex => '<meta name="og:novel:author" content="(.+?)"/>', }, 
        book=>{ regex => '<meta name="og:novel:book_name" content="(.+?)"/>', }, 
    } }

sub scrape_novel_list {
    { path => '//table[@id="at"]//a'}
}

sub scrape_novel_item { {
        title => { path => '//h1' }, 
        content=>{ path => '//dd[@id="contents"]', extract => 'HTML' }, 
    } }

1;
