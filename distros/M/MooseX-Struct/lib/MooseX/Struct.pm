package MooseX::Struct;

use warnings;
use strict;

use Moose ();
use Sub::Install;
use Carp;

our $VERSION = '0.06';

sub import {
   my $class = shift;

   strict->import;
   warnings->import;

   if (@_) {
      my ($name, $attributes) = _parse_arg_structure(@_);

      croak 'Can not build structure out of "main"' if $name eq 'main';

      Moose->import({into  => $name});

      _build_struct($name, $attributes);

      Sub::Install::install_sub({
            into  => $name,
            code  => \&immutable,
            as    => 'immutable',
      });
   } else {
      my $caller = caller;

      Moose->import({into  => $caller}) unless $caller eq 'main';

      Sub::Install::install_sub({
            into  => $caller,
            code  => \&immutable,
            as    => 'immutable',
      });
      Sub::Install::install_sub({
            into  => $caller,
            code  => \&struct,
            as    => 'struct',
      });
   }
}

sub _parse_arg_structure {
   my ($name, $attr);

   my $caller = (caller(1))[0];

   # Check POD for cases
   if (@_ == 1) {
      # One arg, assume ( {} )
      ($name,$attr) = ($caller, shift);
   } elsif (@_ == 2 && ref $_[1] eq 'HASH') {
      # 2 args, second hashref, assume ('', {})
      ($name,$attr) = (shift, shift);
   } else {
      # True: Odd number of args, assume ('', ( '' => $ ))
      # False: Even number of args (second one not hashref), ( ( '' => $ ) )
      $name = (@_ % 2) ? shift : $caller;

      my ($attr_name, $attr_spec);

      while (my $attr_name = shift) {
         $attr_spec = shift;
         if (ref $attr_name eq 'ARRAY') {
            $attr->{$_} = $attr_spec foreach @$attr_name;
         } else {
            $attr->{$attr_name} = $attr_spec;
         }
      }
   }

   # simple check for valid args, else print usage.
   if (!($name || ref $attr eq 'HASH')) {
      croak _usage();
   }

   return ($name, $attr);
}

sub immutable {
   my $class = shift || return;

   return if not eval { $class->can('meta') };

   $class->meta->make_immutable;
}

sub struct {
   my ($name, $attributes) = _parse_arg_structure(@_);

   return _build_struct($name,$attributes);
}

sub _build_struct {
   my $name       = shift;
   my $attributes = shift;

   ### Initialize $name as a Moose object (inherits, by default, from Moose::Object)
   Moose::init_meta($name);

   ### imports moose functions into $name package, not necessarily caller's
   Moose->import({into  => $name});

   foreach my $attr_name (keys %$attributes) {
      my $type = $attributes->{$attr_name};
      my $attr_spec;
      if (ref $type eq 'HASH') {
         $attr_spec = $type;
      } elsif (_types($type)) {
         $attr_spec = _types($type);
      } else {
         ### Else let Class::Mop parse it as an 'isa' value.
         $attr_spec = { is => 'rw', isa => $type }
      }
      if ($attr_name =~ /^ARRAY\([\d\w]x[\d\w]+\)$/) {
         croak "MooseX::Struct - \n".
               "  It looks like you tried to supply an array reference to ".
               "declare multiple attributes at once. This is only possible ".
               "when using parantheses and not curly brackets due to the way ".
               "perl stringifies hash keys. See perldoc MooseX::Struct for ".
               "more information";
      }
      $name->meta->add_attribute( $attr_name, %$attr_spec );
   }

   return $name;
}
   
sub _usage {
   return q/
      Invalid arguments passed to struct(). MooseX::Struct usage: 
         struct ( ['Object::Name',] %hash|$hashref );
         e.g.
         struct 'MyObject' => (
            attribute  => 'Scalar',
         );
/;
}

