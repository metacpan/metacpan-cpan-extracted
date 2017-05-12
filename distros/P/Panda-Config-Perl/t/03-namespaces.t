use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::Config::Perl;
use FindBin qw($Bin);

my $cfg = Panda::Config::Perl->process($Bin.'/configs/namespaces.conf',{hello => 'world'});

my $my_cfg = {
    'N0' => {},
    'N1' => {
        'var' => 'pizdets',
        'hash' => {
            'key2' => 'value2',
            'key1' => 777,
            'key3' => 100500
        },
        'num' => 11,
        'str' => 'jopa'
    },
    'N2' => {
        'array' => [444, 777, 999, 1000, 2000, 3000, 5000, 100000, 1],
        'var' => 'pizdets2',
        'imported_from_N1' => 777,
        'num' => 22,
        'str' => 'popa'
    },
    'N3' => {
        'array' => ['fuck','fuck','fuck'],
        'num' => 777,
        'str' => 'ass'
    },
    'N4' => {},
    'N5' => {
        'N5' => {
            'var' => 88,
            'N5' => {
                'N5' => {
                    'var' => 999
                },
                'var' => 888
             }
        },
        'var' => 8
    },
    'array' => [100, 101, 102, 103, 104],
    'hello' => 'world',
    'num' => 134,
    'str' => 'root',
};

is (ref($cfg),'HASH');
cmp_deeply($cfg,$my_cfg,"got the right horrible data structure");

done_testing();
