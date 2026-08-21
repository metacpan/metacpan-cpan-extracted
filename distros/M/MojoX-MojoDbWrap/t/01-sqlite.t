use strict;
use Test::More;
use Test::Exception;
use MojoX::MojoDbWrap;
use Data::Dumper;

subtest sqlite => sub {
   plan skip_all => 'No Mojo::SQLite available'
      unless eval {
         require Mojo::SQLite;
         Mojo::SQLite->VERSION('2.000');
      };

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

   # unconditional insert here
   my $id_new;
   lives_ok {
      $id_new = $wrap->insert([qw< foo myid >],
         { name => 'baz', other => 'galook' });
   } 'call to insert, got an identifier back';
   ok defined($id_new), 'identifier of new item is defined';

   $id_again = undef;
   lives_ok {
      $id_again = $wrap->id_of([qw< foo myid >], { name => 'baz' });
   } 'call to id_of, retrieving new item';
   ok defined($id_again), 'identifier is defined';
   is $id_again, $id_new, 'retrieved the same id for the same name';

   {
      my $other = $wrap->db->select(foo => undef, { name => 'baz' })->hash->{other};
      is $other, 'galook', 'initial value for other (in baz)';
   }

   throws_ok {
      my $none_really = $wrap->insert([qw< foo myid >],
         { name => 'baz', other => 'galook' });
   } qr{UNIQUE constraint failed}, 'call to insert with conflicting values, got an error';

   $id_again = undef;
   lives_ok {
      $id_again = $wrap->insert([qw< foo myid >],
         { name => 'baz', other => 'fizzbuzz' },
         { on_conflict => [ name => { other => 'fizzbuzz' } ]});
   } 'upsert, explicit with on_conflict';
   ok defined($id_again), 'identifier is defined';
   is $id_again, $id_new, 'retrieved the same id for the same name';

   {
      my $other = $wrap->db->select(foo => undef, { name => 'baz' })->hash->{other};
      is $other, 'fizzbuzz', 'new value for other (in baz)';
   }

   $id_again = undef;
   lives_ok {
      $id_again = $wrap->upsert([qw< foo myid >],
         { name => 'baz', other => 'buzzmazz' },
         { conflicting => 'name' });
   } 'upsert, with upsert method';
   ok defined($id_again), 'identifier is defined';
   is $id_again, $id_new, 'retrieved the same id for the same name';

   {
      my $other = $wrap->db->select(foo => undef, { name => 'baz' })->hash->{other};
      is $other, 'buzzmazz', 'new value for other (in baz)';
   }
};

done_testing();
