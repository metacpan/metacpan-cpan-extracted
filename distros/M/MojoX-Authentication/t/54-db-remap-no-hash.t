use v5.24;
use warnings;
use Test::More;
use File::Temp qw< tempdir >;

for my $module (qw< MojoX::MojoDbWrap Mojo::SQLite >) {
   eval "require $module; 1" or plan skip_all => "$module not available";
}
plan skip_all => 'MojoX::MojoDbWrap 0.100 or later needed'
   unless eval { MojoX::MojoDbWrap->VERSION('0.100'); 1 };

use MojoX::Authentication::Model;

# The stored secret lives under key_for_secret (here a "userpass" column)
# and protected_keys hold more secret material: remaps can neither read
# nor change them, and current_user never carries them, whatever the
# remaps try (copying out, overwriting, in ARRAY, HASH or CODE form).

my $path = tempdir(CLEANUP => 1) . '/users.sqlite';
my $wmdb = MojoX::MojoDbWrap->new(db_url => "sqlite:$path");
$wmdb->db->query('CREATE TABLE account (id INTEGER PRIMARY KEY, '
   . 'username TEXT UNIQUE, userpass TEXT, totp_seed TEXT, fullname TEXT)');

my %seen_by_code;
my $model = MojoX::Authentication::Model->new(
   providers => [
      {
         name  => 'my-db',
         class => 'MojoX::Authentication::Model::Db',
         args  => {
            wmdb           => $wmdb,
            key_for_secret => 'userpass',
            protected_keys => [ 'totp_seed' ],
            remaps         => [
               [ copy1 => 'userpass', seed1 => 'totp_seed' ],
               { okey => 'copy2', ikey => 'userpass' },
               sub {
                  my ($r, $backwards) = @_;
                  return if $backwards;
                  %seen_by_code = map { $_ => $r->{$_} } qw< userpass totp_seed >;
                  $r->{copy3}     = $r->{userpass};
                  $r->{userpass}  = 'overwritten';
                  $r->{totp_seed} = 'overwritten';
               },
            ],
         },
      },
   ],
);
my $db = $model->provider_named('my-db');

eval {
   $db->save_user({ username => 'baz', userpass => 'right',
      totp_seed => 'SEED', fullname => 'Baz' }, 1);
};
is $@, '', 'save_user through the remaps does not die';
my $row = $wmdb->db->select(account => '*', { username => 'baz' })->hash // {};
like $row->{userpass}, qr{\A\$argon2}, 'the secret is hashed in key_for_secret';
is $row->{totp_seed}, 'SEED', 'a protected key is saved as given';

is eval { $model->validate_user(undef, 'baz', 'right', {}) }, 'my-db/baz',
   'the password is checked against key_for_secret, remaps did not change it';
is eval { $model->validate_user(undef, 'baz', 'overwritten', {}) }, undef,
   'the value a remap tried to set is not the secret';

is_deeply \%seen_by_code, { userpass => undef, totp_seed => undef },
   'a CODE remap does not see the protected keys';

my $user = $model->load_user(undef, 'my-db/baz');
my $data = ($user // {})->{data} // {};
is $data->{fullname}, 'Baz', 'current_user has the user data';
is_deeply [ grep { exists $data->{$_} } qw< userpass totp_seed > ], [],
   'current_user has no protected keys';
is_deeply [ grep { defined $data->{$_} } qw< copy1 copy2 copy3 seed1 > ], [],
   'current_user has no copies of protected keys made by remaps';
is_deeply [ grep { ($data->{$_} // '') =~ m{\$argon2|SEED} } keys $data->%* ], [],
   'current_user holds no secret material, under any key';

# Hash provider, same contract without remaps
$model = MojoX::Authentication::Model->new(
   providers => [
      {
         class => 'MojoX::Authentication::Model::Hash',
         args  => { db => { foo => { password => 'right', fullname => 'Foo' } },
                    key_for_secret => 'password', secrets_are_cleartext => 1 },
      },
   ],
);
is eval { $model->validate_user(undef, 'foo', 'right', {}) }, 'hashy/foo',
   'Hash: the password is checked against key_for_secret';
$data = ($model->load_user(undef, 'hashy/foo') // {})->{data} // {};
is $data->{fullname}, 'Foo', 'Hash: current_user has the user data';
ok !exists($data->{password}), 'Hash: current_user has no key_for_secret';

done_testing();
