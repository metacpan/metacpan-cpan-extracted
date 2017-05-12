use 5.012;
use warnings;
use Test::More tests => 3;
use Panda::Lib;

my $data = "hello world";
my $key = "mykey";

# correct crypt
my $ret = Panda::Lib::crypt_xor($data, $key);
ok($ret eq check_xor($data, $key));

# vice-versa
ok(Panda::Lib::crypt_xor($ret, $key) eq $data);

#large strings
my $large_data = $data x 10000;
$ret = Panda::Lib::crypt_xor($large_data, $key);
ok($ret eq check_xor($large_data, $key));

sub check_xor {
    my ($data, $key) = @_;
    my $ret = '';
    my $datalen = length($data);
    my $keylen = length($key);
    for (my $i = 0; $i < $datalen; $i++) {
        $ret .= substr($data, $i, 1) ^ substr($key, $i % $keylen, 1);
    }
    return $ret;
}
