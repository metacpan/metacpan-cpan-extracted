#!/usr/bin/perl -w
use strict;
use Test::More; 
use utf8;
eval "use Text::Unaccent::PurePerl";
if ($@) {
	plan skip_all => "Text::Unaccent::PurePerl required for testing accent changes";
}
else	{
	plan tests => 1;
}

use Music::Tag;


my $tag = Music::Tag->new('t/fake.music',
                          { 'Unaccent' => 1 },
                          "Generic"
                         );

ok ( $tag->plugin('Generic')->simple_compare('Björk', 'Bjork'), 'Accent compare');
