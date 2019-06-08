# ABSTRACT: http://www.ddshu.net
package Novel::Robot::Parser::ddshu;
use strict;
use warnings;
use utf8;
use base 'Novel::Robot::Parser';

sub generate_novel_url {
    my ($self, $url) = @_;
    $url=~s#[^/]+$#opf.html#;
    return $url;
}

sub scrape_novel { { 
        book => { path=> '//div[@class="mytitle"]' },
        writer => { path=> '//div[@class="author"]/a'}, 
    } }

sub parse_novel {
    my ($self, $h, $r) =@_;

    if(! $r->{writer} or ! $r->{book}){
        @{$r}{qw/book writer/} = $$h=~m#<title>\s*(.+?)\s*/\s*(.+?)\s*/#s;
    }
    return $r;
}

sub scrape_novel_list  { {
        path => '//div[@class="opf"]//a' , 
    } }


1;
