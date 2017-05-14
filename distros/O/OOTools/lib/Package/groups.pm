package Package::groups ;
$VERSION = 2.21 ;
use 5.006_001 ;
use strict ;

; use Class::groups
; our @ISA = qw| Class::groups |
   
; 1

__END__

=pod

=head1 NAME

Object::groups - Pragma to implement group of properties

=head1 VERSION 2.21

Included in OOTools 2.21 distribution.

The latest versions changes are reported in the F<Changes> file in this distribution.

The distribution includes:

=over

=item Package::props

Pragma to implement lvalue accessors with options

=item * Package::groups

Pragma to implement groups of properties accessors with options

=item * Class::constr

Pragma to implement constructor methods

=item * Class::props

Pragma to implement lvalue accessors with options

=item * Class::groups

Pragma to implement groups of properties accessors with options

=item * Class::Error

Delayed checking of object failure

=item * Class::Util

Class utility functions

=item * Object::props

Pragma to implement lvalue accessors with options

=item * Object::groups

Pragma to implement groups of properties accessors with options

=back

=head1 INSTALLATION

=over

=item Prerequisites

    Perl version >= 5.6.1

=item CPAN

    perl -MCPAN -e 'install OOTools'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 DESCRIPTION

This pragma is very similar to the C<Class::groups> pragma: the main difference is the underlying variable that holds the value, which is a global hash in the caller package instead in the class. For example:

   package BaseClass;
   use Package::groups 'a_package_group';
   use Class::groups 'a_class_group';
   
   package SubClass;
   our @ISA = 'BaseClass';
   
   # underlaying hash for accessor 'a_package_group' is
   # %BaseClass::a_package_group
   # underlaying hash for accessor 'a_class_group' is
   # %SubClass::a_class_group;

This might seem a subtle difference, but the possible usage in inherited classes makes a big difference.

While you can also call a package group accessor by statically using the implementing package name (e.g. C<BaseClass->a_group>), regardless the subclass that uses it, overridden package accessor groups don't inherit defaults as Class accessors do.

See the documentation of the accessor groups in L<Class::groups> for all the details.

=head1 SUPPORT and FEEDBACK

If you need support or if you want just to send me some feedback or request, please use this link: http://perl.4pro.net/?Object::groups.

=head1 AUTHOR and COPYRIGHT

© 2004-2005 by Domizio Demichelis.

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=head1 CREDITS

Thanks to Juerd Waalboer (http://search.cpan.org/author/JUERD) that with its I<Attribute::Property> inspired the creation of this distribution.

=cut
