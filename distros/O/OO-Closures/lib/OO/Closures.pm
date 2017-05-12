package OO::Closures;

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

our $VERSION = '2009110702';

sub import {
    my $my_package       = __PACKAGE__;
    my $foreign_package  =  caller;
    my $my_sub           = 'create_object';
    shift;
    my $foreign_sub      =  @_ ? shift : $my_sub;

    no strict 'refs';
    *{"${foreign_package}::$foreign_sub"} = \&{"${my_package}::$my_sub"};
}

sub croak {
    require Carp;
    goto &Carp::croak;
}

sub create_object {
    my ($methods, $ISA, $is_base) = @_;

    sub {
        my ($method, @args) = @_;
        my ($call_super, $class);

        if ($method =~ /^((?:[^:]+|:[^:])*)::(.*)/s) {
            $class  = $1;
            $method = $2;
        }

        if (exists   $methods -> {$method} && !defined $class) {
            return   $methods -> {$method} -> (@args) if
               ref   $methods -> {$method} eq 'CODE';
            return ${$methods -> {$method}} if 
               ref   $methods -> {$method} eq 'SCALAR';
            die "Illegal method ($method) in object.\n";
        }

        my  @supers;
        if (defined $class && ($class ne 'SUPER' || exists $ISA -> {$class})) {
            unless (exists $ISA -> {$class}) {
                croak "No class ($class) found\n";
            }
            @supers = ($ISA -> {$class});
        }
        else {@supers = values %$ISA}

        # Go looking for the method in an inherited object.
        foreach my $super (@supers) {
            return eval {$super -> ($method => @args)} unless $@;
            croak $@ unless $@ =~ /^No such method/;
        }

        unless ($is_base) {
            # This is the base object. So, we'll look for AUTOLOAD.
            return $methods -> {AUTOLOAD} -> ($method => @args) if exists
                   $methods -> {AUTOLOAD} && !defined $class;

            # Check %ISA for AUTOLOAD.
            foreach my $super (@supers) {
                return eval {$super -> (AUTOLOAD => $method, @args)} unless $@;
                croak $@ unless $@ =~ /^No such method/;
            }
        }

        croak "No such method ($method) found";
    }
}


1;


__END__

=pod

=head1 NAME

OO::Closures - Object Oriented Programming using Closures.

=head1 SYNOPSIS

    use OO::Closures;

    sub new {
        my (%methods, %ISA, $self);
        $self = create_object (\%methods, \%ISA, !@_);

        ...

        $self;
    }

=head1 DESCRIPTION

This package gives you a way to use Object Oriented programming using
Closures, including multiple inheritance, C<SUPER::> and AUTOLOADing.

To create the object, call the function C<create_object> with three
arguments, a reference to a hash containing the methods of the object,
a reference to a hash containing the inherited objects, and a flag
determining whether the just created object is the base object or
not. This latter flag is important when it comes to trying C<AUTOLOAD>
after not finding a method.

C<create_object> returns a closure which will act as the new object.

Here is an example of the usage:

    use OO::Closures;
    sub dice {
        my (%methods, %ISA, $self);
        $self = create_object (\%methods, \%ISA, !@_);

        my $faces = 6;

        $methods {set}  = sub {$faces = shift;};
        $methods {roll} = sub {1 + int rand $faces};

        $self;
    }

It is a simple object representing a die, with 2 methods, C<set>, to set
the number of faces, and C<roll>, to roll the die. It does not inherit
anything. To make a roll on a 10 sided die, use:

    (my $die = dice) -> (set => 10);
    print $die -> ('roll');

Note that since the objects are closures, method names are the first
arguments of the calls.


=head1 OBJECT VARIABLES

One can make object variables available to the outside world as well.
Just like in Eiffel, for an outsider this will be indistinguishable
from accessing a argumentless method. (However, in a Perlish fashion,
we will actually allow arguments in the call). To do so, instead of
putting a code reference in the %methods hash, put a reference to a
scalar in the hash. Note that to the outside world, no more than read
only access to the variable is given.

