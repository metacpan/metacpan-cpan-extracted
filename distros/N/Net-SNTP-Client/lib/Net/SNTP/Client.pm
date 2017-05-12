package Net::SNTP::Client;

## Validate the version of Perl

BEGIN { die 'Perl version 5.6.0 or greater is required' if ($] < 5.006); }

use strict;
use warnings FATAL => 'all';

=head1 NAME

Net::SNTP::Client - Perl module to calculate the roundtrip delay d and
 system clock offset t from NTP or SNTP Server.


=head1 VERSION

Version 0.22


=cut

## Version of the Net::SNTP::Client module

our $VERSION = '0.22';
$VERSION = eval $VERSION;


## Load our modules

use IO::Socket::INET;
use Time::HiRes qw( gettimeofday );


## Handle importing/exporting of symbols

use base qw( Exporter );
our @EXPORT_OK  = qw ( getSNTPTime );


=head1 SYNOPSIS

The Net::SNTP::Client - Perl module retrieves the time from an NTP or
 SNTP server and uses the local time to calculate the roundtrip delay
 d and system clock offset t based on RFC4330. The module is calculating
 with higher accuracy in comparison to other modules.

    use Net::SNTP::Client qw ( getSNTPTime );

    my ( $error , $hashRefOutput ) = getSNTPTime( %hashInput );
    ...


=head1 ABSTRACT

The module sends a UDP packet formated according to
 L<RFC4330|https://tools.ietf.org/html/rfc4330> to a defined NTP
 or SNTP server set by the user. The received packet, gets decoded
 to a human readable form and also calculated the roundtrip delay
 d and system clock offset t, based on the decoded data.


=head1 DESCRIPTION

This module exports a single method (getSNTPTime) and returns
 an associative hash of hashes upon RFC4330 and a string in
 case of an error occurs. The response from the NTP or SNTP server
 is beeen decoded to a human readable format. The obtained
 information recieved from the server can be can be used into
 further processing or manipulation according to the user needs.
 Maximum accuracy down to nano seconds can only be achieved on LinuxOS.


=over 4

=item * HOSTNAME

    -hostname: The mandatory key inorder the method to produce
    an output is only the hostname, the rest of the keys are optional.


=item * PORT

    -port: By default the the port is set to 123 (NTP default port).
    The user has the option to overwite the port based on the expected
    NTP port on the server side (e.g. -port => 123456).


=item * TIMEOUT

    -timeOut: By default the time out is set to 10 seconds. The user
    has the option to overwite the time out input option based on the
    expected connection time (e.g. timeOut => 15).


=item * RFC4330 OUTPUT

    -RFC4330: This is an optional way to produce an easy visual
    output based on RFC4330 documentation. Expected input is a string,
    integer or boolean in the form (0 or 1).


=item * CLEARSCREEN

    -clearScreen: This is an optional choice based on user preference
    if he/she desires to clear the "terminal screen" before printing
    the captured data. Expected input is a string, integer or boolean
    in the form (0 or 1).


=back

=head1 SUBROUTINES/METHODS

  my ( $error , $hashRefOutput ) = getSNTPTime( %hashInput );


=cut

## Define constands

# The_version_of_constant provided by perl 5.6.1 does not support that.
# use constant {
#     TRUE             => 1,
#     FALSE            => 0,
#     TIMEOUT          => 10,
#     MAXBYTES         => 512,
#     UNIX_EPOCH       => 2208988800,
#     MIN_UDP_PORT     => 1,
#     MAX_UDP_PORT     => 65536,
#     DEFAULT_NTP_PORT => 123,
# };


use constant TRUE             => 1;
use constant FALSE            => 0;
use constant TIMEOUT          => 10;
use constant MAXBYTES         => 512;
use constant UNIX_EPOCH       => 2208988800;
use constant MIN_UDP_PORT     => 1;
use constant MAX_UDP_PORT     => 65536;
use constant DEFAULT_NTP_PORT => 123;

