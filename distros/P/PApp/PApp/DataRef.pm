##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::DataRef - reference data stored in scalars, databases...

=head1 SYNOPSIS

 use PApp::DataRef;

=head1 DESCRIPTION

You often want to store return values from HTML forms
(e.g. L<macro/editform>) or other "action at a distance" events
in your state variable or in a database (e.g. after updates). The
L<DBIx::Recordset|DBIx::Recordset> provides similar functionality.

C<PApp::DataRef> provides the means to create "handles" that can act like
normal perl references. When accessed they fetch/store data from the
underlying storage.

All of the generated references and handles can be serialized.

=over 4

=cut

package PApp::DataRef;

use Convert::Scalar ();

$VERSION = 2.1;

=item $hd = new PApp::DataRef 'DB_row', table => $table, where => [key, value], ...

Create a new handle to a table in a SQL database. C<table> is the name
(view) of the database table. The handle will act like a reference to a
hash. Accessing the hash returns references to tied scalars that can be
read or set (or serialized).

 my $hd = new PApp::DataRef 'DB_row', table => env, where => [name => 'TT_LIBDIR'];
 print ${ $hd->{value} }, "\n";
 ${ $hd->{value} } = "new libdir value";

The default database handle (C<$PApp::SQL::DBH>) is used for all sql
accesses. (Future versions might be more intelligent).

As a special case, if the C<value> part of the C<where> agruments is
undef, it will be replaced by some valid (newly created) id on the first
STORE operation. This currently only works for mysql.

Parameters

   table         the database table to use.
   key           a string or arrayref containing the (primary) key fields.
   id            a scalar or araryref giving the values for the key.

   where         [deprecated but supported] a array-ref with the primary key
                 fieldname and primary key value.

   autocommit    if set to one (default) automatically store the contents
                 when necessary or when the object gets destroyed.
   delay         if set, do not write the table for each update.
                 (delay implies caching of stored values(!))
   cache         if set, cache values that were read.
   preload       if set to a true value, preloads the values from the table on
                 object creation. If set to an array reference, only the mentioned
                 fields are being cached. Implies C<cache => 1>.
   database      the PApp::SQL::Database object to use. If not specified,
                 the default database at the time of the new call is used.
   insertid      when set to true, makes this object allocate sequences using
                 sql_insertid.
   sequence      (use insertid) when set to one and the (single) key id is C<undef>
                 or C<zero>, use sql_insertid to allocate a new one (will be extended
                 to handle the case where no id is given, in which case this parameter
                 describes how to allocate a new id).
   utf8          can be set to a boolean, an arrayref or hashref that decides
                 wether to force the utf8 bit on or off for the selected fields.

=item $hd = new $dataref arg => value, ...

Instead of specifying all the same parameters again and again, you can
create a I<partial> DataRef object (e.g. one without an id) with default
parameters and use this form of the method invocation to "specialise", e.g.

   my $template = new PApp::DataRef 'DB_row', table => "message", key => "id";

   for (1,2,3) {
      my $row = $template->new(id => $_);
      ...
   }

=item $hd = new PApp::DataRef 'Scalar', fetch => ..., ...

Create a scalar reference that calls your callbacks when accessed. Valid arguments are:

  fetch => coderef($self)          # ref not present
  fetch => coderef($self, $value)  # ref present
    A coderef which is to be called for every read access

  value => constant
    As an alternative to fetch, always return a constant on read accesses

  ref => scalar-ref
    When present, this references the scalar that is passed to the fetch
    method or overwritten by the store method.

  store => coderef($value, $value) # ref not present (first argument is DEPRECATED)
  store => coderef($self, $value)  # ref present
    A coderef which is to be called with the new value for every write
    access. If ref is given, the new value should be returned from this
    callback. If the callback returns the empty list, the value won't be
    changed.

For read access, either C<fetch>, C<value> or C<ref> must be present (they
are checked in this order). If C<store> is missing, stored values are
thrown away.

