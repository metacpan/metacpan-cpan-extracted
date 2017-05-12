use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use Panda::Config::Perl;
use FindBin qw($Bin);

my $cfg = Panda::Config::Perl->process($Bin.'/configs/basic.conf');

is (ref($cfg),'HASH');
my $my_cfg = {
          'num1' => 545,
          'num2' => 6000000003,
          'str' => 'jopa',
          'hash' => {
                      'key2' => 'value2',
                      'key1' => 'value1',
                      'key3' => 100500
                    },
          'array' => [1..20]
};

is (ref($cfg),'HASH');
cmp_deeply($cfg,$my_cfg,"got the right horrible nested data structure");

done_testing();
