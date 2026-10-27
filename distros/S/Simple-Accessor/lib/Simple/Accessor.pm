package Simple::Accessor;
$Simple::Accessor::VERSION = '1.15';
use 5.010;
use strict;
use warnings;

# ABSTRACT: a light and simple way to provide accessor in perl

# VERSION

=head1 NAME
Simple::Accessor - very simple, light and powerful accessor

=head1 SYNOPSIS

    package Role::Color;
    use Simple::Accessor qw{color};

    sub _build_color { 'red' } # default color

    package Car;

    # that s all what you need ! no more line required
    use Simple::Accessor qw{brand hp};

    with 'Role::Color';

    sub _build_hp { 2 }
    sub _build_brand { 'unknown' }

    package main;

    my $c = Car->new( brand => 'zebra' );

    is $c->brand, 'zebra';
    is $c->color, 'red';

=head1 DESCRIPTION

Simple::Accessor provides a simple object layer without any dependency.
It can be used where other ORM could be considered too heavy.
But it has also the main advantage to only need one single line of code.

It can be easily used in scripts...

=head1 Usage

Create a package and just call Simple::Accessor.
The new method will be imported for you, and all accessors will be directly
accessible.

    package MyClass;

    # that s all what you need ! no more line required
    use Simple::Accessor qw{foo bar cherry apple};

You can also split your attribute declarations across multiple C<use> statements.
Attributes from all imports are merged and fully supported by the constructor,
strict constructor mode, and deterministic initialization ordering.

    package MyClass;

    use Simple::Accessor qw{foo bar};
    use Simple::Accessor qw{cherry apple};

    # all four attributes work in the constructor
    my $o = MyClass->new(foo => 1, bar => 2, cherry => 3, apple => 4);

Inheritance via C<@ISA> is supported. The constructor recognizes attributes
from parent classes, so you can subclass naturally:

    package Vehicle;
    use Simple::Accessor qw{speed};
    sub _build_speed { 0 }

    package Car;
    use parent -norequire, 'Vehicle';
    use Simple::Accessor qw{brand};

    package main;

    my $car = Car->new(brand => 'Tesla', speed => 100);
    is $car->speed, 100;  # parent attr set via child constructor

You can now call 'new' on your class, and create objects using these attributes.
The constructor accepts both a hash and a hashref:

    package main;
    use MyClass;

    my $o = MyClass->new()
        or MyClass->new(bar => 42)
        or MyClass->new({ apple => 'fruit', cherry => 'fruit' });

You can get / set any value using the accessor

    is $o->bar(), 42;
    $o->bar(51);
    is $o->bar(), 51;

You can provide your own init method that will be call by new with default args.
This is optional.

    package MyClass;

    sub build { # previously known as initialize
        my ($self, %opts) = @_;

        $self->foo(12345);
    }

You can also control the object after or before its creation using

    sub _before_build {
        my ($self, %opts) = @_;
        ...
    }

    sub _after_build {
        my ($self, %opts) = @_;
        ...
        bless $self, 'Basket';
    }

You can also provide individual builders / initializers

    sub _build_bar { # previously known as _initialize_bar
        # will be used if no value has been provided for bar
        1031;
    }

    sub _build_cherry {
        'red';
    }

You can enable strict constructor mode to catch typos in attribute names:

    package MyClass;
    use Simple::Accessor qw{name age};

    sub _strict_constructor { 1 }

    package main;
    MyClass->new(nmae => 'oops');
    # dies: "MyClass->new(): unknown attribute(s): nmae"

This is opt-in and off by default for backward compatibility.

You can even use a very basic but useful hook system.
Any false value returned by before, validate, or after will stop the setting process.
The after hooks include a re-entrancy guard: if an C<_after_*> hook triggers
a setter that would re-enter the same attribute, the nested C<_after_*> call
is skipped to prevent infinite recursion.

    sub _before_foo {
        my ($self, $v) = @_;

        # do whatever you want with $v
        return 1 or 0;
    }

    sub _validate_foo {
        my ($self, $v) = @_;
        # invalid value ( will not be set )
        return 0 if ( $v == 42);
        # valid value
        return 1;
    }

    sub _after_cherry {
        my ($self) = @_;

        # use the set value for extra operations
        $self->apple($self->cherry());
    }

=head1 METHODS

None. The only public method provided is the classical import.

=cut

my $INFO;

# Internal hash key for re-entrancy guard state.  Uses a null-byte prefix
# so it can never collide with a user-declared attribute name (valid Perl
# identifiers cannot start with \0).
my $_GUARD_KEY = "\0_sa_guard";

