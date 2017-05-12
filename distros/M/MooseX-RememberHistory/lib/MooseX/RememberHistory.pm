package MooseX::RememberHistory;
{
  $MooseX::RememberHistory::VERSION = '0.001';
}

use warnings;
use strict;

use Moose ();
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    trait_aliases => [
        [ 'MooseX::RememberHistory::Trait::Attribute' => 'RememberHistory' ],
    ],
);

package Moose::Meta::Attribute::Custom::Trait::RememberHistory;
{
  $Moose::Meta::Attribute::Custom::Trait::RememberHistory::VERSION = '0.001';
}
    
sub register_implementation { "MooseX::RememberHistory::Trait::Attribute" }

1;

__END__

=head1 NAME

MooseX::RememberHistory - Add the ability for attributes to remember their history

=head1 SYNOPSIS

 package MyClass;
 use Moose;
 use MooseX::RememberHistory;

 has 'some_attr' => (
   traits  => [ 'RememberHistory' ],
   isa     => 'Num',
   is      => 'rw', 
   default => 0
 );

 package main;

 my $obj = MyClass->new;
 $obj->some_attr(1);

 my $hist = $obj->some_attr_history; # [ 0, 1 ]

=head1 DESCRIPTION

L<MooseX::RememberHisory> provides an attribute trait (C<RememberHistory>) which will automagically store the values of that attribute in a related ArrayRef on each write to the trait.

=head1 THE HISTORY ATTRIBUTE

When the trait is applied, a history attribute is created. By default, the name of this attribute is the name of the original attribute with the extension C<_history> (e.g. an attribute named C<x> would get an additional C<x_history> attribute). 

This name may be specified manually by the use of the C<history_name> attribute option. In this case the L</SYNOPSIS> example would become:

 package MyClass;
 use Moose;
 use MooseX::RememberHistory;

 has 'some_attr' => (
   traits  => [ 'RememberHistory' ],
   history_name => 'history_of_some_attr',
   isa     => 'Num',
   is      => 'rw', 
   default => 0
 );

 package main;

 my $obj = MyClass->new;
 $obj->some_attr(1);

 my $hist = $obj->history_of_some_attr; # [ 0, 1 ]

=head1 MOTIVATION

The author wrote this module to ease the writing of object-oriented differential equation solver framework. When the objects store the history of their own evolution it eases the burden of writing the solver. The solver object only needs to evolve the constituent objects and it need not worry about storing the results; those objects can now do this themselves!

=head1 SEE ALSO

=over

=item *

L<Moose> - A postmodern object system for Perl 5

=item *

L<Moose::Manual::Attributes/"Attribute-traits-and-metaclasses">

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/MooseX-RememberHistory>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


