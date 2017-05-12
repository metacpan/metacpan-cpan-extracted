package MooseX::Meta::Attribute::Lvalue;

our $VERSION   = '0.981';
our $AUTHORITY = 'cpan:TOBYINK';

use Moose::Role;
use MooseX::LvalueAttribute ();

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::Meta::Attribute::Lvalue - shim for backwards compatibility

=head1 SYNOPSIS

   package MyThing;
   
   use Moose;
   
   with 'MooseX::Meta::Attribute::Lvalue';
   # Instead of: use MooseX::LvalueAttribute;
   
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

This is a small Moose role that doesn't alter your class at all.
It just loads L<MooseX::LvalueAttribute> for you.

There's no reason to use this role for your classes, but it was
required by earlier versions of this software, so is retained for
backwards compatibility.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-LvalueAttribute>.

=head1 SEE ALSO

L<MooseX::LvalueAttribute>.

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

