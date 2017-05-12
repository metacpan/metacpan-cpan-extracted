use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::Config::Perl;
use FindBin qw($Bin);

my $cfg = Panda::Config::Perl->process($Bin.'/configs/merge.conf',{hello => 'world'});
my $my_cfg={
    'root' => {
        'db' => {
            'password' => 1234,
            'host' => '',
            'user' => '',
            'A' => 5
         },
         'inner' => {a => 1, b => 2, c => 3, d => 4}, # checks sassign op -> merge in inner if
    },
    'hello' => 'world',
    'db' => {
        'host' => 'another.host.com',
        'password' => 'otherpass',
        'B' => 6,
        'user' => 'another_user',
        'A' => 7,
     },
};

is (ref($cfg),'HASH');
cmp_deeply($cfg,$my_cfg,"got the right horrible data structure");

done_testing();
