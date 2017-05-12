package MooseX::Method;

use Moose;

use B qw/svref_2object/;
use Carp qw/croak/;
use Class::MOP;
use Moose::Meta::Class;
use Moose::Util qw/does_role/;
use MooseX::Meta::Method::Signature;
use MooseX::Meta::Method::Signature::Compiled;
use MooseX::Meta::Signature::Named;
use MooseX::Meta::Signature::Named::Compiled;
use MooseX::Meta::Signature::Positional;
use MooseX::Meta::Signature::Positional::Compiled;
use MooseX::Meta::Signature::Combined;
use MooseX::Meta::Signature::Combined::Compiled;
use MooseX::Method::Exception;
use Sub::Exporter;
use Sub::Name qw/subname/;

our $VERSION = '0.44';

our $AUTHORITY = 'cpan:BERLE';

my %exports = (
  method       => \&_method_generator,
  named        => \&_named_generator,
  positional   => \&_positional_generator,
  semi         => \&_combined_generator,
  combined     => \&_combined_generator,
  attr         => \&_attr_generator,
  default_attr => \&_default_attr_generator,
);

my $exporter = Sub::Exporter::build_exporter({
    exports => \%exports,
    groups  => {
      default  => [':all' => { compiled => 0 }],
      compiled => [':all' => { compiled => 1 }],
    }
  });

sub import {
  my $class = caller;

  return if $class eq 'main';

  Moose::Meta::Class->initialize ($class)
    unless Class::MOP::does_metaclass_exist ($class);

  goto $exporter;
}

sub unimport {
  my $class = caller;

  foreach my $name (keys %exports) {
    if (defined &{$class . '::' . $name}) {
      my $keyword = \&{$class . '::' . $name};

      my $pkg_name = eval { svref_2object($keyword)->GV->STASH->NAME };

      next if $@;

      next if $pkg_name ne 'MooseX::Method';

      no strict qw/refs/;

      delete ${$class . '::'}{$name};
    }
  }
}

sub _positional_generator {
  my $signature_metaclass;

  if ($_[2]->{compiled}) {
    $signature_metaclass = 'MooseX::Meta::Signature::Positional::Compiled';
  } else {
    $signature_metaclass = 'MooseX::Meta::Signature::Positional';
  }
  
  return subname 'MooseX::Method::positional' => sub { eval { $signature_metaclass->new (@_) } || croak "$@" };
}

sub _named_generator {
  my $signature_metaclass;

  if ($_[2]->{compiled}) {
    $signature_metaclass = 'MooseX::Meta::Signature::Named::Compiled';
  } else {
    $signature_metaclass = 'MooseX::Meta::Signature::Named';
  }

  return subname 'MooseX::Method::named' => sub { eval { $signature_metaclass->new (@_) } || croak "$@" };
}

sub _combined_generator {
  my $signature_metaclass;

  if ($_[2]->{compiled}) {
    $signature_metaclass = 'MooseX::Meta::Signature::Combined::Compiled';
  } else {
    $signature_metaclass = 'MooseX::Meta::Signature::Combined';
  }

  return subname 'MooseX::Method::combined' => sub { eval { $signature_metaclass->new (@_) } || croak "$@" };
}

sub _attr_generator {
  return subname 'MooseX::Method::attr' => sub { return { @_ } };
}

sub _default_attr_generator {
  return subname 'MooseX::Method::default_attr' => sub {
    my $class = caller;

    my $meta = Class::MOP::get_metaclass_by_name ($class);

    $meta->add_method (_default_method_attributes => sub { return { @_ } });

    return;
  }
}

sub _method_generator {
  my $default_method_metaclass;

  if ($_[2]->{compiled}) {
    $default_method_metaclass = 'MooseX::Meta::Method::Signature::Compiled';
  } else {
    $default_method_metaclass = 'MooseX::Meta::Method::Signature';
  }

  return subname 'MooseX::Method::method' => sub {
    my $name = shift;

    croak "You must supply a method name"
      unless defined $name && ! ref $name;

    my $class = caller;

    my ($signature,$coderef,$method,$meta);

    my $local_attributes = {};

    if ($class->can ('meta')) {
      $meta = $class->meta;
    } else {
      $meta = Class::MOP::get_metaclass_by_name ($class);
    }

    for (@_) {
      if (does_role ($_,'MooseX::Meta::Signature')) {
        $signature = $_;
      } elsif (ref $_ eq 'CODE') {
        $coderef = $_;
      } elsif (ref $_ eq 'HASH') {
        $local_attributes = $_;
      } else {
        croak "I have no idea what to do with ($_)";
      }
    }

    unless (defined $coderef) {
      if ($meta->isa ('Moose::Meta::Role')) {
        $meta->add_required_methods ($name);

        return;
      }
       
      croak "You didn't provide a coderef";
    }

    my $attributes;

    # Have a method that allows default attribute settings for methods.
    if ($class->can ('_default_method_attributes')) {
      $attributes = $class->_default_method_attributes ($name);

      croak "_default_method_attributes exists but does not return a hashref"
        unless ref $attributes eq 'HASH';
    } else {
      $attributes = {};
    }

    $attributes = { %$attributes,%$local_attributes };

    my $method_metaclass = $attributes->{metaclass} || $default_method_metaclass;

    subname "$class\::$name", $coderef;

    if (defined $signature) {
      $method = $method_metaclass->wrap_with_signature (
          $signature,$coderef,$class,$name
      );
    } else {
      $method = $method_metaclass->wrap ($coderef,
          package_name => $class, name => $name
      );
    }

    # For Devel::Cover  
    $meta->add_package_symbol ("&__real_${name}" => $coderef);

    $meta->add_method ($name => $method);

    return $method;
  }
}

