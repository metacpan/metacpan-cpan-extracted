use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;
use Perlmazing;

my $author = 'Francisco Zarabozo';
my $password = md5 $author;
my $enc = aes_encrypt $author, $password;
my $hex = unpack 'H*', $enc;
is $hex, '1aed51298490c97cb801836658b74e7b6997c9bfcd0a3c560a12c227600f46f3', 'aes_encrypt';
my $dec = aes_decrypt $enc, $password;
is $dec, $author, 'aes_decrypt';
