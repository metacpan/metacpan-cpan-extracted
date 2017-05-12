use warnings;
use strict;

use Test::More tests => 4;

BEGIN {
    use_ok 'Digest::MD5';
    use_ok 'POE';
    use_ok 'POE::Component::Client::TCP';
    use_ok 'POE::Component::Client::Asterisk::Manager';
}
