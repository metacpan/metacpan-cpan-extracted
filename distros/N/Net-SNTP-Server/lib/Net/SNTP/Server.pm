package Net::SNTP::Server;

BEGIN { die 'Perl version 5.6.0 or greater is required' if ($] < 5.006); }

use strict;
use warnings;

=head1 NAME

Net::SNTP::Server - Perl Module SNTP Server based on L<RFC4330|https://tools.ietf.org/html/rfc4330>

=head1 VERSION

Version 0.06

=cut

## Version of the Net::SNTP::Server module

our $VERSION = '0.06';
$VERSION = eval $VERSION;

use POSIX qw();
use IO::Socket::INET;
use Time::HiRes qw( gettimeofday );

## Handle importing/exporting of symbols

use base qw( Exporter );
our @EXPORT_OK = qw( basicSNTPSetup );  # symbols to export on request

=head1 SYNOPSIS

The Net::SNTP::Server - Perl module has the ability to reply to NTP or SNTP
 client queries towards the Server. The moment that the server is correctly
 initialized, it will wait for client requests on the IP and port defined by
 the user. The SNTP server uses the local clock to retrieve highest possible
 accuracy (seconds and nano seconds) in-order to calculate the round-trip delay
 d and system clock offset t. Accuracy may differ from one OS to the other. The
 server will encode the message and formated based on L<RFC4330|https://tools.ietf.org/html/rfc4330> protocol specifications.
 The server will remain active until the user decides to terminate the connection.

    use Net::SNTP::Server;

    my ( $error , $hashRefOutput ) = basicSNTPSetup( %hashInput );
    ...


=head1 ABSTRACT

The module retrieves and sends a UDP packet formated according to L<RFC4330|https://tools.ietf.org/html/rfc4330> to a defined NTP
 or SNTP server sent by the Client. The received packet, gets decoded end encoded
 to be retransmitted back to the Client.


=head1 DESCRIPTION

This module exports a single method (basicSNTPSetup) and returns
 an associative hash output, based on the user input. In case
 of an error, the connection will be terminated and an error string
 will be printed with the possible cause.

The response from the SNTP server is been encoded to a human readable
 format. The obtained information received from the server on the client
 side can be used into further processing or manipulation according to the
 user needs. Maximum accuracy down to nano seconds can only be achieved based
 on different OS.

=over 2

=item * IP

    -ip: Is not a mandatory for the method key to operate correctly.
    By default the module will assign the localhost IP ("127.0.0.1"),
    but this will restrict the server to localhost communications (only
    internally it can receive and transmit data).


=item * PORT

    -port: Is a mandatory key, that the user must define. By default the
    port is not set. The user has to specify the port. We can not use the
    default 123 NTP due to permission. The user has to choose a port number
    identical to port that the client will use client to communicate with
    the server (e.g. -port => 123456).

=back



=head1 IMPORTANT NOTES

Different OS, different precision abilities. In order the user to gain the most
 out of this module, the script should be executed in Linux-wise OS. Ofcourse
 the  module can operate correctly on all OS but due to OS accuracy limitations
 and internal OS restrictions we need to have administrator authority to access
 these data. For more information see L<Windows Time Service Registry Entries|https://technet.microsoft.com/en-us/library/cc773263%28WS.10%29.aspx#w2k3tr_times_tools_uhlp>.

Given in consideration of the information that we explained why the user should
 execute the module on Linux, Fedora, Redhat etc. We reccomend to L<Install|https://wiki.archlinux.org/index.php/Help:Reading#Installation_of_packages> the L<ntp package|https://www.archlinux.org/packages/?name=ntp>.
 the L<NTP|http://www.ntp.org/> package if you want to use the server as primary
 time synchronization source and you want the daemon to run in the background
 continuously to automatically synchronize your internal OS clock. By installing
 the NTP package, the user can benefit from the L<ntpd|http://linux.die.net/man/8/ntpd>
 daemon and extract all the useful extra information from the Server. In case
 the user does not want to install the NTP package the SNTP Server can provide
 all the information that the Client requires.

The module has been tested on LinuxOS and WindowsOS but it should be compatible
 with MacOS as well, but it has not been tested, not yet at least.



=head1 SUBROUTINES/METHODS

  my ( $error , $hashRefOutput ) = basicSNTPSetup( %hashInput );


=cut

## Define constands

# The_version_of_constant provided by perl 5.6.1 does not support that.
# use constant {
#     TRUE                  => 1,
#     FALSE                 => 0,
#     MAXBYTES              => 512,
#     UNIX_EPOCH            => 2208988800,
#     MIN_UDP_PORT          => 1,
#     MAX_UDP_PORT          => 65535,
#     DEFAULT_LOCAL_HOST_IP => "127.0.0.1",
# };

