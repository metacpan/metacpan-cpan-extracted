package Object::PadX::Enum 0.02;

use v5.22;
use warnings;

use Carp;
use Object::Pad 0.825 ();
use Object::Pad::MOP::Class qw( :experimental(mop) );

# Loaded for its XS keyword registrations
require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=encoding UTF-8

=for highlighter language=perl

=head1 NAME

C<Object::PadX::Enum> - syntactic sugar for enum-like singleton-bearing C<Object::Pad> classes

=head1 SYNOPSIS

   use Object::PadX::Enum;

   enum Raptor {
      item VELOCIRAPTOR   ( max_speed_kmh => 60, max_weight_kg =>  15, max_height_cm =>  50 );
      item DEINONYCHUS    ( max_speed_kmh => 50, max_weight_kg =>  80, max_height_cm =>  87 );
      item UTAHRAPTOR     ( max_speed_kmh => 35, max_weight_kg => 500, max_height_cm => 150 );
      item MICRORAPTOR    ( max_speed_kmh => 40, max_weight_kg =>   1, max_height_cm =>  30 );
      item DROMAEOSAURUS  ( max_speed_kmh => 60, max_weight_kg =>  15, max_height_cm =>  50 );

      field $max_speed_kmh  :param :reader;
      field $max_weight_kg  :param :reader;
      field $max_height_cm  :param :reader;

      method speed_per_kg { return $max_speed_kmh / $max_weight_kg }
      method speed_per_cm { return $max_speed_kmh / $max_height_cm }

      method fastest :common {
         my ( $top ) = sort { $b->max_speed_kmh <=> $a->max_speed_kmh } $class->values;
         return $top;
      }
   }

   say Raptor->VELOCIRAPTOR->max_speed_kmh;  # 60
   say Raptor->DEINONYCHUS->speed_per_kg;    # 0.625
   say Raptor->from_ordinal(2)->name;        # UTAHRAPTOR
   say Raptor->from_name("MICRORAPTOR")->speed_per_cm; # 1.33333333333333
   say 'Fastest in absolute terms: ', Raptor->fastest->name; # VELOCIRAPTOR or DROMAEOSAURUS (tie)

=head1 DESCRIPTION

C<Object::PadX::Enum> adds two keywords on top of L<Object::Pad>:

=over 4

=item * C<enum NAME ATTRS? { ... }>