# Per-class hook/builder cache.  Populated lazily on first access so that
# hooks installed after import() still get picked up.  Keyed by the actual
# object class (ref $self) so subclass overrides resolve correctly.
# Structure: $_hook_cache->{$class}{"$attr\0$hook"} = $coderef | undef
my $_hook_cache = {};

sub import {
    my ( $class, @attr ) = @_;

    my $from = caller();

    $INFO = {} unless defined $INFO;
    $INFO->{$from} = {} unless defined $INFO->{$from};
    $INFO->{$from}->{'attributes'} ||= [];

    _add_with($from);
    _add_new($from);
    _add_accessors( to => $from, attributes => \@attr );

    # append after _add_accessors succeeds (it dies on duplicates)
    push @{$INFO->{$from}->{'attributes'}}, @attr;

    return;
}

sub _add_with {
    my $class = shift;
    return unless $class;
    # Check own namespace only (not @ISA) so each SA class gets its own with().
    # can() walks @ISA and would skip children whose parents already have with(),
    # but with() is called as a bare function — not a method — so it must exist
    # directly in the class's stash.
    {
        no strict 'refs';
        return if defined &{"${class}::with"};
    }

    my $with  = $class . '::with';
    {
        no strict 'refs';
        *$with = sub {
            my ( @what ) = @_;

            $INFO->{$class}->{'with'} = [] unless $INFO->{$class}->{'with'};
            push @{$INFO->{$class}->{'with'}}, @what;

            foreach my $module ( @what ) {
                die "Invalid module name: $module" unless $module =~ /\A[A-Za-z_]\w*(?:::\w+)*\z/;
                # skip require if the role is already registered (e.g. inline package)
                unless ($INFO->{$module} && $INFO->{$module}->{attributes}) {
                    eval qq[require $module; 1] or die $@;
                }
                die "$module is not a Simple::Accessor role"
                    unless $INFO->{$module} && $INFO->{$module}->{attributes};
                # Build a role resolution chain for each attribute.
                # The chain starts with the immediate role ($module), then
                # appends any deeper origins so hooks resolve most-specific
                # first.  E.g. if MiddleRole overrides _validate_foo from
                # OriginRole, the chain is [MiddleRole, OriginRole] — the
                # accessor tries MiddleRole first.
                my $origins = $INFO->{$module}{attr_origin} || {};
                foreach my $att (@{$INFO->{$module}->{attributes}}) {
                    my @chain = ($module);
                    if (my $parent = $origins->{$att}) {
                        push @chain, ref $parent eq 'ARRAY' ? @$parent : $parent;
                    }
                    # dedup while preserving order (most-specific first)
                    my %seen;
                    @chain = grep { !$seen{$_}++ } @chain;
                    _add_accessors(
                        to         => $class,
                        attributes => [$att],
                        from_roles => \@chain
                    );
                }
            }

            return;
        };
    }
}

# Collect all attributes for a class, including inherited ones via @ISA.
# Returns an arrayref of unique attribute names in declaration order:
# own attrs first, then parent attrs following Perl's MRO (DFS or C3).
sub _all_attributes {
    my ($class) = @_;
    my $own = $INFO->{$class}{attributes} || [];
    my @all = @{$own};
    my %seen = map { $_ => 1 } @all;

    # use Perl's MRO (respects both default DFS and use mro 'c3')
    require mro;
    my $mro = mro::get_linear_isa($class);
    # skip $class itself (index 0) — already handled above
    for my $i ( 1 .. $#{$mro} ) {
        my $parent = $mro->[$i];
        my $parent_attrs = $INFO->{$parent}{attributes} || [];
        for my $attr ( @{$parent_attrs} ) {
            push @all, $attr unless $seen{$attr}++;
        }
    }

    return \@all;
}