Here is an example:

    sub dice {
        my (%methods, %ISA, $self);
        $self = create_object (\%methods, \%ISA, !@_);

        my $faces = 6;

        $methods {set}   = sub {$faces = shift;};
        $methods {roll}  = sub {1 + int rand $faces};

        $methods {faces} = \$faces;

        $self;
    }

    (my $die = dice) -> (set => 10);
    print $die -> ('faces');

This will print C<10>.


=head1 INHERITANCE

To use inheritance, we need to set the C<%ISA> hash. We also need to
pass ourselves to the classes we inherited, so an inherited class can
find the base object. (This is similar to the first argument of the
constructor when using regular objects).

Here is an example that implements multi dice, by subclassing C<dice>.
We will also give C<dice> a method C<print_faces> that prints the number
of faces and returns the object.

    use OO::Closures;

    sub dice {
        my (%methods, %ISA, $self);
        $self = create_object (\%methods, \%ISA, !@_);
        my $this_object = shift || $self;

        my $faces = 6;

        $methods {set}         = sub {$faces = shift};
        $methods {roll}        = sub {1 + int rand $faces};
        $methods {print_faces} = sub {print "Faces: $faces\n"; $this_object};

        $self;
    }

    sub multi_dice {
        my (%methods, %ISA, $self);
        $self = create_object (\%methods, \%ISA, !@_);
        my $this_object = shift || $self;

        %ISA  = (dice => dice $this_object);

        my $amount = 1;

        $methods {amount} = sub {$amount = shift};
        $methods {roll}   = sub {
            my $sum = 0;
            foreach (1 .. $amount) {$sum += $self -> ('dice::roll')}
            $sum;
        };

        $self;
    }

    my $die = multi_dice;
    $die -> (set    => 7);
    $die -> (amount => 4);
    print $die -> ('print_faces') -> ('roll'), "\n";
    __END__


Notice the line C<my $this_object = shift || $self;>. That will make
C<$this_object> contain the base object, unlike C<$self> which is the
instance of the current class.

The class C<dice> is subclassed in C<multi_dice> by calling C<dice>
with an extra argument, the base object. Now it's known that C<dice>
is subclassed, and looking for C<AUTOLOAD> if it cannot find the
requested method should not happen; that will be triggered by the
base object.

Inherited classes are named, but they are named by the inheriter,
not the inheritee. This allows you to inherit the same class multiple
times, and getting separate data and method space for it.

When searching for methods in the inheritance tree, no order will be
garanteed. If you subclass multiple classes defining the methods with
the same name, it's better to mask those methods and explicitely
redirect the call to the class you want it to handle.

You can call a method by prepending its class name(s); just like
regular objects. 

Inherited classes are stored in the C<%ISA> hash, but since this variable
is private to the object, each object can have its own inheritance
structure. If you change a class, existing objects of the class will not
be modified.

The pseudo class 'SUPER::' works the same way as regular objects do,
except that it works the right way. It will resolve 'SUPER::' depending
on the inherited classes of the object the method is called in; not
on the C<@ISA> of the package the call is made from.

=head1 C<use OO::Closures;>

By default, the module C<OO::Closures> exports the function C<create_object>.
If you want this function to be known by another name, give that name
as an argument to the C<use> statement.

    use OO::Closure 'other_name';

Now you create objects with C<other_name (\%methods, \%ISA, !@_);>

=head1 BUGS

This documentation uses the word 'class' in cases where it's not really
a class in the sense of the usual object oriented way. Mark-Jason Dominus 
calls this I<class-less> object orientism.

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/oo--closures.git >>.

=head1 AUTHOR

This package was written by Abigail, L<< mailto:oo-closures@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 1998 - 2009, Abigail
        
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
     
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
