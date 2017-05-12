use Test::More tests => 5;
use IPC::Cmd qw(can_run);

BEGIN{use_ok ('Net::OpenVPN::Launcher');}
ok(my $launcher = Net::OpenVPN::Launcher->new, 'Instantiate launcher object');
SKIP:{
    my $openvpn_path = can_run('openvpn');
    skip 'openvpn binary not found', 3 unless $openvpn_path;
    ok($launcher->start('t/test.conf'), 'Launch OpenVPN program');
    ok($launcher->restart, 'Restart OpenVPN');
    ok($launcher->stop, 'Stop OpenVPN');
}