=head2 getSNTPTime

  my %hashInput = (
      -hostname      => $hostname,    # hostnmae or IP
      -port          => $port,        # default NTP port 123
      -timeOut       => $timeOut,     # default 10
      -RFC4330       => $RFC4330,     # default 0
      -clearScreen   => $clearScreen, # default 0
      );

  my ( $error , $hashRefOutput ) = getSNTPTime( %hashInput );

This module exports a single method - getSNTPTime and an error
 string in case of an error or a faulty operation. It expects a
 hash as an input. The input can have four different hash
 keys (-hostname, port, RFC4330 and -clearScreen).


=cut

sub getSNTPTime {
    my $error = undef;
    my %moduleInput = @_;

    return ($error = "Not defined key(s)", \%moduleInput)
	if (_checkHashKeys(%moduleInput));
    return ($error = "Not defined Hostname/IP", \%moduleInput)
	if (!$moduleInput{-hostname});
    return ($error = "Not correct port number", \%moduleInput)
	if (_verifyPort($moduleInput{-port}));
    return ($error = "Not correct timeOut input", \%moduleInput)
	if (_verifyNumericInput($moduleInput{-timeOut}));
    return ($error = "Not correct RFC4330 input", \%moduleInput)
	if (_verifyBoolean($moduleInput{-RFC4330}));
    return ($error = "Not correct clearScreen input", \%moduleInput)
	if (_verifyBoolean($moduleInput{-clearScreen}));

    my $client_socket;
    eval {
	$client_socket = new IO::Socket::INET (
	    PeerHost => $moduleInput{-hostname},
	    Type     => SOCK_DGRAM,
	    PeerPort => $moduleInput{-port} || DEFAULT_NTP_PORT, # Default 123
	    Proto    => 'udp'
	    ) or die "Error Creating Socket";
    };
    return ($error = "Problem While Creating Socket '$!'", \%moduleInput)
	if ( $@ && $@ =~ /Error Creating Socket/ );

    my %SNTP_Client_Hash = (
	"LI"                            => 0,
	"VN"                            => 4,
	"Mode"                          => 3,
	"Stratum"                       => 0,
	"Poll"                          => 0,
	"Precision"                     => 0,
	"Root Delay"                    => 0,
	"Root Dispersion"               => 0,
	"Reference Identifier"          => 0,
	"Reference Timestamp"           => "0.0",
	"Originate Timestamp"           => "0.0",
	"Receive Timestamp Sec"         => 0,
	"Receive Timestamp Micro Sec"   => 0,
	"Transmit Timestamp Sec"        => 0,
	"Transmit Timestamp Micro Sec"  => 0,
	);

    my @SNTP_Receive = ( "LI VN Mode",
			 "Stratum",
			 "Poll",
			 "Precision",
			 "Root Delay",
			 "Root Delay Fraction",
			 "Root Dispersion",
			 "Root Dispersion Fraction",
			 "Reference Identifier",
			 "Reference Timestamp Sec",
			 "Reference Timestamp Micro Sec",
			 "Originate Timestamp Sec",
			 "Originate Timestamp Micro Sec",
			 "Receive Timestamp Sec",
			 "Receive Timestamp Micro Sec",
			 "Transmit Timestamp Sec",
			 "Transmit Timestamp Micro Sec" );

    ( $SNTP_Client_Hash{"Transmit Timestamp Sec"} ,
      $SNTP_Client_Hash{"Transmit Timestamp Micro Sec"} ) = gettimeofday();

    my $sendSntpPacket = pack( "B8 C3 N11",
			       '00100011',
			       (0) x 12,
			       $SNTP_Client_Hash{"Transmit Timestamp Sec"},
			       $SNTP_Client_Hash{"Transmit Timestamp Micro Sec"} );

    eval {
	$client_socket->send( $sendSntpPacket )
	    or die "Error Sending";
    };
    return ($error = "Problem While Sending '$!'", \%moduleInput)
	if ( $@ && $@ =~ /Error Sending/ );

    $moduleInput{-timeOut} = TIMEOUT if ( !defined $moduleInput{-timeOut});
    my $rcvSntpPacket = undef;
    eval {
	local $SIG{ALRM} = sub { die "Error Timeout"; };
	alarm($moduleInput{-timeOut});
	$client_socket->recv( $rcvSntpPacket , MAXBYTES )
	    or die "Error Receiving";
	alarm(0)
    };

    if ( $@ && $@ =~ /Error Receiving/ ){
	return ($error = "Problem While Receiving '$!'", \%moduleInput);

    }
    elsif ($@ && $@ =~ /Error Timeout/) {
	return ($error = "Net::SNTP::Client timed out waiting the packet '$!'", \%moduleInput);
    }

    ( $SNTP_Client_Hash{"Receive Timestamp Sec"} ,
      $SNTP_Client_Hash{"Receive Timestamp Micro Sec"} ) = gettimeofday();

    eval {
	$client_socket->close()
	    or die "Error Closing Socket";
    };
    return ($error = "Problem While Clossing Socket '$!'", \%moduleInput)
	if ( $@ && $@ =~ /Error Closing Socket/ );

    my %RcV;
    @RcV{@SNTP_Receive} = unpack("B8 C3 s n3 H8 N8" , $rcvSntpPacket);

    $RcV{"LI Binary"} = substr( $RcV{"LI VN Mode"} , 0 , 2 );
    $RcV{"LI"} = _binaryToDecimal( $RcV{"LI Binary"} , 8 , "c" );
    delete $RcV{"LI Binary"};

    $RcV{"VN Binary"} = substr( $RcV{"LI VN Mode"} , 2 , 3 );
    $RcV{"VN"} = _binaryToDecimal( $RcV{"VN Binary"} , 8 , "c" );
    delete $RcV{"VN Binary"};

    $RcV{"Mode Binary"} = substr( $RcV{"LI VN Mode"} , 5 , 3 );
    $RcV{"Mode"} = _binaryToDecimal( $RcV{"Mode Binary"} , 8 , "c" );
    delete $RcV{"Mode Binary"};
    delete $RcV{"LI VN Mode"};

    $RcV{"Poll"} = (sprintf("%.1d", $RcV{"Poll"}));

    if ($RcV{"Precision"} > 127) {
	$RcV{"Precision"} = $RcV{"Precision"} - 255;
    }
    else {
	$RcV{"Precision"} = "-" . $RcV{"Precision"};
    }

    $RcV{"Root Delay Fraction"} =
	sprintf("%05d", $RcV{"Root Delay Fraction"});

    $RcV{"Root Delay"} =
	$RcV{"Root Delay"} . "." . $RcV{"Root Delay Fraction"};

    $RcV{"Root Dispersion Fraction"} =
	sprintf("%05d", $RcV{"Root Dispersion Fraction"});

    $RcV{"Root Dispersion"} =
	$RcV{"Root Dispersion"} . "." . $RcV{"Root Dispersion Fraction"};

    $RcV{"Reference Identifier"} =
	_unpackIP($RcV{"Stratum"},$RcV{"Reference Identifier"});

    $RcV{"Reference Timestamp Sec"} -= UNIX_EPOCH;
    $RcV{"Receive Timestamp Sec"} -= UNIX_EPOCH;
    $RcV{"Transmit Timestamp Sec"} -= UNIX_EPOCH;

    my $d = (
	(
	 ( $SNTP_Client_Hash{"Receive Timestamp Sec"} . "." . $SNTP_Client_Hash{"Receive Timestamp Micro Sec"} ) - 
	 ( $SNTP_Client_Hash{"Transmit Timestamp Sec"} . "." . $SNTP_Client_Hash{"Transmit Timestamp Micro Sec"} ) 
	) -
	(
	 ( $RcV{"Transmit Timestamp Sec"} . "." . $RcV{"Transmit Timestamp Micro Sec"} ) -
	 ( $RcV{"Receive Timestamp Sec"} . "." . $RcV{"Receive Timestamp Micro Sec"} )
	)
	);

    my $t = (
	(
	 (
	  ( $RcV{"Receive Timestamp Sec"} . "." . $RcV{"Receive Timestamp Micro Sec"} ) -
	  ( $SNTP_Client_Hash{"Transmit Timestamp Sec"} . "." . $SNTP_Client_Hash{"Transmit Timestamp Micro Sec"} ) 
	 ) +
	 (
	  ( $RcV{"Transmit Timestamp Sec"} . "." . $RcV{"Transmit Timestamp Micro Sec"} ) -
	  ( $SNTP_Client_Hash{"Receive Timestamp Sec"} . "." . $SNTP_Client_Hash{"Receive Timestamp Micro Sec"} )
	 )
	) / 2
	);

    (system $^O eq 'MSWin32' ? 'cls' : 'clear') if ($moduleInput{-clearScreen});

    my %moduleOutput = ();

    if ( $moduleInput{-RFC4330} ) {
	$moduleOutput{-RFC4330} = "
\t Timestamp Name \t ID \t When Generated
\t ------------------------------------------------------------
\t Originate Timestamp \t T1 \t time request sent by client
\t Receive Timestamp \t T2 \t time request received by server
\t Transmit Timestamp \t T3 \t time reply sent by server
\t Destination Timestamp \t T4 \t time reply received by client

\t The roundtrip delay d and local clock offset t are defined as

\t d = (T4 - T1) - (T2 - T3) \t t = ((T2 - T1) + (T3 - T4)) / 2 \n

\t Round Trip delay: ".$d."\n
\t Clock offset: ".$t."\n

\t Field Name \t\t\t Unicast/Anycast
\t\t\t\t Request \t\t Reply
\t ------------------------------------------------------------
\t LI \t\t\t ".$SNTP_Client_Hash{"LI"}." \t\t\t ".$RcV{"LI"}."
\t VN \t\t\t ".$SNTP_Client_Hash{"VN"}." \t\t\t ".$RcV{"VN"}."
\t Mode \t\t\t ".$SNTP_Client_Hash{"Mode"}." \t\t\t ".$RcV{"Mode"}."
\t Stratum \t\t ".$SNTP_Client_Hash{"Stratum"}." \t\t\t ".$RcV{"Stratum"}."
\t Poll \t\t\t ".$SNTP_Client_Hash{"Poll"}." \t\t\t ".$RcV{"Poll"}."
\t Precision \t\t ".$SNTP_Client_Hash{"Precision"}." \t\t\t ".$RcV{"Precision"}."
\t Root Delay \t\t ".$SNTP_Client_Hash{"Root Delay"}." \t\t\t ".$RcV{"Root Delay"}."
\t Root Dispersion \t ".$SNTP_Client_Hash{"Root Dispersion"}." \t\t\t ".$RcV{"Root Dispersion"}."
\t Reference Identifier \t ".$SNTP_Client_Hash{"Reference Identifier"}." \t\t\t ".$RcV{"Reference Identifier"}."
\t Reference Timestamp \t ".$SNTP_Client_Hash{"Reference Timestamp"}." \t\t\t ".
	    $RcV{"Reference Timestamp Sec"}.".".
	    $RcV{"Reference Timestamp Micro Sec"}."
\t Originate Timestamp \t ".$SNTP_Client_Hash{"Originate Timestamp"}." \t\t\t ".
	    $RcV{"Originate Timestamp Sec"}.".".
	    $RcV{"Originate Timestamp Micro Sec"}."
\t Receive Timestamp \t ".
	    $SNTP_Client_Hash{"Receive Timestamp Sec"}.".".$SNTP_Client_Hash{"Receive Timestamp Micro Sec"}." \t ".
	    $RcV{"Receive Timestamp Sec"} . ".".
	    $RcV{"Receive Timestamp Micro Sec"}."
\t Transmit Timestamp \t ".
	    $SNTP_Client_Hash{"Transmit Timestamp Sec"} . "." . $SNTP_Client_Hash{"Transmit Timestamp Micro Sec"}." \t ".
	    $RcV{"Transmit Timestamp Sec"} . ".".
	    $RcV{"Transmit Timestamp Micro Sec"}."";
    }
    else {
	%moduleOutput = (
	    $moduleInput{-hostname} => {
		"LI"                   => $RcV{"LI"},
		    "VN"                   => $RcV{"VN"},
		    "Mode"                 => $RcV{"Mode"},
		    "Stratum"              => $RcV{"Stratum"},
		    "Poll"                 => $RcV{"Poll"},
		    "Precision"            => $RcV{"Precision"},
		    "Root Delay"           => $RcV{"Root Delay"},
		    "Root Dispersion"      => $RcV{"Root Dispersion"},
		    "Reference Identifier" => $RcV{"Reference Identifier"},
		    "Reference Timestamp"  => $RcV{"Reference Timestamp Sec"}.".".
		    $RcV{"Reference Timestamp Micro Sec"},
		    "Originate Timestamp"  => $RcV{"Originate Timestamp Sec"}.".".
		    $RcV{"Originate Timestamp Micro Sec"},
		    "Receive Timestamp"    => $RcV{"Receive Timestamp Sec"}.".".
		    $RcV{"Receive Timestamp Micro Sec"},
		    "Transmit Timestamp"   => $RcV{"Transmit Timestamp Sec"}.".".
		    $RcV{"Transmit Timestamp Micro Sec"},
	    },
	    $0 => {
		"LI"                   => $SNTP_Client_Hash{"LI"},
		    "VN"                   => $SNTP_Client_Hash{"VN"},
		    "Mode"                 => $SNTP_Client_Hash{"Mode"},
		    "Stratum"              => $SNTP_Client_Hash{"Stratum"},
		    "Poll"                 => $SNTP_Client_Hash{"Poll"},
		    "Precision"            => $SNTP_Client_Hash{"Precision"},
		    "Root Delay"           => $SNTP_Client_Hash{"Root Delay"},
		    "Root Dispersion"      => $SNTP_Client_Hash{"Root Dispersion"},
		    "Reference Identifier" => $SNTP_Client_Hash{"Reference Identifier"},
		    "Reference Timestamp"  => $SNTP_Client_Hash{"Reference Timestamp"},
		    "Originate Timestamp"  => $SNTP_Client_Hash{"Originate Timestamp"},
		    "Receive Timestamp"    => $SNTP_Client_Hash{"Receive Timestamp Sec"}.".".
		    $SNTP_Client_Hash{"Receive Timestamp Micro Sec"},
		    "Transmit Timestamp"   => $SNTP_Client_Hash{"Transmit Timestamp Sec"}.".".
		    $SNTP_Client_Hash{"Transmit Timestamp Micro Sec"},
	    },
	    RFC4330 => {
		"Round Trip Delay"     => $d,
		    "Clock Offset"         => $t
	    }
	    )
    }
    return $error, \%moduleOutput;
}

