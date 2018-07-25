package Net::Wireless::802_11::Scan::FreeBSD;

use 5.006;
use strict;
use warnings;
use String::ShellQuote;
use base 'Error::Helper';

=head1 NAME

Net::Wireless::802_11::Scan::FreeBSD - A interface to the wireless interface AP scanning built into ifconfig on FreeBSD

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Net::Wireless::802_11::Scan::FreeBSD;

    my $scan = Net::Wireless::802_11::Scan::FreeBSD->new();

    #scan for APs
    my @APs=$scan->scan;
    if ( $scan->error ){
        warn('$scan->scan errored');
    }

    #print some information for each AP
    my $APs_int=0;
    while ( defined( $APs[$APs_int] ) ){
        print 'SSID:  '.$APs[$APs_int]{'ssid'}."\n".
              'BSSID: '.$APs[$APs_int]{'bssid'}."\n".
              'Chan:  '.$APs[$APs_int]{'chan'}."\n".
              'Sec:   ';

        my $security=none;
        if ( $APs[$APs_int]{'WPA'} ){
            $security='WPA1'
        }
        if ( $APs[$APs_int]{'RSN'} ){
            $security='WPA2'
        }

        print $security."\n\n";

        $APs_int++;
    }

=head1 METHODS

=head2 new

This initializes the object.

At start the interface will be set to 'wlan0'. If you
want to change this, you will need to call ifSet.

No error checking is needed as this will always succeed, as
long as it is being ran on FreeBSD. This will throw a permanent
error if $^O ne 'freebsd'.

    my $scan=Net::Wireless::802_11::Scan::FreeBSD->new();

=cut

sub new {

    my $self={
		perror=>undef,
		error=>undef,
		errorString=>'',
		errorExtra=>{
		    1=>'notFreeBSD',
		    2=>'ifUndef',
		    3=>'ifconfigError',
			    },
		interface=>'wlan0',
	};
    bless $self;

    #this only works on FreeBSD
    if ($^O ne 'freebsd'){
	$self->{errorString}='OS not FreeBSD';
	$self->{error}=1;
	$self->{perror}=1;
	$self->warn;
    }

    return $self;
}

=head2 ifGet

This returns the current interface.

No error checking is needed as this will always succeed.

    my $interface=$scan->ifGet;

=cut

sub ifGet{
    my $self=$_[0];
    $self->errorblank;
    if ( $self->error ){return undef};

    return $self->{'interface'};
}

=head2 ifSet

This sets the interface that will be scanned.

One argument is required and that is the interface name.

As long as the interface is defined, there is no need to do error checking.

    #set the interface to wlan1
    $scan->ifSet('wlan1');

=cut

sub ifSet{
    my $self=$_[0];
    my $interface=$_[1];
    $self->errorblank;
    if ( $self->error ){return undef};

    if ( ! defined( $interface ) ){
	$self->{'error'}=2;
	$self->{'errorString'}='No value defined for the interface';
	$self->warn;
	return undef;
    }

    $self->{'interface'}=$interface;

    return undef;
}

=head2 scan

This runs "ifconfig -v $interface list scan".

    my @APs=$scan->scan;
    use Data::Dumper;
    print Dumper(\@APs);

=head3 returned data

The returned data is a array of hashes.

=head4 ssid

The SSID of the AP.

This may be blank.

=head4 bssid

The BSSID of the AP.

=head4 chan

The channel it is on.

=head4 rate

The rate of the AP in question.

=head4 S:N

The signal noise ratio.

=head4 signal

The signal value from S:N.

=head4 noise

The noise value from S:N.

=head4 int

The beacon interval of the AP.

=head4 caps

This is the raw unparsed caps field.

=head4 Authorized

The station is permitted to send/receive data frames.

=head4 ERP

Extended Rate Phy (ERP).  Indicates that the station is
operating in an 802.11g network using extended transmit
rates.

=head4 HT

The station is using HT transmit rates.

=head4 PowerSave

The station is operating in power save mode.

=head4 QoS

The station is using QoS encapsulation for data frame.

=head4 ShortPreamble

The station is doing short preamble to optionally improve
throughput performance with 802.11g and 802.11b.

=head4 WPS

The station in question allows the use of WPS.

=head4 ATH

The AP in question supports Atheros protocol extensions.

=head4 WME

Indicates WME support.

=head4 WPA

The AP supports WPA, not to be confused with WPA2.

=head4 RSN

The AP supports RSN, WPA2.

=head4 VEN

The AP supports unknown vendor-specific extensions.

=cut