=cut

sub new {
   my $class = shift;

   my $type = "PApp::DataRef::".shift;

   unless (defined &{"${type}::new"}) {
      eval "use $type"; die if $@;
   }

   $type->new(@_);
}

sub new_locked {
   my $class = shift;

   use Carp ();
   Carp::cluck "PApp::DataRef::new_locked is deprecated, use autocommit => 0, delay => 1, preload => 1, cache => 1";
   
   my $type = "PApp::DataRef::".shift;

   unless (defined &{"${type}::new"}) {
      eval "use $type"; die if $@;
   }

   $type->new_locked(@_);
}

package PApp::DataRef::Base;

use Carp ();

sub TIESCALAR {
   my $class = shift;
   bless shift, $class;
}

sub new   { Carp::croak "new() not implemented for ".ref $_[0] }
sub FETCH { Carp::croak "FETCH not implemented for ".ref $_[0] }
sub STORE { Carp::croak "STORE not implemented for ".ref $_[0] }

sub DESTROY { }

package PApp::DataRef::Scalar;

@ISA = PApp::DataRef::Base::;

sub new {
   my $class = shift;

   no warnings;

   my $handle;
   tie $handle, ref $class ? ref $class : $class,
                ref $class ? %$class : (),
                @_;
   bless \$handle, PApp::DataRef::Scalar::Proxy;
}

sub TIESCALAR {
   my $class = shift;
   bless { @_ }, $class;
}

sub FETCH {
   my $self = $_[0];
   if ($self->{fetch}) {
      return $self->{fetch}($self, $self->{ref} ? ${$self->{ref}} : ());
   } elsif (exists $self->{value}) {
      return $self->{value};
   } elsif (exists $self->{ref}) {
      return ${$self->{ref}};
   } else {
      # might become a warning or fatal error
      return undef;
   }
}

sub STORE {
   my $self = $_[0];
   if ($self->{store}) {
      if ($self->{ref}) {
         my @data = $self->{store}($self, $_[1]);
         ${$self->{ref}} = $data[0] if @data;
      } else {
         $self->{store}($_[1], $_[1]);
      }
   } else {
      # might become a warning or fatal error
      ();
   }
}

package PApp::DataRef::DB_row;

use PApp::SQL;
use PApp::Callback ();

use Carp ();

my $sql_insertid = PApp::Callback::register_callback {
   sql_insertid sql_exec $_[0]->dbh, "insert into $_[0]{table} values ()";
} name => "papp_dataref_insertid";

sub new {
   my $class = shift;
   my %handle;

   tie %handle, ref $class ? ref $class : $class,
                autocommit => 1,
                ref $class ? %$class : (),
                @_;
   bless \%handle, PApp::DataRef::Hash::Proxy;
}

sub new_locked {
   my $class = shift;
   my %handle;

   tie %handle, $class, autocommit => 0, delay => 1, preload => 1, cache => 1, @_;
   bless \%handle, PApp::DataRef::Hash::Proxy;
}

sub dbh {
   $_[0]{database}->dbh;
}

