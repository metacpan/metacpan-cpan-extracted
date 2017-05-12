use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;
use Term::ANSIColor::Markup;

dies_ok {
    Term::ANSIColor::Markup->colorize(q{<red>foo</blue>});
} 'Invalid end tag';
like $@, qr{^Invalid end tag was found: </blue>}, 'Invalid end tag';
