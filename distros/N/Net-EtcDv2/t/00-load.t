use 5.30.0;
use strict;
use warnings;
use Test::More;

plan tests => 7;

BEGIN {
    use_ok('Net::EtcDv2') || print "Bail out!\n";
    use_ok('Net::EtcDv2::Auth' || print "Bail out!\n");
    use_ok('Net::EtcDv2::Auth::Role' || print "Bail out!\n");
    use_ok('Net::EtcDv2::Auth::User' || print "Bail out!\n");
    use_ok('Net::EtcDv2::Node') || print "Bail out!\n";
    use_ok('Net::EtcDv2::Node::Directory' || print "Bail out!\n");
    use_ok('Net::EtcDv2::Node::Key' || print "Bail out!\n");
}
