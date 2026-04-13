package Object::Proto::Sugar;

use 5.008003;
use strict;
use warnings;
use BEGIN::Lift;
use Devel::Hook;
use Object::Proto;
use Carp qw/croak/;

our $VERSION = 0.05;

use constant ro => 'ro';
use constant is_ro => ( is => ro );
use constant rw => 'rw';
use constant is_rw => ( is => rw );
use constant nan => undef;
use constant lzy => ( lazy => 1 );
use constant bld => ( builder => 1 );
use constant lzy_bld => ( lazy_build => 1 );
use constant trg => ( trigger => 1 );
use constant clr => ( clearer => 1 );
use constant req => ( required => 1 );
use constant coe => ( coerce => 1 );
use constant lzy_hash => (lazy => 1, isa => 'HashRef', default => {} );
use constant lzy_array => (lazy => 1, isa => 'ArrayRef', default => [] );
use constant lzy_str => (lazy => 1, isa => 'Str', default => "");
use constant dhash => (isa => 'HashRef', default => {});
use constant darray => (isa => 'ArrayRef', default => []);
use constant dstr => (isa => 'Str', default => "");

our (%valid_types, @type_list, %valid_constants, %modifier_dispatch, %accessor_aliases);

BEGIN {
	@type_list  = @{ Object::Proto::list_types() };
	%valid_types = map { $_ => 1 } @type_list;
	%valid_constants = map { $_ => 1 } qw(
		ro rw is_ro is_rw nan
		lzy bld lzy_bld trg clr req coe
		lzy_hash lzy_array lzy_str dhash darray dstr
	);
	%modifier_dispatch = (
		before => \&Object::Proto::before,
		after  => \&Object::Proto::after,
		around => \&Object::Proto::around,
	);
}

