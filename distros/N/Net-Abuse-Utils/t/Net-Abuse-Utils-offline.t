BEGIN { chdir 't' if -d 't' }
use lib '../lib';

use Test::More;
BEGIN { use_ok('Net::Abuse::Utils') }

ok( Net::Abuse::Utils::is_ip('127.0.0.1'),          'is_ip with valid ip' );
ok( !Net::Abuse::Utils::is_ip('192.168.293.3'),     'is_ip with invalid ip' );
ok( Net::Abuse::Utils::is_ip('2600:3c00::2:2001'),  'is_ip with valid v6' );
ok( Net::Abuse::Utils::is_ip('::1'),                'is_ip with localhost' );
ok( !Net::Abuse::Utils::is_ip('2600:3c00::h:2001'), 'is_ip with invalid v6' );

done_testing();
