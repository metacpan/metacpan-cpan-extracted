use v5.24;
use warnings;
use Test::More;
use File::Temp qw< tempdir >;

for my $module (qw< MojoX::MojoDbWrap Mojo::SQLite >) {
   eval "require $module; 1" or plan skip_all => "$module not available";
}

use MojoX::Authentication::Model::SAML2::Db;

my $path = tempdir(CLEANUP => 1) . '/cache.sqlite';
my $wmdb = MojoX::MojoDbWrap->new(db_url => "sqlite:$path");
$wmdb->db->query('CREATE TABLE logged_in (k TEXT, expire INTEGER, data TEXT)');

my $cache = MojoX::Authentication::Model::SAML2::Db->new(wmdb => $wmdb);

my $got = eval { $cache->get('missing') };
is $@, '', 'get on a missing key does not die';
is $got, undef, 'get on a missing key returns nothing';

$cache->set({ foo => 'bar' }, 'present', time() + 60);
$got = eval { $cache->get('present') };
is $@, '', 'get on a present key does not die';
is_deeply $got, { foo => 'bar' }, 'get on a present key returns the data';

done_testing();
