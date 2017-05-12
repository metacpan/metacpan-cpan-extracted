package Class::LOP;

=head1 NAME

Class::LOP - The Lightweight Object Protocol 

=head1 DESCRIPTION

Just like L<Moose> is built from L<Class::MOP>. You can build your own using this module. It is a little different 
from L<Class::MOP> though, because it doesn't use a meta class, it has less features, but it's a lot faster.
If you need a lightweight object protocol, this may be the tool for you. 
Using this module you could build an extremely quick OOP framework that could be used from a CLI or as a standard 
module.

=head1 SYNOPSIS

    package Goosey;

    use Class::LOP;

    sub import {

        my $caller = caller();
        # Methods can be chained for simplicity and easy tracking.
        # Below, we'll create the 'new' constructor, enable warnings and strict, and also
        # bestow the accessors feature, so our module can create them
        Class::LOP->init($caller)
            ->create_constructor
            ->warnings_strict
            ->have_accessors('has');

        # import multiple methods into the specified class
        Class::LOP->init('Goosey')->import_methods($caller, qw/
            extends
            after
            before
        /);
    }

    # Add a few hook modifiers
    # This code sure looks a lot cleaner than writing it yourself ;-)
    sub after {
        my ($name, $code) = @_;

        Class::LOP->init(caller())->add_hook(
            type  => 'after',
            name => $name,
            method   => $code,
        );
    }

    # Extending a class is similar to 'use base'
    # You may have also seen this from Moose
    # ->extend_class() makes it really easy for you
    sub extends {
        my (@classes) = @_;
        Class::LOP->init(caller())
            ->extend_class(@classes);
    }

    # MyClass.pm
    package MyClass;

    use Goosey; # enables warnings/strict
    extends 'Some::Module::To::Subclass';

    has 'name' => ( is => 'rw', default => 'Foo' );

    after 'name' => sub {
        print "This code block runs after the original!\n";
    };

Wow, that all looks familiar.. but we wrote it all in a fairly small amount of code. Class::LOP takes care of the 
dirty work for you, so you can just worry about getting the features in your module that you want.

=cut

use warnings;
use strict;
use mro;

our $VERSION = '0.003';

sub new {
    my ($self, $class) = @_;
    if (!$class) {
        warn "No class specified";
        return 0;
    }

    {
        no strict 'refs';
        if (! scalar %{ "${class}::" }) {
            *{"${class}::new"} = sub {
                return bless {}, $class;
            };
        }
    }

    return bless {
        _name => $class,
        _attributes => [],
    },
    __PACKAGE__;
}

sub init {
    my ($self, $class) = @_;
    if (!$class) {
        warn "No class specified";
        return 0;
    }

    return bless {
        _name => $class,
    },
    __PACKAGE__;
}

sub name {
    my $self = shift;
    return $self->{_name};
}

sub warnings_strict {
    my $self = shift;
    warnings->import();
    strict->import();
    return $self;
}

sub getscope {
    my ($self) = @_;
    return scalar caller(1);
}

sub class_exists {
    my ($self, $class) = @_;
    $class = $self->{_name} if !$class;
    {
        no strict 'refs';
        return scalar %{ "${class}::" };
    }
}

sub list_methods {
    my $self = shift;
    my $class = $self->{_name};
    my @methods = ();
    {
        no strict 'refs';
        foreach my $method (keys %{"${class}::"}) {
            push @methods, $method
                if substr($method, -2, 2) ne '::';
        }
    }

    return @methods;
}

sub method_exists {
    my ($self, $class, $method) = @_;
    if (!$method) {
        $method = $class;
        $class = $self->{_name};
    }
    return $class->can($method);
}

sub subclasses {
    my $self = shift;
    my @list = ();
    my $class = $self->{_name};
    @list = @{ $class->mro::get_isarev() };

    return scalar(@list) > 0 ? @list : 0;
}

sub superclasses {
    my $self = shift;
    my $class = $self->{_name};
    {
        no strict 'refs';
        return @{ "${class}::ISA" };
    }
}

sub import_methods {
    my ($self, $class, @methods) = @_;
    my $caller = $self->name();
    localscope: {
        no strict 'refs';
        if (! scalar(%{ "${class}::" })) {
            warn "Class ${class} does not exist";
            return 0;
        }
        else {
            for my $method (@methods) {
                *{"${class}::${method}"} = *{"${caller}::${method}"}
                    if $caller->can($method);
            }
        }
    }

    return $self;
}

sub extend_class {
    my ($self, @mothers) = @_;

    my $class = $self->{_name};
    foreach my $mother (@mothers) {
        # if class is unknown to us, import it (FIXME)
        unless (grep { $_ eq $mother } @{$self->{'classes'}}) {
            eval "use $mother";
            warn "Could not extend $mother: $@"
                if $@;
        
            $mother->import;
        }
        push @{$self->{'classes'}}, $class;
    }

    {
        no strict 'refs';
        @{"${class}::ISA"} = @mothers;
    }

    return $self;
}

