# $Id: 00load.t,v 1.1 2004/03/05 16:58:44 jgsmith Exp $

BEGIN { print "1..1\n"; }

eval q{
    use Module::Require qw: require_regex require_glob :;
};

if($@) {
    print "not ok 1";
} else {
    print "ok     1";
}

1;
