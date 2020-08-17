use Test::Most;
use Mojo::DOM;

use strict;
use warnings;
use Path::Tiny;











my $tests = 3; # keep on line 17 for ,i (increment and ,d (decrement)
my $skip_most = 0;
plan tests => $tests;
diag( "Running my tests" );

my $html = '<div class="one"><div class="two"><div class="three"><p class="booboo">hi</p></div></div></div>';


my $ex = Mojo::DOM->with_roles('+Analyzer')->new($html);



my @analysis = $ex->tag_analysis('p');
my $result =

        [
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '4',
    'classes' => {
                   'booboo' => 1
                 },
    'direct_children' => 1,
    'selector' => 'div:nth-child(1) > div:nth-child(1) > div:nth-child(1)',
    'size' => 1,
    'top_level' => 1
  }
];

is_deeply (\@analysis, $result, 'gets correct tag analysis result');


$html = '<div class="one"><p>lkj</p><div class="two"><div class="three"><p class="booboo">hi</p></div></div></div>';
$ex = Mojo::DOM->with_roles('+Analyzer')->new($html);
@analysis = $ex->tag_analysis('p');
$result =
        [
  {
    'all_tags_have_same_depth' => 0,
    'avg_tag_depth' => '3',
    'classes' => {
                   'booboo' => 1
                 },
    'direct_children' => 1,
    'selector' => 'div:nth-child(1)',
    'size' => 2,
    'top_level' => 1
  },
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '4',
    'classes' => {
                   'booboo' => 1
                 },
    'direct_children' => 0,
    'selector' => 'div:nth-child(1) > div:nth-child(2)',
    'size' => 1
  }
];

is_deeply (\@analysis, $result, 'gets correct tag analysis result');

my $file = path('t/complex.html')->slurp_utf8;
$ex = Mojo::DOM->with_roles('+Analyzer')->new($file);
@analysis = $ex->tag_analysis('p');
$result =
        [
  {
    'all_tags_have_same_depth' => 0,
    'avg_tag_depth' => '9.289',
    'classes' => {
                   'news-article-header__dek' => 1,
                   'news-article-header__timestamps-posted' => 1,
                   'newsblock-newsletter-signup__description' => 1,
                   'newsblock-support-cta__body' => 1,
                   'reporter-card-list__blurb' => 3,
                   'reporter-card-list__contact-cta' => 3,
                   'reporter-card-list__tip-cta' => 1,
                   'xs-mt1 xs-text-3 xs-font-serif bold' => 1
                 },
    'direct_children' => 0,
    'selector' => 'html:nth-child(1) > body:nth-child(2)',
    'size' => 38,
    'top_level' => 1
  },
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '8',
    'classes' => {
                   'newsblock-newsletter-signup__description' => 1
                 },
    'direct_children' => 0,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > div:nth-child(14)',
    'size' => 1
  },
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '6',
    'classes' => {
                   'newsblock-support-cta__body' => 1
                 },
    'direct_children' => 0,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > div:nth-child(7)',
    'size' => 1
  },
  {
    'all_tags_have_same_depth' => 0,
    'avg_tag_depth' => '9.417',
    'classes' => {
                   'news-article-header__dek' => 1,
                   'news-article-header__timestamps-posted' => 1,
                   'reporter-card-list__blurb' => 3,
                   'reporter-card-list__contact-cta' => 3,
                   'reporter-card-list__tip-cta' => 1,
                   'xs-mt1 xs-text-3 xs-font-serif bold' => 1
                 },
    'direct_children' => 0,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > main:nth-child(5) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1)',
    'size' => 36
  },
  {
    'all_tags_have_same_depth' => 0,
    'avg_tag_depth' => '9.346',
    'classes' => {},
    'direct_children' => 0,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > main:nth-child(5) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > div:nth-child(2)',
    'size' => 26
  },
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '12',
    'classes' => {},
    'direct_children' => 0,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > main:nth-child(5) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > div:nth-child(2) > div:nth-child(2)',
    'size' => 1
  },
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '9',
    'classes' => {},
    'direct_children' => 5,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > main:nth-child(5) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > div:nth-child(2) > div:nth-child(3)',
    'size' => 5
  },
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '12',
    'classes' => {},
    'direct_children' => 0,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > main:nth-child(5) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > div:nth-child(2) > div:nth-child(4)',
    'size' => 1
  },
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '9',
    'classes' => {},
    'direct_children' => 6,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > main:nth-child(5) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > div:nth-child(2) > div:nth-child(6)',
    'size' => 6
  },
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '12',
    'classes' => {},
    'direct_children' => 0,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > main:nth-child(5) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > div:nth-child(2) > div:nth-child(7)',
    'size' => 1
  },
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '9',
    'classes' => {},
    'direct_children' => 12,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > main:nth-child(5) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > div:nth-child(2) > div:nth-child(9)',
    'size' => 12
  },
  {
    'all_tags_have_same_depth' => 0,
    'avg_tag_depth' => '8.667',
    'classes' => {
                   'news-article-header__dek' => 1,
                   'news-article-header__timestamps-posted' => 1,
                   'xs-mt1 xs-text-3 xs-font-serif bold' => 1
                 },
    'direct_children' => 1,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > main:nth-child(5) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > header:nth-child(1)',
    'size' => 3
  },
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '9',
    'classes' => {
                   'xs-mt1 xs-text-3 xs-font-serif bold' => 1
                 },
    'direct_children' => 1,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > main:nth-child(5) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > header:nth-child(1) > div:nth-child(4)',
    'size' => 1
  },
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '9',
    'classes' => {
                   'news-article-header__timestamps-posted' => 1
                 },
    'direct_children' => 1,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > main:nth-child(5) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > header:nth-child(1) > div:nth-child(6)',
    'size' => 1
  },
  {
    'all_tags_have_same_depth' => 1,
    'avg_tag_depth' => '10',
    'classes' => {
                   'reporter-card-list__blurb' => 3,
                   'reporter-card-list__contact-cta' => 3,
                   'reporter-card-list__tip-cta' => 1
                 },
    'direct_children' => 0,
    'selector' => 'html:nth-child(1) > body:nth-child(2) > main:nth-child(5) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > ul:nth-child(5)',
    'size' => 7
  }
];

is_deeply (\@analysis, $result, 'gets correct tag analysis result');
