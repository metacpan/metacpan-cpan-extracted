# ABSTRACT: http://www.zilang.net
package Novel::Robot::Parser::zilang;
use strict;
use warnings;
use utf8;
use base 'Novel::Robot::Parser';

sub base_url {  'http://www.zilang.net'}

sub scrape_novel_list { { path=>'//div[@class="list"]//a', sort=>1 } }

sub scrape_novel { {
        writer => { path => '//div[@class="book"]//span', }, 
        book=>{ path => '//h1', }, 
    } }

sub scrape_novel_item { {
        title => { path => '//h1'}, 
        content=>{ path => '//div[@id="text_area"]', extract => 'HTML'}, 
    } }

1;