1;

__END__

=pod

=head1 NAME

MooseX::Method - (DEPRECATED) Method declaration with type checking

=head1 SYNOPSIS

  package Foo;

  use MooseX::Method; # Or use MooseX::Method qw/:compiled/

  method hello => named (
    who => { isa => 'Str',required => 1 },
    age => { isa => 'Int',required => 1 },
  ) => sub {
    my ($self,$args) = @_;

    print "Hello $args->{who}, I am $args->{age} years old!\n";
  };

  method morning => positional (
    { isa => 'Str',required => 1 },
  ) => sub {
    my ($self,$name) = @_;

    print "Good morning $name!\n";
  };

  method greet => combined (
    { isa => 'Str' },
    excited => { isa => 'Bool',default => 0 },
  ) => sub {
    my ($self,$name,$args) = @_;

    if ($args->{excited}) {
      print "GREETINGS $name!\n";
    } else {
      print "Hi $name!\n";
    }
  };

  no MooseX::Method; # Remove the MooseX::Method keywords.

  Foo->hello (who => 'world',age => 42); # This works.

  Foo->morning ('Jens'); # This too.

  Foo->greet ('Jens',excited => 1); # And this as well.

  Foo->hello (who => 'world',age => 'fortytwo'); # This doesn't.

  Foo->morning; # This neither.

  Foo->greet; # Won't work.

=head1 DEPRECATION NOTICE

This module has been deprecated in favor of L<MooseX::Method::Signatures>. It
is being maintained purely for people who need more time to change their
implementations.  It should not be used for new code.

=head1 DESCRIPTION

=head2 The problem

This module is an attempt to solve a problem I've often encountered but
never really found any good solution for: validation of method
parameters. How many times have we all ourselves writing code like this:

  sub foo {
    my ($self,$args) = @_;

    die "Invalid arg1"
      unless (defined $arg->{bar} && $arg->{bar} =~ m/bar/);
  }

Manual parameter validation is a tedious, repetive process and
maintaining it consistently throughout your code can be downright hard
sometimes. Modules like L<Params::Validate> makes the job a bit easier,
but it doesn't do much for elegance and it still requires more weird
code than what should, strictly speaking, be neccesary.

=head2 The solution

MooseX::Method to the rescue! It lets you declare which parameters
people should pass to your method using Moose-style declaration and
Moose types. It doesn't get much Moosier than this.

=head1 DECLARING METHODS

  method $name => sub {};

  method $name => named () => sub {};

The exported function C<method> installs a method into the class which
call it. The first parameter it takes is the name of the method. The
rest of the parameters need not be in any particular order, though it's
probably best for the sake of readability to keep the subroutine at the
end.

There are two different elements you need to be aware of: the
signature and the parameter. A signature is (for the purpose of this
document) a collection of parameters. A parameter is a collection of
requirements that an individual argument needs to satisfy. No matter
what kind of signature you use, these properties are declared the
same way, although specific properties may behave differently
depending on the particular signature type.

As of version 0.31, signatures are optional in method declarations. If
one is not provided, arguments will be passed directly to the coderef.

=head2 Signatures

MooseX::Method ships with three different signature types. Once the
internal API stabilizes, you'll be able to implement your own signatures
easily.

The three different signatures types are shown below:

  named (
    foo => { isa => 'Int',required => 1 },
    bar => { isa => 'Int' },
  )

  # And methods declared are called like...

  $foo->mymethod (foo => 1,bar => 2);

  positional (
    { isa => 'Int',required => 1 },
    { isa => 'Int' },
  )

  $foo->mymethod (1,2);

  combined (
    { isa => 'Int' },
    foo => { isa => 'Int' },
  )

  $foo->mymethod (1,foo => 2);

The named signature type will let you specify names for the individual
parameters. The example above declares two parameters, foo and bar,
where foo is mandatory. Read more about parameter properties below.

