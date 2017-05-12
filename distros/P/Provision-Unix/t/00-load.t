
use strict;
#use warnings;

use English qw/ -no_match_vars /;
use Test::More;

if ( $OSNAME =~ /cygwin|win32|windows/i ) {
    plan skip_all => "doesn't work on windows";
}
else {
    plan tests => 6;
};

use lib 'lib';

BEGIN {
    use_ok('Provision::Unix');
    use_ok('Provision::Unix::User');
    use_ok('Provision::Unix::DNS');
    use_ok('Provision::Unix::Web');
    use_ok('Provision::Unix::Utility');
    use_ok('Provision::Unix::VirtualOS');
}

diag("Testing Provision::Unix $Provision::Unix::VERSION, Perl $], $^X");