sub TIEHASH {
   my $class = shift;
   my $self = bless { @_ }, $class;

   $self->{database} ||= $PApp::SQL::Database;

   if (my $where = delete $self->{where}) {
      $self->{key} = $where->[0];
      $self->{id}  = $where->[1];
      if ((!ref $self->{key} || @{$self->{key}} == 1) && !$self->{id} && !$self->{insertid}) {
         use Carp ();
         Carp::cluck "PApp::DataRef automatic auto_increment behaviour is deprecated, specify insertid => 1";
         $self->{insertid} = 1;
      }
   }

   exists $self->{table} or Carp::croak("mandatory parameter table missing");
   exists $self->{key}   or Carp::croak("mandatory parameter key missing");

   $self->{key} = [$self->{key}] if defined $self->{key} && !ref $self->{key};
   $self->{id}  = [$self->{id}]  if defined $self->{id}  && !ref $self->{id};

   if (delete $self->{insertid}) {
      $self->{sequence} = $sql_insertid->refer();

      #d# 0 => undef with insertid (should we really?)
      if ($self->{id} && !$self->{id}[0]) {
         delete $self->{id};
      }
   }

   if ($self->{id} && !defined $self->{id}[0]) {
      delete $self->{id};
   }

   $self->{key_expr} = "(".(join " and ", map "$_ = ?", @{$self->{key}}).")";

   if (exists $self->{utf8}) {
      if (ref $self->{utf8} eq "ARRAY") {
         my %utf8;
         $utf8{$_} = 1 for @{$self->{utf8}};
         $self->{utf8} = \%utf8;
      }
   }

   if ($self->{id}) {
      $self->{database} or
         Carp::croak("no database given and no default database found");

      if (my $preload = $self->{preload}) {
         $self->{cache} = 1;

         # try to preload, enable caching
         $preload = ref $preload ? join ",", @$preload : "*";
         my $st = eval {
            local $SIG{__DIE__};
            sql_exec $self->{database}->dbh,
                     "select $preload from $self->{table} where $self->{key_expr}",
                     @{$self->{id}};
         };
         if ($st) {
            my $hash = $st->fetchrow_hashref;
            while (my ($field, $value) = each %$hash) {
               Convert::Scalar::utf8_on $value if $self->{utf8} && (!ref $self->{utf8} || $self->{utf8}{$field});
               $self->{_cache}{$field} = $value;
            }
            $st->finish;
         }
      }
      # ...
   }

   $self;
}

=item $hd->{fieldname} or $hd->{[fieldname, extra-args]}

Return a lvalue to the given field of the row. The optional arguments
C<fetch> and C<store> can be given code-references that are called at
every fetch and store, and should return their first argument (possibly
modified), e.g. to fetch and store a crypt'ed password field:

  my $pass_fetch = create_callback { "" };
  my $pass_store = create_callback { crypt $_[1], <salt> };

  $hd->{["password", fetch => $pass_fetch, store => $pass_store]};

Additional named parameters are:

  fetch => $fetch_cb,
  store => $store_cb,
     
     Functions that should be called with the fetched/to-be-stored value
     as second argument that should be returned, probably after some
     transformations have been used on it. This can be used to convert
     sql-sets or password fields from/to their internal database format.

     If the store function returns nothing (an empty 'list', as it is
     called in list context), the update is being skipped.

     L<PApp::Callback> for a way to create serializable code references.

     PApp::DataRef::DB_row predefines some filter types (these functions
     return four elements, i.e. fetch => xxx, store => xxx, so that you
     can just cut & paste them).

        PApp::DataRef::DB_row::filter_sql_set
                  converts strings of the form a,b,c into array-refs and
                  vice versa.

        PApp::DataRef::DB_row::filter_password
                  returns the empty string and crypt's the value if nonempty.

        PApp::DataRef::DB_row::filter_sfreeze_cr
                  filters the data through Compress::LZF's sfreeze_cr and sthaw.

=cut

use PApp::Callback;

my $sql_set_fetch = create_callback {
   [split /,/, $_[1]];
} name => "papp_dataref_set_fetch";

my $sql_set_store = create_callback {
   join ",", @{$_[1]};
} name => "papp_dataref_set_store";

my $sql_pass_fetch = create_callback {
   "";
} name => "papp_dataref_pass_fetch";

my $sql_pass_store = create_callback {
   $_[1] ne "" ? crypt $_[1], join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64] : ();
} name => "papp_dataref_pass_store";

my $sql_sfreeze_cr_fetch = create_callback {
   require Compress::LZF;
   Compress::LZF::sthaw(Convert::Scalar::utf8_on $_[1]);
} name => "papp_dataref_sfreeze_cr_fetch";

my $sql_sfreeze_cr_store = create_callback {
   require Compress::LZF;
   Compress::LZF::sfreeze_cr(Convert::Scalar::utf8_upgrade $_[1]);
} name => "papp_dataref_sfreeze_cr_store";

