# ABSTRACT: http://www.ddshu.net
package Novel::Robot::Parser::ddshu;
use strict;
use warnings;
use utf8;
use base 'Novel::Robot::Parser';

sub scrape_novel { { 
        book => { path=> '//div[@class="mytitle"]' },
        writer => { path=> '//div[@class="author"]/a'}, 
    } }

1;
