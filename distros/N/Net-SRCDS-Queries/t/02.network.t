use Test::More qw(no_plan);
use IO::Socket::INET;
use lib '../lib';

use constant INFO_RESULT =>
'ffffffff49076d6f64756c652074657374006c34645f686f73706974616c30315f61706172746d656e74006c6566743464656164004c3444202d20436f2d6f70202d204e6f726d616c00f401000400646c0001312e302e312e3300a08769656d7074792c736f757263656d6f642c636f6f702c7665727375732c737572766976616c00';
use constant CHALLENGE_RESULT => 'ffffffff41f8db8403';
use constant PLAYER_RESULT    => 'ffffffff4401004d6173736100000000007c4a6642';
use constant RULES_RESULT =>
'ffffffff454000627564646861003000636f6f7000300064656174686d61746368003100646563616c6672657175656e6379003130006469726563746f725f61666b5f74696d656f757400343500676f640030006d705f616c6c6f774e5043730031006d705f6175746f63726f7373686169720031006d705f6175746f7465616d62616c616e63650031006d705f633474696d6572003435006d705f66616c6c64616d6167650030006d705f666c6173686c696768740031006d705f666f6f7473746570730031006d705f666f7263657265737061776e0031006d705f667261676c696d69740030006d705f667265657a6574696d650036006d705f667269656e646c79666972650031006d705f6c696d69747465616d730032006d705f6d6178726f756e64730030006d705f726f756e6474696d650035006d705f7374616c656d6174655f656e61626c650030006d705f7465616d6c69737400686772756e743b736369656e74697374006d705f7465616d706c61790030006d705f7465616d735f756e62616c616e63655f6c696d69740031006d705f74696d656c696d69740030006d705f776561706f6e737461790030006e6578746c6576656c0000725f416972626f61745669657744616d70656e44616d7000312e3000725f416972626f61745669657744616d70656e4672657100372e3000725f416972626f6174566965775a48656967687400302e3000725f4a6565705669657744616d70656e44616d7000312e3000725f4a6565705669657744616d70656e4672657100372e3000725f4a656570566965775a4865696768740031302e3000725f56656869636c655669657744616d70656e0031007375727669766f725f6c696d697400340073765f616363656c657261746500350073765f616972616363656c65726174650031300073765f616c6c74616c6b00310073765f626f756e636500300073765f63686561747300300073765f636f6e74616374000073765f666f6f74737465707300310073765f6672696374696f6e00340073765f67726176697479003830300073765f6d6178737065656400313030302e3030303030300073765f6e6f636c6970616363656c657261746500350073765f6e6f636c69706672696374696f6e00340073765f6e6f636c6970737065656400350073765f70617373776f726400300073765f726f6c6c616e676c6500300073765f726f6c6c7370656564003230300073765f73706563616363656c657261746500350073765f737065636e6f636c697000310073765f73706563737065656400330073765f737465616d67726f75700035363534340073765f7374657073697a650031380073765f73746f7073706565640037350073765f74616773005365727665722042726f77736572204a6f696e20456e61626c65640073765f766f696365656e61626c6500310073765f7761746572616363656c65726174650031300073765f77617465726672696374696f6e0031007461756e746672657175656e637900310074765f70617373776f726400300074765f72656c617970617373776f7264003000';

BEGIN {
    use_ok('Net::SRCDS::Queries');
}

