use strict;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib";
use MojoX::MojoDbWrap;
use MojoDbWrapTests qw< skip_unless_pg skip_unless_sqlite skip_unless_sqlite_returning >;

# wrapped objects must provide db, like Mojo::Pg and Mojo::SQLite
{ package My::Fake; sub new { bless {}, shift } sub db { bless {}, 'My::Fake::Db' } }

my @insert_args;
my $fake = {
   class  => 'My::Fake',
   create => sub { my ($class, $url) = @_; $url =~ m{\A fake:}mxs ? $class->new : undef },
   insert => sub { @insert_args = @_; return 42 },
};

subtest validation => sub {
   throws_ok { MojoX::MojoDbWrap->new(db_url => 'x', wrappers => {}) }
      qr{invalid value for wrappers}, 'wrappers must be an array ref';
   throws_ok { MojoX::MojoDbWrap->new(db_url => 'x', wrappers => [$fake, 'x']) }
      qr{\A\(MojoX::MojoDbWrap constructor\): item 1 in wrappers is not a hash ref},
      'wrapper items must be hash refs';
   is $@->code, 400, 'non-hash wrapper item is code 400';
   for my $key (qw< class create >) {
      my %w = %$fake;
      delete $w{$key};
      throws_ok { MojoX::MojoDbWrap->new(db_url => 'x', wrappers => [\%w]) }
         qr{item 0 lacks $key}, "wrapper without $key";
   }
   for my $key (qw< create insert >) {
      my %w = (%$fake, $key => 'not a sub');
      throws_ok { MojoX::MojoDbWrap->new(db_url => 'x', wrappers => [$fake, \%w]) }
         qr{item 1 lacks $key}, "wrapper with non-code $key, index reported";
   }
   my %no_insert = %$fake;
   delete $no_insert{insert};
   lives_ok { MojoX::MojoDbWrap->new(db_url => 'x', wrappers => [\%no_insert]) }
      'wrapper without insert is accepted';
   ok !exists($no_insert{insert}), 'caller wrapper data left untouched';
};

subtest 'unsupported URL' => sub {
   skip_unless_sqlite();
   my $url = 'mysql://u:secret@h/db';
   my $wrap = MojoX::MojoDbWrap->new(db_url => $url);
   throws_ok { $wrap->mdb } 'Ouch', 'unsupported URL throws an Ouch';
   my $e = $@;
   is $e->code, 400, 'code 400';
   like $e->message, qr{\Aunsupported DB URL}, 'message';
   unlike "$e", qr{secret}, 'password not in the stringified exception';
   ok !defined($e->data), 'URL (and password) not in exception data';
};

subtest 'Pg URL scheme is case-insensitive' => sub {
   skip_unless_pg();
   for my $url (qw< Postgresql://u@h/db POSTGRES://u@h/db >) {
      # mdb does not connect, no server needed
      is +MojoX::MojoDbWrap->new(db_url => $url)->mdb_class, 'Mojo::Pg',
         "$url goes to Mojo::Pg";
   }
};

subtest 'custom wrapper without insert uses default inserter' => sub {
   skip_unless_sqlite_returning();
   my $wrap = MojoX::MojoDbWrap->new(
      db_url   => 'mine::memory:',
      wrappers => [
         {
            class  => 'My::SQLite',
            create => sub {
               my ($class, $url) = @_;
               return unless $url =~ s{\A mine:}{}mxs;
               return Mojo::SQLite->new($url);
            },
         },
      ],
   );
   is $wrap->mdb_class, 'My::SQLite', 'custom wrapper selected';
   $wrap->db->query('CREATE TABLE t (tid INTEGER PRIMARY KEY, n TEXT UNIQUE)');
   my $id = $wrap->insert([qw< t tid >], { n => 'a' });
   ok defined($id), 'default inserter returned an identifier';
   is $wrap->id_of([qw< t tid >], { n => 'a' }), $id, 'and it is the right one';
   is $wrap->default_inserter([qw< t tid >], { n => 'b' }, {}),
      $wrap->id_of([qw< t tid >], { n => 'b' }), 'default_inserter as a method';
};

