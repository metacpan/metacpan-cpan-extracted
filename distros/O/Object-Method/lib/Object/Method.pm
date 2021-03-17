package Object::Method;

use strict;
use warnings;

use Scalar::Util ();

our $VERSION = '0.04';

sub import {
    no strict;
    if (@_ > 0) {
        *{caller() . '::method'} = \&method;
    }
}

sub method {
    my ($o, $m, $c) = @_;

    my $p = Scalar::Util::blessed($o);
    my $id = Scalar::Util::refaddr($o);

    unless ($p =~ /#<(\d+)>$/ and $id == $1) {
        my $op = $p;

        $p =~ s/(?:#<\d+>)?$/#<$id>/;

        # eval "package $p;";
        bless $o, $p;
        {
            no strict;
            @{$p . '::ISA'}=($op);
        }
    }

    {
        no strict;
        *{$p . "::$m"} = $c;
    }
    return $o;
}

1;

__END__

=head1 NAME

Object::Method - attach method to objects instead of classes.

=head1 SYNOPSIS

  package Stuff;
  use Object::Method;

  package main;

  my $o = Stuff->new;
  my $p = Stuff->new;

  # Attach method 'foo' to $o but not $p
  $o->method("foo", sub { ... });

=head1 DESCRIPTION

Object::Method lets you attach methods to methods to object but not
its classes. There are three different ways to use this module. Keep reading.

The first way is to use it to create a class that allows user to
attach methods at runtime. To do this, simply put 'use Object::Method' in your
class body like this:

    package Stuff;
    use Object::Method;

This effectively exports a C<method> method to your class, which can be used to
create new methods like this:

    my $o = Stuff->new;

    $o->method("foo" => sub { ... });

The C<method> method takes exactly two arguments: the method name, and
a sub-routine or code-ref. After calling that C<method> method on
object C<$o>, a new method C<foo> will be attached to C<$o> and can be
invoked only on C<$o>.

The second way is to use it on all objects through
C<UNIVERSAL::Object::Method> like this:

    use UNIVERSAL::Object::Method;
    use SomeClass;

    my $o = SomeClass->new;

    $o->method("foo" => sub { ... });

This is an overwhelming way due to the use of L<UNIVERSAL> namespace. If
you are not familiar with it, read the linked documentation.

The third way is to use it on a class that does not itself use this
module at all by using C<method> as a function instead of as a method.

    ues Object::Method;
    use SomeClass;
    
    my $o = SomeClass->new;
    
    method($o, "foo" => sub { ... });

Please notice that calling the C<method> method multiple times
obviously override previous definition and there is no way to undo
this for now.

=head1 BEHIND THE SCENE

To implement such mechanism, the object on which the C<method> method is
invoked are re-blessed into its' own, dynamically created, namespace. You
may exam them with C<ref>:

    my $x = My::Awesome::Class->new;
    $x->method("kiss", sub { say ... });

    say ref($x);
    # => My::Awesome::Class#<1>

    say "$x";
    # => My::Awesome::Class#<1>=HASH(0x100826a30)

Those dynamically created classes are properly setup to be inherited
from the original classes with C<@ISA> variable. That effects the
return value of C<ref> but not C<isa>.

The number in the last part of the namespace is a serial that gets
incremented when a new object is encountered. If numerous objects are
encountered it might consume a very big part of symble table.  The
mechanism to reap unused classnames are not implemented at this
moment.


=head1 AUTHOR

Kang-min Liu

=head1 LICENSE

This is free software, licensed under:

    The MIT (X11) License

=cut