sub import {
	my ($pkg, @import) = @_;
	my $caller = caller();
	my (@spec, @modifiers, @extends, @with, @requires, $is_role, $accessor_alias);
	$is_role = 1 if grep { $_ eq '-role' } @import;

	if (grep { $_ eq '-types' } @import) {
		no strict 'refs';
		*{"${caller}::${_}"} = sub { $_ } for @type_list;
	}
	if (grep { $_ eq '-constants' } @import) {
		no strict 'refs';
		*{"${caller}::${_}"} = \&{"Object::Proto::Sugar::${_}"} for keys %valid_constants;
	}

	for my $name (@import) {
		no strict 'refs';
		next if $name =~ /^-/;
		if ($name =~ /^[A-Z]/) {
			croak "Unknown type '$name' requested from Object::Proto::Sugar"
				unless $valid_types{$name};
			*{"${caller}::${name}"} = sub { $name };
		} else {
			croak "Unknown constant '$name' requested from Object::Proto::Sugar"
				unless $valid_constants{$name};
			*{"${caller}::${name}"} = \&{"Object::Proto::Sugar::${name}"};
		}
	}

	BEGIN::Lift::install(
		($caller, 'has') => sub {
			my ($name, %params) = @_;
			if (ref $name) {
				for (@{$name}) {
					push @spec, $_, \%params;
				}
			} else {
				push @spec, $name, \%params;
			}
		}
	);

	BEGIN::Lift::install(
		($caller, 'attributes') => sub {
			my @attr = @_;
			while (@attr) {
				my @names = ref $attr[0] eq 'ARRAY' ? @{ shift @attr } : shift @attr;
				my @sp = @{ shift(@attr) };
				splice @sp, $#sp < 1 ? 0 : 1, 0, delete $sp[-1]->{default}
					if ref $sp[-1] eq 'HASH' && exists $sp[-1]->{default};
				unshift @sp, 'ro' unless (!$sp[0] || !ref $sp[0]) && ($sp[0] || "") =~ m/^(ro|rw|set)$/;
				my %params = (is => $sp[0]);
				$params{default} = ref $sp[1] eq 'CODE' ? $sp[1] : sub { Object::Proto::clone($sp[1]) }
					if defined $sp[1];
				%params = (%params, %{ $sp[2] }) if ref $sp[2] eq 'HASH';
				push @spec, $_, \%params for @names;
			}
		}
	);


	BEGIN::Lift::install(
		($caller, 'extends') => sub { push @extends, @_ }
	);

	BEGIN::Lift::install(
		($caller, 'with') => sub { push @with, @_ }
	);

	BEGIN::Lift::install(
		($caller, 'requires') => sub { push @requires, @_ }
	);

	BEGIN::Lift::install(
		($caller, 'accessor_alias') => sub { $accessor_alias = $_[0] }
	);

	for my $mod_type (qw/before after around/) {
		BEGIN::Lift::install(
			($caller, $mod_type) => sub {
				my ($name, $code) = @_;
				push @modifiers, [$mod_type, $name, $code];
			}
		);
	}

	Devel::Hook->push_UNITCHECK_hook(sub {
		my @spec_copy = @spec;
		my (@func_names, $attr, $spec, %isa, @attributes);
		while (@spec) {
			($attr, $spec) = (shift @spec, shift @spec);
			$attr = _configure_is($attr, $spec);
			$attr = _configure_required($attr, $spec);
			$attr = _configure_lazy($attr, $spec);
			$attr = _configure_isa_and_coerce($attr, $spec, \%isa, $caller);
			$attr = _configure_default_and_builder($attr, $spec, \%isa, $caller);
			$attr = _configure_trigger($attr, $spec, \%isa, $caller);
			$attr = _configure_predicate($attr, $spec, $caller, 'predicate');
			$attr = _configure_clearer($attr, $spec, $caller, 'clearer');
			$attr = _configure_reader_and_writer($attr, $spec, $caller);
			$attr = _configure_init_arg($attr, $spec, $caller);
			$attr = _configure_weak_ref($attr, $spec, $caller);
			push @attributes, $attr;
		}

		my @extends_arg = @extends > 1 
			? (extends => \@extends)
			: @extends 
				? (extends => $extends[0])
				: ();
		if ($is_role) {
			Object::Proto::role($caller, @attributes);
			Object::Proto::requires($caller, @requires) if @requires;
		} else {
			Object::Proto::define($caller, @extends_arg, @attributes);
		}
		Object::Proto::with($caller, @with) if @with;

		$accessor_aliases{$caller} = $accessor_alias if $accessor_alias;

		my %func_to_attr;
		while (@spec_copy) {
			my ($name, $spec) = (shift @spec_copy, shift @spec_copy);
			my @fnames = _install_func_accessors($caller, $name, $spec, $accessor_alias);
			$func_to_attr{$_} = $name for @fnames;
			push @func_names, @fnames;
		}

		if (@func_names) {
			no strict 'refs';
			push @{"${caller}::EXPORT_FUNC"}, @func_names;
		}

		{
			no strict 'refs';
			no warnings 'redefine';
			*{"${caller}::import_accessors"} = sub {
				my ($class, @names) = @_;
				my $target = caller();
				# Use C-level installer - creates CVs with call checkers
				# so code compiled after this gets custom ops
				unless (@names) {
					for my $pkg (_mro($class)) {
						my $alias = $accessor_aliases{$pkg} || '';
						Object::Proto::import_accessors($pkg, ($alias ? "${alias}_" : ""), $target);
					}
				} else {
					for my $name (@names) {
						my $attr = $func_to_attr{$name} || $name;
						for my $pkg (_mro($class)) {
							if (defined &{"${pkg}::${name}"}) {
								Object::Proto::import_accessor($pkg, $attr, $name, $target);
								last;
							}
						}
					}
				}
			};
		}

		for my $mod (@modifiers) {
			my ($type, $name, $code) = @{$mod};
			my $meth = $name =~ /::/ ? $name : "${caller}::${name}";
			$modifier_dispatch{$type}->($meth, $code);
		}
	});
}