subtest 'id_or_insert survives a concurrent insert' => sub {
   skip_unless_sqlite_returning();
   my $racing = 1;
   my $wrap = MojoX::MojoDbWrap->new(
      db_url   => 'racy::memory:',
      wrappers => [
         {
            class  => 'My::Racy',
            create => sub {
               my ($class, $url) = @_;
               return unless $url =~ s{\A racy:}{}mxs;
               return Mojo::SQLite->new($url);
            },
            # another writer inserts the same record just before us; use
            # the same connection, a new one to :memory: is another DB
            insert => sub {
               my ($self, $tablish, $data, $opts) = @_;
               my ($db) = $self->db_and_opts($opts, 'racy insert');
               $db->insert($tablish->[0], $data) if $racing-- > 0;
               return MojoX::MojoDbWrap::default_inserter(@_);
            },
         },
      ],
   );
   $wrap->db->query('CREATE TABLE t (tid INTEGER PRIMARY KEY, n TEXT UNIQUE)');
   my $id;
   lives_ok { $id = $wrap->id_or_insert([qw< t tid >], { n => 'a' }, { n => 'a' }) }
      'id_or_insert lives';
   is $id, $wrap->id_of([qw< t tid >], { n => 'a' }), 'got the racing record id';
   is $wrap->db->query('SELECT count(*) FROM t')->array->[0], 1,
      'only one record';
};

