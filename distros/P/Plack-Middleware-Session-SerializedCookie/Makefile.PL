use strict;
use warnings;
use inc::Module::Install;

name 'Plack-Middleware-Session-SerializedCookie';
all_from 'lib/Plack/Middleware/Session/SerializedCookie.pm';
license 'perl';

# prereqs
requires 'Plack' => '0';

# things the tests need
test_requires 'Test::More' => '0.88';

no_index directory => 'eg';

WriteAll;

