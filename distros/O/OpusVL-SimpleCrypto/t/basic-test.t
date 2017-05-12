use Test::Most;

use OpusVL::SimpleCrypto;

my $s = OpusVL::SimpleCrypto->GenerateKey;
explain $s->key_string;

ok my $ct = $s->encrypt('Test'), 'Succesful encryption';
explain $ct;
is $s->decrypt($ct), 'Test', 'Successful decryption';
my $second = $s->encrypt('Test');
isnt $ct, $second, 'Shouldn\'t encrypt to the same thing twice';

my $long_data = <<"HEREDOC";
This is a long peice of text that can be used
to test the encryption to check it works as intended.
Or not if that's the case.
Honestly, how long?
HEREDOC

is $long_data, $s->decrypt($s->encrypt($long_data)), 'Test long text';
explain $s->encrypt($long_data);

my $loaded_key = OpusVL::SimpleCrypto->new({ key_string => $s->key_string });
is $loaded_key->decrypt($ct), 'Test', 'Decrypt using loaded key';

done_testing;
