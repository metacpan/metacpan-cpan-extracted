use strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MojoX::MojoDbWrap;
use MojoDbWrapTests qw< run_common_tests skip_unless_sqlite_returning >;

skip_unless_sqlite_returning();

subtest sqlite => sub {
   run_common_tests(
      class           => 'Mojo::SQLite',
      new_wrap        => sub { MojoX::MojoDbWrap->new(db_url => ':memory:', @_) },
      duplicate_error => qr{UNIQUE constraint failed},
      tables          => <<'END',
   CREATE TABLE foo (
      myid INTEGER PRIMARY KEY,
      name TEXT UNIQUE,
      other TEXT
   );
   CREATE TABLE bar (
      id INTEGER PRIMARY KEY,
      name TEXT UNIQUE
   );
   CREATE TABLE pair (
      id INTEGER PRIMARY KEY,
      a TEXT,
      b TEXT,
      v TEXT,
      UNIQUE (a, b)
   );
END
   );
};

done_testing();
