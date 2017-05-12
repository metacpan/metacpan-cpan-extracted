# ABSTRACT:  http://m.xiaoxiaoshuwu.com
package Novel::Robot::Parser::xiaoxiaoshuwu;
use strict;
use warnings;
use utf8;
use base 'Novel::Robot::Parser';

sub base_url {  'http://m.xiaoxiaoshuwu.com' }

sub scrape_novel { { 
        book => { path=> '//h3' },
        writer => { regex => '是由作家(.+?)所作', }, 
    } }

sub scrape_novel_list { { path => '//ul[@class="chapter"]//a' } }

sub scrape_novel_item { {
        title => { path => '//div[@id="nr_title"]'}, 
        content=>{ path => '//div[@id="chapterContent"]', extract => 'HTML' }, 
    } }

1;