sub _checkHashKeys {
    my @keysToCompare = ( "-hostname", "-port", "-timeOut", "-RFC4330", "-clearScreen" );
    my %hashInputToCompare = @_;
    my @hashInputKeysToCompare = keys %hashInputToCompare;
    my @differendKeys = _keyDifference(\@hashInputKeysToCompare, \@keysToCompare);
    if (@differendKeys) { return TRUE } else { return FALSE };
};

sub _keyDifference {
    my %hashdiff = map{ $_ => 1 } @{$_[1]};
    return grep { !defined $hashdiff{$_} } @{$_[0]};
}

sub _verifyNumericInput {
    my $numericInput = shift;
    return FALSE if (!defined $numericInput);
    if ( defined $numericInput && $numericInput =~ /^[0-9]+$/ && $numericInput > 0 ) {
	return FALSE;
    }
    return TRUE;
};

sub _verifyPort {
    my $port = shift;
    return FALSE if (!defined $port);
    if ( !_verifyNumericInput($port) ) {
	if ( $port >= MIN_UDP_PORT && MAX_UDP_PORT >= $port ) {
	    return FALSE;
	}
    }
    return TRUE;
};

sub _verifyBoolean {
    my $input = shift;
    return FALSE if (!defined $input);
    if ( !_verifyNumericInput($input) ) {
	if ( $input eq "0" or $input eq "1" ) {
	    return FALSE;
	}
    }
    return TRUE;
};

