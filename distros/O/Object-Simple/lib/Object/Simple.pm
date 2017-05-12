package Object::Simple;

our $VERSION = '3.19';

use strict;
use warnings;
use Scalar::Util ();

no warnings 'redefine';

use Carp ();

sub import {
  my $class = shift;
  
  return unless @_;

  # Caller
  my $caller = caller;
  
  # No export syntax
  my $no_export_syntax;
  unless (grep { $_[0] eq $_ } qw/new attr/) {
    $no_export_syntax = 1;
  }
  
  # Inheritance
  if ($no_export_syntax) {
    my $arg1 = shift;
    my $arg2 = shift;
    
    my $base_class;
    if (defined $arg1) {
      # Option
      if ($arg1 =~ /^-/) {
        if ($arg1 eq '-base') {
          if (defined $arg2) {
            $base_class = $arg2;
          }
        }
        else {
          Carp::croak "'$arg1' is invalid option(Object::Simple::import())";
        }
      }
      # Base class
      else {
        $base_class = $arg1;
      }
    }
    
    # Export has function
    no strict 'refs';
    no warnings 'redefine';
    *{"${caller}::has"} = sub { attr($caller, @_) };
    
    # Inheritance
    if ($base_class) {
      my $base_class_path = $base_class;
      $base_class_path =~ s/::|'/\//g;
      require "$base_class_path.pm";
      @{"${caller}::ISA"} = ($base_class);
    }
    else { @{"${caller}::ISA"} = ($class) }
    
    # strict!
    strict->import;
    warnings->import;
  }
  
  # Export methods
  else {
    my @methods = @_;
  
    # Exports
    my %exports = map { $_ => 1 } qw/new attr/;
    
    # Export methods
    for my $method (@methods) {

      # Can be Exported?
      Carp::croak("Cannot export '$method'.")
        unless $exports{$method};

      warn "function exporting of $method is DEPRECATED(Object::Simple)";
      
      # Export
      no strict 'refs';
      *{"${caller}::$method"} = \&{"$method"};
    }
  }
}

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub attr {
  my ($self, @args) = @_;
  
  my $class = ref $self || $self;
  
  # Fix argument
  unshift @args, (shift @args, undef) if @args % 2;
  
  for (my $i = 0; $i < @args; $i += 2) {
    
    if ($i == 2) {
      warn "The syntax of multiple key-value arguments is DEPRECATED(Object::Simple::has or Object::Simple::attr)";
    }
    
    # Attribute name
    my $attrs = $args[$i];
    $attrs = [$attrs] unless ref $attrs eq 'ARRAY';
    
    # Default
    my $default = $args[$i + 1];
    
    for my $attr (@$attrs) {

      Carp::croak qq{Attribute "$attr" invalid} unless $attr =~ /^[a-zA-Z_]\w*$/;

      # Header (check arguments)
      my $code = "*{\"${class}::$attr\"} = sub {\n  if (\@_ == 1) {\n";

      # No default value (return value)
      unless (defined $default) { $code .= "    return \$_[0]{'$attr'};" }

      # Default value
      else {

        Carp::croak "Default has to be a code reference or constant value (${class}::$attr)"
          if ref $default && ref $default ne 'CODE';

        # Return value
        $code .= "    return \$_[0]{'$attr'} if exists \$_[0]{'$attr'};\n";

        # Return default value
        $code .= "    return \$_[0]{'$attr'} = ";
        $code .= ref $default eq 'CODE' ? '$default->($_[0]);' : '$default;';
      }

      # Store value
      $code .= "\n  }\n  \$_[0]{'$attr'} = \$_[1];\n";

      # Footer (return invocant)
      $code .= "  \$_[0];\n}";

      # We compile custom attribute code for speed
      no strict 'refs';
      warn "-- Attribute $attr in $class\n$code\n\n" if $ENV{OBJECT_SIMPLE_DEBUG};
      Carp::croak "Object::Simple error: $@" unless eval "$code;1";
    }
  }
}

=head1 NAME

Object::Simple - Simplest class builder, Mojo::Base porting, fast and less memory

=over

=item *

B<Simplest class builder>. All you learn is only C<has> function!

=item *

B<Mojo::Base porting>. Do you like L<Mojolicious>? If so, this is good choices!

=item *

B<Fast and less memory>. Fast C<new> and accessor method. Memory saving implementation.

=back

