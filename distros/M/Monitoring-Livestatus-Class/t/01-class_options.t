use strict;
use warnings;
use Test::More tests => 6;
use Data::Dumper;

use_ok('Monitoring::Livestatus::Class');

# single tcp connection
my $class = Monitoring::Livestatus::Class->new( peer => 'localhost:1234', );
isa_ok($class, "Monitoring::Livestatus::Class", 'tcp connection');

# single unix connection
$class = Monitoring::Livestatus::Class->new( peer => '/tmp/unix.socket', );
isa_ok($class, "Monitoring::Livestatus::Class", 'unix connection');

# complex multi config
$class = Monitoring::Livestatus::Class->new(
            peer      => [
                {
                    name => 'DMZ Monitoring',
                    peer => '50.50.50.50:9999',
                },
                {
                    name => 'Local Monitoring',
                    peer => '/tmp/livestatus.socket',
                },
                {
                    name => 'Special Monitoring',
                    peer => '100.100.100.100:9999',
                }
          ]);
isa_ok($class, "Monitoring::Livestatus::Class", 'multi connection');

# keepalive
$class = Monitoring::Livestatus::Class->new( peer => 'localhost:1234', keepalive => 1 );
isa_ok($class, "Monitoring::Livestatus::Class", 'keepalive option');

# verbose
$class = Monitoring::Livestatus::Class->new( peer => 'localhost:1234', verbose => 0 );
isa_ok($class, "Monitoring::Livestatus::Class", 'verbose option');
