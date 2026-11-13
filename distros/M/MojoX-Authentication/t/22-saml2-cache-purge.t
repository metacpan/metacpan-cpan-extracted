use v5.24;
use warnings;
use Test::More;
use File::Temp qw< tempdir >;

use MojoX::Authentication::Model::SAML2::Hash;

# Every SAML2 login attempt stores a request id; an attempt that never
# comes back is never read again. Expired entries must go away anyway,
# otherwise anybody can grow the cache just by hitting the login route.

{
   my $cache = MojoX::Authentication::Model::SAML2::Hash->new;
   $cache->set({ ts => 1 }, "stale-$_", time() - 10) for 1 .. 3;
   $cache->set({ ts => 2 }, 'fresh', time() + 60);
   is_deeply [ keys $cache->_store->%* ], [ 'fresh' ],
      'Hash: expired entries are purged, without reading them';
   is_deeply $cache->get('fresh'), { ts => 2 }, 'Hash: fresh entry kept';
}

SKIP: {
   skip 'MojoX::MojoDbWrap and Mojo::SQLite needed', 2
      unless eval { require Mojo::SQLite; require MojoX::MojoDbWrap; 1 };
   require MojoX::Authentication::Model::SAML2::Db;

   my $path = tempdir(CLEANUP => 1) . '/cache.sqlite';
   my $wmdb = MojoX::MojoDbWrap->new(db_url => "sqlite:$path");
   $wmdb->db->query(
      'CREATE TABLE logged_in (k TEXT, expire INTEGER, data TEXT)');
   my $cache = MojoX::Authentication::Model::SAML2::Db->new(wmdb => $wmdb);

   $cache->set({ ts => 1 }, "stale-$_", time() - 10) for 1 .. 3;
   $cache->set({ ts => 2 }, 'fresh', time() + 60);
   my $keys = $wmdb->db->select(logged_in => ['k'])->arrays->flatten;
   is_deeply $keys->to_array, [ 'fresh' ],
      'Db: expired rows are purged, without reading them';
   is_deeply $cache->get('fresh'), { ts => 2 }, 'Db: fresh row kept';
}

done_testing();