sub have_accessors {
    my ($self, $name) = @_;
    my $class = $self->{_name};
    if ($self->class_exists($class)) {
        {
            no strict 'refs';
            no warnings 'redefine';
            *{"${class}::${name}"} = sub {
                my ($acc, %args) = @_;
                my $default = delete $args{default};
                my $type    = delete $args{is};
                if ($type && $type eq 'ro') {
                    *{"${class}::${acc}"} = sub {
                        if (@_ > 1) {
                            if ($default) {
                                if (! exists $_[0]->{"$acc\_$_[0]\_default_used"}) {
                                    $self->_add_attribute($_[0], $acc, $_[1]);
                                    $_[0]->{$acc} = $_[1];
                                    $_[0]->{"$acc\_$_[0]\_default_used"} = 1;
                                    return $_[1];
                                }
                            }

                            warn "Can't modify a read-only accessor (${acc})";
                            return 0;
                        }

                        return $_[0]->{$acc};
                    };
                }
                else {
                    *{"${class}::${acc}"} = sub {
                        if (@_ > 1) {
                            $self->_add_attribute($_[0], $acc, $_[1]);
                            $_[0]->{$acc} = $_[1];
                        }

                        return $_[0]->{$acc};
                    };
                }

                if ($default) {
                    my $fullpkg = "${class}::${acc}";
                    $class->$acc($default);
                }
            };
        }

        return $self;
    }
    else {
        warn "Can't create accessors in class '$class', because it doesn't exist";
        return 0;
    }
}

sub create_constructor {
    my ($self, @args) = @_;
    my $caller = $self->{_name};
    if (! $caller->can('new')) {
        doconstructor: {
            no strict 'refs';
            *{"${caller}::new"} = sub {
                my ($cself, @cargs) = @_;
                bless {}, $cself;
                shift;
                if ($cself->can('__init')) {
                    $cself->__init(@_);
                }
                
                return $cself;
            };
        }
        
        return $self;
    }
}

sub create_class {
    my ($self, $class) = @_;
    my $caller = $self->{_name};
    if ($self->class_exists($caller)) {
        warn "Can't create class '$class'. Already exists";
        return 0;
    }
    else {
        {
            no strict 'refs';
            *{"${class}::new"} = sub {
                return bless {}, $class;
            };
        }
    }

    return 1;
}

sub create_method {
    my ($self, $name, $code) = @_;
    my $class = $self->{_name};
    if ($self->class_exists($class)) {
        {
            no strict 'refs';
            if ($self->method_exists($class, $name)) {
                warn "Method $name already exists in $class. Did you mean to use override_method()?";
                return 0;
            }
            
            *{"${class}::${name}"} = $code;
        }
    }
    else {
        warn "Can't create ${name} in ${class}, because ${class} does not exist";
        return 0;
    }

    return $self;
}

sub override_method {
    my ($self, $name, $method) = @_;
    my $class = $self->{_name};
    {
        no warnings 'redefine';
        no strict 'refs';
        if (! $self->method_exists($class, $name)) {
            warn "Cant't find '$name' in class $class - override_method()";
            return 0;
        }
        
        *{"${class}::${name}"} = $method;
    }
}

sub last_errors {
    my $self = shift;
    my $errors = $self->{errors};
    $self->{errors} = [];
    return $errors;
}

sub add_hook {
    my ($self, %args) = @_;
    my $caller = $self->{_name};
    my ($type, $class, $method, $code) = (
        $args{'type'},
        $self->{_name},
        $args{'name'},
        $args{'method'}
    );

    if ($self->class_exists($caller)) {
        if ($type && $class && $method && $code) {
            if (! $self->method_exists($class, $method)) {
                warn "Can't add hook because class $class does not have method $method";
                return 0;
            }

            my $fullpkg  = "${class}::${method}";
            my $old_code = \&{$fullpkg};
            my $new_code;

            addhook: {
                no strict 'refs';
                no warnings 'redefine';
                for ($type) {
                    if (/after/) {
                        *{"${fullpkg}"} = sub {
                            $old_code->(@_);
                            $code->(@_);
                        };
                    }
                    elsif (/before/) {
                        *{"${fullpkg}"} = sub {
                            $code->(@_);
                            $old_code->(@_);
                        };
                    }
                    elsif (/around/) {
                        *{"${fullpkg}"} = sub {
                            $code->($old_code, @_);
                        };
                    }
                    else {
                        warn "Unknown hook type: $type";
                        return 0;
                    }
                }
            }
            return $self;
        }
        else {
            warn "Hook expecting type, class, method, and code";
            return 0;
        }
    }
    else {
        warn "Can't add hook becase class '$class' does not exist";
        return 0;
    }
}

