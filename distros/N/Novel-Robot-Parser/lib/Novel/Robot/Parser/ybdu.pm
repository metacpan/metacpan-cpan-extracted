# ABSTRACT: 一本读 http://www.ybdu.com
package Novel::Robot::Parser::ybdu;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';

sub base_url {  'http://www.ybdu.com' }

sub scrape_novel_list { { path=>'//ul[@class="mulu_list"]//a'} }

sub scrape_novel { {
        writer => { regex => '<meta property="og:novel:author" content="(.+?)"/>', }, 
        book=>{ regex => '<meta property="og:novel:book_name" content="(.+?)"/>', }, 
    } }

sub scrape_novel_item { {
        title => { path => '//div[@class="h1title"]//h1'}, 
        content=>{ path => '//div[@id="htmlContent"]', extract => 'HTML', sub => sub {
                my ($c) = @_;
                $c=~s#<div class="ad00">.*##s;
                return $c;
            }}, 
} }

1;
