#
# Test cases for ssh2 keys
#
use Net::SSH::AuthorizedKey;
use Net::SSH::AuthorizedKey::SSH2;
use Test::More;
use Log::Log4perl qw(:easy);

# Log::Log4perl->easy_init($DEBUG);

plan tests => 10;

my $t2key = 'ssh-rsa AAAAB3NzaCKK7696k6U= bar@foo.ms.com';

  # specific
my $pk = Net::SSH::AuthorizedKey::SSH2->parse($t2key);

is($pk->encryption(), "ssh-rsa", "encryption");
is($pk->key(), "AAAAB3NzaCKK7696k6U=", "key");
is($pk->email(), 'bar@foo.ms.com', "email");
is($pk->type(), "ssh-2", "type");
ok($pk->sanity_check(), "sanity check");

  # generic
$pk = Net::SSH::AuthorizedKey->parse($t2key);

is($pk->encryption(), "ssh-rsa", "encryption");
is($pk->key(), "AAAAB3NzaCKK7696k6U=", "key");
is($pk->email(), 'bar@foo.ms.com', "email");
is($pk->type(), "ssh-2", "type");
ok($pk->sanity_check(), "sanity check");