use constant TRUE                  => 1;
use constant FALSE                 => 0;
use constant MAXBYTES              => 512;
use constant UNIX_EPOCH            => 2208988800;
use constant MIN_UDP_PORT          => 1;
use constant MAX_UDP_PORT          => 65536;
use constant DEFAULT_LOCAL_HOST_IP => "127.0.0.1";

=head2 basicSNTPSetup

  my %hashInput = (
      -ip      => "127.0.0.1", # IP
      -port    => 12345,       # Default NTP locked port 123
      );

  my ( $error , $hashRefOutput ) = basicSNTPSetup( %hashInput );

This module exports a single method (basicSNTPSetup) and returns an associative
 hash output, based on the user input. In case of an error, the connection will
 be terminated and an error string will be printed with the possible cause.

The response from the SNTP server is been encoded to a human readable format.
 The obtained information received from the server on the client side can be
 used into further processing or manipulation according to the user needs.
 Maximum accuracy down to nano seconds can only be achieved based on different OS.


=cut

my @SNTP_Transmit = ( { "LI VN Mode"                    => '00100100' },
		      { "Stratum"                       => '2' },
		      { "Poll"                          => '3' },
		      { "Precision"                     => undef },
		      { "Root Delay"                    => undef },
		      { "Root Delay Fraction"           => undef },
		      { "Root Dispersion"               => undef },
		      { "Root Dispersion Fraction"      => undef },
		      { "Reference Identifier"          => undef },
		      { "Reference Timestamp Sec"       => undef },
		      { "Reference Timestamp Micro Sec" => undef },
		      { "Originate Timestamp Sec"       => undef },
		      { "Originate Timestamp Micro Sec" => undef },
		      { "Receive Timestamp Sec"         => undef },
		      { "Receive Timestamp Micro Sec"   => undef },
		      { "Transmit Timestamp Sec"        => undef },
		      { "Transmit Timestamp Micro Sec"  => undef } );

