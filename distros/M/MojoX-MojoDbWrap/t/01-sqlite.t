use strict;
use Test::More;
use Test::Exception;
use MojoX::MojoDbWrap;
use Data::Dumper;

subtest sqlite => sub {
   plan skip_all => 'No Mojo::SQLite available'
      unless eval { require Mojo::SQLite };

   my $wrap = MojoX::MojoDbWrap->new(
      db_url => ':memory:',
      migrations_for => {
         'Mojo::SQLite' => <<'END'
-- 1 up
   CREATE TABLE foo (
      myid INTEGER PRIMARY KEY,
      name TEXT UNIQUE,
      other TEXT
   );
-- 1 down
   DELETE TABLE foo;

END
      },
   );

   isa_ok $wrap, 'MojoX::MojoDbWrap';
   isa_ok $wrap->mdb, 'Mojo::SQLite';
   is $wrap->mdb_class, 'Mojo::SQLite', 'mdb_class';
   is $wrap->mdb_module, 'Mojo::SQLite', 'mdb_module';

   lives_ok { $wrap->init } 'call to init';

   my $id;
   lives_ok {
      $id = $wrap->id_or_insert([qw< foo myid >], { name => 'bar' },
         { name => 'bar', other => 'baz' });
   } 'call to id_or_insert';
   ok defined($id), 'identifier is defined';
   diag "created record with id <$id>";

   my $id_again;
   lives_ok {
      $id_again = $wrap->id_or_insert([qw< foo myid >], { name => 'bar' },
         { name => 'bar', other => 'baz' });
   } 'call to id_or_insert, same data as before';
   ok defined($id_again), 'identifier is defined';
   is $id_again, $id, 'retrieved the same id for the same name';

   {
      my $other = $wrap->db->select(foo => undef, { name => 'bar' })->hash->{other};
      is $other, 'baz', 'initial value for other';
   }
};

done_testing();
