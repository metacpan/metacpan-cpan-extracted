use Test;
BEGIN { plan tests => 1 }
use PostScript::CDCover;

my $c = new PostScript::CDCover;

ok(-f $c->ps());