=head1 SYNOPSIS

  package SomeClass;
  use Object::Simple -base;
  
  # Create accessor
  has 'foo';
  
  # Create accessor with default value
  has foo => 1;
  has foo => sub { [] };
  has foo => sub { {} };
  has foo => sub { OtherClass->new };
  
  # Create accessors at once
  has ['foo', 'bar', 'baz'];
  has ['foo', 'bar', 'baz'] => 0;
  
Create object.

  # Create a new object
  my $obj = SomeClass->new;
  my $obj = SomeClass->new(foo => 1, bar => 2);
  my $obj = SomeClass->new({foo => 1, bar => 2});
  
  # Set and get value
  my $foo = $obj->foo;
  $obj->foo(1);
  
  # Setter can be chained
  $obj->foo(1)->bar(2);

Inheritance
  
  package Foo;
  use Object::Simple -base;
  
  # Bar inherit Foo
  package Bar;
  use Object::Simple 'Foo';

=head1 DESCRIPTION

Object::Simple is B<Simplest> class builder. All you learn is only C<has> function.
You can learn all features of L<Object::Simple> in B<an hour>. There is nothing difficult.

Do you like L<Mojolicious>? In fact, Object::Simple is L<Mojo::Base> porting. Mojo::Base is basic class builder in Mojolicious project.
If you like Mojolicious, this is good choice. If you have known Mojo::Base, you learn nothing.

C<new> and accessor method is B<fast>. Implementation is pure perl and plain old hash-base object.
Memory is saved. Extra objects is not created at all. Very light-weight object-oriented module.

Comparison with L<Class::Accessor::Fast>

Class::Accessor::Fast is simple, but lack often used features.
C<new> method can't receive hash arguments.
Default value can't be specified.
If multiple values is set through the accessor,
its value is converted to array reference without warnings.

Comparison with L<Moose>

Moose has very complex syntax and depend on much many modules.
You have to learn many things to do object-oriented programing.
Understanding source code is difficult.
Compile-time is very slow and memory usage is very large.
Execution speed is not fast.
For simple OO, Moose is overkill.
L<Moo> is improved in this point.

=head1 TUTORIAL

=head2 1. Create class and accessor

At first, you create class.

  package SomeClass;
  use Object::Simple -base;

By using C<-base> option, SomeClass inherit Object::Simple and import C<has> method.

L<Object::Simple> have C<new> method. C<new> method is constructor.
C<new> method can receive hash or hash reference.
  
  my $obj = SomeClass->new;
  my $obj = SomeClass->new(foo => 1, bar => 2);
  my $obj = SomeClass->new({foo => 1, bar => 2});

Create accessor by using C<has> function.

  has 'foo';

If you create accessor, you can set or get value

  # Set value
  $obj->foo(1);
  
  # Get value
  my $foo = $obj->foo;

Setter can be chained.

  $obj->foo(1)->bar(2);

You can define default value.

  has foo => 1;

If C<foo> value is not exists, default value is used.

  my $foo_default = $obj->foo;

If you want to use reference or object as default value,
default value must be surrounded by code reference.
the return value become default value.

  has foo => sub { [] };
  has foo => sub { {} };
  has foo => sub { SomeClass->new };

You can create multiple accessors at once.

  has ['foo', 'bar', 'baz'];
  has ['foo', 'bar', 'baz'] => 0;

=head2 2. Override method

Method can be overridden.

B<Example:>

Initialize the object

  sub new {
    my $self = shift->SUPER::new(@_);
    
    # Initialization
    
    return $self;
  }

B<Example:>

Change arguments of C<new>.
  
  sub new {
    my $self = shift;
    
    $self->SUPER::new(x => $_[0], y => $_[1]);
    
    return $self;
  }

You can pass array to C<new> method.

  my $point = Point->new(4, 5);

=head2 3. Examples - class, accessor, inheritance and method overriding

I introduce L<Object::Simple> example.

Point class: two accessor C<x> and C<y>,
and C<clear> method to set C<x> and C<y> to 0.

  package Point;
  use Object::Simple -base;

  has x => 0;
  has y => 0;
  
  sub clear {
    my $self = shift;
    
    $self->x(0);
    $self->y(0);
  }

Use Point class.

  use Point;
  my $point = Point->new(x => 3, y => 5);
  print $point->x;
  $point->y(9);
  $point->clear;

