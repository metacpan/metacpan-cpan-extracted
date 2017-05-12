use strict;
use warnings;
use Test::More tests => 21;
use Data::Dumper;

use_ok('Monitoring::Livestatus::Class::Lite');

# single tcp connection
my $class = Monitoring::Livestatus::Class::Lite->new( peer => 'localhost:1234', );
isa_ok($class, "Monitoring::Livestatus::Class::Lite", 'tcp connection');
isa_ok($class->{'backend_obj'}, "Monitoring::Livestatus");
isa_ok($class->{'backend_obj'}->{'CONNECTOR'}, "Monitoring::Livestatus::INET");
is($class->{'backend_obj'}->{'CONNECTOR'}->{'peer'}, "localhost:1234");

# single unix connection
$class = Monitoring::Livestatus::Class::Lite->new( peer => '/tmp/unix.socket', );
isa_ok($class, "Monitoring::Livestatus::Class::Lite", 'unix connection');
isa_ok($class->{'backend_obj'}, "Monitoring::Livestatus");
isa_ok($class->{'backend_obj'}->{'CONNECTOR'}, "Monitoring::Livestatus::UNIX");
is($class->{'backend_obj'}->{'CONNECTOR'}->{'peer'}, "/tmp/unix.socket");

# verbose
$class = Monitoring::Livestatus::Class::Lite->new( peer => 'localhost:1234', verbose => 0 );
isa_ok($class, "Monitoring::Livestatus::Class::Lite", 'verbose option');
isa_ok($class->{'backend_obj'}, "Monitoring::Livestatus");
isa_ok($class->{'backend_obj'}->{'CONNECTOR'}, "Monitoring::Livestatus::INET");
is($class->{'backend_obj'}->{'CONNECTOR'}->{'peer'}, "localhost:1234");

# simple
$class = Monitoring::Livestatus::Class::Lite->new('localhost:1234');
isa_ok($class, "Monitoring::Livestatus::Class::Lite", 'simple tcp connection');
isa_ok($class->{'backend_obj'}, "Monitoring::Livestatus");
isa_ok($class->{'backend_obj'}->{'CONNECTOR'}, "Monitoring::Livestatus::INET");
is($class->{'backend_obj'}->{'CONNECTOR'}->{'peer'}, "localhost:1234");

# single tcp connection as hash
$class = Monitoring::Livestatus::Class::Lite->new({ peer => 'localhost:1234' });
isa_ok($class, "Monitoring::Livestatus::Class::Lite", 'tcp connection');
isa_ok($class->{'backend_obj'}, "Monitoring::Livestatus");
isa_ok($class->{'backend_obj'}->{'CONNECTOR'}, "Monitoring::Livestatus::INET");
is($class->{'backend_obj'}->{'CONNECTOR'}->{'peer'}, "localhost:1234");
