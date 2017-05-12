use Test::Most;

use OpusVL::SimpleCrypto;

my $s = OpusVL::SimpleCrypto->GenerateKey;
explain $s->key_string;

ok my $ct = $s->encrypt_deterministic('Test'), 'Succesful encryption';
explain $ct;
is $s->decrypt($ct), 'Test', 'Successful decryption';
my $second = $s->encrypt_deterministic('Test');
is $ct, $second, 'Should end up with the same thing';

my $long_data = <<"HEREDOC";
This is a long peice of text that can be used
to test the encryption to check it works as intended.
Or not if that's the case.
Honestly, how long?
HEREDOC

is $long_data, $s->decrypt($s->encrypt($long_data)), 'Test long text';
explain $s->encrypt($long_data);
$long_data .= ' ';
# FIXME: ideally check that these are massively different
# rather than just eyeballing it.
explain $s->encrypt($long_data);

my $loaded_key = OpusVL::SimpleCrypto->new({ 
    key_string => $s->key_string, 
    deterministic_salt_string => $s->deterministic_salt_string 
});
is $loaded_key->decrypt($ct), 'Test', 'Decrypt using loaded key';

# prove we can do the fundamental thing we need this function for
# and search a list for a key.
my $data = [
    { name => '100001' , email => 'test1@opusvl.com' },
    { name => '100002', email => 'test2@opusvl.com' },
    { name => '100003', email => 'test3@opusvl.com' },
    { name => '100004', email => 'test4@opusvl.com' },
];
map { $_->{name} = $loaded_key->encrypt_deterministic($_->{name}) } @$data;

my @items = grep { $_->{name} eq $loaded_key->encrypt_deterministic('100002') } @$data;
is scalar @items, 1, 'Should have found just one item';
is $items[0]->{email}, 'test2@opusvl.com', 'Should have found correct item';
explain @items;


done_testing;

