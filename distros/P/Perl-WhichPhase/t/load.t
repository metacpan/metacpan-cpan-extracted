# $Id: load.t,v 1.1 2002/01/07 15:00:50 jgsmith Exp $

BEGIN { print "1..1\n"; }

no warnings;

eval {
    use Perl::WhichPhase qw: :;
};

if($@) {
    print "not ok 1";
} else {
    print "ok     1";
}

1;
