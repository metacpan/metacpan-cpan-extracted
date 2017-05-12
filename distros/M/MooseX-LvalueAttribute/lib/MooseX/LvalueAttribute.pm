use 5.008;
use strict;
use warnings;

package MooseX::LvalueAttribute;

our $VERSION   = '0.981';
our $AUTHORITY = 'cpan:TOBYINK';

my $implementation = 'MooseX::LvalueAttribute::Trait::Attribute';

use Exporter::Shiny qw( lvalue );
my $_cached;
sub _generate_lvalue { $_cached ||= sub () { $implementation } }

our $INLINE;
$INLINE = 1 unless defined $INLINE;

{
	package Moose::Meta::Attribute::Custom::Trait::Lvalue;
	our $VERSION   = '0.981';
	our $AUTHORITY = 'cpan:TOBYINK';
	sub register_implementation { $implementation }
}

{
	package Moose::Meta::Attribute::Custom::Trait::lvalue;
	our $VERSION   = '0.981';
	our $AUTHORITY = 'cpan:TOBYINK';
	sub register_implementation { $implementation }
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::LvalueAttribute - lvalue attributes for Moose

=head1 SYNOPSIS

   package MyThing;
   
   use Moose;
   use MooseX::LvalueAttribute;
   
   has name => (
      traits      => ['Lvalue'],
      is          => 'rw',
      isa         => 'Str',
      required    => 1,
   );
   
   has size => (
      traits      => ['Lvalue'],
      is          => 'rw',
      isa         => 'Int',
      default     => 0,
   );
   
   package main;
   
   my $thing = MyThing->new(name => 'Foo');
   
   $thing->name = "Bar";
   print $thing->name;   # Bar
   
   $thing->size++;
   print $thing->size;   # 1

=head1 DESCRIPTION

This package provides a Moose attribute trait that provides Lvalue
accessors. Which means that instead of writing:

   $thing->name("Foo");

You can use the more natural looking:

   $thing->name = "Foo";

For details of Lvalue implementation in Perl, please see: 
L<http://perldoc.perl.org/perlsub.html#Lvalue-subroutines>

Type constraints and coercions still work for lvalue attributes.
Triggers still fire. Everything should just work. (Unless it doesn't.)

You can optionally import a constants called C<< lvalue >> that
expands to the full name of the attribute trait, allowing:

   use MooseX::LvalueAttribute 'lvalue';
   
   has name => (
      traits      => [ lvalue ],
      is          => 'rw',
      isa         => 'Str',
      required    => 1,
   );

This may allow Moose to compile your attribute very, very, slightly
faster, but the main advantage is aesthetic.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-LvalueAttribute>.

=head1 SEE ALSO

L<MooX::LvalueAttribute>,
L<Object::Tiny::Lvalue>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Based on work by
Christopher Brown, C<< <cbrown at opendatagroup.com> >>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster;
2008 by Christopher Brown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

