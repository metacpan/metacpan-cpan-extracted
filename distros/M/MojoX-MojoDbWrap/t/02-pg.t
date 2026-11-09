use strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MojoX::MojoDbWrap;
use MojoDbWrapTests qw< run_common_tests skip_unless_pg >;

plan skip_all => 'set TEST_PG to a postgresql:// URL to run these tests'
   unless defined $ENV{TEST_PG};
skip_unless_pg();

# private schema, so that we never touch anything else in the database
my $schema = "mojodbwrap_test_${$}_" . time;
my $admin  = Mojo::Pg->new($ENV{TEST_PG});
my $created; # drop only what we created, never a pre-existing schema
END { $admin->db->query("DROP SCHEMA $schema CASCADE") if $created }
$admin->db->query("CREATE SCHEMA $schema");
$created = 1;

subtest pg => sub {
   run_common_tests(
      class    => 'Mojo::Pg',
      new_wrap => sub {
         my $wrap = MojoX::MojoDbWrap->new(db_url => $ENV{TEST_PG}, @_);
         $wrap->mdb->search_path([$schema]);
         return $wrap;
      },
      duplicate_error => qr{duplicate key value violates unique constraint},
      tables          => <<'END',
   CREATE TABLE foo (
      myid SERIAL PRIMARY KEY,
      name TEXT UNIQUE,
      other TEXT
   );
   CREATE TABLE bar (
      id SERIAL PRIMARY KEY,
      name TEXT UNIQUE
   );
   CREATE TABLE pair (
      id SERIAL PRIMARY KEY,
      a TEXT,
      b TEXT,
      v TEXT,
      UNIQUE (a, b)
   );
END
   );
};

done_testing();
