package MojoX::MojoDbWrap;
use v5.24;
{ our $VERSION = '0.004' }

use Moo;
use warnings;
use experimental qw< signatures >;
use Ouch qw< :trytiny_var >;

sub coerce_wrappers ($x) {
   $x //= [];
   ouch 400, 'invalid value for wrappers, need undef or array ref'
      unless ref($x) eq 'ARRAY';
   return [
      ($x // [])->@*,
      {
         class => 'Mojo::Pg',
         create => sub ($class, $url) {
            return unless $url =~ m{\A postgres (?:ql)? ://}mxs;
            require Mojo::Pg;
            return Mojo::Pg->new($url);
         },
         insert => sub ($self, $tablish, $data, $opts) {
            my ($tbl, $idf) =
               ref($tablish) eq 'ARRAY' ? $tablish->@* : ($tablish, 'id');
            my $ext_opts = {
               ($opts // {})->%*,
               on_conflict => undef,
               returning   => $idf,
            };
            return $self->db->insert($tbl, $data, $ext_opts)->hash->{id};
         },
      },
      {
         class => 'Mojo::SQLite',
         create => sub ($class, $url) {
            require Mojo::SQLite;
            return Mojo::SQLite->new($url);
         },
         insert => sub ($self, $tablish, $data, $opts) {
            my $tbl = ref($tablish) eq 'ARRAY' ? $tablish->[0] : $tablish;
            my $ext_opts = {
               ($opts // {})->%*,
               on_conflict => undef,
            };
            return $self->db->insert($tbl, $data, $ext_opts)->last_insert_id;
         },
      },
   ];
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
      my $instance = $candidate->{create}->($class, $url)
         or next;
      return {
         class    => $class,
         insert   => $candidate->{insert},
         instance => $instance,
      };
   }
}

# handy accessors
sub mdb        ($self) { return $self->_wrapped->{instance} }
sub mdb_class  ($self) { return $self->_wrapped->{class}    }
sub mdb_module ($self) { return $self->_wrapped->{class}    }
sub db         ($self) { return $self->mdb->db }

# real stuff
sub id_of ($self, $tablish, $cond, $opts = undef) {
   my ($tbl, $idf) = ref($tablish) eq 'ARRAY' ? $tablish->@* : ($tablish, 'id');
   my $hash = $self->db->select($tbl, [$idf], $cond, $opts // {})->hash;
   return $hash ? $hash->{$idf} : undef;
}

sub _inserter ($self) { return $self->_wrapped->{insert} }

sub id_or_insert ($self, $tablish, $condition, $default, $opts = undef) {
   $opts //= {};
   my $inserter;
   for (1 .. 3) { # paranoia for quick insert/delete
      my $id = $self->id_of($tablish, $condition, $opts->{select});
      return $id if defined($id);

      # we have to try an insertion, let's make sure we have an inserter
      $inserter //= $self->_inserter;

      $id = $inserter->($self, $tablish, $default, $opts->{insert} // {});
      return $id if defined($id);
   }
   ouch 500, 'cannot select nor insert, bailing out',
      [ id_or_insert => $tablish, $condition, $default, $opts];
}

sub select ($self, @args) {
   return $self->mdb->db->select(@args);
}

#sub upsert ($self, $table, $data, $opts = undef) {
#   $opts //= {};
#   $self->db->insert($table, $data, { $opts->%*, on_conflict => $data });
#   return $self;
#}

sub init ($self, $name = 'migrations') {
   my $migrations = $self->migrations_for // {};
   if (my $migration = $migrations->{$self->mdb_class} // undef) {
      $self->mdb->migrations
         ->name($name)
         ->from_string($migration)
         ->migrate;
   }
   return $self;
}

1;