{
   my $map = {
      '$'   => { is => 'rw', isa => 'Value' },
      '*$'  => { is => 'rw', isa => 'ScalarRef' },
      '@'   => { is => 'rw', isa => 'ArrayRef'},
      '*@'  => { is => 'rw', isa => 'ArrayRef'},
      '%'   => { is => 'rw', isa => 'HashRef'},
      '*%'  => { is => 'rw', isa => 'HashRef'},
      '*'   => { is => 'rw', isa => 'GlobRef'},
      '#'   => { is => 'rw', isa => 'Num'},
      '1'   => { is => 'rw', isa => 'Int'},
      'w'   => { is => 'rw', isa => 'Str'},
      'rx'  => { is => 'rw', isa => 'RegexpRef'},
      '&'   => { is => 'rw', isa => 'CodeRef'},
      '?'   => { is => 'rw' },
      '!'   => { is => 'rw', isa => 'Bool'},
      'rw'  => { is => 'rw' },
      'ro'  => { is => 'ro' },
   };

   $map->{'array'}      = $map->{'@'};
   $map->{'arrayref'}   = $map->{'*@'};
   $map->{'hash'}       = $map->{'%'};
   $map->{'hashref'}    = $map->{'*%'};
   $map->{'scalar'}     = $map->{'$'};
   $map->{'scalarref'}  = $map->{'*$'};
   $map->{'glob'}       = $map->{'*'};
   $map->{'number'}     = $map->{'#'};
   $map->{'string'}     = $map->{'w'};
   $map->{'regex'}      = $map->{'rx'};
   $map->{'any'}        = $map->{'?'};
   $map->{'bool'}       = $map->{'!'};
   $map->{'boolean'}    = $map->{'!'};
   $map->{'int'}        = $map->{'1'};
   $map->{'integer'}    = $map->{'1'};
   $map->{''}           = $map->{'?'};

   sub _types {
      my $type = shift;
      if (defined $type) {
         return $map->{lc $type} || undef;
      } else {
         if (wantarray) {
            return keys %$map;
         } else {
            no warnings 'uninitialized';
            print "+----------------+-----------------------+\n";
            print "| MooseX::Struct | Moose/Class::MOP type |\n";
            print "+----------------+-----------------------+\n";
            printf("| %14s | %-21s |\n", $_, $map->{$_}->{isa}) foreach sort keys %$map;
            print "+----------------+-----------------------+\n";
         }
      }
   }
}

1;

__END__

=head1 MooseX::Struct

MooseX::Struct - Struct-like interface for Moose Object creation

=head1 Version

Version 0.06

=cut

=head1 Synopsis

   use MooseX::Struct;

   struct 'MyClass::Foo' => (
      bar   => 'Scalar',
      baz   => 'Array',
   );
    
   my $obj = new MyClass::Foo;
  
   $obj->bar(44);    # sets $obj->{bar} to 44
   
   print $obj->bar;  # prints 44
  
   ### or

   package MyClass::Foo;
   use MooseX::Struct;

   ### This will default to the current package : 'MyClass::Foo'

   struct (
      bar   => 'Scalar',
      baz   => 'Array',
   );

   ### or create your struct at compile-time
   
   use MooseX::Struct 'MyClass::Foo' => (
      bar   => 'Scalar',
      baz   => 'Array',
   );

   ### Immutable Moose Objects

   package MyClass::Foo;
   use MooseX::Struct;

   immutable struct (
      bar   => 'Scalar',
      baz   => 'Array',
   );

=head1 Description

This module is a reimplementation of the core L<Class::Struct> package for
the L<Moose> Object System. The original Class::Struct is a very useful
package but offers little to no extensibility as soon as you outgrow its
features.

=head2 For the Class::Struct users:

This is not a drop-in replacement (though
for most common cases, it I<is> a drop in replacement), it works somewhat
differently and has different performance concerns.

=head2 For Moose users:

This can be used as an alternate way to create Moose objects. All exports
that normally come from 'use Moose' are exported to the specified package,
or the current package if none given (unless the current package is 'main').

A lot of this package passes off work to L<Moose> and L<Class::MOP>, so
both of those should be considered good reading recommendations.

=head1 Exports

MooseX::Struct exports two functions, C<struct> and C<immutable>, to the caller's
namespace.

=head2 C<immutable>

C<immutable()> is a convenience method that takes in a class name and calls
CLASS->meta->make_immutable(). Since struct() returns the class name of the
object it just defined, you can write out very nice looking code such as:

   immutable struct 'MyClass' => ( class definition );

=head2 C<struct>

The C<struct> function can be passed parameters in four forms but boil
down to :

   struct( ['Class Name',] %hash|$hashref );

Omitting the 'Class Name' argument allows MooseX::Struct to default to
the current package's namespace.

Because you do not need parantheses for predefined functions and the
C<< => >> is a synonym for C<,>, the above can be written in a more
attractive way :

   struct 'My::Class' => (
      attribute   => 'type',
   );

Thus the following three forms are:

   struct 'My::Class' => {
      attribute   => 'type',
   };
   
   struct (
      attribute   => 'type',
   );
   
   struct {
      attribute   => 'type',
   };

The last two would default to the current package name.

=head1 Compile-time declaration of a struct

