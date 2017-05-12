#
# Test cases for ssh1 keys
#
use Net::SSH::AuthorizedKey;
use Net::SSH::AuthorizedKey::SSH1;
use Test::More;
use Log::Log4perl qw(:easy);

# Log::Log4perl->easy_init($DEBUG);

plan tests => 12;

my $t1key = " 1042 17 123123123";

  # direct
my $pk = Net::SSH::AuthorizedKey::SSH1->parse($t1key);

is($pk->keylen(), "1042", "keylen");
is($pk->key(), "123123123", "key");
is($pk->exponent(), "17", "exponent");
is($pk->email(), "", "email");
is($pk->type(), "ssh-1", "type");
ok($pk->sanity_check(), "sanity check");

  # generic
$pk = Net::SSH::AuthorizedKey->parse($t1key);

is($pk->keylen(), "1042", "keylen");
is($pk->key(), "123123123", "key");
is($pk->exponent(), "17", "exponent");
is($pk->email(), "", "email");
is($pk->type(), "ssh-1", "type");
ok($pk->sanity_check(), "sanity check");