sub filter_sql_set  (){ ( fetch => $sql_set_fetch,        store => $sql_set_store        ) }
sub filter_password (){ ( fetch => $sql_pass_fetch,       store => $sql_pass_store       ) }
sub filter_sfree_cr (){ ( fetch => $sql_sfreeze_cr_fetch, store => $sql_sfreeze_cr_store ) }

sub _sequence {
   my $self = shift;

   unless (defined $self->{id}) {
      # create a new ID
      $self->{id} = [$self->{sequence}->($self)];
   }
}

sub FETCH {
   my $self = shift; my ($field, %args) = ref $_[0] ? @{+shift} : shift;
   my $value;

   if (exists $self->{_cache}{$field}) {
      $value = $self->{_cache}{$field};
   } else {
      if ($self->{id}) {
         $value = sql_fetch $self->dbh, "select $field from $self->{table} where $self->{key_expr}",  @{$self->{id}};
         Convert::Scalar::utf8_on $value if $self->{utf8} && (!ref $self->{utf8} || $self->{utf8}{$field});
         $self->{_cache}{$field} = $value if $self->{cache};
      } else {
         $value = ();
      }
   }

   ref $args{fetch} ? $args{fetch}->($self, $value) : $value;
}

sub STORE {
   my $self = shift; my ($field, %args) = ref $_[0] ? @{+shift} : shift;
   my @value = ref $args{store} ? $args{store}->($self, shift) : shift;
   return unless @value;

   Convert::Scalar::utf8_upgrade $value[0] if $self->{utf8} && (!ref $self->{utf8} || $self->{utf8}{$field});

   if ($self->{delay}) {
      $self->{_store}{$field} = \($self->{_cache}{$field} = $value[0]);
   } else {
      $self->{_cache}{$field} = $value[0] if $self->{cache};

      $self->_sequence unless defined $self->{id};
      sql_exec $self->dbh,
               "update $self->{table} set $field = ? where $self->{key_expr}",
               $value[0], @{$self->{id}};
      $sql_exec > 0
         or sql_exec $self->dbh,
            "insert into $self->{table} (" .
               (join ",", $field, @{$self->{key}}) .
            ") values (" .
               (join ",", ("?") x (1 + @{$self->{key}})) .
            ")",
            $value[0],
            @{$self->{id}};
   }
}

# we do not officially support iterators yet, but define them so we can display this object
sub FIRSTKEY {
   my $self = shift;
   keys %{$self->{_cache}};
   each %{$self->{_cache}};
}

sub NEXTKEY {
   my $self = shift;
   each %{$self->{_cache}};
}

sub EXISTS {
   my $self = shift;
   my $field = shift;
   exists $self->{_cache}{$field} or do {
      # do it the slow way. not sure wether the limit 0 is portable or not
      my $st = sql_exec $self->{database}->dbh,
                        "select * from $self->{table} limit 0";
      my %f; @f{@{$st->{NAME_lc}}} = ();
      $st->finish;
      exists $f{lc $field};
   };
}

=item @key = $hd->id

Returns the key value(s) for the selected row, creating it if necessary.

=cut

sub id($) {
   my $self = shift;
   $self->_sequence;
   wantarray ? @{$self->{id}} : $self->{id}[0];
}

=item $hd->flush

Flush all pending store operations. See HOW FLUSHES ARE IMPLEMENTED below
to see how, well, flushes are implemented on the SQL-level.

=cut