sub _mro {
	my ($class) = @_;
	my (@queue, @order, %seen) = ($class);
	while (my $pkg = shift @queue) {
		next if $seen{$pkg}++;
		push @order, $pkg;
		no strict 'refs';
		push @queue, @{"${pkg}::ISA"};
	}
	return @order;
}

sub _configure_is {
	my ($attr, $spec) = @_;
	if (defined $spec->{is}) {
		if ($spec->{is} eq 'ro') {
			$attr .= ":readonly";
		}
	}
	return $attr;
}


sub _configure_required {
	my ($attr, $spec) = @_;
	if ($spec->{required}) {
		$attr .= ":required";
	}
	return $attr;
}

sub _configure_lazy {
	my ($attr, $spec) = @_;
	if ( $spec->{lazy} ) {
		$attr .= ":lazy";
	}
	return $attr;
}

sub _configure_isa_and_coerce {
	my ($attr, $spec, $isa, $caller) = @_;
	my ($ref, $val1, $val2);
	if (defined $spec->{isa} || defined $spec->{coerce}) {
		$ref = ref $spec->{isa} || "";
		if ($ref eq 'CODE' || defined $spec->{coerce}) {
			$val1 = (exists $spec->{isa} ? $spec->{isa} + 0 : '0000');
			$val2 = (exists $spec->{coerce} ? $spec->{coerce} + 0 : '0000');
			if (!$isa->{$val1 . $val2}++) {
				Object::Proto::register_type('T' . $val1 . $val2,
					$spec->{isa} || sub { 1 },
					$spec->{coerce} || sub { $_[0] }
				);
			}
			$attr .= sprintf(":T%s%s", $val1, $val2);
		} elsif ( !$ref ) {
			$val1 = ucfirst($spec->{isa});
			if ($valid_types{$val1}) {
				$attr .= sprintf(":%s", $val1);
			}
		} else {
			croak "Failed to attach isa for $attr in $caller";
		}
	}

	return $attr;
}

sub _configure_default_and_builder {
	my ($attr, $spec, $isa, $caller) = @_;
	my ($ref1, $ref2, $val1, $cb);
	return $attr unless exists $spec->{default} || exists $spec->{builder};
	$ref1 = ref($spec->{default}) || "";
	if (exists $spec->{builder} || $ref1 eq 'CODE') {
		$ref2 = ref($spec->{builder});
		if (! $ref2 && $ref1 ne 'CODE') {
			if ($spec->{builder} =~ m/^1$/) {
				$attr .= ':builder()';
			} else {
				$attr .= sprintf(":builder(%s)", $spec->{builder});
			}
		} elsif ( $ref2 eq 'CODE' || $ref1 eq 'CODE' ) {
			my $cb = exists $spec->{builder} ? $spec->{builder} : $spec->{default};
			$val1 = 'BUILDER' . ($cb + 0);
			if (!$isa->{$val1}++) {
				no strict 'refs';
				*{"${caller}::${val1}"} = $cb;
			}
			$attr .= sprintf(":builder(%s)", $val1);
		} else {
			croak "Failed to attach builder for $attr in $caller";
		}
	} elsif ( ! $ref1 ) {
		$attr .= sprintf(":default(%s)", defined $spec->{default} ? $spec->{default} : 'undef' );
	} elsif ( $ref1 eq 'ARRAY') {
		$attr .= ":default([])";
	} elsif ( $ref1 eq 'HASH' ) {
		$attr .= ":default({})";
	}
	return $attr;
}

