#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    no warnings 'redefine';
    use_ok('PDF::Make::Render');
    use_ok('PDF::Make::RenderPage');
}

is(PDF::Make::Render::LINE_CAP_BUTT(), 0, 'Render LINE_CAP_BUTT constant');
is(PDF::Make::Render::LINE_CAP_ROUND(), 1, 'Render LINE_CAP_ROUND constant');
is(PDF::Make::Render::LINE_CAP_SQUARE(), 2, 'Render LINE_CAP_SQUARE constant');

is(PDF::Make::Render::LINE_JOIN_MITER(), 0, 'Render LINE_JOIN_MITER constant');
is(PDF::Make::Render::LINE_JOIN_ROUND(), 1, 'Render LINE_JOIN_ROUND constant');
is(PDF::Make::Render::LINE_JOIN_BEVEL(), 2, 'Render LINE_JOIN_BEVEL constant');

is(PDF::Make::Render::FILL_RULE_NONZERO(), 0, 'Render FILL_RULE_NONZERO constant');
is(PDF::Make::Render::FILL_RULE_EVENODD(), 1, 'Render FILL_RULE_EVENODD constant');

is(PDF::Make::RenderPage::SCALE_NEAREST(), 0, 'RenderPage SCALE_NEAREST constant');
is(PDF::Make::RenderPage::SCALE_BILINEAR(), 1, 'RenderPage SCALE_BILINEAR constant');
is(PDF::Make::RenderPage::SCALE_BICUBIC(), 2, 'RenderPage SCALE_BICUBIC constant');

is(PDF::Make::RenderPage::ROTATE_0(), 0, 'RenderPage ROTATE_0 constant');
is(PDF::Make::RenderPage::ROTATE_90(), 90, 'RenderPage ROTATE_90 constant');
is(PDF::Make::RenderPage::ROTATE_180(), 180, 'RenderPage ROTATE_180 constant');
is(PDF::Make::RenderPage::ROTATE_270(), 270, 'RenderPage ROTATE_270 constant');

done_testing;