sub basicSNTPSetup {
    my $error = undef;
    my %moduleInput = @_;

    return ($error = "Not defined key(s)", \%moduleInput)
	if (_checkHashKeys(%moduleInput));
    return ($error = "Not defined Hostname/IP", \%moduleInput)
	if (!$moduleInput{-ip});
    return ($error = "Not defined Port", \%moduleInput)
	if (!$moduleInput{-port});
    return ($error = "Not correct port number", \%moduleInput)
	if (_verifyPort($moduleInput{-port}));

    my ( @array_IP ) = ( $moduleInput{-ip}
			 =~ /(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/ );

    return ($error = "Not correct input IP syntax", \%moduleInput)
	if ( (!defined $array_IP[0]) ||
	     (!defined $array_IP[1]) ||
	     (!defined $array_IP[2]) ||
	     (!defined $array_IP[3]) );

    my $server_socket = undef;
    eval {
	$server_socket = IO::Socket::INET->new(
	    LocalAddr  => $moduleInput{-ip} || DEFAULT_LOCAL_HOST_IP,
	    LocalPort  => $moduleInput{-port},
	    Proto      => 'udp',
	    Type       => SOCK_DGRAM,
	    Broadcast  => 1 ) or die "Error Creating Socket";
    };
    return ($error = "Problem While Creating Socket '$!'", \%moduleInput)
	if ( $@ && $@ =~ /Error Creating Socket/ );

    print "\n[Server $0 listens at PORT: ".$moduleInput{-port}." and IP: ".$moduleInput{-ip}."]\n\n";

    my @SNTP_Receive = ( "LI VN Mode",
			 "Stratum",
			 "Poll",
			 "Precision",
			 "Root Delay",
			 "Root Dispersion",
			 "Reference Identifier",
			 "Reference Timestamp Sec",
			 "Reference Timestamp Micro Sec",
			 "Originate Timestamp Sec",
			 "Originate Timestamp Micro Sec",
			 "Receive Timestamp Sec",
			 "Receive Timestamp Micro Sec",
			 "Transmit Timestamp Sec",
			 "Transmit Timestamp Micro Sec" );

    while ( TRUE ) {
	my $peer_address = $server_socket->peerhost();
	my $peer_port = $server_socket->peerport();

	if ( $peer_address ) { print "Peer address: ".$peer_address."\n" };
	if ( $peer_port ) { print "Peer port: ".$peer_port."\n" };

	( $SNTP_Transmit[9]{"Reference Timestamp Sec"},
	  $SNTP_Transmit[10]{"Reference Timestamp Micro Sec"} ) = gettimeofday();

	my $rcv_sntp_packet = undef;
	eval {
	    $server_socket->recv( $rcv_sntp_packet , MAXBYTES )
		or die "Error Receiving";
	};
	return ($error = "Problem While Receiving '$!'", \%moduleInput)
	    if ( $@ && $@ =~ /Error Receiving/ );

	( $SNTP_Transmit[13]{"Receive Timestamp Sec"},
	  $SNTP_Transmit[14]{"Receive Timestamp Micro Sec"} ) = gettimeofday();

	my %RcV;
	@RcV{@SNTP_Receive} = unpack( "B8 C3 N11" , $rcv_sntp_packet );

	my @ntpdate_tmp = `ntpdc -c sysinfo 2>&1`;

	if ( !defined( $ntpdate_tmp[0] ) ||
	     # index is 4 times faster than regex
	     index( $ntpdate_tmp[0] , 'ntpdc' ) != -1 ) {
	    _setSntpServerValues( @array_IP );
	}
	else {
	    _setNtpServerValues( \@array_IP, \@ntpdate_tmp );
	}

	$SNTP_Transmit[11]{"Originate Timestamp Sec"} = $RcV{"Transmit Timestamp Sec"};
	$SNTP_Transmit[12]{"Originate Timestamp Micro Sec"} = $RcV{"Transmit Timestamp Micro Sec"};

	( $SNTP_Transmit[15]{"Transmit Timestamp Sec"},
	  $SNTP_Transmit[16]{"Transmit Timestamp Micro Sec"} ) = gettimeofday();

	$SNTP_Transmit[9]{"Reference Timestamp Sec"} += UNIX_EPOCH;
	$SNTP_Transmit[13]{"Receive Timestamp Sec"} += UNIX_EPOCH;
	$SNTP_Transmit[15]{"Transmit Timestamp Sec"} += UNIX_EPOCH;

	my @SNTP;
	foreach my $href ( @SNTP_Transmit ) {
	    foreach my $role ( keys %$href ) {
		push @SNTP, $href->{$role};
	    }
	}

	my $send_sntp_packet = pack( "B8 C3 s n3 H8 N8" , @SNTP );

	eval {
	    $server_socket->send( $send_sntp_packet )
		or die "Error Sending";
	};
	return ($error = "Problem While Sending '$!'", \%moduleInput)
	    if ( $@ && $@ =~ /Error Sending/ );

    } # End of while(TRUE) loop

    $server_socket->close(); # Close socket

    my %moduleOutput = ();
    return $error, \%moduleOutput;
}

sub _setSntpServerValues {
    my ( @serverIP ) = @_;
    ( undef , undef ,  $SNTP_Transmit[3]{"Precision"} , undef , undef )
	= POSIX::times();
    $SNTP_Transmit[4]{"Root Delay"} = 0;
    $SNTP_Transmit[5]{"Root Delay Fraction"} = 0;
    $SNTP_Transmit[6]{"Root Dispersion"} = 0;
    $SNTP_Transmit[7]{"Root Dispersion Fraction"} = 0;
    $SNTP_Transmit[8]{"Reference Identifier"} .= _decToHex( @serverIP );
}

sub _setNtpServerValues {
    my ( $serverIP , $ntpdate_tmp ) = @_;
    my %ntpdc = _setKeyAndValue( @{ $ntpdate_tmp } );
    $SNTP_Transmit[1]{"Stratum"} = $ntpdc{"stratum"};
    $SNTP_Transmit[3]{"Precision"} = $ntpdc{"precision"};
    $SNTP_Transmit[3]{"Precision"} = substr $SNTP_Transmit[3]{"Precision"}, 1;
    chop($ntpdc{"root distance"});
    chop($ntpdc{"root dispersion"});
    ( $SNTP_Transmit[4]{"Root Delay"},
      $SNTP_Transmit[5]{"Root Delay Fraction"} ) = split(/\./,$ntpdc{"root distance"});
    ( $SNTP_Transmit[6]{"Root Dispersion"},
      $SNTP_Transmit[7]{"Root Dispersion Fraction"} ) = split(/\./,$ntpdc{"root dispersion"});
    $ntpdc{"reference ID"} = substr $ntpdc{"reference ID"}, 1, -1;
    @{ $serverIP } = split(/\./, $ntpdc{"reference ID"});
    $SNTP_Transmit[8]{"Reference Identifier"} .= _decToHex( @{ $serverIP } );
    ($ntpdc{"reference time"}, $ntpdc{"tmp"}) = split(/ /, $ntpdc{"reference time"}, 2);
    delete $ntpdc{"tmp"};
    ( $SNTP_Transmit[9]{"Reference Timestamp Sec"},
      $SNTP_Transmit[10]{"Reference Timestamp Micro Sec"} ) = split(/\./,$ntpdc{"reference time"});
    $SNTP_Transmit[9]{"Reference Timestamp Sec"} =
	hex($SNTP_Transmit[9]{"Reference Timestamp Sec"}) - UNIX_EPOCH;
    $SNTP_Transmit[10]{"Reference Timestamp Micro Sec"} =
	hex($SNTP_Transmit[10]{"Reference Timestamp Micro Sec"});
    %ntpdc = ();
}

sub _decToHex {
    my ( @decimal_IP ) = @_;
    my $hex = join('', map { sprintf '%02X', $_ } $decimal_IP[0],
		   $decimal_IP[1],
		   $decimal_IP[2],
		   $decimal_IP[3] );
    return ( uc( $hex ) );
}

sub _checkHashKeys {
    my @keysToCompare = ( "-ip", "-port" );
    my %hashInputToCompare = @_;
    my @hashInputKeysToCompare = keys %hashInputToCompare;
    my @differendKeys = _keyDifference(\@hashInputKeysToCompare, \@keysToCompare);
    if (@differendKeys) { return TRUE } else { return FALSE };
    # c - style if condition
    #return TRUE ? @differendKeys : return FALSE;
};

sub _keyDifference {
    my %hashdiff = map{ $_ => 1 } @{$_[1]};
    return grep { !defined $hashdiff{$_} } @{$_[0]};
}

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

sub _verifyNumericInput {
    my $numericInput = shift;
    return FALSE if (!defined $numericInput);
    if ( defined $numericInput && $numericInput =~ /^[0-9]+$/ && $numericInput > 0 ) {
	return FALSE;
    }
    return TRUE;
};

sub _setKeyAndValue {
    my @KeyAndValue = @_;
    @KeyAndValue = map { s/^\s+|\s+$//g; $_; } @KeyAndValue;
    my @ntpdc = ();
    foreach my $element (@KeyAndValue) {
	$element =~ s/\s\s+/ /g;
	push @ntpdc, split (/: /, $element);
    }
    my %ntpdcTmp = @ntpdc;
    return %ntpdcTmp;
}

=head1 EXAMPLE

This example starts a remote SNTP server based on RFC4330 message format. IP and
 Port need to be provided on the start up based on user preference.

We use the L<Data::Dumper|http://search.cpan.org/~ilyam/Data-Dumper-2.121/Dumper.pm>
 module to print the error output in case of faulty initiliazation. The module
 does not require to printout the output. It should be used only for initialization
 purposes to assist the user with debugging in case of an error. The $error string
 it is also optional that will assist the user to identify the root that can cause
 a faulty initialization.


  #!/usr/bin/perl
  use strict;
  use warnings;
  use Data::Dumper;

  use Net::SNTP::Server qw(basicSNTPSetup);

  my %hashInput = (
      -ip      => "127.0.0.1",
      -port    => 12345,
      );

  my ( $error , $hashRefOutput ) = basicSNTPSetup( %hashInput );

  print Dumper $hashRefOutput;
  print "Error: $error\n" if ($error);


=head1 AUTHOR

Athanasios Garyfalos, C<< <garyfalos at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-sntp-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SNTP-Server>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SNTP::Server


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SNTP-Server>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SNTP-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SNTP-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SNTP-Server/>

=back

=head1 SEE ALSO

perl, IO::Socket, Net::SNTP::Client, L<RFC4330|https://tools.ietf.org/html/rfc4330>

Net::NTP has a similar focus as this module. In my opinion it
 is less accurate when it comes to the precission bellow second(s).

=head1 REPOSITORY

L<https://github.com/thanos1983/perl5-Net-SNTP-Server>


=head1 DIFFERENCES BETWEEN NTP AND SNTP

SNTP (Simple Network Time Protocol) and NTP (Network Time Protocol)
 are describing exactly the same network package format, the differences
 can be found in the way how a system deals with the content of these
 packages in order to synchronize its time.


=head1 ACKNOWLEDGEMENTS

I want to say thank you to L<Perl Monks The Monastery Gates|http://www.perlmonks.org/>
 for their guidance and assistance when ever I had a problem with
 the implementation process of module.

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

$Log: Server.pm,v $
Revision 6.0  2015/10/09 12:13:31 pm  Thanos


=cut

1; # End of Net::SNTP::Server