sub _configure_trigger {
	my ($attr, $spec, $isa, $caller) = @_;
	my ($ref, $val1);
	if (exists $spec->{trigger}) {
		$ref = ref $spec->{trigger};
		if ( ! $ref ) {
			$attr .= sprintf(":trigger(%s)", $spec->{trigger});
		} elsif ( $ref eq 'CODE' ) {
			$val1 = 'TRIG' . ($spec->{trigger} + 0);
			if (!$isa->{$val1}++) {
				no strict 'refs';
				*{"${caller}::${val1}"} = $spec->{trigger};
			}
			$attr .= sprintf(":trigger(%s::%s)", $caller, $val1);
		}

	}
	return $attr;
}

sub _configure_predicate {
	my ($attr, $spec, $caller) = @_;
	if (defined $spec->{predicate}) {
		if ($spec->{predicate} =~ 1) {
			$attr .= ":predicate";
		} elsif (! ref $spec->{predicate}) {
			$attr .= sprintf(":predicate(%s)", $spec->{predicate});
		} else {
			croak "Failed to attach predicate for $attr in $caller";
		}
	}
	return $attr;
}

sub _configure_clearer {
	my ($attr, $spec, $caller) = @_;
	if (defined $spec->{clearer}) {
		if ($spec->{clearer} =~ 1) {
			$attr .= ":clearer";
		} elsif (! ref $spec->{clearer}) {
			$attr .= sprintf(":clearer(%s)", $spec->{clearer});
		} else {
			croak "Failed to attach clearer for $attr in $caller";
		}
	}
	return $attr;
}

sub _configure_reader_and_writer {
	my ($attr, $spec, $caller) = @_;
	my ($name) = $attr =~ m/^([^\:]+)/;
	if (exists $spec->{reader}) {
		croak "Failed to attach reader for $attr in $caller" unless ! ref $spec->{reader};
		if ($spec->{reader} =~ m/^1$/) {
			$attr .= sprintf(":reader(get_%s)", $name);
		} else {
			$attr .= sprintf(":reader(%s)", $spec->{reader});
		}
	}
	if (exists $spec->{writer}) {
		croak "Failed to attach writer for $attr in $caller" unless ! ref $spec->{writer};
		if ($spec->{writer} =~ m/^1$/) {
			$attr .= sprintf(":writer(set_%s)", $name);
		} else {
			$attr .= sprintf(":writer(%s)", $spec->{writer});
		}
	}
	return $attr;
}

sub _configure_init_arg {
	my ($attr, $spec) = @_;
	if (defined $spec->{init_arg} || defined $spec->{arg}) {
		$attr .= sprintf(":arg(%s)", $spec->{init_arg} || $spec->{arg});
	}
	return $attr;
}

sub _configure_weak_ref {
	my ($attr, $spec) = @_;
	if ($spec->{weak_ref} || $spec->{weak}) {
		$attr .= ':weak';
	}
	return $attr;
}

sub _install_func_accessors {
	my ($caller, $name, $spec, $alias) = @_;
	my @installed;
	if (exists $spec->{accessor}) {
		my $fname = ($alias && $spec->{accessor} eq '1')
			? $alias . '_' . $name
			: $spec->{accessor} eq '1' ? $name : $spec->{accessor};
		Object::Proto::import_accessor($caller, $name, $fname, $caller);
		push @installed, $fname;
	}
	if (exists $spec->{reader} && !ref $spec->{reader}) {
		my $fname = $spec->{reader} eq '1' ? "get_$name" : $spec->{reader};
		$fname = $alias . '_' . $fname if $alias && $spec->{reader} eq '1';
		Object::Proto::import_accessor($caller, $name, $fname, $caller);
		push @installed, $fname;
	}
	if (exists $spec->{writer} && !ref $spec->{writer}) {
		my $fname = $spec->{writer} eq '1' ? "set_$name" : $spec->{writer};
		$fname = $alias . '_' . $fname if $alias && $spec->{writer} eq '1';
		Object::Proto::import_accessor($caller, $name, $fname, $caller);
		push @installed, $fname;
	}
	return @installed;
}

1;

__END__

=head1 NAME

