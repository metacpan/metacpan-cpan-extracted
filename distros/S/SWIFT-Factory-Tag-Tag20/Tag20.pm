package SWIFT::Factory::Tag::Tag20;
use strict;
use warnings;

###########################################################################################################
# Provide a SWIFT TAG 20.
#
# Use this class to provide a Senders Reference.
#
###########################################################################################################

BEGIN{
   *provide=*string;
   *borken=*invalid;
}

use vars qw($VERSION);
$VERSION='0.01';

use constant REF_MAX_LEN=>16;

###########################################################################################################
sub new {
   my$self={};
   bless($self,shift())->_init(@_);
}

###########################################################################################################
# The class cannot guarantee that the TAG will be valid in the SWIFT network.
# It can point out that it's found some invalid data, though.
# Return number of problems detected.
sub invalid {
   my$self=shift;

   # Implement verifications here!
   0;
}

###########################################################################################################
sub ref_max_len {
   REF_MAX_LEN;
}

###########################################################################################################
# If a new Reference is provided, store it for future use.
# If requested, return the stored Reference to the caller.
sub reference {
   my($self,$reference)=@_;
   defined($reference)&&$self->_store_reference($reference);
   return(defined(wantarray)?wantarray?($self->{REFERENCE}):$self->{REFERENCE}:undef);
}

###########################################################################################################
sub string {
   my$self=shift;
   ':20:'.
   $self->{REFERENCE}.
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
      DO_CLEANUP=>0,
      REFERENCE=>'',
      @_);

   $self->{DO_CLEANUP}=defined($args{DO_CLEANUP})?$args{DO_CLEANUP}?1:0:0;
   $self->_store_reference($args{REFERENCE});
   $self;
}

###########################################################################################################
# If Reference is defined, store it together with some simple cleanup applied.
sub _store_reference {
   my($self,$reference)=@_;

   defined($reference)||return;

   $self->{DO_CLEANUP}&&length($reference)>REF_MAX_LEN&&do{
      # Apply conditional warnings here!
      $reference=substr($reference,0,REF_MAX_LEN);
   };

   $self->{REFERENCE}=$reference;
}

###########################################################################################################
'Choppers rule';
__END__

=head1 NAME

SWIFT::Factory::Tag::Tag20 - Provide a TAG20 for a SWIFT message.

=head1 SYNOPSIS

  use SWIFT::Factory::Tag::Tag20;
  my $tag20 = SWIFT::Factory::Tag::Tag20->new( DO_CLEANUP=>0, REFERENCE=>'SOME_REF' );

=head1 DESCRIPTION

Tag 20 is used to provide the Senders Reference in a SWIFT message.
It is up to the sending party to make sure the reference is unambigous.

=head1 CONSTRUCTOR

=over 4

=item new( DO_CLEANUP=>0, REFERENCE=>'SOME_REF' );

=back

=over 4

Instantiates a new Tag20 object.

The parameters may be given in arbitrary order.
Both parameters have built-in default values.
If the calling application doesn't provide a specific parameter at all,
the object will apply the default value to that parameter.

=item C<DO_CLEANUP=E<gt>>

Optional. Default value: I<false>

If given with a I<true> value,
the object will try to cleanup some of the parameters given.
For instance,
if C<REFERENCE=E<gt>> is too long,
the Tag20 object will truncate it.

If not given, or if given with a false value,
it is fully up to the calling application to assure that the given parameters contain reasonable values.

=item C<REFERENCE=E<gt>>

Optional.

A scalar value that can be used to uniquely identify the message at the sender side.
May not be longer than SWIFT::Factory::Tag::Tag20::REF_MAX_LEN.

If C<DO_CLEANUP=E<gt>> was given a I<true> value,
then the value given in C<REFERENCE=E<gt>> will be truncated if it is too long.

=back

=head1 PUBLIC CLASS METHODS

Class methods are always called with the fully qualified name, like:

 print SWIFT::Factory::Tag::Tag20::REF_MAX_LEN();

(The new() constructor is a typical example of a class method.)

=over 4

=item REF_MAX_LEN()

Returns the maximum length allowed for the I<Reference> in a TAG20.
See also the ref_max_len() object method.

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

=item ref_max_len()

Returns the maximum length allowed for the I<Reference> in a TAG20.
See also the REF_MAX_LEN() class method.

=item reference()

Get and/or set the Senders Reference that will be used when providing the TAG20 string.

Takes one optional parameter,
a scalar containing a new I<Senders Reference> that will be used in all subsequent method calls for this object.

If a I<Senders Reference> is provided,
it will be stored for future use.

Returns:

=over

=item If called in a scalar context,

the method will return the Senders Reference stored.

=item If called in an array context,

the method will return an array containing one single value, the Senders Reference stored.

=item If called in void context,

the method will return undef.

=back

=item string()

Will return a fully formatted string containing a TAG20 for a SWIFT message.

=item VERSION()

Will return the version of this Perl module.
(This method is inherited from the UNIVERSAL class.)

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

