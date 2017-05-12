package Object::Lazy; ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = '0.15';

use Carp qw(confess);
use Try::Tiny;
use Object::Lazy::Validate;

sub new { ## no critic (ArgUnpacking)
    my ($class, $params) = Object::Lazy::Validate::validate_new(@_);

    $params = Object::Lazy::Validate::init($params);
    my $self = bless $params, $class;
    if ( exists $params->{ref} ) {
        Object::Lazy::Ref::register($self);
    }

    return $self;
}

my $build_object = sub {
    my ($self, $self_ref) = @_;

    local *__ANON__ = 'BUILD_OBJECT'; ## no critic (LocalVars)
    my $built_object = $self->{build}->();
    # don't build a second time
    $self->{build} = sub { return $built_object };
    if ( ! $self->{is_built} ) {
        $self->{is_built} = 1;
        if ( exists $self->{logger} ) {
            try {
                confess('object built');
            }
            catch {
                $self->{logger}->($_);
            };
        }
    }
    ${$self_ref} = $built_object;

    return $built_object;
};

sub DESTROY {} # is not AUTOLOAD

sub AUTOLOAD { ## no critic (Autoloading ArgUnpacking)
    my ($self, @params) =  @_;

    my $method = substr our $AUTOLOAD, 2 + length __PACKAGE__;
    my $built_object = $build_object->($self, \$_[0]);

    return $built_object->$method(@params);
}

sub isa { ## no critic (ArgUnpacking)
    my ($self, $class2check) = @_;

    my @isa
        = ref $self->{isa} eq 'ARRAY'
        ? @{ $self->{isa} }
        : ( $self->{isa} );
    if ( $self->{is_built} || ! @isa ) {
        my $built_object = $build_object->($self, \$_[0]);
        return $built_object->isa($class2check);
    }
    CLASS: for my $class (@isa) {
        $class->isa($class2check) and return 1;
    }
    my %isa = map { ($_ => undef) } @isa;

    return exists $isa{$class2check};
}

sub DOES { ## no critic (ArgUnpacking)
    my ($self, $class2check) = @_;

    UNIVERSAL->can('DOES')
        or confess 'UNIVERSAL 1.04 (Perl 5.10) required for method DOES';

    my @does
        = ref $self->{DOES} eq 'ARRAY'
        ? @{ $self->{DOES} }
        : ( $self->{DOES} );
    my @isa_and_does = (
        (
            ref $self->{isa} eq 'ARRAY'
            ? @{ $self->{isa} }
            : ( $self->{isa} )
        ),
        @does,
    );
    if ( $self->{is_built} || ! @isa_and_does ) {
        my $built_object = $build_object->($self, \$_[0]);
        return $built_object->DOES($class2check);
    }
    CLASS: for my $class (@does) {
        $class->DOES($class2check) and return 1;
    }
    my %isa_and_does = map { ($_ => undef) } @isa_and_does;

    return exists $isa_and_does{$class2check};
}

sub can { ## no critic (ArgUnpacking)
    my ($self, $method) = @_;

    my $built_object = $build_object->($self, \$_[0]);

    return $built_object->can($method);
}

sub VERSION { ## no critic (ArgUnpacking)
    my ($self, @version) = @_;

    if ( ! $self->{is_built} ) {
        if ( defined $self->{VERSION} ) {
            $Object::Lazy::Version::VERSION = $self->{VERSION};
            return +( bless {}, 'Object::Lazy::Version' )->VERSION(@version);
        }
        if ( $self->{version_from} ) {
            return +( bless {}, $self->{version_from} )->VERSION(@version);
        }
    }
    my $built_object = $build_object->($self, \$_[0]);

    return $built_object->VERSION(@version);
}

# $Id$

1;

__END__

=pod

=head1 NAME

Object::Lazy - create objects late from non-owned (foreign) classes

=head1 VERSION

0.15

=head1 SYNOPSIS

    use Foo 123; # because the class of the real object is Foo, version could be 123
    use Object::Lazy;

    my $foo = Object::Lazy->new(
        sub {
            return Foo->new;
        },
    );

    bar($foo);

    sub bar {
        my $foo = shift;

        if ($condition) {
            # a foo object will be created
            print $foo->output;
        }
        else {
            # foo object is not created
        }

        return;
    }

To combine this and a lazy use, write somthing like that:

    use Object::Lazy;

    my $foo = Object::Lazy->new(
        sub {
            # 3 lines instead of "use Foo 123"
            require Foo;
            Foo->import;
            Foo->VERSION('123');
            return Foo->new;
        },
    );

    # and so on

After a build object the scalar which hold the object will be updated too.

  $object->method;
  ^^^^^^^-------------- will update this scalar after a build

Read topic SUBROUTINES/METHODS to find the entended constructor
and all the optional parameters.

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 DESCRIPTION

