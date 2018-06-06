#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Template::Test;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $tt = Template->new;

test_expect(\*DATA, $tt, { POST_CHOMP => 1 });

__DATA__
-- test --
[%- USE Filter.IDN -%]
[% 'xn--mller-kva.example.org' | idn('to_utf8') %]
-- expect --
müller.example.org

-- test --
[%- USE Filter.IDN -%]
<a href="http://[% 'müller.example.org' | idn('to_ascii') %]">Link</a>
-- expect --
<a href="http://xn--mller-kva.example.org">Link</a>

-- test --
[%- USE Filter.IDN -%]
[% 'example.org' | idn('to_utf8') %]
-- expect --
example.org

-- test --
[%- USE Filter.IDN -%]
[% 'example.org' | idn('to_utf8') %]
-- expect --
example.org

-- test --
[%- USE Filter.IDN -%]
[% 'example.org' | idn('to_ascii') %]
-- expect --
example.org

-- test --
[%- USE Filter.IDN -%]
[% 'xn--mller-kva.example.org' | idn('to_ascii') %]
-- expect --
xn--mller-kva.example.org

-- test --
[%- USE Filter.IDN -%]
[% 'xn--eqrt2g.xn--6frz82g' | idn('to_utf8') %]
-- expect --
域名.移动

-- test --
[%- USE Filter.IDN -%]
[% '域名.移动' | idn('to_ascii') %]
-- expect --
xn--eqrt2g.xn--6frz82g

-- test --
[%- USE Filter.IDN -%]
[% '域名.移动' | idn('to_utf8') %]
-- expect --
域名.移动

-- test --
[%- USE Filter.IDN -%]
[% '域名.移动' | idn('encode') %]
-- expect --
xn--eqrt2g.xn--6frz82g

-- test --
[%- USE Filter.IDN -%]
[% 'xn--eqrt2g.xn--6frz82g' | idn('decode') %]
-- expect --
域名.移动

-- test --
[%- USE Filter.IDN -%]
[% 'xn--eqrt2g.xn--6frz82g' | idn %]
-- expect --
域名.移动
-- test --
[%- USE Filter.IDN -%]
[% '域名.移动' | idn %]
-- expect --
xn--eqrt2g.xn--6frz82g
