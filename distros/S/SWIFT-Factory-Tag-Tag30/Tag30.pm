package SWIFT::Factory::Tag::Tag30;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION='0.01';

# Two potentially overridden class methods.
use constant TAG_ID=>'';
use constant FIGURES_IN_YEAR=>2;

BEGIN{
   *provide=*string;
   *borken=*invalid;
}

###########################################################################################################
# Class method, potentially overridden.
sub new {
   my$self={};
   bless($self,shift())->_init(@_);
}

###########################################################################################################
# Object method, potentially overridden.
# The class cannot guarantee that the TAG will be valid in the SWIFT network.
# It can point out that it's found some invalid data, though.
# Return number of problems detected.
sub invalid {
   my$self=shift;

   # Implement verifications here!
   0;
}

###########################################################################################################
# Object method, potentially overridden.
sub string {
   my$self=shift;
   ':30'.
   $self->TAG_ID.
   ':'.
   sprintf("%0".$self->FIGURES_IN_YEAR."u",$self->{YEAR}).
   sprintf("%02u",$self->{MONTH}).
   sprintf("%02u",$self->{DAY}).
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
# Object method, potentially overridden.
sub _init {
   my$self=shift();
   my%args=(
      YEAR=>0,
      MONTH=>0,
      DAY=>0,
      DO_CLEANUP=>0,
      @_);

   $self->{YEAR}=($args{DO_CLEANUP}?
                  (length($args{YEAR})>$self->FIGURES_IN_YEAR?
                     substr($args{YEAR},
                            length($args{YEAR})-$self->FIGURES_IN_YEAR,
                            $self->FIGURES_IN_YEAR):
                     $args{YEAR}):
                     $args{YEAR});
   $self->{MONTH}=$args{MONTH};
   $self->{DAY}=$args{DAY};
   $self;
}

###########################################################################################################
'Choppers rule';
__END__

=head1 NAME

SWIFT::Factory::Tag::Tag30 - Provides a TAG30 for a SWIFT message

=head1 SYNOPSIS

  use SWIFT::Factory::Tag::Tag30;
  my $tag30 = SWIFT::Factory::Tag::Tag30->new();

=head1 DESCRIPTION

This class provides a TAG30 for SWIFT messages.
TAG30 is used for

The class is also used as a base class for other I<TAGnn> classes,
for instance TAG30T and TAG30V.

=head1 CONSTRUCTOR

=over 4

=item new( DO_CLEANUP=>1, YEAR=>3, MONTH=>2, DAY=>23 );

=back

=over 4

Instantiates a new Tag30 object.

The parameters may be given in arbitrary order.
All parameters have built-in default values.
If the calling application doesn't provide a specific parameter at all,
the object will apply the default value to that parameter.

Note that the default values may be invalid in a SWIFT message.

=item C<DO_CLEANUP=E<gt>>

Optional scalar value. Default value: I<false>

If given with a I<true> value,
the object will try to cleanup some of the parameters given.
For instance,
if the value given in C<YEAR=E<gt>> is too long,
the Tag30 object will truncate it to the length returned by
SWIFT::Factory::Tag::Tag30->FIGURES_IN_YEAR().

If not given, or if given with a false value,
it is fully up to the calling application to assure that the given parameters contain reasonable values.

=item C<YEAR=E<gt>>

Technically optional but logically required.
A numeric scalar value that will be part of the date in TAG30.

Default value: 0 (zero).
Beware that the default value is B<valid> in a SWIFT message,
but may not be what you want to send to the receiver.

If C<DO_CLEANUP=E<gt>> was given a I<true> value,
then the value given in C<YEAR=E<gt>> will be truncated if it is longer than what is returned by
SWIFT::Factory::Tag::Tag30->FIGURES_IN_YEAR().

Any truncation of the Year happens to the 'left'.
When provided by the string() and provide() methods,
the Year will always be formatted to the length of
SWIFT::Factory::Tag::Tag30->FIGURES_IN_YEAR().

Be aware that other classes derives from this class.
In those instances, SWIFT::Factory::Tag::Tag30->FIGURES_IN_YEAR() will potentially return a different value
than what is returned from this class.

=item C<MONTH=E<gt>>

Technically optional but logically required. Default value: 0 (zero).
Beware that the default value is invalid in a SWIFT message.

A numeric scalar value that will be part of the value date in TAG30.
Valid values are 1 - 12, inclusive.

=item C<DAY=E<gt>>

Technically optional but logically required. Default value: 0 (zero).
Beware that the default value is invalid in a SWIFT message.

A numeric scalar value that will be part of the value date in TAG30T.
Valid values are 1 - 31, inclusive.

=back

=head1 PUBLIC CLASS METHODS

Class methods are always called with the fully qualified name, like:

 print SWIFT::Factory::Tag::Tag30->VERSION();

(The new() constructor is a typical example of a class method.)

=over 4

=item VERSION()

Will return the version of this Perl module.
(This method is inherited from the UNIVERSAL class.)

=item TAG_ID()

This method is probably never called by an application.

The method is primarily provided to be overridden by classes
inheriting from SWIFT::Factory::Tag::Tag30,
like for instance TAG30T and TAG30V.

The TAG30 class returns nothing but a zero length string.

=item FIGURES_IN_YEAR()

Returns a numeric scalar value indicating how many figures will be used when formatting the
I<Year> in the I<date> provided by this class.

The application should preferrably never provide a C<YEAR=E<gt>> value containing more figures than
the value returned by this method.

The provide() and string() methods will always format the I<Year> of the I<Date> to this many figures.

This method will typically be overridden by any class inheriting from this class,
for instance the Tag30T and Tag30V classes.

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

Will return a fully formatted string containing a TAG30 for a SWIFT message.

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

