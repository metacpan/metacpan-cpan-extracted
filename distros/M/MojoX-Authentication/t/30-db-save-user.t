use v5.24;
use warnings;
use Test::More;
use File::Temp qw< tempdir >;

for my $module (qw< MojoX::MojoDbWrap Mojo::SQLite >) {
   eval "require $module; 1" or plan skip_all => "$module not available";
}

# Model::Db relies on upsert with "conflicting", available since 0.100
plan skip_all => 'MojoX::MojoDbWrap 0.100 or later needed'
   unless eval { MojoX::MojoDbWrap->VERSION('0.100'); 1 };

use MojoX::Authentication::Model::Db;

my $path = tempdir(CLEANUP => 1) . '/users.sqlite';
my $wmdb = MojoX::MojoDbWrap->new(db_url => "sqlite:$path");
$wmdb->db->query(
   'CREATE TABLE account (id INTEGER PRIMARY KEY, username TEXT UNIQUE, secret TEXT)');
$wmdb->db->insert(account => { username => 'bar', secret => 'pre' });

my $model = MojoX::Authentication::Model::Db->new(wmdb => $wmdb);

my $user = eval { $model->load_user(undef, 'bar') };
is $@, '', 'load_user does not die';
is $user && $user->{secret}, 'pre', 'load_user finds an existing record';

{
   eval { $model->save_user({ username => 'foo', secret => 'hashed' }) };
   is $@, '', 'save_user does not die';

   $user = eval { $model->load_user(undef, 'foo') };
   is $user && $user->{secret}, 'hashed', 'saved user can be loaded back';

   # same name again: must update in place, not insert or fail
   eval { $model->save_user({ username => 'foo', secret => 'changed' }) };
   is $@, '', 'save_user on an existing user does not die';

   $user = eval { $model->load_user(undef, 'foo') };
   is $user && $user->{secret}, 'changed', 'existing user is updated';
}

done_testing();
