#!/usr/bin/env perl

use strict;
use Template::Test;

test_expect(\*DATA);

__END__
--test--
[% USE Filter.Minify.CSS -%]
[% FILTER minify_css %]
   .foo {
       color: #aabbcc;
       margin: 0;
   }
[% END %]
--expect--
.foo{color:#aabbcc;margin:0;}

