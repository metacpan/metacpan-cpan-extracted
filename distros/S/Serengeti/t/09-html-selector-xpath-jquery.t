#!/usr/bin/perl

use strict;
use warnings;

use Test::More skip_all => "This doesn't work yet as it requires a patched HMTL::Selector::XPath";



BEGIN { use_ok("HTML::Selector::XPath::Serengeti") }

for (qw(checkbox file image password radio reset submit text)) {
    is(
        HTML::Selector::XPath::Serengeti->new(":$_")->to_xpath,
        qq{//*[\@type='$_']},
    );
}

is(
    HTML::Selector::XPath::Serengeti->new(q{div:contains("Företag")})->to_xpath,
    q{//div[text()[contains(string(.),"Företag")]]}
);

is(
    HTML::Selector::XPath::Serengeti->new(q{input[name='man']})->to_xpath,
    q{//input[@name='man']}
)