Object::Proto::Sugar - Moo-se-like syntax for Object::Proto

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

	package Animal;
	use Object::Proto::Sugar -types, -constants;

	has name  => (is_rw, req, isa => Str);
	has sound => (is_rw, isa => Str, default => 'silence');

	sub speak { $_[0]->sound }

	package Dog;
	use Object::Proto::Sugar qw(Str is_rw);

	extends 'Animal';

	has breed => (is_rw, isa => Str);

	package main;

	my $dog = new Dog name => 'Rex', sound => 'woof', breed => 'Lab';
	print $dog->speak;          # woof
	print $dog->isa('Animal');  # 1

=head1 DESCRIPTION

C<Object::Proto::Sugar> provides Moo-se-like declarative syntax over
L<Object::Proto>, giving you C<has>, C<extends>, C<with>, C<requires>,
and method modifiers - all compiled down to the zero-overhead XS layer
underneath.

Nothing beyond the keywords are imported by default. Type constants
(C<Str>, C<Int>, ...) and sugar constants (C<is_rw>, C<req>, ...) are
opt-in via import flags or explicit named imports. See L</IMPORTING>.

=head1 KEYWORDS

=head2 has $name => (%options)

Declares an attribute. All options are optional unless noted.

	has age => (
	    is       => 'rw',        # 'rw' (read-write) or 'ro' (read-only)
	    isa      => Int,         # type constraint (string or constant)
	    required => 1,           # must be supplied to constructor
	    default  => 0,           # default value when parsed a codeblock it's actually installed as a builder
	    lazy     => 1,           # compute default on first access
	    builder  => '_build_age',# method name (or 1 for _build_$name)
	    coerce   => sub { ... }, # coerce incoming value
	    trigger  => sub { ... }, # called after value is set
	    predicate => 1,          # install has_$name (or custom name)
	    clearer   => 1,          # install clear_$name (or custom name)
	    reader    => 1,          # install get_$name (or custom name)
	    writer    => 1,          # install set_$name (or custom name)
	    init_arg  => '_age',     # constructor key (alias: arg)
	    weak_ref  => 1,          # store a weak reference (alias: weak)
	);

=head3 is

	is => 'rw'   # read-write accessor
	is => 'ro'   # read-only (setter dies)

=head3 isa

Accepts a type name string, an imported type constant, or a custom coderef:

	isa => 'Str'              # type name string - always works
	isa => Str                # type constant - requires: use Object::Proto::Sugar qw(Str)
	isa => sub { $_[0] > 0 } # custom check - dies on failure

=head3 default

	default => 42           # scalar
	default => 'text'       # string
	default => []           # fresh arrayref per object
	default => {}           # fresh hashref per object
	default => sub { ... }  # coderef - called as builder

=head3 builder

	builder => 1              # calls _build_$name on the object
	builder => '_my_builder'  # calls named method on the object
	builder => sub { ... }    # anonymous sub installed as builder

=head3 predicate and clearer

	predicate => 1           # installs has_$name
	predicate => 'is_set'    # installs is_set

	clearer => 1             # installs clear_$name
	clearer => 'reset_age'   # installs reset_age

=head3 reader and writer

	reader => 1              # installs get_$name
	reader => 'fetch_age'    # installs fetch_age

	writer => 1              # installs set_$name
	writer => 'store_age'    # installs store_age

=head3 accessor

Install a function-style accessor for maximum performance. The function can be
called as C<fname($obj)> (get) or C<fname($obj, $value)> (set), avoiding
method dispatch overhead entirely.

	accessor => 1          # installs function named after the attribute
	accessor => 'fname'    # installs function with custom name

Unlike C<reader>/C<writer>, C<accessor> installs a single combined get/set
function. C<reader> and C<writer> also install function-style versions
alongside their method-style ones when specified.

	has age => ( is => 'rw', accessor => 1 );
	# method style: $obj->age
	# function style: age($obj) or age($obj, 42)

	has age => ( is => 'rw', reader => 1, writer => 1 );
	# method style: $obj->get_age, $obj->set_age
	# function style: get_age($obj), set_age($obj, 42)

