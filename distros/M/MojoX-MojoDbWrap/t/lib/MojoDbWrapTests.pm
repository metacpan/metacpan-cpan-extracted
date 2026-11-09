package MojoDbWrapTests;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Exporter 'import';
our @EXPORT_OK = qw<
   run_common_tests skip_unless_pg skip_unless_sqlite
   skip_unless_sqlite_returning
>;

# skip_all helpers, minimum versions in one place
sub skip_unless_pg {
   plan skip_all => 'No Mojo::Pg available'
      unless eval { require Mojo::Pg; Mojo::Pg->VERSION('5.0') };
}

sub skip_unless_sqlite {
   plan skip_all => 'No Mojo::SQLite available'
      unless eval { require Mojo::SQLite; Mojo::SQLite->VERSION('4.000') };
}

# default_inserter needs RETURNING, i.e. SQLite 3.35+
sub skip_unless_sqlite_returning {
   skip_unless_sqlite();
   my $v = Mojo::SQLite->new(':memory:')->db->dbh->{sqlite_version};
   plan skip_all => "SQLite $v lacks RETURNING (needs 3.35.0+)"
      if sprintf('%03d%03d', (split /\./, $v)[0, 1]) lt '003035';
}

# Scenarios shared by all DB engines, so that they stay aligned. Arguments:
# - class:           expected wrapped class, e.g. Mojo::SQLite
# - new_wrap:        sub receiving constructor args (except db_url) and
#                    returning a MojoX::MojoDbWrap object
# - tables:          engine-specific DDL creating tables foo, bar and pair
#                    (see the engine test files for the expected columns)
# - duplicate_error: regex matching the engine's unique violation error
sub run_common_tests {
   my %args = @_;
   my ($class, $new_wrap, $tables, $duplicate_error) =
      @args{qw< class new_wrap tables duplicate_error >};
   my $foo = [qw< foo myid >];

   my $wrap = $new_wrap->(migrations_for => { $class => <<"END" });
-- 1 up
$tables
-- 1 down
   DROP TABLE pair;
   DROP TABLE bar;
   DROP TABLE foo;
END

   isa_ok $wrap, 'MojoX::MojoDbWrap';
   isa_ok $wrap->mdb, $class;
   is $wrap->mdb_class, $class, 'mdb_class';
   is $wrap->mdb_module, $class, 'mdb_module';
   isa_ok $wrap->db, "${class}::Database";

   my $retval;
   lives_ok { $retval = $wrap->init } 'call to init';
   is $retval, $wrap, 'init returns the object itself';

   my $count = sub { $wrap->db->query('SELECT count(*) FROM foo')->array->[0] };

   is $wrap->id_of($foo, { name => 'bar' }), undef,
      'id_of on a missing record returns undef';

   my $id;
   lives_ok {
      $id = $wrap->id_or_insert($foo, { name => 'bar' },
         { name => 'bar', other => 'baz' });
   } 'call to id_or_insert';
   ok defined($id), 'identifier is defined';
   is $count->(), 1, 'one record inserted';

   my $id_again;
   lives_ok {
      $id_again = $wrap->id_or_insert($foo, { name => 'bar' },
         { name => 'bar', other => 'baz' });
   } 'call to id_or_insert, same data as before';
   is $id_again, $id, 'retrieved the same id for the same name';
   is $count->(), 1, 'no further record inserted';
   is $wrap->db->select(foo => ['other'], { name => 'bar' })->hash->{other},
      'baz', 'initial value for other (via select)';

   # unconditional insert here
   my $id_new;
   lives_ok {
      $id_new = $wrap->insert($foo, { name => 'baz', other => 'galook' });
   } 'call to insert';
   ok defined($id_new), 'identifier of new item is defined';
   isnt $id_new, $id, 'new item has a different identifier';
   is $wrap->id_of($foo, { name => 'baz' }), $id_new,
      'id_of retrieves the new item';
   is $wrap->db->select(foo => ['other'], { name => 'baz' })->hash->{other},
      'galook', 'initial value for other (in baz)';

   throws_ok {
      $wrap->insert($foo, { name => 'baz', other => 'galook' });
   } $duplicate_error, 'call to insert with conflicting values, got an error';

   # options for select, two records share the same "other"
   my $id_d1 = $wrap->insert($foo, { name => 'd1', other => 'dup' });
   my $id_d2 = $wrap->insert($foo, { name => 'd2', other => 'dup' });
   is $wrap->id_of($foo, { other => 'dup' }, { order_by => { -asc => 'myid' } }),
      $id_d1, 'id_of with select options (ascending)';
   is $wrap->id_of($foo, { other => 'dup' }, { order_by => { -desc => 'myid' } }),
      $id_d2, 'id_of with select options (descending)';
   my $n_before = $count->();
   is $wrap->id_or_insert($foo, { other => 'dup' }, { name => 'd3', other => 'dup' },
         { select => { order_by => { -desc => 'myid' } } }),
      $id_d2, 'id_or_insert with select options';

   # legacy SQL::Abstract sort hashes (accepted on 0.005) are rejected
   for my $dir (qw< -asc -desc >) {
      throws_ok { $wrap->id_of($foo, { other => 'dup' }, { $dir => 'myid' }) }
         qr{\Aid_of: old-style sort hashes are unsupported, use order_by},
         "id_of rejects a legacy sort hash ($dir)";
      is $@->code, 400, "legacy sort hash in id_of is code 400 ($dir)";
      throws_ok {
         $wrap->id_or_insert($foo, { other => 'dup' },
            { name => 'd3', other => 'dup' }, { select => { $dir => 'myid' } });
      } qr{\Aid_or_insert: old-style sort hashes are unsupported, use order_by},
         "id_or_insert rejects a legacy sort hash as select options ($dir)";
      is $@->code, 400, "legacy sort hash in id_or_insert is code 400 ($dir)";
   }
   is $count->(), $n_before, 'id_or_insert with select options inserted nothing';

   # updates of an existing record must return *its* id, not the id of the
   # latest inserted record (d2 above)
   $id_again = undef;
   lives_ok {
      $id_again = $wrap->insert($foo, { name => 'baz', other => 'fizzbuzz' },
         { on_conflict => [ name => { other => 'fizzbuzz' } ] });
   } 'upsert, explicit with on_conflict';
   is $id_again, $id_new, 'retrieved the id of the updated record';
   is $wrap->db->select(foo => ['other'], { name => 'baz' })->hash->{other},
      'fizzbuzz', 'new value for other (in baz)';

   $id_again = undef;
   lives_ok {
      $id_again = $wrap->upsert($foo, { name => 'baz', other => 'buzzmazz' },
         { conflicting => 'name' });
   } 'upsert, with upsert method';
   is $id_again, $id_new, 'retrieved the id of the updated record';
   is $wrap->db->select(foo => ['other'], { name => 'baz' })->hash->{other},
      'buzzmazz', 'new value for other (in baz)';

   $id_again = undef;
   lives_ok {
      $id_again = $wrap->upsert($foo, { name => 'fresh', other => 'new' },
         { conflicting => 'name' });
   } 'upsert of a missing record';
   ok defined($id_again), 'identifier is defined';
   is $wrap->id_of($foo, { name => 'fresh' }), $id_again,
      'upsert of a missing record inserted it';

   # upsert with only the conflicting column, nothing else to update
   $n_before = $count->();
   $id_again = undef;
   lives_ok {
      $id_again = $wrap->upsert($foo, { name => 'baz' }, { conflicting => 'name' });
   } 'upsert with only the conflicting column, existing record';
   is $id_again, $id_new, 'retrieved the id of the existing record';
   is $count->(), $n_before, 'nothing inserted';
   is $wrap->db->select(foo => ['other'], { name => 'baz' })->hash->{other},
      'buzzmazz', 'existing record untouched';

   $id_again = undef;
   lives_ok {
      $id_again = $wrap->upsert($foo, { name => 'lonely' }, { conflicting => 'name' });
   } 'upsert with only the conflicting column, missing record';
   is $wrap->id_of($foo, { name => 'lonely' }), $id_again,
      'missing record inserted';

   # DO NOTHING on conflict: no row comes back, no id
   $n_before = $count->();
   $id_again = 'not undef';
   lives_ok {
      $id_again = $wrap->insert($foo, { name => 'baz', other => 'nope' },
         { on_conflict => undef });
   } 'insert with on_conflict DO NOTHING on a conflict';
   is $id_again, undef, 'no identifier when nothing is inserted';
   is $count->(), $n_before, 'nothing inserted';
   is $wrap->db->select(foo => ['other'], { name => 'baz' })->hash->{other},
      'buzzmazz', 'existing record untouched';

   # condition never matches and the insert conflicts: by default
   # id_or_insert inserts with DO NOTHING, retries and gives up with 409
   throws_ok {
      $wrap->id_or_insert($foo, { name => 'nowhere' }, { name => 'baz' });
   } qr{\Aid_or_insert: no record matches the condition},
      'id_or_insert gives up after retries';
   is $@->code, 409, 'conflict outside the condition is code 409';
   ok !defined($@->data), 'no caller data in the 409 exception';
   is $count->(), $n_before, 'still nothing inserted';

   # conditions generating no WHERE clause would yield an arbitrary record
   for my $cond ({}, [], [{}], [[]], { -or => [] }, { -and => [{}] }) {
      my $what = Test::More::explain($cond);
      throws_ok { $wrap->id_of($foo, $cond) }
         qr{\Aid_of: empty condition matches everything},
         "id_of rejects condition $what";
      is $@->code, 400, "condition $what in id_of is code 400";
      throws_ok { $wrap->id_or_insert($foo, $cond, { name => 'never' }) }
         qr{\Aid_or_insert: empty condition matches everything},
         "id_or_insert rejects condition $what";
      is $@->code, 400, "condition $what in id_or_insert is code 400";
   }
   is $count->(), $n_before, 'nothing inserted with empty conditions';
   throws_ok { $wrap->id_of($foo, '1') }
      qr{\Aid_of: invalid condition, expected a reference},
      'id_of rejects a plain value condition, which would match everything';
   is $@->code, 400, 'plain value condition is code 400';
   is $wrap->id_of($foo, \"name = 'baz'"), $id_new,
      'id_of accepts a literal SQL condition';
   is $wrap->id_of($foo, [ { name => 'nowhere' }, { name => 'baz' } ]),
      $id_new, 'id_of accepts a non-empty array reference condition';

   # explicit insert options override the DO NOTHING default
   is $wrap->id_or_insert($foo, { name => 'nowhere' },
         { name => 'baz', other => 'via id_or_insert' },
         { insert => { on_conflict => [ name => { other => 'via id_or_insert' } ] } }),
      $id_new, 'id_or_insert with explicit on_conflict';
   is $wrap->db->select(foo => ['other'], { name => 'baz' })->hash->{other},
      'via id_or_insert', 'explicit on_conflict applied';

   # upsert argument checks
   throws_ok {
      $wrap->upsert($foo, { name => 'baz' },
         { conflicting => 'name', on_conflict => undef });
   } qr{cannot use both conflicting and on_conflict},
      'upsert rejects conflicting together with on_conflict';
   throws_ok {
      $wrap->upsert($foo, { name => 'baz' }, { conflicting => [] });
   } qr{empty conflicting}, 'upsert rejects empty conflicting';
   $n_before = $count->();
   throws_ok {
      $wrap->upsert($foo, { other => 'orphan' }, { conflicting => 'name' });
   } qr{no value for conflicting column\(s\) name},
      'upsert rejects conflicting column missing from data';
   throws_ok {
      $wrap->upsert($foo, { name => undef, other => 'orphan' },
         { conflicting => 'name' });
   } qr{no value for conflicting column\(s\) name},
      'upsert rejects undef conflicting column';
   throws_ok {
      $wrap->upsert(pair => { a => 1, v => 'orphan' },
         { conflicting => [qw< a b >] });
   } qr{no value for conflicting column\(s\) b},
      'upsert rejects missing column among multiple conflicting';
   throws_ok {
      $wrap->upsert($foo, { name => 'baz', other => 'plain' });
   } qr{need either conflicting or on_conflict},
      'upsert rejects missing conflicting and on_conflict';
   throws_ok {
      $wrap->upsert($foo, { name => 'baz', other => 'plain' },
         { conflicting => undef });
   } qr{need either conflicting or on_conflict},
      'upsert rejects undef conflicting without on_conflict';
   is $count->(), $n_before, 'rejected upserts inserted nothing';
   is $wrap->upsert($foo, { name => 'baz', other => 'via on_conflict' },
         { on_conflict => [ name => { other => 'via on_conflict' } ] }),
      $id_new, 'upsert with explicit on_conflict only';
   is $wrap->db->select(foo => ['other'], { name => 'baz' })->hash->{other},
      'via on_conflict', 'explicit on_conflict applied by upsert';

   # upsert on multiple conflicting columns
   my $pair_id = $wrap->upsert(pair => { a => 1, b => 2, v => 'first' },
      { conflicting => [qw< a b >] });
   ok defined($pair_id), 'upsert on multiple columns, new record';
   is $wrap->upsert(pair => { a => 1, b => 2, v => 'second' },
         { conflicting => [qw< a b >] }),
      $pair_id, 'upsert on multiple columns, existing record';
   is $wrap->db->select(pair => ['v'], { a => 1, b => 2 })->hash->{v},
      'second', 'upsert on multiple columns updated the record';
   is $wrap->upsert(pair => { a => 1, b => 2 }, { conflicting => [qw< a b >] }),
      $pair_id, 'upsert on multiple columns, only conflicting columns';
   is $wrap->db->select(pair => ['v'], { a => 1, b => 2 })->hash->{v},
      'second', 'and the record is untouched';

   # default identifier column "id"
   my $bar_id;
   lives_ok { $bar_id = $wrap->insert(bar => { name => 'one' }) }
      'insert with default id column';
   ok defined($bar_id), 'identifier is defined';
   is $wrap->id_of(bar => { name => 'one' }), $bar_id,
      'id_of with default id column';
   is $wrap->id_or_insert(bar => { name => 'one' }, { name => 'one' }), $bar_id,
      'id_or_insert with default id column';

   # transactions via the db option. No $wrap->db inside the blocks:
   # with SQLite :memory: another connection is another (empty) database
   my $bar_count = sub { $_[0]->query('SELECT count(*) FROM bar')->array->[0] };
   my $n_bar = $bar_count->($wrap->db);
   {
      my $db = $wrap->db;
      my $tx = $db->begin;
      my $other = $wrap->db;
      my %o = (db => $db);
      my $id_i = $wrap->insert(bar => { name => "i-db" }, {%o});
      ok defined($id_i), "insert with db";
      is $wrap->id_of(bar => { name => "i-db" }, {%o}), $id_i,
         "id_of with db sees the inserted record";
      my $id_u = $wrap->upsert(bar => { name => "u-db" },
         { conflicting => 'name', %o });
      is $wrap->id_of(bar => { name => "u-db" }, {%o}), $id_u,
         "upsert with db";
      my $id_x = $wrap->id_or_insert(bar => { name => "x-db" },
         { name => "x-db" }, {%o});
      ok defined($id_x), "id_or_insert with db";
      is $wrap->id_or_insert(bar => { name => "x-db" },
            { name => "x-db" }, {%o}),
         $id_x, "id_or_insert with db, existing record";
      # nested db in select and insert options is overridden
      my $id_n;
      lives_ok {
         $id_n = $wrap->id_or_insert(bar => { name => "n-db" },
            { name => "n-db" },
            { %o, select => { db => $other }, insert => { db => $other } });
      } "id_or_insert with db and nested db";
      is $wrap->id_of(bar => { name => "n-db" }, {%o}), $id_n,
         "id_or_insert with db and nested db inserted the record";
      is $bar_count->($db), $n_bar + 4,
         "four records inside the transaction (db)";
      # no commit: rolled back when $tx goes out of scope
   }
   is $bar_count->($wrap->db), $n_bar, "transaction rolled back (db)";

   my $id_committed;
   {
      my $db = $wrap->db;
      my $tx = $db->begin;
      $id_committed = $wrap->insert(bar => { name => 'committed' }, { db => $db });
      $tx->commit;
   }
   is $wrap->id_of(bar => { name => 'committed' }), $id_committed,
      'record inserted in a committed transaction is there';

   # init variants
   lives_ok { $retval = $new_wrap->()->init } 'init without migrations';
   isa_ok $retval, 'MojoX::MojoDbWrap';

   my $named = $new_wrap->(migrations_for => { $class => <<'END' });
-- 1 up
   CREATE TABLE baz (id INTEGER PRIMARY KEY);
-- 1 down
   DROP TABLE baz;
END
   lives_ok { $named->init('extra') } 'init with a migrations name';
   is $named->mdb->migrations->name('extra')->active, 1,
      'migrations recorded under the provided name';
   lives_ok { $named->db->query('SELECT count(*) FROM baz') }
      'table from named migrations exists';

   return;
}

1;
