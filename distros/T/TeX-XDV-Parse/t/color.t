use strict;
use warnings;
use Test::More;
use Text::Diff ();
BEGIN { plan tests => 4 }
use_ok('TeX::XDV::Print' );

my $xdv = new_ok( 'TeX::XDV::Print', ['t/tex/color.xdv'] );

open OUT, '> t/tex/color.out';
select OUT;

$xdv->parse;
ok( 1, 'parse' );

select STDOUT;
close OUT;

{
    local $/;
    open IN,  '< t/tex/color.out';
    open CMP, '< t/tex/color.cmp';
    my $out = <IN>;
    my $cmp = <CMP>;

    my $d = Text::Diff::diff( \$cmp, \$out );
    ok( $d eq '', 'diff' ) or note( $d );
}

