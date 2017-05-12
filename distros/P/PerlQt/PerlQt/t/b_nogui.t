
BEGIN { print "1..6\n" }

use Qt;
use Qt::constants;

eval {my $c = Qt::TextCodec::codecForLocale()};

print +$@ ? "not ok\n" : "ok 1\n";

eval {my $s = Qt::Variant( Qt::DateTime::currentDateTime() ) };

print +$@ ? "not ok\n" : "ok 2\n";

my $ret;
eval {$ret = Qt::Point(20,20); $ret += Qt::Point(10,10); $ret *= 2 ; $ret /= 3 };

print +$@ ? "not ok\n" : "ok 3\n";

eval { $ret = ($ret->x != 20 or $ret->y != 20) ? 1 : 0 };

print +($@ || $ret) ? "not ok\n" : "ok 4\n";   

eval { my $z = Qt::GlobalSpace::qVersion() };

if( $@ )
{
    print "ok 5 # skip Smoke version too old\n";
    print "ok 6 # skip Smoke version too old\n";
}
else
{
    eval{  my $p = Qt::Point( 20, 20 );
           my $p2 = Qt::Point( 30, 30 );
           $p = $p + $p2 + $p;
           $p2 = $p * 2;
           $p2 = -$p2;
           $ret = ($p2->x != -140 or $p2->y != -140) ? 1 : 0
    };
    print +($@ || $ret) ? "not ok\n" : "ok 5\n";

    eval {
        $str = "Fooooooooooo";
        $ts = Qt::TextStream( $str, IO_WriteOnly );
        $ts << "pi = " << 3.14;
    };
    print +($str eq "pi = 3.14ooo") ? "ok 6\n":"not ok\n";
}
