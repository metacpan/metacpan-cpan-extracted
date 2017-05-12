use Test;
BEGIN { plan tests => 4 }
use PostScript::CDCover;

my $c = new PostScript::CDCover;

ok(PostScript::CDCover::_quote_paren('()()') eq "\\(\\)\\(\\)");
my ($r, $g, $b) = PostScript::CDCover::_split_color(0x80a0ff);
ok($r == 128 / 255);
ok($g == 160 / 255);
ok($b == 255 / 255);

