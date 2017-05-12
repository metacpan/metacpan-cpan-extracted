use Test::More qw(no_plan);
use lib '../lib';

BEGIN {
    use_ok('Net::SRCDS::Queries');
}

my $q = Net::SRCDS::Queries->new;
ok $q->can('new');
ok $q->can('add_server');
ok $q->can('get_all');
ok $q->can('send_challenge');
ok $q->can('send_a2s_info');
ok $q->can('send_a2s_player');
ok $q->can('send_a2s_rules');
ok $q->can('get_result');
ok $q->can('parse_packet');
ok $q->can('parse_a2s_info');
ok $q->can('parse_a2s_player');
ok $q->can('parse_challenge');
