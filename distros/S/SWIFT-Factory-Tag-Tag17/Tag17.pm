package SWIFT::Factory::Tag::Tag17;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION='0.01';

# Three potentially (and typically) overridden class methods.
use constant TAG_ID=>'';
use constant INDICATOR_TRUE=>'Y';
use constant INDICATOR_FALSE=>'N';

BEGIN{
   *provide=*string;
}

###########################################################################################################
# Constructor. Rarely overridden.
sub new {
   my$self={};
   bless($self,shift())->_init(@_);
}

###########################################################################################################
# Object method, potentially (but rarely) overridden.
# In normal cases, a subclass would override TAG_ID, INDICATOR_FALSE and INDICATOR_TRUE to achieve
# a specialized behaviour.
sub string {
   my$self=shift;
   ':17'.
   $self->TAG_ID.
   ':'.
   $self->{INDICATOR}.
   chr(13). # CR
   chr(10); # LF
}

###########################################################################################################
###########################################################################################################
#
# 'Internal' subs. Don't call these since they may, and will, change without notice.
#
###########################################################################################################
###########################################################################################################

###########################################################################################################
sub _init {
   my$self=shift();
   my%args=(
      INDICATOR=>'',
      @_);

   $self->{INDICATOR}=(defined($args{INDICATOR})&&$args{INDICATOR}?$self->INDICATOR_TRUE:$self->INDICATOR_FALSE);
   $self;
}

###########################################################################################################
'Choppers rule';
__END__

=head1 NAME

SWIFT::Factory::Tag::Tag17 - Provides a base class for the TAG17x for a SWIFT message.

=head1 SYNOPSIS

  use SWIFT::Factory::Tag::Tag17;
  my $tag17 = SWIFT::Factory::Tag::Tag17->new();

=head1 DESCRIPTION

This class provides a a base class for the TAG17x family of classes.

The class is primarily used as a base class for other I<TAG17x> classes,
for instance TAG17T and TAG17U.

=head1 CONSTRUCTOR

=over 4

=item new( INDICATOR=>1 );

=back

=over 4

Instantiates a new Tag17 object.

It is still unclear to the author if there exists a clean TAG17 holding a boolean type of value.

If you use this class to directly instantiate a clean TAG17,
then please contact me so that I can take appropriate action.

=item C<INDICATOR=E<gt>>

Optional scalar value. Default value: I<false>

If given with any I<true> value,
the object will provide a I<Yes> or logically I<True> value in the string() method.

If omitted, or given with a I<false> value,
the object will provide a I<No> or logically I<False> value in the string() method.

=back

=head1 PUBLIC CLASS METHODS

Class methods are always called with the fully qualified name, like:

 print SWIFT::Factory::Tag::Tag17->VERSION();

(The new() constructor is a typical example of a class method.)

=over 4

=item VERSION()

Will return the version of this Perl module.
(This method is inherited from the UNIVERSAL class.)

=item TAG_ID()

This method is probably never called by an application.

The method is primarily provided to be overridden by classes
inheriting from SWIFT::Factory::Tag::Tag17,
like for instance TAG17T and TAG17U.

The TAG17 class returns nothing but a zero length string.

=item INDICATOR_TRUE()

This method is probably never called by an application.

The method is primarily provided to be overridden by classes
inheriting from SWIFT::Factory::Tag::Tag17,
like for instance TAG17T and TAG17U.

Returns a scalar value with the logically I<True> boolean value stored in the object.

=item INDICATOR_FALSE()

This method is probably never called by an application.

The method is primarily provided to be overridden by classes
inheriting from SWIFT::Factory::Tag::Tag17,
like for instance TAG17T and TAG17U.

Returns a scalar value with the logically I<False> boolean value stored in the object.

=back

=head1 PUBLIC OBJECT METHODS

=over 4

=item provide()

An alias for string(). Will execute exactly the same code as the string() method.

=item string()

Will return a fully formatted string containing a TAG17 for a SWIFT message.

=back

=head1 AUTHOR

BIKER, E<lt>biker_cpan@hotmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, BIKER. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Other Perl modules implementing SWIFT tags in the SWIFT::Factory::Tag::Tag17I<x> family.

Appropriate SWIFT documentation.

=cut

