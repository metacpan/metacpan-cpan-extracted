# $Date: 2003/06/19 12:03:31 $
# $Revision: 1.5 $ 
our $VERSION = '0.02';


package Net::Z3950::AsyncZ::ErrMsg;
use Net::Z3950::AsyncZ::Errors;
use POSIX qw(:errno_h strerror );

use Exporter;
@ISA=qw (Exporter);
@EXPORT=qw(%errors isSystem isNetwork isUnspecified isZ3950);
use strict;

my $_ERROR_VAL = Net::Z3950::AsyncZ::Errors::errorval();

use vars "%errors";

# structure:  Error_Number => [ Error_Number,  retry, type ]
#             retry 1 = true, 0 = false
#	      type  0 = system, 1 = network, 2 = try again, 3 = unspecified, 4 = success
#		    5 = Z3950 error 

%errors =
 (
# syseror
	(EBUSY+0)=> [EBUSY, 1, 0],     	    	   #  Device or resource busy
	(ENODEV+0)=> [ENODEV, 0, 0],  	    	   #  No such device	
	(EUSERS+0)=> [EUSERS,1, 0],                #  Too many users
        (EACCES+0)=> [EACCES, 0, 0],               #  Permission denied
	(ECONNABORTED+0)=> [ECONNABORTED, 1, 0],   #  Software caused connection abort
        (EINTR +0)=> [EINTR, 1, 0],                # Interrupted system call
        (EINVAL +0)=> [EINVAL, 1, 0],              # Invalid argument 

# %neterr
	(ETIMEDOUT+0)=> [ETIMEDOUT, 1, 1],         #  Connection timed out
	(ECONNRESET+0)=> [ECONNRESET, 1, 1],       #  Connection reset by peer
	(EHOSTDOWN+0)=> [EHOSTDOWN,0, 1],          #  Host is down
	(EHOSTUNREACH +0)=> [EHOSTUNREACH,0, 1],   #  No route to host
	(ENETDOWN+0)=> [ENETDOWN, 0, 1],           #  Network is down
	(ENETUNREACH+0)=> [ENETUNREACH,0, 1],      #  Network is unreachable
	(ENETRESET+0)=> [ENETRESET,1, 1],          #  Network dropped connection because of reset
	(ECONNREFUSED+0)=> [ECONNREFUSED,0,1],     #  Connection refused
	(EDESTADDRREQ+0)=> [EDESTADDRREQ,0,1],     #  Destination address required
	(EADDRINUSE+0)=> [EADDRINUSE,0,1],         #  Address already in use
	(EADDRNOTAVAIL+0)=> [EADDRNOTAVAIL,0,1],   #  Cannot assign requested address
        (ESPIPE + 0)=> [ESPIPE, 0,0],		   #  Illegal seek (from failure to connect)

#try again
	(EAGAIN +0)=>[EAGAIN, 1,2],                   #  Try again
        (-1 + 0) =>  [-1, 1,2], 		      #  unprocessed fork

#  NZ3950 Error	       
        ($_ERROR_VAL+0) =>[$_ERROR_VAL, 1,5],         #  NZ3950 Error
        ($_ERROR_VAL+1) =>[$_ERROR_VAL +1, 1,5],         #  NZ3950 Error:  timeout
        ($_ERROR_VAL+2) =>[$_ERROR_VAL +2, 1,1],         #  Our timeout
        ($_ERROR_VAL+3) =>[$_ERROR_VAL +3, 1,1],         #  Alarm timeout

# Success
      (0 + 0) => [0,1,4]			     #  successful exit--no errors
);


my @Z3950_MSG = (
              "An error occurred when accessing the library database.",
	      "Failed to connect to the server.",
	      "Failed to connect to the server within time out period.",
	      "Failed to connect to the server within time out period."
);   	


# returns error message string for storing in $self->{msg}
# [1] exit without a result, error code 0, type = 4, "Timed out, try again"
# [2] error code = -1, failed connection, try again
# [3] error code >= $Net::Z3950::Errors::$_ERROR_VAL, substract $_ERROR_VAL from error code to get error 
#      see NZ3950 Error	above
# [4] None of the above, return the system error string for this error code

sub _getError {

  return   "Timed out. Try again." 
              if $_[0]->[2] == 4;
  return   "Failed to connect at this time. Try again." 
             if $_[0]->[0] == -1;
  return   $Z3950_MSG[$_[0]->[0] - $_ERROR_VAL]
             if $_[0]->[0] >= $_ERROR_VAL;                       
  return  strerror($_[0]->[0]); 
}


sub new {
  my($class, $errno) = @_;

  my $self = {
	errno => $errno,
	msg  => undef,
        type => undef,
        retry => undef,
        abort => undef 
  };  

 if (exists $errors{$errno}) {       
    $self->{type} = $errors{$errno}->[2];
    $self->{retry} = $errors{$errno}->[1];
    $self->{abort} = _abort($errno);
    $self->{msg} = _getError($errors{$errno});
 }
 else {
    $self->{msg} = "Unspecified Error";
    $self->{type} = 3;
    $self->{retry} = 0;
    $self->{abort} = _abort($errno);
 }

  bless $self, $class;
  
}

sub isSystem {
 my $self = shift;
 return defined $self->{type} && $self->{type} == 0;
}

sub isNetwork {  $_[0]->{type} == 1; }

sub isTryAgain { $_[0]->{type} == 2; }

sub isSuccess { $_[0]->{type} == 4; }

sub isUnspecified { $_[0]->{type} == 3; }

sub isZ3950 { $_[0]->{type} == 5; }

sub doRetry {  $_[0]->{retry}; }

sub doAbort {  $_[0]->{abort};  }

sub _abort { $_[0] == EINVAL; }

sub _EINVAL { return EINVAL; }


1;



=head1 NAME

Net::Z3950::AsyncZ - Perl extension for the Net::Z3950::AsyncZ module

=head1 SYNOPSIS

	use Net::Z3950::AsyncZ::ErrMsg;

	my $err = Net::Z3950::AsyncZ::ErrMsg->new($error_number});

=head1 ABSTRACT

C<Net::Z3950::AsyncZ::ErrMsg> objects are created internally by
C<Net::Z3950::AsyncZ> for keeping track of errors returned by each
forked process.

=head1 DESCRIPTION

C<Net::Z3950::AsyncZ::ErrMsg> objects are created internally by
Net::Z3950::AsyncZ for keeping track of errors returned by each
forked process. This means that there may be an an C<ErrMsg> object for
both cycle one and cycle two processes. 

The user does not create these objects. They are made available by means
of C<Net::Z3950::AsyncZ::getErrors()>, which returns a reference to an
array of two C<ErrMsg> obects, representing possible errors from cycle
one and cycle two processes. 

A detailed account of error handling will be found in the documentation
for C<Net::Z3950::AsyncZ> under the heading C<Errors>.  

=head1 Object Methods

=over 4

=item isSystem

=item sub isNetwork

=item sub isTryAgain

=item sub isSuccess

=item sub isUnspecified

=item sub isZ3950

=item sub doRetry

=item sub doAbort

=back

These methods enable the user to determine the type of error which has
been returned.  They return true or false.

	print "Network error\n" if $err->isNetwork();

See the C<Net::Z3950::AsyncZ> documentation for examples.

=head1 AUTHOR

Myron Turner
E<lt>turnermm@shaw.caE<gt>
or E<lt>mturner@ms.umanitoba.caE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Myron Turner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

