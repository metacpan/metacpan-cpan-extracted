package SWIFT::Factory::ApplicationHeader;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION='0.02';

use constant MSG_PRIORITY_SYSTEM=>'S';
use constant MSG_PRIORITY_URGENT=>'U';
use constant MSG_PRIORITY_NORMAL=>'N';

use constant MONITORING_NON_DELIVERY=>1;
use constant MONITORING_DELIVERY_NOTIFICATION=>2;
use constant MONITORING_DELIVERY_BOTH=>3;

BEGIN{
   *provide=*string;
   *borken=*invalid;
}

###########################################################################################################
# The Application Header is block number 2 of a SWIFT message.
# This block is not required in all SWIFT messages.
#
# The block is normally built for "input", which in SWIFT
# speak means "input to the SWIFT network".
#
# This module will implement an "Input Application Header".
###########################################################################################################

###########################################################################################################
# Class private stuff.
my$io_id_input=sub{'I'};
###########################################################################################################

###########################################################################################################
# Constructor.
sub new {
   my$self={};
   bless($self,shift())->_init(@_);
}

###########################################################################################################
# The class cannot guarantee that the provided string will be valid in the SWIFT network.
# It can point out that it's found some invalid data, though.
# Return number of problems detected.
sub invalid {
   my$self=shift;

   # Implement verifications here!
   0;
}

###########################################################################################################
sub string {
   my$self=shift;

   '{2:'.
   $self->$io_id_input().
   sprintf("%03u",$self->{MSG_TYPE}).
   $self->{BIC}.
   $self->{TERMINAL}.
   $self->{BRANCH_CODE}.
   $self->{MSG_PRIORITY}.
   $self->{DELIVERY_MONITORING}.
   (defined($self->{OBSOLESCENCE_PERIOD})&&length($self->{OBSOLESCENCE_PERIOD})?sprintf("%03u",$self->{OBSOLESCENCE_PERIOD}):'').
   '}';
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
   my$self=shift;
   my%args=(
      MESSAGE_TYPE=>0,
      BIC=>'X'x8,             # Receiver BIC for SWIFT input msg.
      TERMINAL=>'X',          # Receiver Terminal for SWIFT input msg.
      BRANCH_CODE=>'X'x3,     # Receiver Branch code for SWIFT input msg.
      MESSAGE_PRIORITY=>MSG_PRIORITY_NORMAL,
      DELIVERY_MONITORING=>'',
      OBSOLESCENCE_PERIOD=>'',
      @_
   );

   $self->{MSG_TYPE}=$args{MESSAGE_TYPE};
   $self->{BIC}=$args{BIC};
   $self->{TERMINAL}=$args{TERMINAL};
   $self->{BRANCH_CODE}=$args{BRANCH_CODE};
   $self->{MSG_PRIORITY}=$args{MESSAGE_PRIORITY};
   $self->{DELIVERY_MONITORING}=$args{DELIVERY_MONITORING};
   $self->{OBSOLESCENCE_PERIOD}=$args{OBSOLESCENCE_PERIOD};

   $self;
}

###########################################################################################################
'Choppers rule';
__END__

=head1 NAME

SWIFT::Factory::ApplicationHeader - Provide an Application Header Block (Block 2) for a SWIFT message.

=head1 SYNOPSIS

  use SWIFT::Factory::ApplicationHeader;
  my $hdr2=SWIFT::Factory::ApplicationHeader->new();

=head1 DESCRIPTION

This class is primarily intended to be used by the different SWIFT::Factory::MTnnn modules to provide full SWIFT messages for input to the SWIFT network.

Nevertheless,
there is nothing prohibiting an application to directly use this class for whatever purpose.

Given reasonable parameter values in the constructor,
the string() method in this class will return an Application Header Block (Block nbr 2) that can be used in a SWIFT message sent to the SWIFT network.

=head1 CONSTRUCTOR

=over 4

=item new( MESSAGE_TYPE=>300, BIC=>'VALIDBIC', TERMINAL=>'X', BRANCH_CODE=>'XXX', MESSAGE_PRIORITY=>'N', DELIVERY_MONITORING=>1, OBSOLESCENCE_PERIOD=>'' )

=back

=over 4

The parameters may be given in arbitrary order.
Many parameters have builtin default values.
If the calling application doesn't provide the parameter at all,
the object will apply the default value.

=item C<MESSAGE_TYPE=E<gt>>

Technically optional, but it's hard to see a reason not to provide this parameter.

A numeric scalar value that indicates the message type being provided.
For an MT300 message, use the value 300.
For an MT515, use 515.
Etc.

=item C<BIC=E<gt>>

An eight character scalar value that contains a valid receiver BIC.

The receiver BIC is technically optional,
but it will probably quite rarely make sense to instantiate an object of this class without specifying a BIC.

=item C<TERMINAL=E<gt>>