subtest 'custom wrapper selected' => sub {
   my $wrap = MojoX::MojoDbWrap->new(db_url => 'fake:whatever', wrappers => [$fake]);
   isa_ok $wrap->mdb, 'My::Fake';
   is $wrap->mdb_class, 'My::Fake', 'mdb_class';
   is $wrap->insert(tbl => { a => 1 }), 42, 'insert goes through custom inserter';
   is $insert_args[0], $wrap, 'custom inserter receives the wrapper object';
   is_deeply [ @insert_args[1, 2] ], [ tbl => { a => 1 } ],
      'custom inserter receives tablish and data';
   is_deeply [ sort keys $insert_args[3]->%* ], ['db'],
      'custom inserter receives only db in default options';
   isa_ok $insert_args[3]{db}, 'My::Fake::Db', 'db in options';

   my $mydb = My::Fake->new->db;
   $wrap->insert(tbl => { a => 1 }, { db => $mydb, foo => 'bar' });
   is $insert_args[3]{db}, $mydb, 'custom inserter receives the provided db';
   is $insert_args[3]{foo}, 'bar', 'custom inserter receives other options';

   throws_ok { $wrap->insert(tbl => { a => 1 }, []) }
      qr{\Ainsert: invalid input, expected a hash reference},
      'insert error names insert';
   throws_ok { $wrap->upsert(tbl => { a => 1 }, 'x') }
      qr{\Aupsert: invalid input, expected a hash reference},
      'upsert error names upsert';
   throws_ok { $wrap->upsert(tbl => [1], { conflicting => 'a' }) }
      'Ouch', 'upsert with conflicting rejects non-hash data with an Ouch';
   is ref($@) && $@->code, 400, 'non-hash upsert data is code 400';
   throws_ok { $wrap->id_or_insert(tbl => { a => 1 }, { a => 1 }, []) }
      qr{\Aid_or_insert: invalid input, expected a hash reference},
      'id_or_insert error names id_or_insert';
   for my $key (qw< select insert >) {
      for my $bad ([], 'x') {
         throws_ok {
            $wrap->id_or_insert(tbl => { a => 1 }, { a => 1 }, { $key => $bad })
         } qr{\Aid_or_insert: invalid input $key, expected a hash reference},
            "id_or_insert rejects non-hash $key options (@{[ ref($bad) || 'string' ]})";
         is $@->code, 400, "non-hash $key options is code 400";
      }
   }
   # an undefined db must not silently become a fresh connection
   my %undef_db_call = (
      insert       => sub { $wrap->insert(tbl => { a => 1 }, $_[0]) },
      upsert       => sub {
         $wrap->upsert(tbl => { a => 1 }, { conflicting => 'a', $_[0]->%* })
      },
      id_of        => sub { $wrap->id_of(tbl => { a => 1 }, $_[0]) },
      id_or_insert => sub {
         $wrap->id_or_insert(tbl => { a => 1 }, { a => 1 }, $_[0])
      },
      default_inserter =>
         sub { $wrap->default_inserter(tbl => { a => 1 }, $_[0]) },
   );
   for my $method (sort keys %undef_db_call) {
      throws_ok { $undef_db_call{$method}->({ db => undef }) }
         qr{\A$method: db is present but undefined},
         "$method rejects an undefined db";
      is $@->code, 400, "undefined db in $method is code 400";
   }

   throws_ok { $wrap->default_inserter(tbl => { a => 1 }, []) }
      qr{\Adefault_inserter: invalid input, expected a hash reference},
      'default_inserter rejects non-hash options';
   is $@->code, 400, 'non-hash default_inserter options is code 400';

   # id_of fetches only one record, whatever the caller asks
   my @select_args;
   {
      no strict 'refs';
      *{'My::Fake::Db::select'} = sub { @select_args = @_; bless {}, 'My::Fake::Res' };
      *{'My::Fake::Res::hash'}  = sub { return { id => 7 } };
   }
   my %id_of_opts = (db => $mydb, order_by => 'x', limit => 10);
   is $wrap->id_of(tbl => { a => 1 }, \%id_of_opts), 7, 'id_of via fake db';
   is_deeply $select_args[4], { order_by => 'x', limit => 10 },
      'id_of without can_limit passes options as they are';

   my $wrap_l = MojoX::MojoDbWrap->new(db_url => 'fake:whatever',
      wrappers => [ { %$fake, can_limit => 1 } ]);
   is $wrap_l->id_of(tbl => { a => 1 }, \%id_of_opts), 7,
      'id_of via fake db with can_limit';
   is_deeply $select_args[4], { order_by => 'x', limit => 1 },
      'id_of with can_limit forces limit 1 and keeps other options';
   is $id_of_opts{limit}, 10, 'caller options for id_of left untouched';

   $wrap_l->id_of(tbl => { a => 1 }, { db => $mydb });
   is_deeply $select_args[4], { limit => 1 },
      'id_of with can_limit sets limit 1 without caller options';

   # id_or_insert rejects options it does not know, e.g. insert options
   # put at the top level instead of under key insert
   throws_ok {
      $wrap->id_or_insert(tbl => { a => 1 }, { a => 1 }, { on_conflict => undef })
   } qr{\Aid_or_insert: unknown option on_conflict\b},
      'id_or_insert rejects an unknown option';
   is $@->code, 400, 'with code 400';
   throws_ok {
      $wrap->id_or_insert(tbl => { a => 1 }, { a => 1 },
         { order_by => 'x', on_conflict => undef });
   } qr{\Aid_or_insert: unknown options on_conflict, order_by\b},
      'id_or_insert lists all unknown options, sorted';
   lives_ok {
      $wrap->id_or_insert(tbl => { a => 1 }, { a => 1 },
         { db => $mydb, select => {}, insert => {} });
   } 'id_or_insert accepts its known options';

   # an undefined condition matches everything, whatever the wrapper
   throws_ok { $wrap->id_of(tbl => undef, { db => $mydb }) }
      qr{\Aid_of: undefined condition matches everything},
      'id_of rejects an undefined condition';
   is $@->code, 400, 'undefined condition in id_of is code 400';
   @insert_args = ();
   throws_ok { $wrap->id_or_insert(tbl => undef, { a => 1 }, { db => $mydb }) }
      qr{\Aid_or_insert: undefined condition matches everything},
      'id_or_insert rejects an undefined condition';
   is $@->code, 400, 'undefined condition in id_or_insert is code 400';
   is scalar(@insert_args), 0, 'nothing inserted with an undefined condition';

   # a plain value is bound as WHERE ?, i.e. "1" matches everything
   for my $cond ('1', '') {
      throws_ok { $wrap->id_of(tbl => $cond, { db => $mydb }) }
         qr{\Aid_of: invalid condition, expected a reference},
         "id_of rejects plain value condition '$cond'";
      is $@->code, 400, "plain value condition '$cond' in id_of is code 400";
      throws_ok { $wrap->id_or_insert(tbl => $cond, { a => 1 }, { db => $mydb }) }
         qr{\Aid_or_insert: invalid condition, expected a reference},
         "id_or_insert rejects plain value condition '$cond'";
      is $@->code, 400, "plain value condition '$cond' in id_or_insert is code 400";
   }
   is scalar(@insert_args), 0, 'nothing inserted with plain value conditions';

   # without abstract in the wrapped object, other conditions pass through
   is $wrap->id_of(tbl => {}, { db => $mydb }), 7,
      'empty condition passes through without abstract';
};

subtest 'custom wrapper declines, fall back to defaults' => sub {
   skip_unless_sqlite();
   my $wrap = MojoX::MojoDbWrap->new(db_url => ':memory:', wrappers => [$fake]);
   is $wrap->mdb_class, 'Mojo::SQLite', 'fell back to Mojo::SQLite';
};

# outside of any sub (no subtest here), even inside an eval, the
# message falls back to the default name
{
   my $wrap = MojoX::MojoDbWrap->new(db_url => 'fake:whatever', wrappers => [$fake]);
   eval { $wrap->db_and_opts([]) };
   like "$@", qr{\Adb_and_opts: invalid input, expected a hash reference},
      'db_and_opts called in an eval at file scope names db_and_opts';
}

done_testing();