sub scan{
    my $self=$_[0];
    my $interface=$_[1];
    $self->errorblank;
    if ( $self->error ){return undef};

    $interface=shell_quote($self->{'interface'});
    my $output=`/sbin/ifconfig -v $interface scan`;
    my $exitcode=$?;
    if ( $exitcode ne '0' ){
	$self->{error}=3;
	$self->{errorString}='"/sbin/ifconfig -v '.$interface.' scan." exited with "'.$exitcode.'"';
	$self->warn;
	return undef;
    }

    my @toReturn;

    my @outputA=split(/\n/, $output);
    my $lineNumber=1;
    while ( defined( $outputA[$lineNumber] ) ){
	my %ap;
	my $line=$outputA[$lineNumber];

	$ap{'ssid'}=substr($line, 0, 32);
	$ap{'ssid'}=~s/[\ \t]*$//; #remove trailing white space
	$line=substr($line, 34); #remove the SSID from the line

	my @lineA=split(/ +/, $line, 7);
	$ap{'bssid'}=$lineA[0];
	$ap{'chan'}=$lineA[1];
	$ap{'rate'}=$lineA[2];
	$ap{'S:N'}=$lineA[3];
	$ap{'int'}=$lineA[4];
	$ap{'caps'}=$lineA[5];

	#split the SNR so others don't have to do it later
	($ap{'signal'}, $ap{'noise'})=split(/\:/, $ap{'S:N'});

	#parse the caps as per ifconfig
	#
        # A    Authorized.  Indicates that the station is permitted to
        #      send/receive data frames.
	if ( $ap{'caps'} =~ /A/ ){
	    $ap{'Authorized'}=1;
	}else{
	    $ap{'Authorized'}=0;
	}
	# E    Extended Rate Phy (ERP).  Indicates that the station is
        #      operating in an 802.11g network using extended transmit
        #      rates.
	if ( $ap{'caps'} =~ /E/ ){
	    $ap{'ERP'}=1;
	}else{
	    $ap{'ERP'}=0;
	}
        #     H    High Throughput (HT).  Indicates that the station is using
        #          HT transmit rates.  If a `+' follows immediately after then
        #          the station associated using deprecated mechanisms supported
        #          only when htcompat is enabled.
	#
	if ( $ap{'caps'} =~ /H/ ){
	    $ap{'HT'}=1;
	}else{
	    $ap{'HT'}=0;
	}
        #     P    Power Save.  Indicates that the station is operating in
        #          power save mode.
	if ( $ap{'caps'} =~ /P/ ){
	    $ap{'PowerSave'}=1;
	}else{
	    $ap{'PowerSave'}=0;
	}
        #     Q    Quality of Service (QoS).  Indicates that the station is
        #          using QoS encapsulation for data frame.  QoS encapsulation
        #          is enabled only when WME mode is enabled.
	if ( $ap{'caps'} =~ /Q/ ){
	    $ap{'QoS'}=1;
	}else{
	    $ap{'QoS'}=0;
	}
        #     S    Short Preamble.  Indicates that the station is doing short
        #          preamble to optionally improve throughput performance with
        #          802.11g and 802.11b.
	if ( $ap{'caps'} =~ /S/ ){
	    $ap{'ShortPreamble'}=1;
	}else{
	    $ap{'ShortPreamble'}=0;
	}
        #     T    Transitional Security Network (TSN).  Indicates that the
        #          station associated using TSN; see also tsn below.
	if ( $ap{'caps'} =~ /T/ ){
	    $ap{'TSN'}=1;
	}else{
	    $ap{'TSN'}=0;
	}
        #     W    Wi-Fi Protected Setup (WPS).  Indicates that the station
        #          associated using WPS.
	if ( $ap{'caps'} =~ /W/ ){
	    $ap{'WPS'}=1;
	}else{
	    $ap{'WPS'}=0;
	}

	$line=$lineA[6];
	$line=~s/SSID\<$ap{'ssid'}\>//; #remove the SSID so we don't hit on that
	#$line=~s/\<{1}[^\>]*\>{1}//g;
	#print $line."\n";

	# ATH (station supports Atheros protocol extensions),
	if ( $line =~ /\ ATH\</ ){
	    $ap{'ATH'}=1;
	}else{
	    $ap{'ATH'}=0;
	}
	# WME (station supports WME),
	if ( $line =~ /\ WME\</ ){
	    $ap{'WME'}=1;
	}else{
	    $ap{'WME'}=0;
	}
	# WPA (station supports WPA),
	if ( $line =~ /\ WPA\</ ){
	    $ap{'WPA'}=1;
	}else{
	    $ap{'WPA'}=0;
	}
	# VEN (station supports unknown vendor-specific extensions)
	if ( $line =~ /\ VEN\</ ){
	    $ap{'VEN'}=1;
	}else{
	    $ap{'VEN'}=0;
	}
	# RSN https://en.wikipedia.org/wiki/IEEE_802.11i-2004
	# appears to
	if ( $line =~ /\ RSN\</ ){
	    $ap{'RSN'}=1;
	}else{
	    $ap{'RSN'}=0;
	}


	push(@toReturn, \%ap);
	$lineNumber++;
    }

    return @toReturn;
}

=head1 ERROR CODES/FLAGS

For information on error handling and the like, please see the documentation on Error::Helper.

=head2 1/notFreeBSD

$^O ne 'freebsd'. This module only works on FreeBSD.

=head2 2/ifUndef

Interface not defined.

=head2 3/ifconfigError

Ifconfig errored when trying to run "ifconfig -v $interface list scan".

This means it returned a non-0 exist code.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-wireless-802_11-scan-freebsd at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Wireless-802_11-Scan-FreeBSD>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Wireless::802_11::Scan::FreeBSD


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Wireless-802_11-Scan-FreeBSD>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Wireless-802_11-Scan-FreeBSD>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-Wireless-802_11-Scan-FreeBSD>

=item * Search CPAN

L<https://metacpan.org/release/Net-Wireless-802_11-Scan-FreeBSD>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Zane C. Bowers-Hadley.

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


=cut

1; # End of Net::Wireless::802_11::Scan::FreeBSD