Like Class::Struct, MooseX::Struct allows you to specify a class at
compile time by passing the appropriate definition to MooseX::Struct at import.

e.g.

   use MooseX::Struct 'My::Class' => (
      attribute   => 'type',
   );

Again, like Class::Struct, there is no real time savings, but you do
get a more logical flow of events and it does get all of the hard work
done at startup.

=head1 Attributes

Attributes all take the form of a hash key/value pair with the hash key
being the name of the attribute and the default name of the accessor,
and the value being a predefined type alias (see below). All attributes
are read/write by default (is => 'rw'). Advanced attributes can be made
by specifying a hashref of acceptible attribute specifications (see 
C<Class::MOP::Attribute>) instead of a type alias, e.g.

   struct 'My::Class'   => (
      foo   => 'Scalar',
      bar   => { accessor  => 'quux' }
      baz   => { is => 'ro', reader => 'get_baz', [etc] }
   );

=head2 Note / Warning / Not a bug

Multiple attributes can be declared at once in an array reference B<while being
defined within parantheses> as opposed to curly brackets (i.e., as a standard
array of arguments as opposed to a hash / hash reference). This is due to perl
stringifying references in order to use them as hash keys and the fact that perl
can't dereference them after that happens.

=head1 Types

These are used to constrain an attribute's value to a certain data type
(isa => 'Type').

Types are case-insensitive for matching purposes, but you can specify a
type that is not listed here and it will be passed through unchanged
to Moose::Meta::Class / Class::MOP::Class. So if you are familiar with
advanced types or have created your own type constraints, you can still
use MooseX::Struct.
 
   +----------------+-----------------------+
   | MooseX::Struct | Moose/Class::MOP type |
   +----------------+-----------------------+
   |             '' | [No type constraint]  |
   |              ? | [No type constraint]  |
   |            any | [No type constraint]  |
   |             ro | [Read Only - No Type] |
   |             rw | [Read/Write - No Type]|
   |              ! | Bool                  |
   |              # | Num                   |
   |              1 | Int                   |
   |              $ | Value                 |
   |             *$ | ScalarRef             |
   |              @ | ArrayRef              |
   |             *@ | ArrayRef              |
   |              % | HashRef               |
   |             *% | HashRef               |
   |              & | CodeRef               |
   |              * | GlobRef               |
   |              w | Str                   |
   |             rx | RegexpRef             |
   |            int | Int                   |
   |        integer | Int                   |
   |         number | Num                   |
   |         scalar | Value                 |
   |      scalarref | ScalarRef             |
   |          array | ArrayRef              |
   |       arrayref | ArrayRef              |
   |           hash | HashRef               |
   |        hashref | HashRef               |
   |           bool | Bool                  |
   |        boolean | Bool                  |
   |           glob | GlobRef               |
   |          regex | RegexpRef             |
   |         string | Str                   |
   +----------------+-----------------------+

=head1 Notes

=head2 strict and warnings are imported automatically

By issuing a C<use MooseX::Struct>, same as with C<use>ing Moose, strict
and warnings are automatically imported into the calling package.

=head2 Differences from Class::Struct

The accessors that are created for each attribute are simple read / write
accessors. They will attempt to assign any passed value to the attribute,
and they will return the whole value on access.

   # For an object 'foo' with an attribute 'bar' of type ArrayRef:

   $foo->bar([1,2,3]);  # sets bar to [1,2,3]

   $foo->bar;           # returns [1,2,3]

   $foo->bar(0);        # Attempts to set bar to 0 and errors out because
                        # 0 is not an array reference. Class::Struct would
                        # have given you the element at index 0;

   $foo->bar->[0]       # Correct

The types have been changed and extended. There are no '%' or '@' types that
indicate 'Hash' and 'Array,' respectively. Both of those symbols now refer
to the reference of the type.

=head1 Author

Jarrod Overson, C<< <jsoverson at googlemail.com> >>

=head1 Bugs

Of course there could be bugs with use cases I hadn't thought of 
during testing, but most of this module's work passes off to Class::MOP or Moose,
so if you find a bug, please do some testing to determine where the actual bug
is occurring.

Please report any bugs or feature requests to C<bug-moosex-struct at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Struct>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 Support

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Struct


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Struct>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Struct>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Struct>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Struct>

=back


=head1 Acknowledgements

Thanks to everyone who worked on Class::Struct for providing us a very clean interface
for creating intuitive, logical data structures within perl.

And thanks to everyone who has worked on Moose for providing a somewhat complicated
method of creating extremely powerful and extensible data structures within perl.

=head1 Copyright & License

Copyright 2008 Jarrod Overson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