Point3D class: Point3D inherit Point class.
Point3D class has C<z> accessor in addition to C<x> and C<y>.
C<clear> method is overridden to clear C<x>, C<y> and C<z>.

  package Point3D;
  use Object::Simple 'Point';
  
  has z => 0;
  
  sub clear {
    my $self = shift;
    
    $self->SUPER::clear;
    
    $self->z(0);
  }

Use Point3D class.

  use Point3D;
  my $point = Point->new(x => 3, y => 5, z => 8);
  print $point->z;
  $point->z(9);
  $point->clear;

=head1 WHAT IS OBJECT-ORIENTED PROGRAMING?

I introduce essence of Object-Oriented programing.

=head2 1. Inheritance

First concept is inheritance.
Inheritance means that
if Class Q inherit Class P, Class Q call all methods of class P.

  +---+
  | P | Base class
  +---+   have method1 and method2
    |
  +---+
  | Q | Sub class
  +---+   have method3

Class Q inherits Class P,
Q can call all methods of P in addition to methods of Q.

In other words, Q can call
C<method1>, C<method2>, and C<method3>

You can inherit other class by the following way.

  # P.pm
  package P;
  use Object::Simple -base;
  
  sub method1 { ... }
  sub method2 { ... }
  
  # Q.pm
  package Q;
  use Object::Simple 'P';
  
  sub method3 { ... }

Perl have useful functions and methods to help Object-Oriented programing.

If you know what class the object is belonged to, use C<ref> function.

  my $class = ref $obj;

If you know what class the object inherits, use C<isa> method.

  $obj->isa('SomeClass');

If you know what method the object(or class) can use, use C<can> method 

  SomeClass->can('method1');
  $obj->can('method1');

=head2 2. Encapsulation

Second concept is encapsulation.
Encapsulation means that
you don't touch internal data directory.
You must use public method when you access internal data.

Create accessor and use it to keep this rule.

  my $value = $obj->foo;
  $obj->foo(1);

=head2 3. Polymorphism

Third concept is polymorphism.
Polymorphism is divided into two concepts,
overload and override

Perl programmer don't need to care overload.
Perl is dynamic type language.
Subroutine can receive any value.

Override means that you can change method behavior in sub class.
  
  # P.pm
  package P;
  use Object::Simple -base;
  
  sub method1 { return 1 }
  
  # Q.pm
  package Q;
  use Object::Simple 'P';
  
  sub method1 { return 2 }

P C<method1> return 1. Q C<method1> return 2.
Q C<method1> override P C<method1>.

  # P method1 return 1
  my $obj_a = P->new;
  $obj_p->method1; 
  
  # Q method1 return 2
  my $obj_b = Q->new;
  $obj_q->method1;

If you want to call super class method from sub class,
use SUPER pseudo-class.

  package Q;
  use Object::Simple 'P';
  
  sub method1 {
    my $self = shift;
    
    # Call supper class P method1
    my $value = $self->SUPER::method1;
    
    return 2 + $value;
  }

If you understand three concepts,
you have learned Object-Oriented programming primary parts.

=head1 FUNCTIONS

=head2 has

Create accessor.
  
  has 'foo';
  has ['foo', 'bar', 'baz'];
  has foo => 1;
  has foo => sub { {} };

  has ['foo', 'bar', 'baz'];
  has ['foo', 'bar', 'baz'] => 0;

C<has> function receive
accessor name and default value.
Default value is optional.
If you want to create multiple accessors at once,
specify accessor names as array reference at first argument.

If you want to specify reference or object as default value,
it must be code reference
not to share the value with other objects.

Get and set a value.

  my $foo = $obj->foo;
  $obj->foo(1);

If a default value is specified and the value is not exists,
you can get default value.

Setter return invocant. so you can do chained call.

  $obj->foo(1)->bar(2);

=head1 METHODS

=head2 new

  my $obj = Object::Simple->new;
  my $obj = Object::Simple->new(foo => 1, bar => 2);
  my $obj = Object::Simple->new({foo => 1, bar => 2});

Create a new object. C<new> receive
hash or hash reference as arguments.

=head2 attr

  __PACKAGE__->attr('foo');
  __PACKAGE__->attr(['foo', 'bar', 'baz']);
  __PACKAGE__->attr(foo => 1);
  __PACKAGE__->attr(foo => sub { {} });

  __PACKAGE__->attr(['foo', 'bar', 'baz']);
  __PACKAGE__->attr(['foo', 'bar', 'baz'] => 0);

Create accessor.
C<attr> method usage is equal to C<has> function.

=head1 OPTIONS

=head2 -base

