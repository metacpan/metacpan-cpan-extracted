use strict;
use warnings;
use utf8;

eval <<'END_BLOCK'
use Test::More (
    skip_all => 'HTML::Entities and Apache::Util not installed; skipping'
);
END_BLOCK
    unless eval { require HTML::Entities } or eval { require Apache::Util };

eval 'use Template::Test';

test_expect(\*DATA);

__DATA__
[% USE Ligature %]

--test--
[% 'offloading floral offices refines effectiveness' | ligature | html_entity %]
--expect--
o&#xFB04;oading &#xFB02;oral o&#xFB03;ces re&#xFB01;nes e&#xFB00;ectiveness