=head3 init_arg / arg

Override the constructor key used to populate this attribute:

	has name => ( is => 'rw', init_arg => '_name' );
	# new MyClass _name => 'Alice'

C<arg> is an alias for C<init_arg>.

=head3 weak_ref / weak

Store a weak reference. The attribute becomes C<undef> when the referent
is garbage-collected:

	has parent => ( is => 'rw', weak_ref => 1 );

C<weak> is an alias for C<weak_ref>.

=head2 attributes $name => \@spec, ...

A positional shorthand for declaring one or more attributes in a compact
array-based syntax, rather than the named-pair style of C<has>.

Each declaration is a name (or arrayref of names) paired with an arrayref
specifying C<[mode, default, \%options]>:

	attributes x => ['rw'];
	attributes y => ['ro', 0];
	attributes z => ['rw', sub { [] }, { required => 1 }];

Multiple names sharing the same spec can be declared in one call:

	attributes [qw(width height)] => ['rw', 0];

=head3 Spec arrayref format

	[ $mode ]
	[ $mode, $default ]
	[ $mode, $default, \%options ]
	[ $mode, \%options ]          # default supplied inside %options
	[ \%options ]                 # mode defaults to 'ro'

=over 4

=item * B<mode> - C<'ro'>, C<'rw'>, or C<'set'>. Defaults to C<'ro'> if omitted.

=item * B<default> - a scalar, reference, or coderef. Non-code values are
deep-cloned per object via C<Object::Proto::clone> so each instance gets its
own independent copy. A coderef is installed as a builder.

=item * B<%options> - any option accepted by C<has>: C<required>, C<lazy>,
C<isa>, C<coerce>, C<builder>, C<trigger>, C<predicate>, C<clearer>,
C<reader>, C<writer>, C<init_arg>/C<arg>, C<weak_ref>/C<weak>,
C<accessor>. The C<default> key may also be placed here instead of in the
positional slot.

=back

Examples:

	# equivalent to: has x => (is => 'rw', default => 0)
	attributes x => ['rw', 0];

	# equivalent to: has tags => (is => 'ro', default => sub { [] })
	attributes tags => ['ro', []];

	# default inside options hash - identical result
	attributes tags => ['ro', { default => [] }];

	# multiple names, shared spec
	attributes [qw(created_at updated_at)] => ['ro', { required => 1 }];

	# full options
	attributes email => ['rw', undef, { isa => Str, required => 1 }];

=head2 extends @parents

Inherit from one or more Object::Proto classes. Parent slots are copied
into the child at define time; C<@ISA> is set up for method dispatch.

	extends 'Animal';
	extends 'Animal', 'Flyable';   # multiple inheritance

The parent class must have been defined with C<Object::Proto::Sugar> (or
C<Object::Proto::define>) before the child's package is compiled.

=head2 with @roles

Compose one or more roles into the current class (or role):

	with 'Printable';
	with 'Printable', 'Serializable';

The role must have been defined before the consuming class.

=head2 requires @methods

Declare methods that a consuming class must implement. Only meaningful
inside a role (C<use Object::Proto::Sugar -role>):

	requires 'name';
	requires 'to_string', 'to_hash';

=head2 before $method => sub { ... }

Run code before the named method. Receives the same arguments as the method.

	before 'save' => sub {
	    my ($self) = @_;
	    $self->updated_at(time);
	};

=head2 after $method => sub { ... }

Run code after the named method. Receives the same arguments as the method.

	after 'save' => sub {
	    my ($self) = @_;
	    log_action('saved ' . $self->name);
	};

=head2 around $method => sub { ... }

Wrap a method. The wrapper receives C<$orig> as its first argument:

	around 'greet' => sub {
	    my ($orig, $self, @args) = @_;
	    return uc $self->$orig(@args);
	};

