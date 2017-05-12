package SWIFT::Factory::Tag::Tag30V;
use strict;
use warnings;

###########################################################################################################
# Provide a SWIFT TAG 30V.
#
# Use this class to provide a Value Date.
#
###########################################################################################################

use base qw/SWIFT::Factory::Tag::Tag30/;
use constant TAG_ID=>'V';
use constant FIGURES_IN_YEAR=>4;

use vars qw($VERSION);
$VERSION='0.01';

###########################################################################################################
'Choppers rule';
__END__

=head1 NAME

SWIFT::Factory::Tag::Tag30V - Provide a TAG30V for a SWIFT message.

=head1 SYNOPSIS

  use SWIFT::Factory::Tag::Tag30V;
  my $tag30V = SWIFT::Factory::Tag::Tag30V->new( YEAR=>2003, MONTH=>2, DAY=>17 );

=head1 DESCRIPTION

Tag 30V is used to provide the I<Value Date> in a SWIFT message.

This class is derived from SWIFT::Factory::Tag::Tag30 and the reader is strongly
encouraged to read the documentation for that class as well.

=head1 CONSTRUCTOR

=over 4

=item new( YEAR=>2003, MONTH=>2, DAY=>17 );

=back

=over 4

Instantiates a new Tag30V object.

The parameters may be given in arbitrary order.
All parameters have built-in default values.
If the calling application doesn't provide a specific parameter at all,
the object will apply the default value to that parameter.
Beware that the default values may be invalid in a SWIFT message.

=item C<YEAR=E<gt>>

Technically optional but logically required. Default value: 0 (zero).
Beware that the default value is invalid in a SWIFT message.

A numeric scalar value that will be part of the value date in TAG30V.

=item C<MONTH=E<gt>>

Technically optional but logically required. Default value: 0 (zero).
Beware that the default value is invalid in a SWIFT message.

A numeric scalar value that will be part of the value date in TAG30V.
Valid values are 1 - 12, inclusive.

=item C<DAY=E<gt>>

Technically optional but logically required. Default value: 0 (zero).
Beware that the default value is invalid in a SWIFT message.

A numeric scalar value that will be part of the value date in TAG30V.
Valid values are 1 - 31, inclusive.

=back

=head1 PUBLIC CLASS METHODS

Class methods are always called with the fully qualified name, like:

 print SWIFT::Factory::Tag::Tag30V::VERSION();

(The new() constructor is a typical example of a class method.)

=over 4

=item VERSION()

Will return the version of this Perl module.
(This method is inherited from the UNIVERSAL class.)

=item TAG_ID()

It is very unlikeley that the calling application will benefit from calling this method.
The method is providing the Tag ID which is the difference between a TAG30 and a TAG30V.
By providing this method in this class, the equivalent method in the base class is overridden
and a TAG30V is provided by string() instead of a TAG30.

=item FIGURES_IN_YEAR();

The method provides an important difference between the base class and Tag30V,
namely the number of figures allowed in the C<YEAR=E<gt>> in the constructor.

=back

=head1 PUBLIC OBJECT METHODS

=over 4

=item borken()

A really broken alias for invalid(). Will execute exactly the same code as the invalid() method.

=item invalid()

Will return the number of errors detected in the objects instance data.

The class can never be charged to B<guarrantee> that the provided string() will be fully compliant
with the SWIFT standards or SWIFT verification rules.
It can only point out known problems in the object as it is currently loaded.

B<BETA>

Please beware that the current implementation of invalid() doesn't check anything at all.
Consider it a placeholder for now.
When time permits, the method will be filled with validation code.

B<Return value:>

As it stands, the method will always return zero since it wasn't able to discover any error at all.

=item provide()

An alias for string(). Will execute exactly the same code as the string() method.

=item string()

Will return a fully formatted string containing a TAG30V for a SWIFT message.

=back

=head1 AUTHOR

Gustav Schaffter, E<lt>schaffter_cpan@hotmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, Gustav Schaffter. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Other Perl modules implementing SWIFT tags in the SWIFT::Factory::Tag::TagI<nn> family.

Appropriate SWIFT documentation.

=cut

