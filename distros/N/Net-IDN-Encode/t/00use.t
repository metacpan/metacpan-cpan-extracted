use strict;
use Test::More tests => 1 + 5;
use Test::NoWarnings;

use_ok 'Net::IDN::Encode';
use_ok 'Net::IDN::Punycode';
use_ok 'Net::IDN::Punycode::PP';

use_ok 'Net::IDN::UTS46';
use_ok 'Net::IDN::UTS46::_Mapping';

exit(0);