The positional signature type lets you, surprisingly, declare positional
unnamed parameters. If a parameter has the 'required' property set in a
positional signature, a parameter is counted as provided if the argument
list is equal or larger to its position. One thing about this is that it
leads to a situation where a parameter is implicitly required if a later
parameter is explicitly required.  Even so, you should always mark all
required parameters explicitly.

The combined signature type combines the two signature types above. You
may declare both named and positional parameters. Parameters do not need
to come in any particular order (although positional parameters must be
ordered correctly relative to each other like with the positional
signature) so it's possible to declare a combined signature like this:

  combined (
    { isa => 'Int' },
    foo => { isa => 'Int' },
    { isa => 'Int' },
    bar => { isa => 'Int' },
  )

This is however not recommended for the sake of readability. Put
positional arguments first, then named arguments last, which is the same
order combined signature methods receive them. Also be aware that all
positional parameters are always required in a combined signature. Named
parameters may be both optional or required however.

=head2 Parameters

Currently, a parameter may set any of the following fields:

=over 4

=item B<isa>

If a value is provided, it must satisfy the constraints of the type
specified in this field. This field should accept the same values
as its counterpart in Moose attributes, see the Moose documentation
for more details on what you can use.

=item B<does>

Require that the value provided is able to do a certain role. It's
implied that the value must also be blessed, although setting this
property does not alter the isa property.

=item B<default>

Sets the parameter to a default value if the user does not provide it.

=item B<required>

If this field is set, supplying a value to the method isn't optional
but the value may be supplied by the default field.

=item B<coerce>

If the type supports coercion, attempt to coerce the value provided if
it does not satisfy the requirements of isa. See Moose for examples
of how to coerce.

=item B<metaclass>

This is used as parameter metaclass if specified. If you don't know
what this means, read the documentation for Moose.

=back

=head2 Attributes

To set a method attribute, use the following syntax:

  method foo => attr (
    attribute => $value,
  ) => sub {};

You can set the default method attributes for a class by using the
function default_attr like this:

  default_attr (attribute => $value);

  method foo => attr (
    overridden_attribute => $value,
  ) => sub {};

If you discover any attributes other than those listed here while diving
through the code, they're not guaranteed to be in the next release.

=over 4

=item B<metaclass>

Sets the metaclass to use when creating the method.

=back

=head1 EXPORTED FUNCTIONS

=over 4

=item B<method>

The function for declaring methods.

=item B<named>

A function for constructing a named signature.

=item B<positional>

A function for constructing a positional signature.

=item B<combined>

A function for constructing a combined signature.

=item B<semi>

An alias for the combined structure. B<Will be removed post version 1.0.>

=item B<attr>

A function for declaring method attributes.

=item B<default_attr>

A function for setting the default attributes on methods of a class.

=back

=head1 ROLES

Inside Moose roles, MooseX::Method can be used as sugar for declaring
a required method. This is done by not attaching a coderef to method
declaration, like this...

  method foo => ();

Which will make MooseX::Method add the method to the list of required
methods instead of making it a real method in the role. Signatures in
such declarations are at the moment not used, but I'm working with
stevan on making it possible to require a specific signature.

=head1 COMPILATION SUPPORT

As of 0.40, MooseX::Method has experimental support for compiling the
signatures into Perl code and inlining it to achieve a significant
performance improvement. This behaviour is not enabled by default since
it is not yet tested extensively, and may or may not be severely
bugged -- but if you dare, you can enable inline compilation with

  use MooseX::Method qw/:compiled/;

And all methods within this class will take adventage of the new
experimental feature. This does not affect classes that do not
explicitly enable it; the effect is local. If you try this and
get an error using it, please make a small test case and send it
to me.

=head1 FUTURE

I'm considering using a param() function to declare individual
parameters, but I feel this might have too high a risk of clashing with
existing functions of other modules. Your thoughts on the subject are
welcome.

=head1 CAVEATS

Methods are added to the class at runtime, which obviously means they
won't be available to play with at compile-time. Moose won't mind this
but a few other modules probably will. A workaround for this that
sometimes works is to encapsulate the method declarations in a BEGIN
block.

There's also a problem related to how roles are loaded in Moose. Since
both MooseX::Method methods and Moose roles are loaded at runtime, any
methods a role requires in some way must be declared before the 'with'
statement. This affects things like 'before' and 'after'.

=head1 ACKNOWLEDGEMENTS

=over 4

=item Stevan Little for making Moose and luring me into the
world of metafoo.

=item Max Kanat-Alexander for testing.

=item Christopher Nehren for documentation review.

=back

=head1 SEE ALSO

=over 4

=item L<Moose>

=item The #moose channel on irc.perl.org

=back

=head1 BUGS

Most software has bugs. This module probably isn't an exception. 
If you find a bug please either email me, or add the bug to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Anders Nor Berle.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

