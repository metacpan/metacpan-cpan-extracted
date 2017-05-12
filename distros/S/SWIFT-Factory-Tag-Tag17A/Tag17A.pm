package SWIFT::Factory::Tag::Tag17A;
use strict;
use warnings;

use base qw/SWIFT::Factory::Tag::Tag17/;

use vars qw($VERSION);
$VERSION='0.01';

# Override these class methods from the SUPER class.
use constant TAG_ID=>'A';

###########################################################################################################
'Choppers rule';
__END__

=head1 NAME

SWIFT::Factory::Tag::Tag17A - Provides the TAG17A for a SWIFT message.

=head1 SYNOPSIS

  use SWIFT::Factory::Tag::Tag17A;
  my $tag17A = SWIFT::Factory::Tag::Tag17A->new();

=head1 DESCRIPTION

TAG17A is used as a I<Buy (Sell) Indicator>.

If the payload data in TAG17A holds a I<true> value,
then this is a I<Buy> transaction.

If the payload data in TAG17A holds a I<false> value,
then this is a I<Sell> transaction.

=head1 CONSTRUCTOR

=over 4

=item new( INDICATOR=>1 );

=back

=over 4

Instantiates a new Tag17A object.

=item C<INDICATOR=E<gt>>

Optional scalar value. Default value: I<false>

If given with any I<true> value,
the object will provide a I<Yes> or logically I<True> value in the string() method.

If omitted, or given with a I<false> value,
the object will provide a I<No> or logically I<False> value in the string() method.

=back

=head1 PUBLIC CLASS METHODS

Class methods are always called with the fully qualified name, like:

 print SWIFT::Factory::Tag::Tag17A->VERSION();

(The new() constructor is a typical example of a class method.)

=over 4

=item VERSION()

Will return the version of this Perl module.
(This method is inherited from the UNIVERSAL class.)

=item TAG_ID()

This method is probably never called by an application.

The method overrides the class method with the same name in the SWIFT::Factory::Tag::Tag17
class and gives the unique identifier for the Tag17A class.

=item INDICATOR_TRUE()

This method is probably never called by an application.

The method is inherited from the class method with the same name in the SWIFT::Factory::Tag::Tag17
class and returns a scalar value with the logically I<True> boolean value stored in the object.

=item INDICATOR_FALSE()

This method is probably never called by an application.

The method is inherited from the class method with the same name in the SWIFT::Factory::Tag::Tag17
class and returns a scalar value with the logically I<False> boolean value stored in the object.

=back

=head1 PUBLIC OBJECT METHODS

=over 4

=item provide()

An alias for string(). Will execute exactly the same code as the string() method.

=item string()

Will return a fully formatted string containing a TAG17A for a SWIFT message.

=back

=head1 AUTHOR

BIKER, E<lt>biker_cpan@hotmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, BIKER. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

The SWIFT::Factory::Tag::Tag17 class.

Other Perl modules implementing SWIFT tags in the SWIFT::Factory::Tag::Tag17I<x> family.

Appropriate SWIFT documentation.

=cut