sub _unpackIP{
    my $ip;
    my $stratum = shift;
    my $tmp_ip = shift;
    if($stratum < 2){
	$ip = unpack("A4",
		     pack("H8", $tmp_ip)
	    );
    }else{
	$ip = sprintf("%d.%d.%d.%d",
		      unpack("C4",
			     pack("H8", $tmp_ip)
		      )
	    );
    }
    return $ip;
};

sub _binaryToDecimal {
    my $bits     = shift;
    my $size     = shift;
    my $template = shift;
    return unpack($template, pack("B$size", substr("0" x $size . $bits , -$size)));
};

=head1 EXAMPLE

This example gets the time from a remote NTP server from the
 L<pool.ntp.org: public ntp time server for everyone|http://www.pool.ntp.org/en/> 
 and calculates the roundtrip delay d and local clock offset
 t as defined on RFC4330.

We use the L<Data::Dumper|http://search.cpan.org/~ilyam/Data-Dumper-2.121/Dumper.pm>
 module to print the output.

  #!/usr/bin/perl
  use strict;
  use warnings;
  use Data::Dumper;

  use Net::SNTP::Client;

  my %hashInput = (
      -hostname      => "0.pool.ntp.org",
      -port          => 123,
      -timeOutInput  => 10,
      -RFC4330       => 1,
      -clearScreen   => 1,
      );

  my ( $error , $hashRefOutput ) = getSNTPTime( %hashInput );

  print Dumper $hashRefOutput;
  print "Error: $error\n" if ($error);

