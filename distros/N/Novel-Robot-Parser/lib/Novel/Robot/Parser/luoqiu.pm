# ABSTRACT: http://www.luoqiu.com
package Novel::Robot::Parser::luoqiu;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';

sub base_url { 'http://www.luoqiu.com' };

sub scrape_novel_list { { path => '//div[@id="container_bookinfo"]//a' } }

sub scrape_novel { { 
        book => { path=> '//h1//a' },
        writer => { regex => '<meta name="author" content="(.+?)" />', }, 
} }

sub scrape_novel_item { {
        title => { path => '//h1[@class="bname_content"]'}, 
        content=>{ path => '//div[@id="content"]', extract => 'HTML' }, 
    } }

1;
