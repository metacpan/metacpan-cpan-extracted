package Object::Extend;

use 5.008;
use strict;
use warnings;
use base qw(Exporter);

use constant {
    SINGLETON   => sprintf('%s::_Singleton', __PACKAGE__ ),
    METHOD_NAME => qr{^[a-zA-Z_]\w*$},
};

use B qw(perlstring);
use Carp qw(confess);
use Scalar::Util qw(blessed);
use Storable qw(freeze);

our @EXPORT_OK = qw(extend with SINGLETON);
our $VERSION = '0.4.0';

my $ID = 0;
my %CACHE;

# find/create a unique class name for the supplied object's class/methods combination.
#
# Eigenclasses are immutable i.e. once an eigenclass has been created,
# its @ISA and installed methods never change. This means we can reuse/recycle
# an eigenclass if we're passed the same superclass/methods combo.
#
# Note: we need to identify the subs in the method hash by value (deparse)
# rather than by reference (refaddr), since ref addresses can be recycled
# (and frequently are for anonymous subs).
#
# Note: the SINGLETON class added to the eigenclass's @ISA doesn't
# implement any methods: we just use it as metadata to indicate that
# the object has been extended.

sub _eigenclass($$) {
    my ($class, $methods) = @_;

    my $key = do {
        no warnings qw(once);

        local $Storable::Deparse = 1;
        # XXX squashed bugs 1) sort hash keys
        # 2) freeze the $hashref, not the %$hash!
        local $Storable::canonical = 1;

        freeze [ $class, $methods ];
    };

    my $eigenclass = $CACHE{$key};

    unless ($eigenclass) {
        $eigenclass = sprintf '%s::_%x', SINGLETON, ++$ID;
        $CACHE{$key} = $eigenclass;

        if ($class->isa(SINGLETON)) {
            _set_isa($eigenclass, [ $class ]);
        } else {
            _set_isa($eigenclass, [ $class, SINGLETON ]);
        }

        while (my ($name, $sub) = each(%$methods)) {
            _install_sub("$eigenclass\::$name", $sub);
        }
    }

    return $eigenclass;
}

# install the supplied sub in the supplied class.
# "extend" is a pretty clear statement of intent, so
# we don't issue a warning if the sub already exists
#
# XXX if we used Exporter::Tiny, we could
# allow the redefine warning to be enabled e.g.:
#
#     use Object::Extend extend => { warn_on_redefine => 1 };

sub _install_sub($$) {
    my ($class, $sub) = @_;
    no warnings 'redefine';
    no strict 'refs';
    *$class = $sub;
}

# set a class's @ISA array
sub _set_isa($$) {
    my ($class, $isa) = @_;
    no strict 'refs';
    *{"$class\::ISA"} = $isa;
}

# return true if $ref ISA $class - works with non-references,
# unblessed references and objects
sub _isa($$) {
    my ($ref, $class) = @_;
    return blessed($ref) ? $ref->isa($class) : ref($ref) eq $class;
}

# confess with a message whose string parameters are quoted
sub _error($;@) {
    my $template = shift;
    my @args = map { defined($_) ? perlstring($_) : 'undef' } @_;
    confess sprintf($template, @args);
}

# sanity check the arguments to extend
sub _validate(@) {
    my $object = shift;
    my $class = blessed($object);

    unless ($class) {
        _error(
            "invalid 'object' parameter: expected blessed reference, got: %s",
            ref($object)
        );
    }

    my $methods;

    if (@_ == 1) {
        $methods = shift;
    } elsif (@_ % 2 == 0) {
        $methods = { @_ };
    }

    unless (_isa($methods, 'HASH')) {
        _error(
            "invalid 'methods' parameter: expected a hashref, got: %s",
            ref($methods)
        );
    }

    for my $name (keys %$methods) {
        if (!defined($name)) {
            _error 'invalid method name (undef)';
        } elsif ($name !~ METHOD_NAME) {
            _error(
                'invalid method name (%s): name must match %s',
                $name,
                METHOD_NAME
            );
        } else {
            my $method = $methods->{$name};

            unless (_isa($method, 'CODE')) {
                _error(
                    'invalid method value for %s: expected a coderef, got: %s',
                    $name,
                    ref($method),
                );
            }
        }
    }

    return ($object, $class, $methods);
}

# dummy sub to optionally make the syntax
# a bit more DSL-ish: extend $object => with ...
sub with($) {
    my $methods = shift;

    unless (_isa($methods, 'HASH')) {
        _error(
            "invalid 'methods' parameter: expected a hashref, got: %s",
           ref($methods)
        );
    }

    return $methods;
}

# find/create an eigenclass for the object's class/methods and bless the object into it
sub extend($;@) {
    my ($object, $class, $methods) = _validate(@_);

    if (%$methods) {
        my $eigenclass = _eigenclass($class, $methods);
        bless $object, $eigenclass;
    } # else return the original object unchanged

    return $object;
}

1;

=head1 NAME

Object::Extend - add and override per-object methods

=head1 SYNOPSIS

    use Object::Extend qw(extend);

    my $foo1 = Foo->new;
    my $foo2 = Foo->new;

    extend $foo1 => {
        bar => sub { ... },
    };

    $foo1->bar; # OK
    $foo2->bar; # error

=head1 DESCRIPTION

This module allows objects to be extended with per-object methods, similar to the use of
L<singleton methods|http://madebydna.com/all/code/2011/06/24/eigenclasses-demystified.html>
in Ruby. Object methods are added to an object-specific shim class (known as an C<eigenclass>),
which extends the object's original class. The original class is left unchanged.

=head2 EXPORTS

=head3 extend

C<extend> takes an object and a hash or hashref of method names and method values (coderefs) and adds
the methods to the object's shim class. The object is then blessed into this class and returned.

It can be used in standalone statements:

    extend $object, foo => sub { ... }, bar => \&bar;

Or expressions:

    return extend($object => { bar => sub { ... } })->bar;

In both cases, C<extend> operates on and returns the supplied object i.e. a new object is never created.
If a new object is needed, it can be created manually e.g.:

    my $object2 = Object->new($object1);
    my $object3 = clone($object1);

    extend($object2, foo => sub { ... })->foo;
    return extend($object3 => ...);

Objects can be extended multiple times with new or overridden methods:

    # call the original method
    my $object = Foo->new;
    $object->foo;

    # override the original method
    extend $object, foo => sub { ... };
    $object->foo;

    # add a new method
    extend $object, bar => sub { ... };
    $object->bar;

=head3 with

This sub can optionally be imported to make the use of C<extend> more descriptive. It takes and
returns a hashref of method names/coderefs:

    use Object::Extend qw(extend with);

    extend $object => with { foo => sub { ... } };

=head3 SINGLETON

Every extended object's shim class includes an additional (empty) class in its C<@ISA> which indicates
that the object has been extended. The name of this class can be accessed by importing the C<SINGLETON>
constant e.g.:

    use Object::Extend qw(SINGLETON);

    if ($object->isa(SINGLETON)) { ... } # object extended with object-specific methods

=head1 VERSION

0.4.0

=head1 SEE ALSO

=over

=item * L<Class::SingletonMethod|Class::SingletonMethod>

=item * L<MooseX::SingletonMethod|MooseX::SingletonMethod>

=item * L<MouseX::SingletonMethod|MouseX::SingletonMethod>

=item * L<SingletonMethod|https://github.com/tom-lpsd/p5-singleton-method>

=back

=head1 AUTHOR

chocolateboy <chocolate@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by chocolateboy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