Multiple modifiers can be stacked. C<before> modifiers run in reverse
declaration order; C<after> modifiers run in declaration order.

The C<$method> name may be unqualified (resolved to the current package)
or fully qualified (C<'Other::Package::method'>).

=head2 accessor_alias $prefix

Set a package-level prefix for all function-style accessors installed via
C<accessor =E<gt> 1>, C<reader =E<gt> 1>, and C<writer =E<gt> 1>. The
prefix is prepended with an underscore separator. Custom accessor/reader/writer
names (i.e. not C<1>) are not affected.

	package Point;
	use Object::Proto::Sugar;

	accessor_alias 'pt';

	has x => ( is => 'rw', accessor => 1 );
	has y => ( is => 'rw', accessor => 1 );

	# Installs: pt_x(), pt_y() instead of x(), y()
	# Method accessors $obj->x, $obj->y still work

When used with C<reader> and C<writer>:

	accessor_alias 'db';

	has name => ( is => 'rw', accessor => 1, reader => 1, writer => 1 );
	# accessor: db_name()
	# reader:   db_get_name()
	# writer:   db_set_name()

Each class in an inheritance chain can have its own alias. When
C<import_accessors> is called, each class's accessors use that class's
alias:

	package Vehicle;
	use Object::Proto::Sugar;
	accessor_alias 'v';
	has speed => ( is => 'rw', accessor => 1 );

	package Car;
	use Object::Proto::Sugar;
	extends 'Vehicle';
	accessor_alias 'c';
	has brand => ( is => 'rw', accessor => 1 );

	package main;
	Car->import_accessors;
	# Imports: c_brand() from Car, v_speed() from Vehicle

Without C<accessor_alias>, C<accessor =E<gt> 1> installs a function named
after the attribute as before.

=head1 ROLES

Define a role by passing C<-role> to the import:

	package Printable;
	use Object::Proto::Sugar -role;

	requires 'name';

	has format => ( is => 'rw', default => 'text' );

	sub print_self { $_[0]->name . ' (' . $_[0]->format . ')' }

Consume it with C<with>:

	package Document;
	use Object::Proto::Sugar qw(Str);

	with 'Printable';

	has name => ( is => 'rw', isa => Str );

Check consumption at runtime:

	Object::Proto::does($doc, 'Printable');  # true

=head1 IMPORTING

By default C<use Object::Proto::Sugar> installs only the compile-time
keywords (C<has>, C<attributes>, C<extends>, C<with>, C<requires>,
C<before>, C<after>, C<around>). Everything else is opt-in:

=over 4

=item C<-role>

Mark the current package as a role instead of a class.

=item C<-types>

Import all built-in type constants (C<Str>, C<Int>, C<ArrayRef>, ...).

=item C<-constants>

Import all sugar shorthand constants (C<is_rw>, C<req>, C<lzy_array>, ...).

=item Named imports

Import individual types or constants by name. Uppercase names are treated
as types, lowercase as sugar constants. Unknown names croak at compile time.

=back

Examples:

	use Object::Proto::Sugar;                        # keywords only
	use Object::Proto::Sugar -types;                 # + all type constants
	use Object::Proto::Sugar -constants;             # + all sugar constants
	use Object::Proto::Sugar -types, -constants;     # + both
	use Object::Proto::Sugar qw(Str Int);            # + specific types
	use Object::Proto::Sugar qw(is_rw req);          # + specific sugar constants
	use Object::Proto::Sugar qw(Str is_rw req);      # + mix of both
	use Object::Proto::Sugar -role, -types;          # role + all types



=head1 TYPE CONSTANTS

Type constants are opt-in. See L</IMPORTING> for the full import syntax.

The built-in types are:

=over 4

=item * C<Any>

=item * C<Defined>

=item * C<Str>

=item * C<Int>

=item * C<Num>

=item * C<Bool>

=item * C<ArrayRef>

=item * C<HashRef>

