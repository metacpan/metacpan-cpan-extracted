use Test::More qw(no_plan);
use ExtUtils::testlib;
use Storable::AMF3 qw();
use lib 't';
use GrianUtils qw(loose);
use strict;
use warnings;

# vim: ts=8 et sw=4 sts=4
dfg();
sub dfg{
    ok( Storable::AMF::Util::total_sv(), "can call total_sv()" );
    is( loose { my $a; my $b = []; } , 0, "not a looser" );
    is( loose { my $a; $a = \$a }, 1, "looser - 1" );
    ok( loose { my $a; my $b = \$a; $a =  [ \$b, 1] } > 0, "looser -2 ");
    ok( loose(\&abc) > 0, "looser -abc" );
}
sub abc{
    my $a;
    my $b =  \$a;
    $a = [\$b];
}