sub _add_new {
    my $class = shift;
    return unless $class;
    # Same rationale as _add_with: check own stash, not @ISA.
    # new() is called as a method (Class->new), so inheritance works,
    # but installing per-class ensures correct behavior when a non-SA
    # class sits between two SA classes in the MRO.
    {
        no strict 'refs';
        return if defined &{"${class}::new"};
    }

    my $new  = $class . '::new';
    {
        no strict 'refs';
        *$new = sub {
            my $class = shift;
            $class = ref($class) || $class;
            my %opts = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

            my $self = bless {}, $class;

            if ( $self->can( '_before_build') ) {
                $self->_before_build( %opts );
            }

            # includes inherited attributes from parent classes via @ISA
            my $attrs = _all_attributes($class);

            # strict constructor: die on unknown attributes BEFORE setting
            # any values, so attribute hooks don't fire with side effects
            # that would be discarded when the constructor dies.
            if ( $self->can('_strict_constructor') && $self->_strict_constructor() ) {
                my %known = map { $_ => 1 } @{$attrs};
                my @unknown = sort grep { !$known{$_} } keys %opts;
                if (@unknown) {
                    die "$class\->new(): unknown attribute(s): "
                        . join(', ', @unknown) . "\n";
                }
            }

            # set values for known attributes (in declaration order)
            foreach my $attr ( @{$attrs} ) {
                $self->$attr( $opts{$attr} ) if exists $opts{$attr};
            }

            foreach my $init ( 'build', 'initialize' ) {
                if ( $self->can( $init ) ) {
                    return unless $self->$init(%opts);
                    last;  # build takes precedence over initialize
                }
            }

            if ( $self->can( '_after_build') ) {
                $self->_after_build( %opts );
            }

            return $self;
        };
    }
}

sub _add_accessors {
    my (%opts) = @_;

    return unless my $class = $opts{to};
    my @attributes = @{ $opts{attributes} };
    return unless @attributes;

    my $from_roles = $opts{from_roles} || [];

    foreach my $att (@attributes) {
        my $accessor = $class . "::" . $att;

        if ( $class->can($att) ) {
            # skip silently when composing roles (duplicates are OK)
            next if @$from_roles;
            die "$class: attribute '$att' is already defined.";
        }

        # track role attributes in the class's attribute list and remember
        # which roles defined them (for transitive composition)
        if ( @$from_roles ) {
            push @{$INFO->{$class}{attributes}}, $att;
            $INFO->{$class}{attr_origin}{$att} = $from_roles;
        }

        # allow symbolic refs to typeglob
        no strict 'refs';
        *$accessor = sub {
            my ( $self, $v ) = @_;
            if ( @_ > 1 ) {
                # re-entrancy guard: skip _after_* if we're already setting this attribute
                my $is_reentrant = $self->{$_GUARD_KEY}{$att};
                local $self->{$_GUARD_KEY}{$att} = 1;

                # save old state so _after_* can rollback the set on false return
                my $had_old = exists $self->{$att};
                my $old_val = $self->{$att};

                my $hc = $_hook_cache->{ref $self} //= {};

                foreach (qw{before validate set after}) {
                    if ( $_ eq 'set' ) {
                        $self->{$att} = $v;
                        next;
                    }
                    if ( $_ eq 'after' && $is_reentrant ) {
                        next;
                    }

                    my $ck = "${att}\0${_}";
                    unless (exists $hc->{$ck}) {
                        my $sub = '_' . $_ . '_' . $att;
                        $hc->{$ck} = $self->can($sub);
                        if (!$hc->{$ck} && @$from_roles) {
                            for my $role (@$from_roles) {
                                if (my $code = $role->can($sub)) {
                                    $hc->{$ck} = $code;
                                    last;
                                }
                            }
                        }
                    }

                    if (my $code = $hc->{$ck}) {
                        unless ( $code->($self, $v) ) {
                            if ( $_ eq 'after' ) {
                                if ($had_old) { $self->{$att} = $old_val }
                                else          { delete $self->{$att}     }
                            }
                            return;
                        }
                    }
                }
            }
            elsif ( !exists $self->{$att} ) {
                # try to initialize the value (try first with build)
                #   initialize is here for backward compatibility with older versions
                my $hc = $_hook_cache->{ref $self} //= {};
                foreach my $builder ( qw{build initialize} ) {
                    my $ck = "${att}\0${builder}";
                    unless (exists $hc->{$ck}) {
                        my $sub = '_' . $builder . '_' . $att;
                        $hc->{$ck} = $self->can($sub);
                        if (!$hc->{$ck} && @$from_roles) {
                            for my $role (@$from_roles) {
                                if (my $code = $role->can($sub)) {
                                    $hc->{$ck} = $code;
                                    last;
                                }
                            }
                        }
                    }
                    if (my $code = $hc->{$ck}) {
                        return $self->{$att} = $code->($self);
                    }
                }
            }

            return $self->{$att};
        };
    }
}

1;

=head1 CONTRIBUTE

You can contribute to this project on github https://github.com/atoomic/Simple-Accessor

=head1 AI POLICY

This project uses AI tools to assist development. Humans review and approve every change before it is merged. See [AI\_POLICY.md](AI_POLICY.md) for details.

=cut

__END__
