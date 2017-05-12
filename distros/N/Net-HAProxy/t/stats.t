use strict;
use warnings;
use Test::More skip_all => 'TODO';
use Net::HAProxy;

my $socket = '/var/run/haproxy-services.sock';

my $haproxy = Net::HAProxy->new(
    socket => $socket
);

isa_ok $haproxy, 'Net::HAProxy';

__END__
my $res =  $haproxy->stats;

for my $row (grep { $_->{pxname} =~ /robin/} @$res) {
    diag join ' | ', , $row->{pxname}, $row->{svname} ;
}

is ref($haproxy->info()), 'HASH';
diag Dumper $haproxy->errors();
diag Dumper $haproxy->sessions;

$haproxy->enable_server('robin-trunk.listing', 'port_20740');

diag $haproxy->set_weight('robin-trunk.listing', 'port_20740', 100);
