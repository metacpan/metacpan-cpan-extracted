package MojoX::MojoDbWrap;
use v5.24;
{ our $VERSION = '0.100' }

use Moo;
use warnings;
use experimental qw< signatures >;
use Ouch qw< :trytiny_var >;

sub assert_condition ($name, $condition, $mdb) {
   ouch 400, "$name: undefined condition matches everything"
      unless defined($condition);
   ouch 400, "$name: invalid condition, expected a reference"
      unless ref($condition);

   if ($mdb->can('abstract')) {
      my $where = $mdb->abstract->where($condition);
      ouch 400, "$name: empty condition matches everything"
         if length($where) == 0;
   }

   return $condition;
}

sub assert_hash_reference ($name, $candidate, $msg = undef) {
   return $candidate if ref($candidate) eq 'HASH';
   ouch 400, $name . ': '
      . ($msg // 'invalid input, expected a hash reference');
}

sub assert_new_style_opts ($name, $opts) {
   assert_hash_reference($name, $opts);
   ouch 400, "$name: old-style sort hashes are unsupported, use order_by"
      if exists($opts->{-asc}) || exists($opts->{-desc});
}

sub assert_valid_keys ($name, $href, @keys) {
   return unless defined($href);
   assert_hash_reference($name, $href);
   my %is_valid = map { $_ => 1 } @keys;
   my @bad = grep { ! $is_valid{$_} } keys($href->%*) or return;
   my $what = @bad == 1 ? 'option' : 'options';
   ouch 400, "$name: unknown $what " . join(', ', sort @bad);
}

sub coerce_wrappers ($x) {
   $x //= [];
   ouch 400, 'invalid value for wrappers, need undef or array ref'
      unless ref($x) eq 'ARRAY';
   my @wrappers = map {
      my $w = $x->[$_];
      assert_hash_reference('(' . __PACKAGE__ . ' constructor)',
         $w, "item $_ in wrappers is not a hash ref");
      # copy, so that the caller's data is not touched
      +{ $w->%*, insert => $w->{insert} // \&default_inserter };
   } 0 .. $x->$#*;
   return [
      @wrappers,
      {
         class => 'Mojo::Pg',
         create => sub ($class, $url) {
            return unless $url =~ m{\A postgres (?:ql)? ://}imxs;
            require Mojo::Pg;
            return Mojo::Pg->new($url);
         },
         insert => \&default_inserter,
         can_limit => 1,
      },
      {
         class => 'Mojo::SQLite',
         create => sub ($class, $url) {
            local $@; # don't clobber $EVAL_ERROR, we don't use it!
            require Mojo::SQLite;
            return eval { Mojo::SQLite->new($url) };
         },
         insert => \&default_inserter,
         can_limit => 1,
      },
   ];
}

sub explode_tablish ($t) {
   my ($tbl, $idf) = ref($t) eq 'ARRAY' ? $t->@* : $t;
   return ($tbl, $idf // 'id');
}

sub isa_wrappers ($x) {
   for my $i (0 .. $x->$#*) {
      my $w = $x->[$i];
      ouch 400, "item $i lacks class name" unless defined($w->{class});
      ouch 400, "item $i lacks create sub"
         unless ref($w->{create}) eq 'CODE';
      ouch 400, "item $i lacks insert sub"
         unless ref($w->{insert}) eq 'CODE';
   }
   return;
}

sub sub_name ($default, $name, $level = 2) {
   return $name if defined($name);
   my $subroutine = (caller($level))[3];
   return $default if !defined($subroutine);
   return $default if $subroutine eq '(eval)'; # this would be... *meh*
   return ($subroutine =~ s{\A.*::}{}rmxs);
}

use namespace::clean;

# actual input stuff
has db_url => (is => 'ro', required => 1);
has migrations_for => (is => 'ro', default => sub { return {} });
has _wrapped  => (is => 'lazy', init_arg => undef);
has _wrappers => (
   is => 'ro',
   init_arg => 'wrappers',
   default  => undef,
   coerce   => \&coerce_wrappers,
   isa      => \&isa_wrappers,
);

sub _build__wrapped ($self) {
   my $url = $self->db_url;
   for my $candidate ($self->_wrappers->@*) {
      my $class = $candidate->{class};
      my $instance = $candidate->{create}->($class, $url) or next;
      return { $candidate->%*, instance => $instance };
   }
   ouch 400, 'unsupported DB URL';
}

# handy accessors
sub mdb        ($self) { return $self->_wrapped->{instance} }
sub mdb_class  ($self) { return $self->_wrapped->{class}    }
sub mdb_module ($self) { return $self->_wrapped->{class}    }
sub db         ($self) { return $self->mdb->db }

sub db_and_opts ($self, $ext_opts, $name = undef) {
   $name = sub_name(db_and_opts => $name, 2);

   # SQL::Abstract::Pg is nice to old-style sort hashes; we are not.
   assert_new_style_opts($name, $ext_opts //= {});
   my $opts = { $ext_opts->%* };

   my $db;
   if (exists($opts->{db})) {
      $db = delete($opts->{db});
      ouch 400, "$name: db is present but undefined" unless defined($db);
   }
   return ($db // $self->db, $opts);
}

# RETURNING (Pg, SQLite 3.35+) instead of last_insert_id, which is wrong
# when on_conflict turns the insert into an update
sub default_inserter ($self, $tablish, $data, $ext_opts = undef) {
   my ($tbl, $idf) = explode_tablish($tablish);
   my ($db, $opts) = $self->db_and_opts($ext_opts);
   $opts->{returning} = $idf;
   my $row = $db->insert($tbl, $data, $opts)->hash;
   return $row ? $row->{$idf} : undef;
}

sub id_of ($self, $tablish, $cond, $ext_opts = undef) {
   assert_condition(id_of => $cond, $self->mdb);
   my ($tbl, $idf) = explode_tablish($tablish);
   my ($db, $opts) = $self->db_and_opts($ext_opts);
   $opts->{limit} = 1 if $self->_can_limit; # we fetch only the first one
   my $hash = $db->select($tbl, [$idf], $cond, $opts)->hash;
   return $hash ? $hash->{$idf} : undef;
}

sub _can_limit ($self) { return $self->_wrapped->{can_limit} }
sub _inserter  ($self) { return $self->_wrapped->{insert} }

sub id_or_insert ($self, $tablish, $condition, $default, $e_opts = undef) {
   assert_condition(id_or_insert => $condition, $self->mdb);
   assert_valid_keys(id_or_insert => $e_opts, qw< db insert select >);
   my ($db, $opts) = $self->db_and_opts($e_opts);

   # get options and validate them on the fly. Use shallow copies so that
   # we can fiddle with them later.
   my ($sel_opts, $ins_opts) = map {
      my $href = $opts->{$_} // {};
      assert_hash_reference(id_or_insert => $href,
         "invalid input $_, expected a hash reference");
      +{ $href->%* };
   } qw< select insert >;

   # SQL::Abstract::Pg is nice to old-style sort hashes; we are not.
   assert_new_style_opts(id_or_insert => $sel_opts);

   # use the same 'db' down the line
   $sel_opts->{db} = $ins_opts->{db} = $db;

   # if not set by the caller, we settle for DO NOTHING
   $ins_opts->{on_conflict} //= undef;

   my $inserter = $self->_inserter;
   for (1 .. 3) { # paranoia for quick insert/delete
      my $id = $self->id_of($tablish, $condition, $sel_opts);
      return $id if defined($id);

      $id = $inserter->($self, $tablish, $default, $ins_opts);
      return $id if defined($id);
   }

   # insert did nothing three times: almost surely $default conflicts on
   # a unique key that $condition does not cover, so a 409 is better than
   # a generic 500, even though it might be a problem on the library side
   ouch 409, 'id_or_insert: no record matches the condition, but '
      . 'the default record conflicts with an existing one';
}

sub insert ($self, $tablish, $data, $ext_opts = undef) {
   # call it here to ensure checks over $ext_opts
   my ($db, $opts) = $self->db_and_opts($ext_opts, 'insert');
   $opts->{db} = $db;
   return $self->_inserter->($self, $tablish, $data, $opts);
}

sub upsert ($self, $tablish, $data, $ext_opts = undef) {
   # call it here to ensure checks over $ext_opts
   my ($db, $opts) = $self->db_and_opts($ext_opts);
   $opts->{db} = $db;
   if (defined(my $conflicting = delete($opts->{conflicting}))) {
      ouch 400, 'upsert: cannot use both conflicting and on_conflict'
         if exists($opts->{on_conflict});
      my @keys = ref($conflicting) eq 'ARRAY' ? $conflicting->@* : $conflicting;
      ouch 400, 'upsert: empty conflicting' unless @keys;

      # SQL::Abstract(::*) accept $data as an array reference, but in this
      # "DWIM" branch we insist on getting a hash reference
      assert_hash_reference(upsert => $data,
         'data must be a hash reference when using key "conflicting"');

      # NULLs never conflict, so this would insert a new record every time
      my @missing = grep { !defined($data->{$_}) } @keys;
      ouch 400, "upsert: no value for conflicting column(s) @missing"
         if @missing;
      my %is_key = map { $_ => 1 } @keys;
      my %reduced_data = (
         map { $_ => $data->{$_} }
            grep { !$is_key{$_} }
            keys($data->%*)
      );
      # nothing else to set: no-op update, so RETURNING still gives the id
      %reduced_data = ($keys[0] => $data->{$keys[0]})
         unless %reduced_data;
      $opts->{on_conflict} = [ $conflicting => \%reduced_data ];
   }
   elsif (!exists($opts->{on_conflict})) {
      ouch 400, 'upsert: need either conflicting or on_conflict';
   }
   return $self->insert($tablish, $data, $opts);
}

sub init ($self, $name = 'migrations') {
   my $migrations = $self->migrations_for // {};
   if (my $migration = $migrations->{$self->mdb_class}) {
      $self->mdb->migrations
         ->name($name)
         ->from_string($migration)
         ->migrate;
   }
   return $self;
}

1;
