#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
use Socialtext::Resting::Mock;

BEGIN {
    use_ok 'Socialtext::Resting::TaggedPages', 'tagged_pages';
}

my $r = Socialtext::Resting::Mock->new;
$r->{_get_pages} = [
    { page_id => 'none', tags => [] },
    { page_id => 'one',  tags => ['a'] },
    { page_id => 'two',  tags => [ 'a', 'b' ] },
];

Untagged_pages: {
    my $pages = tagged_pages(rester => $r, notags => 1);
    is_deeply $pages, ['none'], 'page has no tags';
}

One_tag: {
    my $pages = tagged_pages(rester => $r, tags => ['a']);
    is_deeply $pages, [qw/one two/], 'page has one tag';
}

Two_tags: {
    my $pages = tagged_pages(rester => $r, tags => ['a', 'b']);
    is_deeply $pages, ['two'], 'page has two tags';
}