This module implements lazy evaluation
and can create lazy objects from every class.

Creates a dummy object including a subroutine
which knows how to build the real object.

Later, if a method of the object is called,
the real object will be built.

Inherited methods from UNIVERSAL.pm are implemented and so overwritten.
This are isa, DOES, can and VERSION.

=head1 SUBROUTINES/METHODS

=head2 method new

=head3 short constructor

    $object = Object::Lazy->new(
        sub {
            return RealClass->new(...);
        },
    );

=head3 extended constructor

    $object = Object::Lazy->new({
        build => sub {
            return RealClass->new(...);
        },
    });

=over 4

=item * optional parameter isa

There are 3 ways to check the class or inheritance.

If there is no parameter isa, the object must be built before.

If the C<use RealClass;> is outside of C<<build => sub {...}>>
then the class method C<<RealClass->isa(...);>> checks the class or inheritance.

Otherwise the isa parameter is a full notation of the class
and possible of the inheritance.

    $object = Object::Lazy->new({
        ...
        isa => 'RealClass',
    });

or

    $object = Object::Lazy->new({
        ...
        isa => [qw(RealClass BaseClassOfRealClass)],
    });

=item * optional parameter DOES

It is similar to parameter isa.
But do not note the inheritance.
Note the Rules here.

    $object = Object::Lazy->new({
        ...
        DOES => 'Role1',
    });

or

    $object = Object::Lazy->new({
        ...
        DOES => [qw(Role1 Role2)],
    });

=item * optional parameter VERSION

For the VERSION method tell Object::Lazy which version shold be checked.

    $object = Object::Lazy->new({
        ...
        VERSION => '123',
    });

or

    use version;

    $object = Object::Lazy->new({
        ...
        VERSION => qv('1.2.3'), # version object
    });

=item * optional parameter version_from

For the VERSION method tell Object::Lazy which class shold be version checked.

    $object = Object::Lazy->new({
        ...
        version_from => 'RealClass',
    });

=item * optional parameter logger

Optional notation of the logger code to show the build process.

    $object = Object::Lazy->new({
        ...
        logger => sub {
            my $at_stack = shift;
            print "RealClass $at_stack";
        },
    });

=item * optional parameter ref

Optional notation of the ref answer.

It is not a good idea to use the Object::Lazy::Ref module by default.
But there are situations, the lazy idea would run down the river
if I had not implemented this feature.

    use Object::Lazy::Ref; # overwrite CORE::GLOBAL::ref

    $object = Object::Lazy->new({
        ...
        ref => 'RealClass',
    });

    $boolean_true = ref $object eq 'RealClass';

=back

=head2 method isa

If no isa parameter was given at method new, the object will build.

Otherwise the method isa checks by isa class method
or only the given parameters.

    $boolean = $object->isa('RealClass');

or

    $boolean = $object->isa('BaseClassOfRealClass');

=head2 method DOES

If no isa or DOES parameter was given at method new, the object will build.

Otherwise the method DOES checks by DOES class method
or only the given parameters isa and DOES.

    $boolean = $object->DOES('Role');

=head2 method can

The object will build. After that the can method checks the built object.

    $coderef_or_undef = $object->can('method');

=head2 method VERSION

If no VERSION or version_from parameter was given at method new,
the object will build.

=head3 VERSION parameter set

The given version will be returnd or checked.

    $version = $object->VERSION;

or

    $object->VERSION($required_version);

=head3 version_from parameter set

The version of the class in version_from will be returnd or checked.
This class should be used or required before.
Is that not possible use parameter VERSION instead.

    $version = $object->VERSION;

or

    $object->VERSION($required_version);

=head1 DIAGNOSTICS

The constructor can confess at false parameters.

UNIVERSAL 1.04 (Perl 5.10) required for method DOES.

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

L<Carp|Carp>

L<Try::Tiny|Try::Tiny>

L<Object::Lazy::Validate|Object::Lazy::Validate>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

UNIVERSAL.pm 1.04 implements DOES first time.
This version is part of the Perl 5.10 distribution.

=head1 SEE ALSO

UNIVERSAL

L<Data::Lazy|Data::Lazy> The scalar will be built at C<my $scalar = shift;> at first sub call.

L<Scalar::Defer|Scalar::Defer> The scalar will be built at C<my $scalar = shift;> at first sub call.

L<Class::LazyObject|Class::LazyObject> No, I don't write my own class/package.

L<Object::Realize::Later|Object::Realize::Later> No, I don't write my own class/package.

L<Class::Cache|Class::Cache> There are lazy parameters too.

L<Object::Trampoline|Object::Trampoline> This is nearly the same idea.

L<Objects::Collection::Object|Objects::Collection::Object> Object created at call of method isa.

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 - 2015,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
