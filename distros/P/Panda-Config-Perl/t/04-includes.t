use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::Config::Perl;
use FindBin qw($Bin);

my $cfg = Panda::Config::Perl->process($Bin.'/configs/includes.conf',{hello => 'world'});
my $my_cfg = {
    'xx' => 'zz',
    'root' => {
        'N1' => {
            'var' => 'jopa1',
            'hash' => {
                'key1' => 'jopa1',
                'key2' => 'jopa1'
            }
        },
        'N2' => {
            'hash' => {
                'key2' => 'jopa2',
                'key1' => 'jopa2'
             },
             'var' => 'jopa2'
         },
         'N3' => {
             'hash' => {
                 'key1' => 'jopa3',
                 'key2' => 'jopa3'
             },
             'var' => 'jopa3'
         },
         'hello' => 'world2',
         'ohdear' => {
             'fuck' => {
                 'yeah' => 'baby'
              }
         },
         'hash' => {
             'key3' => 100500,
             'key1' => 'value1',
             'key2' => 'value2'
         },
                  'num' => 55,
         'array' => [270..290],
         'var' => 'jopa4',
	 'n1' => 100,
	 'n2' => 200,
      },
      'hi' => {
          'xxx' => 'yyy'
      },
      'hello' => 'world',
};

is (ref($cfg),'HASH');
cmp_deeply($cfg,$my_cfg,"got the right horrible data structure");

done_testing();
