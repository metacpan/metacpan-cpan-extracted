# ABSTRACT: 123yq http://www.123yq.com
package Novel::Robot::Parser::yesyq;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';

sub base_url { 'http://www.123yq.com' }

sub scrape_novel_list { { path=>'//div[@id="list"]//dd//a', sort=>1 } }

sub scrape_novel { {
        writer => { path => '//div[@id="info"]//p[1]', }, 
        book=>{ path => '//h1', }, 
    } }

sub parse_novel {
    my ($self, $h, $ref) = @_;

    $ref->{writer}=~s/.*?者：//;

    return $ref;
} ## end sub parse_novel

sub scrape_novel_item { {
        title => { path => '//h1'}, 
        content=>{ path => '//div[@id="TXT"]', extract => 'HTML', sub => sub {
                my ($c) = @_;
                $c=~s#<div[^>]*?>.+?</div>##sg;
                return $c;
            }}, 
    } }
1;
