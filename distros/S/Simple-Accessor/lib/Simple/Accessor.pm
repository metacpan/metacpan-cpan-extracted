package Simple::Accessor;
$Simple::Accessor::VERSION = '1.14';
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

You can now call 'new' on your class, and create objects using these attributes

    package main;
    use MyClass;

    my $o = MyClass->new()
        or MyClass->new(bar => 42)
        or MyClass->new(apple => 'fruit', cherry => 'fruit', banana => 'yummy');

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
Any false value return by before or validate, will stop the setting process.
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
    return if $class->can('with');

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
                # Resolve each attribute's origin role for transitive composition.
                # If MiddleRole composed OriginRole's attrs, their hooks live
                # in OriginRole — not MiddleRole.  Pass the correct origin so
                # the accessor closure can find _build_*, _before_*, etc.
                my $origins = $INFO->{$module}{attr_origin} || {};
                foreach my $att (@{$INFO->{$module}->{attributes}}) {
                    _add_accessors(
                        to         => $class,
                        attributes => [$att],
                        from_role  => $origins->{$att} || $module
                    );
                }
            }

            return;
        };
    }
}

sub _add_new {
    my $class = shift;
    return unless $class;
    return if $class->can('new');

    my $new  = $class . '::new';
    {
        no strict 'refs';
        *$new = sub {
            my ( $class, %opts ) = @_;

            my $self = bless {}, $class;

            if ( $self->can( '_before_build') ) {
                $self->_before_build( %opts );
            }

            # set values for known attributes (in declaration order)
            my $attrs = $INFO->{$class}{attributes} || [];
            foreach my $attr ( @{$attrs} ) {
                $self->$attr( $opts{$attr} ) if exists $opts{$attr};
            }

            # strict constructor: die on unknown attributes
            if ( $self->can('_strict_constructor') && $self->_strict_constructor() ) {
                my %known = map { $_ => 1 } @{$attrs};
                my @unknown = sort grep { !$known{$_} } keys %opts;
                if (@unknown) {
                    die "$class\->new(): unknown attribute(s): "
                        . join(', ', @unknown) . "\n";
                }
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

    my $from_role = $opts{from_role};

    foreach my $att (@attributes) {
        my $accessor = $class . "::" . $att;

        if ( $class->can($att) ) {
            # skip silently when composing roles (duplicates are OK)
            next if $from_role;
            die "$class: attribute '$att' is already defined.";
        }

        # track role attributes in the class's attribute list and remember
        # which role originally defined them (for transitive composition)
        if ( $from_role ) {
            push @{$INFO->{$class}{attributes}}, $att;
            $INFO->{$class}{attr_origin}{$att} = $from_role;
        }

        # allow symbolic refs to typeglob
        no strict 'refs';
        *$accessor = sub {
            my ( $self, $v ) = @_;
            if ( @_ > 1 ) {
                # re-entrancy guard: skip _after_* if we're already setting this attribute
                my $is_reentrant = $self->{__sa_setting}{$att};
                local $self->{__sa_setting}{$att} = 1;

                foreach (qw{before validate set after}) {
                    if ( $_ eq 'set' ) {
                        $self->{$att} = $v;
                        next;
                    }
                    if ( $_ eq 'after' && $is_reentrant ) {
                        next;
                    }
                    my $sub = '_' . $_ . '_' . $att;
                    if ( $self->can( $sub ) ) {
                        return unless $self->$sub($v);
                    } elsif ( $from_role  ) {
                        if ( my $code = $from_role->can( $sub ) ) {
                            return unless $code->( $self, $v );
                        }
                    }
                }
            }
            elsif ( !exists $self->{$att} ) {
                # try to initialize the value (try first with build)
                #   initialize is here for backward compatibility with older versions
                foreach my $builder ( qw{build initialize} ) {
                    my $sub = '_' . $builder . '_' . $att;
                    if ( $self->can( $sub ) ) {
                        return $self->{$att} = $self->$sub();
                    } elsif ( $from_role  ) {
                        if ( my $code = $from_role->can( $sub ) ) {
                            return $self->{$att} = $code->( $self );
                        }
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

=cut

__END__
