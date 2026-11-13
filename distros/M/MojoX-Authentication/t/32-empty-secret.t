use v5.24;
use warnings;
use Test::More;
use experimental qw< signatures >;
use File::Temp qw< tempdir >;

use MojoX::Authentication::Model::Hash;

# With secrets_are_cleartext, a record without a secret must not end up
# with the hash of an empty string: that would let anyone in with an empty
# password. Records with a secret must still be hashed and work.

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

# a refused password dies (it ends the login), count it as "no"
sub can_login ($model, $name, $password) {
   return eval { $model->validate_user(undef, $name, $password, {}) };
}

{
   my $hash = MojoX::Authentication::Model::Hash->create({},
      db => [
         { username => 'foo', secret => 'right' },
         { username => 'svc' },
      ],
      secrets_are_cleartext => 1,
   );

   is can_login($hash, 'foo', 'right'), 'foo', 'Hash: right password works';
   ok !can_login($hash, 'foo', 'wrong'), 'Hash: wrong password fails';
   isnt $hash->load_user(undef, 'foo')->{secret}, 'right',
      'Hash: cleartext secret is not kept in memory';

   ok !can_login($hash, 'svc', ''), 'Hash: no secret, empty password fails';
   ok !can_login($hash, 'svc', undef),
      'Hash: no secret, undefined password fails';

   $hash->save_user({ username => 'new' }, 1);
   ok !can_login($hash, 'new', ''),
      'Hash: saved without secret, empty password fails';

   $hash->save_user({ username => 'new2', secret => 'pw' }, 1);
   is can_login($hash, 'new2', 'pw'), 'new2',
      'Hash: saved with cleartext secret, password works';
}

SKIP: {
   skip 'MojoX::MojoDbWrap 0.100 and Mojo::SQLite needed', 3
      unless eval {
         require Mojo::SQLite;
         require MojoX::MojoDbWrap;
         MojoX::MojoDbWrap->VERSION('0.100');
         1;
      };
   require MojoX::Authentication::Model::Db;

   my $path = tempdir(CLEANUP => 1) . '/users.sqlite';
   my $wmdb = MojoX::MojoDbWrap->new(db_url => "sqlite:$path");
   $wmdb->db->query('CREATE TABLE account '
      . '(id INTEGER PRIMARY KEY, username TEXT UNIQUE, secret TEXT)');
   my $db = MojoX::Authentication::Model::Db->new(wmdb => $wmdb);

   $db->save_user({ username => 'svc' }, 1);
   ok !can_login($db, 'svc', ''),
      'Db: saved without secret, empty password fails';

   $db->save_user({ username => 'foo', secret => 'right' }, 1);
   is can_login($db, 'foo', 'right'), 'foo',
      'Db: saved with cleartext secret, password works';
   ok !can_login($db, 'foo', ''), 'Db: empty password fails';
}

done_testing();