By using C<-base> option, the class inherit Object::Simple
and import C<has> function.

  package Foo;
  use Object::Simple -base;
  
  has x => 1;
  has y => 2;

strict and warnings is automatically enabled.

If you want to inherit class, let's write the following way.
  
  # Bar inherit Foo
  package Bar;
  use Object::Simple 'Foo';

You can also use the following syntax. This is Object::Simple only.

  # Same as above
  package Bar;
  use Object::Simple -base => 'Foo';

You can also use C<-base> option in sub class
to inherit other class. This is Object::Simple only.

  # Same as above
  package Bar;
  use Foo -base;

=head1 FAQ

=head2 Really enough object-oriented programing with this few features?

Yes, for example, Mojolicious is very big project, but in fact, source code is clean only using single inheritance.
Generally speaking, readable source code is build on simple concepts, not complex features.

C<BUILD>, C<BUILDARGS> and C<DEMOLISH> methods in L<Moo> are needed for good object-oriented programming?
If you want to use multiple inheritance or role, these methods is needed.

But I strongly recommend you use only single inheritance in object-oriented programming. Single inheritance is clean and readable.

If you use only single inheritance,
You can create custom constructor and call constructors in correct order.
and You can create custom destructor and call destructors in correct order,

Creating custom constructor is very very easy. There is nothing difficult.
    
  # Custom constructor
  sub new {
    # At first Call super class constructor. Next do what you want
    my $self = shift->SUPER::new(@_);
    
    # What you want
    
    return $self;
  }
  
  # Custom destructor
  sub DESTROY {
    my $self = shift;
    
    # What you want

    # At first, do what you want, Next call super class destructor
    $selft->SUPER::DESTROY;
    
    return $self;
  }

=head2 Object::Simple is fastest OO module?

No, Object::Simple is B<not> fastest module, but enough fast. If you really need performance, you can access hash value directory.

  # I want performance in some places. Let's access hash value directory!
  # Object::Simple is plain old hash-based object
  $self->{x};

=head2 What is benefits comparing with Mojo::Base?

=over

=item *

Support Perl 5.8

=item *

Installation is very fast because there are a few files.

=item *

Some people think that my module want not to depend on whole Mojolicious to use Mojo::Base only. Object::Simple satisfy the demand.

=head2 Why Object::Simple is different from Mojo::Base in some points?

In old days, Object::Simple wasn't Mojo::Base porting. I tried different things.

Now, I want Object::Simple to be same as Mojo::Base completely except supporting Perl 5.8.

=back

=head1 BACKWARDS COMPATIBILITY POLICY

If a functionality is DEPRECATED, you can know it by DEPRECATED warnings.
You can check all DEPRECATED functionalities by document.
DEPRECATED functionality is removed after five years,
but if at least one person use the functionality and tell me that thing
I extend one year each time he tell me it.

EXPERIMENTAL functionality will be changed without warnings.

(This policy was changed at 2011/10/22)

=head1 DEPRECATED

  function exporting of C<new> and C<attr> method # Will be removed 2021/6/1
  
  The syntax of multiple key-value arguments 
    has x => 1, y => 2;      
    __PACAKGE__->attr(x => 1, y => 2);
  # Will be removed 2021/6/1

=head1 BUGS

Tell me the bugs
by mail(C<< <kimoto.yuki at gmail.com> >>) or github L<http://github.com/yuki-kimoto/Object-Simple>

=head1 SUPPORT

If you have any questions the documentation might not yet answer, don't hesitate to ask on the mailing list or the official IRC channel
#object-simple on irc.perl.org.

=head1 AUTHOR

Yuki Kimoto(C<< <kimoto.yuki at gmail.com> >>)

I'm pleasure if you send message for cheer. I can get power by only your messages!

=head1 USERS

Projects using L<Object::Simple>.

=over 4

=item *

GitPrep - Portable GitHub system into your own server. L<https://github.com/yuki-kimoto/gitprep>

=item *

L<DBIx::Custom> - DBI extension to execute insert, update, delete, and select easily

=item *

L<Validator::Custom> - HTML form Validation, simple and good flexibility

=back

=head1 SEE ALSO

CPAN have various class builders. Let's compare it with L<Object::Simple>.

L<Mojo::Base>, L<Class::Accessor>, L<Class::Accessor::Fast>, L<Moose>, L<Moo>, L<Class::Tiny>.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2017 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Artistic v2.

This is same as L<Mojolicious> licence.

=cut

1;
