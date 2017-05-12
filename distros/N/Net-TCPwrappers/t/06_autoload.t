#
# $Id: 06_autoload.t 151 2004-12-26 22:35:29Z james $
#

use strict;
use warnings;

BEGIN {
    use Test::More;
    use Test::Exception;
    our $tests = 3;
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
}

use_ok 'Net::TCPwrappers';

# make sure that attempts to look up an unknown constant fail
throws_ok { Net::TCPwrappers::foo() }
    qr/foo is not a valid Net::TCPwrappers macro/,
    'look up constant Net::TCPwrappers::foo';

# The AUTOLOAD sub that is created by ExtUtils::Constant::autoload has
# these lines:
#
# ($constname = $AUTOLOAD) =~ s/.*:://;
# croak "&Net::TCPWrappers::constant not defined" if $constname eq 'constant';
#
# but I can't figure out how $AUTOLOAD would get set to a value ending in
# '::constant'.  This makes the coverage reports max out below 100% because
# the true condition of the statement is never tested.
#
# The following test artificially tests that condition
throws_ok {
    $Net::TCPwrappers::AUTOLOAD = 'Net::TCPwrappers::constant';
    Net::TCPwrappers::AUTOLOAD()
} qr/&Net::TCPWrappers::constant not defined/,
"call Net::TCPwrappers::AUTOLOAD to look up 'constant'";

#
# EOF
