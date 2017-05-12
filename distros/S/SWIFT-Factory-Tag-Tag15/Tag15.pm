package SWIFT::Factory::Tag::Tag15;
use strict;
use warnings;

###########################################################################################################
# Provide a SWIFT TAG 15a.
#
# Use this class to provide all different tags 15A, 15B .. 15Z.
#
###########################################################################################################

BEGIN{
   *provide=*string;
   *borken=*invalid;
}

use vars qw($VERSION);
$VERSION='0.02';

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
# If a new Sequence ID is provided, store it for future use.
# If requested, return the stored Sequence ID to the caller.
sub sequence_id {
   my($self,$seq_id)=@_;
   defined($seq_id)&&$self->_store_seq_id($seq_id);
   return(defined(wantarray)?wantarray?($self->{SEQUENCE_ID}):$self->{SEQUENCE_ID}:undef);
}

###########################################################################################################
sub string {
   my$self=shift;
   ':15'.
   $self->{SEQUENCE_ID}.
   ':'.
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
      SEQUENCE_ID=>'',
      @_);

   $self->{DO_CLEANUP}=defined($args{DO_CLEANUP})?$args{DO_CLEANUP}?1:0:0;
   $self->_store_seq_id($args{SEQUENCE_ID});
   $self;
}

###########################################################################################################
# If Sequence ID is defined, store it together with some simple cleanup applied.
sub _store_seq_id {
   my($self,$seq_id)=@_;

   defined($seq_id)||return;

   $self->{DO_CLEANUP}&&length($seq_id)>1&&do{
      # Apply conditional warnings here!
      $seq_id=substr($seq_id,0,1);
   };

   $self->{DO_CLEANUP}&&do{
      # Apply warnings here too.
      $seq_id=uc($seq_id);
   };

   $self->{SEQUENCE_ID}=$seq_id;
}

###########################################################################################################
'Choppers rule';
__END__

=head1 NAME

SWIFT::Factory::Tag::Tag15 - Provide a generic TAG15 for a SWIFT message.

=head1 SYNOPSIS

  use SWIFT::Factory::Tag::Tag15;
  my $tag15 = SWIFT::Factory::Tag::Tag15->new( DO_CLEANUP=>1, SEQUENCE_ID=>'A' );

=head1 DESCRIPTION

Tag 15 is used to start different sub-sequences in many SWIFT messages.

This class is generic in the sence that it can be used to provide TAG15A, TAG15B .. TAG15Z,
all depending upon the C<SEQUENCE_ID> given in either the constructor or in the C<sequence_id()> method.

If the SWIFT message that is going to be built contains more than one TAG15,
it is probably wise to instantiate more than one object of the SWIFT::Factory::Tag::Tag15 class.

Like this:

  use SWIFT::Factory::Tag::Tag15;
  my $tag15A = SWIFT::Factory::Tag::Tag15->new( SEQUENCE_ID=>'A' );
  my $tag15B = SWIFT::Factory::Tag::Tag15->new( SEQUENCE_ID=>'B' );

Or like this:

  use SWIFT::Factory::Tag::Tag15;
  my $tag15A = SWIFT::Factory::Tag::Tag15->new();
  my $tag15B = SWIFT::Factory::Tag::Tag15->new();

  $tag15A->secuence_id('A');
  $tag15B->secuence_id('B');

=head1 CONSTRUCTOR

=over 4

=item SWIFT::Factory::Tag::Tag15->new( DO_CLEANUP=>0, SEQUENCE_ID=>'A' );

=back

=over 4

Instantiates a new Tag15 object.

The parameters may be given in arbitrary order.
Both parameters have built-in default values.
If the calling application doesn't provide a specific parameter at all,
the object will apply the default value to that parameter.

=item C<DO_CLEANUP=E<gt>>

Optional. Default value: I<false>

If given with any true value,
the object will try to cleanup some of the parameters given.
For instance,
if C<SEQUENCE_ID=E<gt>> is given in lower-case,
the Tag15 object will convert it to upper-case.

If not given, or if given with a false value,
it is fully up to the calling application to assure that the given parameters contain reasonable values.

=item C<SEQUENCE_ID=E<gt>>

Optional.

A one character value that will be appended to the TAG.
If C<SEQUENCE_ID=E<gt>> contains the letter 'A',
then a TAG15A will be provided.
If C<SEQUENCE_ID=E<gt>> contains the letter 'B',
then a TAG15B will be provided.
Etc.

If C<DO_CLEANUP=E<gt>> was given a I<true> value,
then the character given in C<SEQUENCE_ID=E<gt>> will always be converted to upper-case,
as well as the object will only honor the first character in C<SEQUENCE_ID=E<gt>>.

If C<DO_CLEANUP=E<gt>> holds a I<false> value (the default),
then whatever value given in C<SEQUENCE_ID=E<gt>> will be used without any questions asked.

=back

=head1 PUBLIC METHODS

=over 4

=item borken()

A really broken alias for invalid(). Will execute exactly the same code as the invalid() method.

=item invalid()

Will return the number of errors detected in the objects instance data.

The class can never be charged to B<guarrantee> that the provided string() will be fully compliant
with the SWIFT standards or SWIFT verification rules.
It can only point out known problems in the object as it is curently loaded.

B<BETA>

Please beware that the current implementation of invalid() doesn't check anything at all.
Consider it a placeholder for now.
When time permits, the method will be filled with validation code.

B<Return value:>

As it stands, the method will always return zero since it wasn't able to discover any error at all.

=item provide()

An alias for string(). Will execute exactly the same code as the string() method.

=item sequence_id()

Get and/or set the Sequence ID that will be used when providing the TAG15x string.

Takes one optional scalar parameter,
a one character Sequence ID that will be used in all subsequent method calls for this object.

If a Sequence ID is provided,
it will be stored for future use.

B<Return value:>

 If called in a scalar context, the method will return the Sequence ID stored.
 If called in an array context, the method will return an array containing one single value, the Sequence ID stored.
 If called in void context, the method will return undef.

=item string()

Will return a fully formatted string containing a TAG15x for a SWIFT message.

=item VERSION()

Will return the version of this Perl module.
(This method is inherited from the UNIVERSAL class.)

=back

=head1 EXAMPLE

 my $tag15C = SWIFT::Factory::Tag::Tag15->new(DO_CLEANUP=>1);

 $tag15C->sequence_id('A');               # Note, we're giving an 'A' to the TAG15C.

 print('TAG15 has Sequence ID: '.
       $tag15C->sequence_id().
       "\n");

 # Prints: TAG15 has Sequence ID: A

 print('TAG15 has Sequence ID: '.
       $tag15C->sequence_id('ceasar').    # Aiming for 'C'. DO_CLEANUP will come into play.
       "\n");

 # Prints: TAG15 has Sequence ID: C

 if( $tag15C->invalid() ) {
    die("Invalid data in TAG15C");
 }
 else {
    print($tag15C->provide());
 }

 # Prints: :15C:  (Plus a trailing CR-LF, which is the only payload data in a TAG15x tag.

=head1 AUTHOR

BIKER, E<lt>biker_cpan@hotmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, BIKER. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Other Perl modules implementing SWIFT tags in the SWIFT::Factory::Tag::TagI<nn> family.

Appropriate SWIFT documentation.

=cut

