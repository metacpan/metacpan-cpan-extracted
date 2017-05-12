#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use HTML::Declare ':all';
use SyForm::Util::HTML;

use Scalar::Util 'refaddr';

my $span = SPAN { class => 'test' };

is(get_html_attr($span,'class'),'test','Testing get_html_attr on $span');

my $div = DIV { class => 'test2', _ => [
  SPAN { class => 'test3' }, SPAN { class => 'test4' },
] };

my $adiv = add_html_attr($div, class => 'other', align => 'left');

ok(refaddr($div) != refaddr($adiv),'Not identical ref addr on $div add_html_attr clone');
ok(refaddr($div->children->[0]) != refaddr($adiv->children->[0]),'Not identical ref addr on $div add_html_attr clone first child');
ok(refaddr($div->children->[1]) != refaddr($adiv->children->[1]),'Not identical ref addr on $div add_html_attr clone second child');
is(get_html_attr($adiv,'class'),'test2 other','class added to div clone via add_html_attr');
is(get_html_attr($adiv,'align'),'left','align set to div clone via add_html_attr');

my $pdiv = put_html_attr($div, class => 'other', align => 'left');

ok(refaddr($div) != refaddr($pdiv),'Not identical ref addr on $div put_html_attr clone');
ok(refaddr($div->children->[0]) != refaddr($pdiv->children->[0]),'Not identical ref addr on $div put_html_attr clone first child');
ok(refaddr($div->children->[1]) != refaddr($pdiv->children->[1]),'Not identical ref addr on $div put_html_attr clone second child');
is(get_html_attr($pdiv,'class'),'other test2','class put to div clone via put_html_attr');
is(get_html_attr($pdiv,'align'),'left','align set to div clone via put_html_attr');

my $sdiv = set_html_attr($div, class => 'other', align => 'left');

ok(refaddr($div) != refaddr($sdiv),'Not identical ref addr on $div set_html_attr clone');
ok(refaddr($div->children->[0]) != refaddr($sdiv->children->[0]),'Not identical ref addr on $div set_html_attr clone first child');
ok(refaddr($div->children->[1]) != refaddr($sdiv->children->[1]),'Not identical ref addr on $div set_html_attr clone second child');
is(get_html_attr($sdiv,'class'),'other','class set to div clone via set_html_attr');
is(get_html_attr($sdiv,'align'),'left','align set to div clone via set_html_attr');

done_testing;
