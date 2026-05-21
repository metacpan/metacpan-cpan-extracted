use strict;
use warnings;
use Test::More;

use lib 'lib';
use lib 't/lib';

use Qmail::Deliverable ':all';
$Qmail::Deliverable::qmail_dir = 't/fixtures';
Qmail::Deliverable::reread_config();

is qmail_local('alice'), 'alice', 'bare local returns input unchanged';

is qmail_local('alice@sub.example.com'), 'alice', 'address in locals returns the localpart';

is qmail_local('alice@host.example.org'), 'alice', 'second locals entry works';

is qmail_local('alice@example.com'), 'example.com-alice', 'virtualdomain prepends per the rule';

is qmail_local('whoever@catchall.example'), 'catchall-whoever', 'second virtualdomain entry works';

is qmail_local('user@foo.wild.org'), 'wild-user', 'wildcard .wild.org prepends "wild-"';

is qmail_local('user@a.b.c.wild.org'), 'wild-user', 'wildcard matches deep subdomains';

is qmail_local('user@wild.org'), 'wild-user', 'wildcard also matches the bare wild.org';

is qmail_local('user@unknown.test'), undef, 'non-local domain returns undef';

is qmail_local('Alice@Sub.Example.COM'), 'alice', 'input is lowercased';

is qmail_local('alice@sub.example.com.'), 'alice', 'trailing dot is tolerated';

done_testing();
