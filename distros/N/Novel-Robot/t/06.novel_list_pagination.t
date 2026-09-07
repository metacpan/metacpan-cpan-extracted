#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use lib 'lib';

use Novel::Robot;
use Test::More;

{
    package Local::PagedBrowser;

    sub new {
        my ( $class, $pages ) = @_;
        return bless { pages => $pages, requests => [] }, $class;
    }

    sub request_url {
        my ( $self, $url ) = @_;
        push @{ $self->{requests} }, $url;
        return $self->{pages}{$url} || '';
    }
}

my $first_url  = 'https://example.test/book/';
my $second_url = 'https://example.test/book/p-2.html#dir';
my %pages = (
    $first_url => <<'HTML',
<html><body>
<dl class="chapterlist"><dd><a href="1.html">第一章</a></dd></dl>
<a class="gr" href="p-2.html#dir">下一页</a>
</body></html>
HTML
    $second_url => <<'HTML',
<html><body>
<dl class="chapterlist"><dd><a href="2.html">第二章</a></dd></dl>
<a class="gr" href="./">下一页</a>
</body></html>
HTML
);

my $robot = Novel::Robot->new( site => 'default' );
my $browser = Local::PagedBrowser->new( \%pages );
$robot->{browser} = $browser;

my $result = $robot->get_novel_items(
    $first_url,
    info_sub      => sub { return {} },
    item_list_sub => $robot->{parser}->can( 'parse_item_list' ),
    next_page_sub => $robot->{parser}->can( 'generate_next_page_url' ),
);

is( scalar @{ $result->{item_list} }, 2, 'merge chapters from two list pages' );
is( $result->{item_list}[1]{title}, '第二章', 'parse chapter from next list page' );
is_deeply(
    $browser->{requests},
    [ $first_url, $second_url ],
    'resolve relative next URL and stop a pagination cycle',
);

my $skip_browser = Local::PagedBrowser->new( \%pages );
$robot->{browser} = $skip_browser;
my $second_page_only = $robot->get_novel_items(
    $first_url,
    info_sub      => sub { return {} },
    item_list_sub => $robot->{parser}->can( 'parse_item_list' ),
    next_page_sub => $robot->{parser}->can( 'generate_next_page_url' ),
    min_page_num  => 2,
    max_page_num  => 2,
);

is_deeply(
    [ map { $_->{title} } @{ $second_page_only->{item_list} } ],
    ['第二章'],
    'fetch skipped pages to discover and select the requested page range',
);

done_testing;