sub clone_object {
    my $self = shift;
    my $class = $self->{_name};
    if (! ref($class)) {
        warn "clone_object() expects a reference\n";
        return 0;
    }
    bless { %{ $class } }, ref $class;
}

sub delete_method {
    my ($self, $name) = @_;
    my $class = $self->{_name};
    {
        no strict 'refs';
        #$class = \%{"$class\::"};
        delete $class::{$name};
    }
}

sub get_attributes {
    my $self = shift;
    my $class = $self->{_name};
    return $self->{_attributes}->{$class};
}

sub _add_attribute {
    my ($self, $class, $attr, $value) = @_;
    if ($self->{_attributes}->{$class}) {
        $self->{_attributes}->{$class}->{$attr} = $value; 
    }
    else {
        $self->{_attributes}->{$class} = {
            $attr => $value,
        };
    }
}
=head1 METHODS

=head2 init

Initialises a class. This won't create a new one, but will set the current class as the one specified, if it 
exists.
You can then chain other methods onto this, or save it into a variable for repeated use.

    Class::LOP->init('SomeClass');

=head2 new

Initialises a class, but will also create a new one should it not exist. If you're wanting to initialise a class 
you know exists, you're probably better off using C<init>, as it involves less work.

    Class::LOP->new('MyNewClass')
        ->create_method('foo', sub { print "foo!\n" });

    my $class = MyNewClass->new();
    $class->foo(); # prints foo!

Using C<new> then chaining C<create_method> onto it, we were able to create a class and a method on-the-fly.

=head2 warnings_strict

Enables C<use warnings> and C<use strict> pragmas in Class::LOP modules

    $class->warnings_strict();

=head2 getscope

Basically just a C<caller>. Use this in your modules to return the class name

    my $caller = $class->getscope();

=head2 class_exists

Checks to make sure the class has been imported

    use Some::Module;

    if ($class->class_exists()) {
        print "It's there!\n";
    }

=head2 method_exists

Detects if a specific method in a class exists

    if ($class->method_exists($method_name)) { .. }

=head2 subclasses

Returns an list of subclassed modules

    my @subclass_mods = $class->subclasses();
    for (@subclass_mods) {
        print "$_\n";
    }

=head2 superclasses

Returns a list of superclass (base) modules

    my @superclass_mods = $class->superclasses();
    for (@superclass_mods) {
        print "$_\n";
    }

=head2 import_methods

Injects existing methods from the scoped module to a specified class

    $class->import_methods($destination_class, qw/this that and this/);

Optionally, C<import_methods> can return errors if certain methods don't exist. You can read these 
errors with C<last_errors>. This is only experimental at the moment.

=head2 extend_class

Pretty much the same as C<use base 'Mother::Class'>. The first parameter is the subclass, and the following array 
will be its "mothers".

    my @mommys = qw(This::Class That::Class);
    $class->extend_class(@mommys)

=head2 have_accessors

Adds Moose-style accessors to a class. First parameter is the class, second will be the name of the method to 
create accessors.

    # Goosey.pm
    $class->have_accessors('acc');

    # test.pl
    use Goosey;

    acc 'x' => ( is => 'rw', default => 7 );

Currently the only two options is C<default> and C<is>.

=head2 create_constructor

Simply adds the C<new> method to your class. I'm wondering whether this should be done automatically? The 
aim of this module is to give the author as much freedom as possible, so I chose not to.

    $class->create_constructor;

=head2 create_method

Adds a new method to an existing class.

    $class->create_method('greet', sub {
        my $self = shift;
        print "Hello, World from " . ref($self) . "\n";
    });

    MooClass->greet();

=head2 add_hook

Adds hook modifiers to your class. It won't import them all - only use what you need :-)

    $class->add_hook(
        type  => 'after',
        method => $name,
        code   => $code,
    );

The types are C<after>, C<before>, and C<around>.

=head2 list_methods

Returns a list of all the methods within an initialised class. It will filter out classes

    my @methods = Class::LOP->init('SomeClass')->list_methods();

=head2 clone_object

Takes an object and spits out a clone of it. This means mangling the original will have no side-effects to the cloned one
I know L<DateTime> has its own C<clone> method, but still, it's a good example.

    my $dt = DateTime->now;
    my $dt2 = Class::LOP->init($dt)->clone_object;

    print $dt->add(days => 5)->dmy() . "\n";
    print $dt2->dmy() . "\n";

Simply changing C<$dt2 = $dt> would mean both results would have the same date when we printed them, but because we cloned the object, they are separate.

=head2 override_method

Unlike C<create_method>, this method will let you replace the existing one, thereby overriding it.

    sub greet { print "Hello\n"; }
    
    Class::LOP->init('ClassName')->override_method('greet', sub { print "Sup\n" });

    greet(); # prints Sup

=head1 AUTHOR

Brad Haywood <brad@perlpowered.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
