package Net::EMI::Common;
use strict;

use vars qw($VERSION);
$VERSION='1.01';

###########################################################################################################
# Since 'constants' are actually implemented as subs,
# they can be called from the outside as any other class method.
use constant STX=>chr(2);
use constant ETX=>chr(3);
use constant UCP_DELIMITER=>'/';
use constant DEF_SMSC_PORT=>3024;
use constant ACK=>'A';
use constant NACK=>'N';

###########################################################################################################
sub new {
   my$self={};
   bless($self,shift())->_init(@_);
}

###########################################################################################################
# Calculate packet checksum
sub checksum {
   shift;         # Ignore $self.
   defined($_[0])||return(0);

   my$checksum=0;
   for(split(//,shift)) {
      $checksum+=ord;
   }
   # 2003-Apr-24 Rainer Thieringer: format string corrected from %X to %02X.
   sprintf("%02X",$checksum%256);
}

###########################################################################################################
# Calculate data length
sub data_len {
	my$len=length(pop @_)+17;
	for(1..(5-length($len))) {
		$len='0'.$len;
	}
	$len;
}

###########################################################################################################
# The first 'octet' in the string returned will contain the length of the remaining user data.
sub encode_7bit {
   my($self,$msg)=@_;
   my($bit_string,$user_data)=('','');
   my($octet,$rest);

   defined($msg)&&length($msg)||return('00');   # Zero length user data.

   for(split(//,$msg)) {
      $bit_string.=unpack('b7',$_);
   }

   #print("Bitstring:$bit_string\n");

   while(defined($bit_string)&&(length($bit_string))) {
      $rest=$octet=substr($bit_string,0,8);
      $user_data.=unpack("H2",pack("b8",substr($octet.'0'x7,0,8)));
      $bit_string=(length($bit_string)>8)?substr($bit_string,8):'';
   }

   sprintf("%02X",length($rest)<5?length($user_data)-1:length($user_data)).uc($user_data);
}

###########################################################################################################
sub ia5_decode {
   my($self,$message)=@_;
   my($decoded,$i);

   defined($message)&&length($message)||return('');

	for($i=0;$i<=length($message);$i+=2) {
		$decoded.=chr(hex(substr($message,$i,2)));
	}
	$decoded;
}

###########################################################################################################
sub ia5_encode {
	join('',map{sprintf "%X",ord} split(//,pop(@_)));
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
   shift;
}

###########################################################################################################
'Choppers rule';
__END__

=head1 NAME

Net::EMI::Common - EMI/UCP GSM SMSC Protocol Common library class

=head1 SYNOPSIS

C<use Net::EMI::Common>

C<$emi = Net::EMI::Common-E<gt>new();>

=head1 DESCRIPTION

This module implements a collection of common routines used in the Net::EMI set of classes.

The Net::EMI::Common class is primarily intended to part some functionality between
the Net::EMI::Client class and any future Net::EMI::Server classes.

Even so, there is nothing to stop any application or other module to make use of the
common routines found in this class.

(If someone makes use of this module to support another public module I'd like to hear about it.
That way I may be able to maintain backwards compatibility for those modules.)

=head1 CONSTRUCTOR

=over 4

=item new()

No parameters are currently honored.

=back

=head1 PUBLIC OBJECT METHODS

=over 4

=item checksum('Some string')

Calcuate packet checksum.

=item data_len('Some string')

Calculate data length.

=item encode_7bit('Some string')

=item ia5_decode('Some string')

=item ia5_encode('Some string')

=back

=head1 SEE ALSO

L<Net::EMI::Client>

=head1 ACKNOWLEDGMENTS

I'd like to thank Jochen Schneider for writing the first beta releases under the name Net::EMI
and also for letting me in on the project.

In February 2003, Jochen gave me free hands to distribute this class module
which is primarily built upon his work.
Without Jochens initial releases, this module would probably not have seen the light.

Thanks, Rainer Thieringer, for pointing out a bug in the checksum() method.

And, as everyone else I owe so much to Larry.
For having provided Perl.

=head1 AUTHOR

Gustav Schaffter, E<lt>schaffter_cpan@hotmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2002 Jochen Schneider.
Copyright (c) 2003 Gustav Schaffter.
All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

