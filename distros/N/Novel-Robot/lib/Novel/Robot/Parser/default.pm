# ABSTRACT: default
package Novel::Robot::Parser::default;
use strict;
use warnings;
use utf8;
use base 'Novel::Robot::Parser';

#sub scrape_novel_item { {
        ##content => { regex=> '<DIV id=content name="content">.*?<P>(.+?)</P>' },
        #content=>{ path => '//div[@id="TXT"]', extract => 'HTML', sub => sub {
            #my ($c) = @_;
            #$c=~s#<div class="bottem">.*$##s;
            #return $c;
        #}, 
    #}, 
#} }

#sub parse_novel_item {
    #my ( $self, $html_ref, $ref ) = @_;

    #$ref->{content}=~s/^.*?正文，敬请欣赏！//s;
    #return $ref;
#} ## end sub parse_novel_item
  
1;