Declares a class (using L<Object::Pad>'s C<class> machinery) and auto-injects
C<$ordinal :reader> and C<name :reader> fields. The C<name> reader returns the
identifier under which the singleton was declared (e.g. C<"RED">). Inside the
block, all normal C<Object::Pad> constructs (C<field>, C<method>, C<ADJUST>,
...) are available, plus the C<item> keyword.

The following class-level attributes are accepted:

=over 4

=item C<:isa(CLASS)>, C<:isa(CLASS VERSION)>

=item C<:extends(CLASS)>, C<:extends(CLASS VERSION)>

Declares a superclass; equivalent to L<Object::Pad>'s C<:isa>. The package is
loaded automatically. If a VERSION is given, C<< CLASS->VERSION(VERSION) >> is
called to enforce it.

An C<enum> may inherit from another C<enum>. Fields, methods, roles and
C<ADJUST> phasers from the parent are inherited normally. The parent's
B<items> are I<not> inherited: the child has its own ordinal-zero-based item
sequence, and accessing a parent item name on the child raises an error. The
child's C<values>, C<from_ordinal> and C<from_name> see only the child's
items. A parent enum must be finalized (i.e. its declaration must have
already executed at runtime) before a child enum that inherits from it; in
practice this is satisfied by normal source ordering and C<use> ordering.

=item C<:does(ROLE)>, C<:does(ROLE VERSION)>

Composes a role into the enum class. May be repeated for multiple roles. The
role package is loaded automatically.

=back

The class attributes C<:abstract>, C<:strict>, C<:repr> and C<:lexical_new>
are not supported. C<:abstract> is semantically incompatible with C<item>
(singletons cannot be constructed for an abstract class); the others have no
public L<Object::Pad::MOP::Class> entry point and would require reaching into
private Object::Pad internals.

=item * C<item NAME ( ARGS );>

Declares a named singleton instance of the enclosing C<enum>. C<ARGS> is the
key/value list passed to the auto-generated constructor; the parentheses (and
the arg list) are optional, so C<item FOO;> is equivalent to C<item FOO();>.

=back

After the C<enum> block closes, the following class-level methods are
installed on the enum class for each declared singleton C<NAME>:

   $singleton = ClassName->NAME;          # the named singleton
   @all       = ClassName->values;        # all singletons in declaration order
   $byord     = ClassName->from_ordinal(0);
   $byname    = ClassName->from_name("RED");

Direct construction via C<< ClassName->new(...) >> is blocked after the
C<enum> block closes; the only ways to obtain a singleton are the per-item
accessor, C<from_name>, and C<from_ordinal>. Subclasses (whether plain
C<class> or another C<enum>) may still call C<new> on themselves; the block
applies only to direct invocation on the enum class itself.

=head1 CAVEATS

=over 4

=item *

User C<field>s require explicit C<:param> if you intend to set them via
C<item> args. C<Object::PadX::Enum> does I<not> inject C<:param> automatically.

=item *

Singletons are constructed at the runtime of the compilation unit that
contains the C<enum> declaration, after that unit's C<UNITCHECK> phase. They
are therefore not visible from earlier C<BEGIN>/C<UNITCHECK> blocks of the
same unit. Normal runtime code (including code inside C<do BLOCK> and
C<eval "STRING"> blocks executed during main runtime) sees them as expected.

=item *

C<enum>-level C<:abstract>, C<:strict>, C<:repr> and C<:lexical_new> are not
supported. See the description of the C<enum> keyword above for the rationale;
C<:isa> and C<:does> I<are> supported.

=item *

The names C<values>, C<from_ordinal>, C<from_name>, C<ordinal> and C<name> are
reserved and must not be used as C<item> names.

=back

=cut

# Per-class state captured during compilation.
# $Pending{$class} = { meta => $meta, items => [ [ $name, \@args, $line ], ... ], seen => { $name => 1 } }
my %Pending;

# Permanent per-class registry of finalized enum item names, in declaration
# order. Populated by `_finalize_enum`. Queried by descendant enum finalizes
# (to shadow inherited item accessors) and could be useful for introspection
# in the future. Keys are class names; values are arrayrefs of item names.
my %EnumItems;

my %RESERVED_ITEM_NAMES = map { $_ => 1 } qw(
   values from_ordinal from_name ordinal name
   new BUILD DOES META
);

sub import {
   my $class  = shift;
   my $caller = caller;

   $^H{ 'Object::PadX::Enum/enum' } = 1;
   $^H{ 'Object::PadX::Enum/item' } = 1;

   Object::Pad->import_into( $caller );
}

# Attributes that have a documented public-MOP entry point.
my %ENUM_ATTR_HANDLERS = (
   isa     => \&_attr_isa,
   extends => \&_attr_isa,
   does    => \&_attr_does,
);

# Attributes that exist on Object::Pad's `class` keyword but are deliberately
# rejected here. The message explains why so users aren't left guessing.
my %ENUM_ATTR_REJECTED = (
   abstract    => "':abstract' is incompatible with enum: singleton values cannot be constructed for an abstract class",
   strict      => "':strict' is not supported on enum (no public Object::Pad MOP entry point); declare a plain 'class' instead",
   repr        => "':repr' is not supported on enum (no public Object::Pad MOP entry point); declare a plain 'class' instead",
   lexical_new => "':lexical_new' is not supported on enum (no public Object::Pad MOP entry point); declare a plain 'class' instead",
);

# Load $pkg via `require`, mirroring Object::Pad's :isa/:does autoload. Returns
# silently on success; croaks on failure.
sub _require_package {
   my ( $pkg, $for ) = @_;

   # Skip require for packages already defined inline (no .pm needed).
   no strict 'refs';
   keys %{ "${pkg}::" } and return;

   ( my $file = "$pkg.pm" ) =~ s{::}{/}g;
   eval { require $file; 1 }
      or croak "Failed to load package '$pkg' for $for: $@";

   return;
}

# Parse "Pkg" or "Pkg VER" into ($pkg, $ver). $ver is undef when absent.
sub _split_versioned_pkg {
   my ( $raw, $attr_name ) = @_;

   defined $raw && length $raw
      or croak "Attribute ':$attr_name' requires a value";

   my ( $pkg, $ver, $extra ) = split /\s+/, $raw, 3;
   defined $extra
      and croak "Attribute ':$attr_name($raw)' has too many parts; expected 'PACKAGE' or 'PACKAGE VERSION'";

   return ( $pkg, $ver );
}

sub _attr_isa {
   my ( $state, $value ) = @_;

   exists $state->{ isa }
      and croak "Multiple ':isa' / ':extends' attributes on enum '$state->{name}'";

   my ( $pkg, $ver ) = _split_versioned_pkg( $value, 'isa' );
   _require_package( $pkg, "':isa($pkg)' on enum '$state->{name}'" );
   defined $ver and $pkg->VERSION( $ver );

   $state->{ isa } = $pkg;
   return;
}

sub _attr_does {
   my ( $state, $value ) = @_;

   my ( $pkg, $ver ) = _split_versioned_pkg( $value, 'does' );
   _require_package( $pkg, "':does($pkg)' on enum '$state->{name}'" );
   defined $ver and $pkg->VERSION( $ver );

   push @{ $state->{ roles } }, $pkg;
   return;
}

# Called by XS at compile-time when `enum NAME ATTRS? {` is encountered.
sub _begin_enum {
   my ( $name, $attrs ) = @_;

   exists $Pending{ $name }
      and croak "Cannot declare enum '$name'; already being defined";

   my $state = { name => $name, roles => [] };
   for my $pair ( @{ $attrs // [] } ) {
      my ( $attr, $value ) = @$pair;

      if ( my $msg = $ENUM_ATTR_REJECTED{ $attr } ) {
         croak "$msg (enum '$name')";
      }

      my $handler = $ENUM_ATTR_HANDLERS{ $attr }
         or croak "Unrecognised attribute ':$attr' on enum '$name'";

      $handler->( $state, $value );
   }

   my @begin_args = ( $name );
   exists $state->{ isa }
      and push @begin_args, ( isa => $state->{ isa } );

   my $meta = Object::Pad::MOP::Class->begin_class( @begin_args );

   $meta->add_role( $_ ) for @{ $state->{ roles } };

   # $ordinal and $_name are reader-only (not :param) so user item args cannot
   # override them; both are stamped after construction in _finalize_enum.
   $meta->add_field( '$ordinal', reader => 'ordinal' );
   $meta->add_field( '$_name',   reader => 'name'    );

   $Pending{ $name } = { meta => $meta, items => [], seen => {} };

   return;
}

# Called at runtime, in source order, for each `item NAME(args)` statement.
sub _register_item {
   my ( $class, $name, $line, @args ) = @_;

   my $entry = $Pending{ $class }
      or croak "Internal error: item '$name' for unknown enum '$class' at line $line";

   $entry->{ seen }{ $name }
      and croak "Duplicate item '$name' in enum '$class' at line $line";

   $RESERVED_ITEM_NAMES{ $name }
      and croak "item name '$name' is reserved in enum '$class' at line $line";

   push @{ $entry->{ items } }, [ $name, \@args, $line ];
   $entry->{ seen }{ $name } = 1;

   return;
}

# Called at runtime, once, after all item statements for the enum have run.
sub _finalize_enum {
   my ( $class ) = @_;

   my $entry = delete $Pending{ $class }
      or croak "Internal error: _finalize_enum on unknown enum '$class'";

   my $meta       = $entry->{ meta };
   my $ord_field  = $meta->get_field( '$ordinal' );
   my $name_field = $meta->get_field( '$_name'   );
   my @ordered;

   my $n = 0;
   for my $item ( @{ $entry->{ items } } ) {
      my ( $name, $args, $line ) = @$item;

      my $instance = eval { $class->new( @$args ) };
      $@ and croak "Failed to construct enum value '$name' of '$class' at line $line: $@";

      # Stamp the ordinal and name after construction so they aren't user-facing :params.
      $ord_field->value(  $instance ) = $n;
      $name_field->value( $instance ) = $name;

      push @ordered, [ $name, $instance ];
      $n++;
   }

   no strict 'refs';
   no warnings 'redefine';

   my %own_names;
   for my $pair ( @ordered ) {
      my ( $name, $instance ) = @$pair;
      $own_names{ $name } = 1;
      *{ "${class}::${name}" } = sub { $instance };
   }

   *{ "${class}::values" } = sub {
      return map { $_->[1] } @ordered;
   };

   *{ "${class}::from_ordinal" } = sub {
      my ( undef, $idx ) = @_;
      defined $idx                  or return undef;
      $idx >= 0 && $idx < @ordered  or return undef;
      return $ordered[ $idx ][ 1 ];
   };

   *{ "${class}::from_name" } = sub {
      my ( undef, $want ) = @_;
      defined $want or return undef;
      for my $pair ( @ordered ) {
         return $pair->[1] if $pair->[0] eq $want;
      }
      return undef;
   };

   # Shadow ancestor enum items not redefined locally. A child enum inherits
   # fields/methods from a parent enum but loses the parent's items: accessing
   # a parent item name on the child raises a clear error rather than
   # returning the parent's singleton via MRO.
   require mro;
   my $linear = mro::get_linear_isa( $class );
   my %shadowed;
   for my $ancestor ( @$linear ) {
      next if $ancestor eq $class;
      my $ancestor_items = $EnumItems{ $ancestor } or next;
      for my $aname ( @$ancestor_items ) {
         next if $own_names{ $aname };
         next if $shadowed{ $aname };
         $shadowed{ $aname } = $ancestor;
         my $msg = "'$aname' is not an item of '$class' (inherited from '$ancestor', shadowed)";
         *{ "${class}::${aname}" } = sub { croak $msg };
      }
   }

   # Register before installing the `new` override so any descendant enum
   # whose finalize runs later (and which calls our `new` via MRO) sees us in
   # the registry.
   $EnumItems{ $class } = [ map { $_->[0] } @ordered ];

   # Block external construction. Capture the original Object::Pad-generated
   # `new` so subclass enums (and plain subclasses) can pass through during
   # their own construction; only direct calls on the enum class itself are
   # rejected.
   my @item_names = map { $_->[0] } @ordered;
   my $orig_new   = \&{ "${class}::new" };

   my $new_msg = "Cannot construct new instances of enum class '$class' directly";
   if ( @item_names ) {
      $new_msg .= '; use one of: ' . join( ', ', @item_names );
      $new_msg .= " (or ${class}->from_name / ${class}->from_ordinal)";
   }

   *{ "${class}::new" } = sub {
      my $invocant = shift;
      $invocant ne $class
         and return $invocant->$orig_new( @_ );
      croak $new_msg;
   };

   return;
}

0x55AA;
