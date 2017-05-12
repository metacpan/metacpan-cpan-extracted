use strict;
use Test::More tests => 2;
use Sledge::Template::Xslate;

my $option = {
    syntax => 'TTerse',
    module => ['Text::Xslate::Bridge::TT2Like'],
};

isnt(Text::Xslate->new($option), Text::Xslate->new($option));
is(Sledge::Template::Xslate::create_xslate($option), Sledge::Template::Xslate::create_xslate($option));
