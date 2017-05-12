use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 3;

use_ok('Monitoring::TT::Render');

my $hash = {
    'ssh'  => '',
    'http' => [80, 8080],
};
my $joined   = Monitoring::TT::Render::join_hash_list($hash);
my $list_exp = 'http=80, http=8080, ssh';
is_deeply($joined, $list_exp, 'hash list') or diag(Dumper($joined));

$hash = {
    'ssh'   => '',
    'http'  => [80, 8080],
    '_test' => [80, 8080],
};
$joined   = Monitoring::TT::Render::join_hash_list($hash, ['^_']);
$list_exp = 'http=80, http=8080, ssh';
is_deeply($joined, $list_exp, 'hash list with exceptions') or diag(Dumper($joined));