Optional. A one character scalar value that identifies the receiving terminal.

Default value: 'X'.
It is I<very> unusual that the sending party would populate this entity with anything else than the default value.
It is thereby recommended that most applications don't provide this parameter at all.

=item C<BRANCH_CODE=E<gt>>

Optional. A three character scalar value that identifies the branch code at the receiver.

Default value: 'XXX'.

=item C<MESSAGE_PRIORITY=E<gt>>

Optional.
A one character scalar value indicating the requested network priority for the message.

If given, use one of the values:

 SWIFT::Factory::ApplicationHeader::MSG_PRIORITY_SYSTEM();
 SWIFT::Factory::ApplicationHeader::MSG_PRIORITY_URGENT();
 SWIFT::Factory::ApplicationHeader::MSG_PRIORITY_NORMAL();

Default value provided by the class:

 SWIFT::Factory::ApplicationHeader::MSG_PRIORITY_NORMAL();

=item C<DELIVERY_MONITORING=E<gt>>

Technically optional.
SWIFT requires this entity for urgent messages.
A one digit numeric scalar value B<or> a zero length string.

If given, use one of the values:

 SWIFT::Factory::ApplicationHeader::MONITORING_NON_DELIVERY();
 SWIFT::Factory::ApplicationHeader::MONITORING_DELIVERY_NOTIFICATION();
 SWIFT::Factory::ApplicationHeader::MONITORING_DELIVERY_BOTH();

Default value provided by the class: A zero length string which implies I<No monitoring>.

=item C<OBSOLESCENCE_PERIOD=E<gt>>

Optional. A numeric scalar value expressing the delay in units of 5 minutes.
I.e. 3 means 15 minutes and 20 means 100 minutes.

Maximum three digits long.
See the relevant SWIFT handbook for details.

Default value provided by the class: A zero length string which implies I<No obsolescence period>.

=back

=head2 Typical example of a constructor

As can be seen above,
the constructor can take a high number of parameters.
Nevertheless,
in most cases only a small subset of these parameters will be provided by the calling application.
The object will then provide reasonable default values for the missing parameters.

 use SWIFT::Factory::ApplicationHeader;

 my $h2 = SWIFT::Factory::ApplicationHeader->new(MESSAGE_TYPE=>300,
                                                 BIC=>'VALIDBIC',
                                                 DELIVERY_MONITORING=>SWIFT::Factory::ApplicationHeader->MONITORING_NON_DELIVERY);

=head1 PUBLIC CLASS METHODS

Class methods are always called with the fully qualified name, like:

 print SWIFT::Factory::ApplicationHeader::MSG_PRIORITY_SYSTEM();

(The new() constructor is a typical example of a class method.)

=over 4

=item MSG_PRIORITY_SYSTEM

Returns a valid code for a SWIFT I<System message>.
This can be used to feed the new() constructor with the code for a System message in the C<MESSAGE_TYPE=E<gt>> parameter.

=item MSG_PRIORITY_URGENT

Returns a valid code for an I<Urgent SWIFT message>.
This can be used to feed the new() constructor with the code for an Urgent message in the C<MESSAGE_TYPE=E<gt>> parameter.

=item MSG_PRIORITY_NORMAL

Returns a valid code for a I<Normal SWIFT message>.
This can be used to I<explicitly> feed the new() constructor with the code for a Normal message in the C<MESSAGE_TYPE=E<gt>> parameter,
even though this is the default value in the constructor.

=item MONITORING_NON_DELIVERY

Returns a valid code for requesting a I<Non delivery message> from the SWIFT network.

This can be used to feed the new() constructor with the code for a I<Non delivery request> in the C<DELIVERY_MONITORING=E<gt>> parameter.

=item MONITORING_DELIVERY_NOTIFICATION

Returns a valid code for requesting a I<Delivery notification message> from the SWIFT network.

This can be used to feed the new() constructor with the code for a I<Delivery notification request> in the C<DELIVERY_MONITORING=E<gt>> parameter.

=item MONITORING_DELIVERY_BOTH

Returns a valid code for requesting a B<combination> of a I<Non delivery message> and a I<Delivery notification message> from the SWIFT network.

This can be used to feed the new() constructor with the code for a I<Combined request> in the C<DELIVERY_MONITORING=E<gt>> parameter.

=back

=head1 PUBLIC OBJECT METHODS

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

As it stands, the method will always return zero, since it wasn't able to discover any error at all.

=item provide()

An alias for string(). Will execute exactly the same code as the string() method.

=item string()

Will return a fully formatted string containing an Application Header Block 2 for a SWIFT message.

=item VERSION()

Will return the version of this Perl module.
(This method is inherited from the UNIVERSAL class.)

=back

=head1 AUTHOR

BIKER, E<lt>biker_cpan@hotmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, BIKER. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Appropriate SWIFT documentation.

=cut