sub flush {
   my $self = shift;

   my $store = delete $self->{_store};

   if (%$store) {
      my $dbh = $self->dbh;

      my $insrep = sub {
         sql_exec $dbh,
               "$_[0] into $self->{table} (" .
                  (join ",", @{$self->{key}}, keys %$store) .
               ") values (" .
                  (join ",", ("?") x (@{$self->{key}} + keys %$store)) .
               ")",
               @{$self->{id}},
               (map $$_, values %$store);
      };

      my $update = sub {
         sql_exec $dbh,
                  "update $self->{table} set" .
                     (join ",", map " $_ = ?", keys %$store) .
                  " where $self->{key_expr}",
                  (map $$_, values %$store), @{$self->{id}};
      };

      $self->_sequence unless $self->{id};

      if (0 && $self->{preload} && !ref $self->{preload}
          && $dbh->{Driver}{Name} eq "mysql"
        ) {
         # disabled because $store doesn't contain all values, and _cache might contain
         # the id field twice. reenable when id is a normal member of _cache
         $insrep->("replace");
         delete $self->{preload}; # preload also acts as a "we know all columns" flag
      } else {
         &$update;
         $sql_exec > 0 or eval { local $SIG{__DIE__}; $insrep->("insert") };
         $sql_exec > 0 or &$update;
      }
   }
}

=item $hd->dirty

Return true when there are store operations that are delayed. Call
C<flush> to execute these.

=cut

sub dirty {
   my $self = shift;
   ! ! %{$self->{_store}}; # !! Isnogood for vim
}

=item $hd->invalidate

Empties any internal caches. The next access will reload the values
from the database again. Any dirty values will be discarded.

=cut

sub invalidate {
   my $self = shift;
   delete $self->{_cache};
   delete $self->{_store};
}

=item $hd->discard

Discard all pending store operations. Only sensible when C<delay> is true.

=cut

sub discard {
   my $self = shift;
   delete $self->{_store};
}

=item $hd->delete

Delete the row from the database

=cut

sub delete {
   my $self = shift;

   if ($self->{id}) {
      sql_exec $self->dbh,
               "delete from $self->{table} where $self->{key_expr}",
               @{$self->{id}};
   }

   $self->discard;
}

sub DESTROY {
   my $self = shift;

   if ($self->{autocommit}) {
      local $@; # do not erase valuable error information (like upcalls ;)
      eval {
         local $SIG{__DIE__} = \&PApp::Exception::diehandler;
         $self->flush;
      };
      warn "$@, during PApp::DataRef object destruction" if $@;
   }
}

package PApp::DataRef::Scalar::Proxy;

# merely a proxy class to re-route method calls

sub AUTOLOAD {
   my $package = ref tied ${$_[0]};
   (my $method = $AUTOLOAD) =~ s/.*(?=::)/$package/se;
   *{$AUTOLOAD} = sub {
      unshift @_, tied ${+shift};
      goto &$method;
   };
   goto &$AUTOLOAD;
}

sub DESTROY { }

package PApp::DataRef::Hash::Proxy;

# merely a proxy class to re-route method calls

sub AUTOLOAD {
   my $package = ref tied %{$_[0]};
   (my $method = $AUTOLOAD) =~ s/.*(?=::)/$package/se;
   *{$AUTOLOAD} = sub {
      unshift @_, tied %{+shift};
      goto &$method;
   };
   goto &$AUTOLOAD;
}

sub DESTROY { }

=back

=head1 How Flushes are Implemented

When a single value (delay => 0) is being read or written, DataRef creates
a single access:

   SELECT column FROM table WHERE id = ?
   UPDATE table SET column = ? where id = ?

In other cases, DataRef reads and writes full rows:

   SELECT * FROM table WHERE id = ?

When a row is being written and the id is C<undef> or zero, DataRef uses
the C<insertid> callback to create a new insertion id followed by an
INSERT (if insretid is 1, it uses an INSERT followed by C<sql_insertid>,
so your id volumn should better be defined as auto increment in your
database). If the id is defined, the update is driver specific:

for mysql (if appropriate):

   REPLACE INTO table (...) VALUES (...)

and for other databases:

   INSERT INTO table (...) VALUES (...)
   and, if the above commend fails,
   UPDATE table SET ? = ?, ? = ?, ... WHERE id = ?

no checking wether the UPDATE succeeded is done (yet).

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

