# ABSTRACT: 千千小说
package Novel::Robot::Parser::qqxs;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';
use Web::Scraper;

sub base_url { 'http://www.qqxs.cc' }

sub scrape_novel_list { '//div[@id="list"]//dd/a' }

sub parse_novel {

    my ( $self, $html_ref ) = @_;

    my $parse_novel = scraper {
          process_first '//div[@id="intro"]/h3', book => 'TEXT';
    };

    my $ref = $parse_novel->scrape($html_ref);

    $ref->{book}=~s/^.*?《//s;
    $ref->{book}=~s/》.*$//s;
    @{$ref}{qw/writer/} = $$html_ref=~/作者([^\n]+?)所写的/s;

    return $ref;
} ## end sub parse_novel

sub parse_novel_item {

    my ( $self, $html_ref ) = @_;

    my $parse_novel_item = scraper {
        process_first '//div/h1', 'title'=> 'TEXT';
        process_first '//div[@id="booktext"]', content=> 'HTML';
    };
    my $ref = $parse_novel_item->scrape($html_ref);
    $ref->{title}=~s/^.*?\s+//s;
    $ref->{content}=~s/<[^>]+>/<br>/sg;
    return $ref;
} ## end sub parse_novel_item

1;
