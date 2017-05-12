#!perl		-*- coding:utf8 -*-

use strict;
use warnings;
use Template::Test;
use utf8;

binmode( STDOUT, ':encoding(utf-8)' );
test_expect( \*DATA );

__END__
-- test --
The quick brown fox jumps over the lazy dog 01234567890
`~!@#$%^&*()-_=+[]{}\|"':;?/>.<,
-- expect --
The quick brown fox jumps over the lazy dog 01234567890
`~!@#$%^&*()-_=+[]{}\|"':;?/>.<,

-- test --
éïÒ€<>&"“”
-- expect --
éïÒ€<>&"“”

-- test --
[% USE HTML_NonAsc; 'éïÒ€<>&"“”' | html_nonasc %]
-- expect --
&eacute;&iuml;&Ograve;&euro;<>&"&ldquo;&rdquo;
