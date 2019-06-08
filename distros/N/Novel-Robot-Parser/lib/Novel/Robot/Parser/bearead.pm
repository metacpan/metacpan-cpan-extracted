# ABSTRACT: http://www.bearead.org
package Novel::Robot::Parser::bearead;
use strict;
use warnings;
use utf8;
use JSON;

use base 'Novel::Robot::Parser';

sub base_url { 'https://wwwj.bearead.com' }

sub generate_novel_url {
  my ( $self, $index_url ) = @_;
  return $index_url if($index_url=~m#https://wwwj.bearead.com/book/b\d+$#);
  my ( $bid ) = $index_url =~ m#bid=([^&]+)#;
  return 'https://wwwj.bearead.com/book/'.$bid;
  #return ( 'https://www.bearead.com/api/book/detail', "bid=$bid" );
}

sub scrape_novel { {
        book => { path => '//span[@class="articleName"]' }, 
        writer => { path => '//h2[@class="userName"]' }, 
    }
}

sub scrape_novel_list {
    { path=> '//ul[@class="chapterList"]//li//a'}
}

sub scrape_novel_item { {
        #content => { regex=> '<div style="display: none;" class="article_main arc-no-select">(.+?)</div>' },
        content=>{ 
            path => '//div[@class="article_main arc-no-select"]', 
            #extract => 'HTML', 
    }, 
} }


1;
