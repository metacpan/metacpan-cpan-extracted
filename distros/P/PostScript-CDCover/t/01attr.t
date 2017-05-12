use Test;
BEGIN { plan tests => 5 }
use PostScript::CDCover;

my $cdc = new PostScript::CDCover;

ok($cdc->cdcolor() == 0xccd8e5);
ok($cdc->cdcolor(0xffff80) == 0xccd8e5);
ok($cdc->cdcolor() == 0xffff80);
ok(!defined($cdc->title()));
ok($cdc->ps() ne '');