=item * C<CodeRef>

=item * C<Object>

=back

Custom types registered with C<Object::Proto::register_type> before
C<use Object::Proto::Sugar> is called will also get a constant exported.

=head1 SUGAR CONSTANTS

Sugar constants are opt-in shorthand that expand inline into C<has> option
lists. See L</IMPORTING> for the full import syntax.

	use Object::Proto::Sugar -constants;

	has name  => (is_rw, req);
	has tags  => (is_ro, lzy_array);
	has score => (is_rw, nan);    # explicit undef default

=head2 Mode constants

	ro          # 'ro'
	rw          # 'rw'
	is_ro       # (is => 'ro')
	is_rw       # (is => 'rw')

=head2 Value constants

	nan         # undef  (explicit undef default)

=head2 Option constants

	req         # (required => 1)
	lzy         # (lazy => 1)
	bld         # (builder => 1)
	lzy_bld     # (lazy_build => 1)
	trg         # (trigger => 1)
	clr         # (clearer => 1)
	coe         # (coerce => 1)

=head2 Lazy + default constants

	lzy_hash    # (lazy => 1, isa => 'HashRef',  default => {})
	lzy_array   # (lazy => 1, isa => 'ArrayRef', default => [])
	lzy_str     # (lazy => 1, isa => 'Str',      default => "")

=head2 Default-only constants

	dhash       # (isa => 'HashRef',  default => {})
	darray      # (isa => 'ArrayRef', default => [])
	dstr        # (isa => 'Str',      default => "")

The C<default> values in these constants are plain refs/scalars. Sugar
deep-clones them via C<Object::Proto::clone> so each object instance gets
its own independent copy.

=head2 Usage examples

	has config   => (is_rw, lzy_hash);
	has items    => (is_ro, darray);
	has label    => (is_rw, dstr);
	has name     => (is_rw, req, isa => 'Str');
	has handler  => (is_ro, lzy, bld, isa => 'CodeRef');

	# positional attributes syntax also works
	attributes score => [rw, 0, { req }];

=head1 INHERITANCE

=head2 Single parent

	package Dog;
	use Object::Proto::Sugar qw(Str);

	extends 'Animal';

	has breed => ( is => 'rw', isa => Str );

C<Dog> inherits all of C<Animal>'s slots and methods. Inherited slots
occupy the same positions as in the parent so there is no runtime
overhead for access.

=head2 Multiple parents

	extends 'Animal', 'Flyable';

Parent slots are merged left-to-right. A child slot with the same name
as a parent slot overrides it.

=head1 BENCHMARK

	Test: new + set + get
	------------------------------------------------------------
	Benchmark: running Moo, Mouse, Sugar, Sugar (fn) for at least 3 CPU seconds...
	       Moo:  3 wallclock secs ( 3.09 usr +  0.00 sys =  3.09 CPU) @ 1264320.39/s (n=3906750)
	     Mouse:  4 wallclock secs ( 3.15 usr +  0.00 sys =  3.15 CPU) @ 1290237.46/s (n=4064248)
	     Sugar:  4 wallclock secs ( 3.01 usr +  0.00 sys =  3.01 CPU) @ 2784378.41/s (n=8380979)
	Sugar (fn):  4 wallclock secs ( 3.11 usr +  0.00 sys =  3.11 CPU) @ 3174092.93/s (n=9871429)
			Rate        Moo      Mouse      Sugar Sugar (fn)
	Moo        1264320/s         --        -2%       -55%       -60%
	Mouse      1290237/s         2%         --       -54%       -59%
	Sugar      2784378/s       120%       116%         --       -12%
	Sugar (fn) 3174093/s       151%       146%        14%         --

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-object-proto-sugar at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Proto-Sugar>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Object::Proto::Sugar

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Object-Proto-Sugar>

=item * Search CPAN

L<https://metacpan.org/release/Object-Proto-Sugar>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Object::Proto::Sugar