my $port = 27014;
my $s    = start_server($port);
SKIP: {
    skip 'skip network test. failed to bind local server' unless $s;
    my $q = Net::SRCDS::Queries->new;
    #warn "sockport = " . $q->{socket}->sockport;

    my $buf;
    my $dest = sockaddr_in $port, inet_aton 'localhost';
    #my $src = sockaddr_in $q->{socket}->sockport, inet_aton 'localhost';

    # send client
    $q->send_a2s_info($dest);
    # recv server
    my $sender = $s->recv( $buf, 65535 );
    my $msg = pack( 'H*', INFO_RESULT );
    $s->send( $msg, 0, $sender );
    # recv client
    sleep 1;
    $q->{socket}->recv( $buf, 65535 );
    my $result = $q->parse_a2s_info($buf);
    my $expect = {
        'secure'    => 1,
        'max'       => 4,
        'players'   => 0,
        'app_id'    => 500,
        'os'        => 'l',
        'dir'       => 'left4dead',
        'map'       => 'l4d_hospital01_apartment',
        'password'  => 0,
        'bots'      => 0,
        'sname'     => 'module test',
        'desc'      => 'L4D - Co-op - Normal',
        'dedicated' => 'd',
        'version'   => 7,
        'port'      => 27015,
        'game_tag'  => 'empty,sourcemod,coop,versus,survival',
        'gversion'  => '1.0.1.3',
        'type'      => 'I'
    };
    is_deeply $result, $expect;

    # send client
    $q->send_challenge($dest);
    # recv server
    $sender = $s->recv( $buf, 65535 );
    $s->send( pack( 'H*', CHALLENGE_RESULT ), 0, $sender );
    # recv client
    sleep 1;
    $q->{socket}->recv( $buf, 65535 );
    $result = $q->parse_challenge($buf);
    $expect = {
        'cnum' => pack( 'H*', 'f8db8403' ),
        'type' => 'A',
    };
    is_deeply $result, $expect;

    # send client
    my $cnum = $result->{cnum};
    $q->send_a2s_player( $dest, $cnum );
    # recv server
    $sender = $s->recv( $buf, 65535 );
    $s->send( pack( 'H*', PLAYER_RESULT ), 0, $sender );
    # recv client
    sleep 1;
    $q->{socket}->recv( $buf, 65535 );
    $result = $q->parse_a2s_player($buf);

    # XXX : unpack( 'f', $xx ); returns different value
    # in some enviromnent.
    is int $result->{player_info}->[0]->{connected}, 57;

    is $result->{player_info}->[0]->{name}, 'Massa';
    is $result->{player_info}->[0]->{kills}, 0;
    is $result->{num_players}, 1;
    is $result->{type}, 'D';

    # send client
    $q->send_a2s_rules( $dest, $cnum );
    # recv server
    $sender = $s->recv( $buf, 65535 );
    $s->send( pack( 'H*', RULES_RESULT ), 0, $sender );
    # recv client
    sleep 1;
    $q->{socket}->recv( $buf, 65535 );
    $result = $q->parse_a2s_rules($buf);
    $expect = {
        'num_rules'  => 64,
        'rules_info' => [
            {
                'value' => '0',
                'name'  => 'buddha'
            },
            {
                'value' => '0',
                'name'  => 'coop'
            },
            {
                'value' => '1',
                'name'  => 'deathmatch'
            },
            {
                'value' => '10',
                'name'  => 'decalfrequency'
            },
            {
                'value' => '45',
                'name'  => 'director_afk_timeout'
            },
            {
                'value' => '0',
                'name'  => 'god'
            },
            {
                'value' => '1',
                'name'  => 'mp_allowNPCs'
            },
            {
                'value' => '1',
                'name'  => 'mp_autocrosshair'
            },
            {
                'value' => '1',
                'name'  => 'mp_autoteambalance'
            },
            {
                'value' => '45',
                'name'  => 'mp_c4timer'
            },
            {
                'value' => '0',
                'name'  => 'mp_falldamage'
            },
            {
                'value' => '1',
                'name'  => 'mp_flashlight'
            },
            {
                'value' => '1',
                'name'  => 'mp_footsteps'
            },
            {
                'value' => '1',
                'name'  => 'mp_forcerespawn'
            },
            {
                'value' => '0',
                'name'  => 'mp_fraglimit'
            },
            {
                'value' => '6',
                'name'  => 'mp_freezetime'
            },
            {
                'value' => '1',
                'name'  => 'mp_friendlyfire'
            },
            {
                'value' => '2',
                'name'  => 'mp_limitteams'
            },
            {
                'value' => '0',
                'name'  => 'mp_maxrounds'
            },
            {
                'value' => '5',
                'name'  => 'mp_roundtime'
            },
            {
                'value' => '0',
                'name'  => 'mp_stalemate_enable'
            },
            {
                'value' => 'hgrunt;scientist',
                'name'  => 'mp_teamlist'
            },
            {
                'value' => '0',
                'name'  => 'mp_teamplay'
            },
            {
                'value' => '1',
                'name'  => 'mp_teams_unbalance_limit'
            },
            {
                'value' => '0',
                'name'  => 'mp_timelimit'
            },
            {
                'value' => '0',
                'name'  => 'mp_weaponstay'
            },
            {
                'value' => '',
                'name'  => 'nextlevel'
            },
            {
                'value' => '1.0',
                'name'  => 'r_AirboatViewDampenDamp'
            },
            {
                'value' => '7.0',
                'name'  => 'r_AirboatViewDampenFreq'
            },
            {
                'value' => '0.0',
                'name'  => 'r_AirboatViewZHeight'
            },
            {
                'value' => '1.0',
                'name'  => 'r_JeepViewDampenDamp'
            },
            {
                'value' => '7.0',
                'name'  => 'r_JeepViewDampenFreq'
            },
            {
                'value' => '10.0',
                'name'  => 'r_JeepViewZHeight'
            },
            {
                'value' => '1',
                'name'  => 'r_VehicleViewDampen'
            },
            {
                'value' => '4',
                'name'  => 'survivor_limit'
            },
            {
                'value' => '5',
                'name'  => 'sv_accelerate'
            },
            {
                'value' => '10',
                'name'  => 'sv_airaccelerate'
            },
            {
                'value' => '1',
                'name'  => 'sv_alltalk'
            },
            {
                'value' => '0',
                'name'  => 'sv_bounce'
            },
            {
                'value' => '0',
                'name'  => 'sv_cheats'
            },
            {
                'value' => '',
                'name'  => 'sv_contact'
            },
            {
                'value' => '1',
                'name'  => 'sv_footsteps'
            },
            {
                'value' => '4',
                'name'  => 'sv_friction'
            },
            {
                'value' => '800',
                'name'  => 'sv_gravity'
            },
            {
                'value' => '1000.000000',
                'name'  => 'sv_maxspeed'
            },
            {
                'value' => '5',
                'name'  => 'sv_noclipaccelerate'
            },
            {
                'value' => '4',
                'name'  => 'sv_noclipfriction'
            },
            {
                'value' => '5',
                'name'  => 'sv_noclipspeed'
            },
            {
                'value' => '0',
                'name'  => 'sv_password'
            },
            {
                'value' => '0',
                'name'  => 'sv_rollangle'
            },
            {
                'value' => '200',
                'name'  => 'sv_rollspeed'
            },
            {
                'value' => '5',
                'name'  => 'sv_specaccelerate'
            },
            {
                'value' => '1',
                'name'  => 'sv_specnoclip'
            },
            {
                'value' => '3',
                'name'  => 'sv_specspeed'
            },
            {
                'value' => '56544',
                'name'  => 'sv_steamgroup'
            },
            {
                'value' => '18',
                'name'  => 'sv_stepsize'
            },
            {
                'value' => '75',
                'name'  => 'sv_stopspeed'
            },
            {
                'value' => 'Server Browser Join Enabled',
                'name'  => 'sv_tags'
            },
            {
                'value' => '1',
                'name'  => 'sv_voiceenable'
            },
            {
                'value' => '10',
                'name'  => 'sv_wateraccelerate'
            },
            {
                'value' => '1',
                'name'  => 'sv_waterfriction'
            },
            {
                'value' => '1',
                'name'  => 'tauntfrequency'
            },
            {
                'value' => '0',
                'name'  => 'tv_password'
            },
            {
                'value' => '0',
                'name'  => 'tv_relaypassword'
            }
        ],
        'type' => 'E'
    };
    is_deeply $result, $expect;
}

sub start_server {
    my $port   = shift;
    my $server = IO::Socket::INET->new(
        Proto     => 'udp',
        LocalPort => $port,
    );
    return $server;
}