DEPENDENCIES

The module is implemented using IO::Socket::INET and Time::HiRes
 and requires both these modules to be installed.


=head1 AUTHOR

Athanasios Garyfalos, C<< <garyfalos at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-net-sntp-client at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SNTP-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SNTP::Client

You can also look for information at:


=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SNTP-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SNTP-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SNTP-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SNTP-Client/>

=back

=head1 SEE ALSO

perl, IO::Socket, Net::NTP, Net::SNTP::Server, L<RFC4330|https://tools.ietf.org/html/rfc4330>

Net::NTP has a similar focus as this module. In my opinion it
 is less accurate when it comes to the precission bellow second(s).

=head1 REPOSITORY

L<https://github.com/thanos1983/perl5-Net-SNTP-Client>


=head1 DIFFERENCES FROM OTHER MODULES

Based on the current known modules Net::SNTP::Client is only similar
 to Net::NTP module. The two modules do not have in common the
 encoding and decoding process of fractions of seconds.

Be aware that on different OS different precision can be achieved.

=head1 DIFFERENCES BETWEEN NTP AND SNTP

SNTP (Simple Network Time Protocol) and NTP (Network Time Protocol)
 are describing exactly the same network package format, the differences
 can be found in the way how a system deals with the content of these
 packages in order to synchronize its time.

=head1 ACKNOWLEDGEMENTS

The original concept for this module was based on F<NTP.pm>
written by James G. Willmore E<lt>willmorejg@gmail.comE<gt>.

Copyright 2004 by James G. Willmore

This library is free software; you can redistribute it and/or modify it under
 the same terms as Perl itself.


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Athanasios Garyfalos.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 CHANGE LOG
$Log: Client.pm,v $
Revision 22.0  2015/11/6 10:33:21 am  Thanos

=cut

1; # End of Net::SNTP::Client
