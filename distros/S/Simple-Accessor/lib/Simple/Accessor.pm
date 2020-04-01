package Simple::Accessor;
$Simple::Accessor::VERSION = '1.13';
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

You can even use a very basic but useful hook system.
Any false value return by before or validate, will stop the setting process.
Be careful with the after method, as there is no protection against infinite loop.

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
    $INFO->{$from}->{'attributes'} = [ @attr ];

    _add_with($from);
    _add_new($from);
    _add_accessors( to => $from, attributes => \@attr );

    return;
}

sub _add_with {
    my $class = shift;
    return unless $class;

    my $with  = $class . '::with';
    {
        no strict 'refs';
        *$with = sub {
            my ( @what ) = @_;

            $INFO->{$class}->{'with'} = [] unless $INFO->{$class}->{'with'};
            push @{$INFO->{$class}->{'with'}}, @what;

            foreach my $module ( @what ) {
                eval qq[require $module; 1] or die $@;
                _add_accessors(
                    to => $class,
                    attributes => $INFO->{$module}->{attributes},
                    from_role => $module
                );
            }

            return;
        };
    }
}

sub _add_new {
    my $class = shift;
    return unless $class;

    my $new  = $class . '::new';
    {
        no strict 'refs';
        *$new = sub {
            my ( $class, %opts ) = @_;

            my $self = bless {}, $class;

            # set values if attributes exist
            map {
                eval { $self->$_( $opts{$_} ) }
            } keys %opts;

            if ( $self->can( '_before_build') ) {
                $self->_before_build( %opts );
            }

            foreach my $init ( 'build', 'initialize' ) {
                if ( $self->can( $init ) ) {
                    return unless $self->$init(%opts);
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

        die "$class: attribute '$att' is already defined." if $class->can($att);

        # allow symbolic refs to typeglob
        no strict 'refs';
        *$accessor = sub {
            my ( $self, $v ) = @_;
            if ( defined $v ) {
                foreach (qw{before validate set after}) {
                    if ( $_ eq 'set' ) {
                        $self->{$att} = $v;
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
            elsif ( !defined $self->{$att} ) {
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
    @attributes = ();
}

1;

=head1 CONTRIBUTE

You can contribute to this project on github https://github.com/atoomic/Simple-Accessor

=cut

__END__
