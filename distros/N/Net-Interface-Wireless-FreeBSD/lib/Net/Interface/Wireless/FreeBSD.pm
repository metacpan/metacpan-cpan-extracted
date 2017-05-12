package Net::Interface::Wireless::FreeBSD;

use warnings;
use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

our @ISA         = qw(Exporter);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(ListWirelessInterfaces ListScan);
our %EXPORT_TAGS = ();

=head1 NAME

Net::Interface::Wireless::FreeBSD - Get information for wireless interfactes.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';


=head1 SYNOPSIS

	use Net::Interface::Wireless::FreeBSD qw/ListWirelessInterfaces/;

	#gets a array of wireless interfaces
	my @wifs=ListWirelessInterfaces();

	#get a list of visible APs with exporting the Listscan function for the first wireless device found
	my %scanhash=Net::Interface::Wireless::FreeBSD::ListScan($wifs[0]);

	while(my ($ssid, $ap)=each(%scanhash)){
		print "SSID: ".$ssid.
			"\nBSSID: ".$ap->{bssid}.
			"\nChannel: ".$ap->{channel}.
			"\nSNR: ".$ap->{snr}.
			"\nRate: ".$ap->{rate}.
			"\nBeacon Interval: ".$ap->{int}.
			"\nESS: ".$ap->{ess}.
			"\nIBSS".$ap->{ibss}.
			"\nPrivacy: ".$ap->{privacy}.
			"\nShort Preanble: ".$ap->{"short preamble"}.
			"\nShort Time Slot: ".$ap->{"short time slot"}."\n\n";
	};

=head1 EXPORT

ListWirelessInterfaces
ListScan

=head1 FUNCTIONS

=head2 ListWirelessInterfaces

This looks in "/dev/net/" and checks to see if any of them there are
recognized interfaces.

Currently it recognizes an(4), ath(4), awi(4), ipw(4), iwi(4), 
ral(4), ural(4), and wi(4).

=cut

sub ListWirelessInterfaces {
	#a list of wireless interface bases
	my @ifs=("an", "ath", "awi", "ipw", "iwi", "ral", "ural", "wi");
	
	#try to open the dir that contains the interfaces
	#return undef upon failure
	if(!opendir(GETINTERFACES, "/dev/net/")){
		return undef;
	};
	my @foundifs=readdir(GETINTERFACES);
	closedir(GETINTERFACES);
	
	my @wifs=();
	
	my $foundifsInt=0;
	while(defined($foundifs[$foundifsInt])){
		my $ifsInt=0;
		#go through and checks the various interfaces
		while(defined($ifs[$ifsInt])){
			#builds the check as otherwise it generates errors if it is done in the regex
			my $test="^".$ifs[$ifsInt]."[0123456789]*\$";
			#checks if the interface matches
			if($foundifs[$foundifsInt] =~ /$test/){
				push(@wifs, $foundifs[$foundifsInt]);
			};
					
			$ifsInt++;
		};
		
		$foundifsInt++;
	};
	
	return @wifs;
};

=head2 ListScan($interface)

Fetch a list of seen APs. This can be used as a non-super user. It just lists seen APs.

This function returns undef upon error and upon success a hash. For info on the hash return,
please see the section SCAN RETURN.

=cut

sub ListScan{
	my $if=$_[0];
	
	if (!-e "/dev/net/".$if){
		warn("'".$if."' is a non-existant interface.");
		return undef;
	};
	
	my %scan=();
	
	my @rawscan=`ifconfig -v $if list scan`;
	
	#tests the first row to see if it matches the expected return for it...
	#if not, assume there was a error and warn...
	if($rawscan[0] eq "SSID                              BSSID              CHAN RATE  S:N   INT CAPS\n"){

		my $rawscanInt=1;
		while(defined($rawscan[$rawscanInt])){
			chomp($rawscan[$rawscanInt]);
			#get the first 34 characters... which will include the 
			my $ssid=substr($rawscan[$rawscanInt], 0, 33);
	
			#remove any trailing spaces. from the ssid
			$ssid=~s/ +$//;
			
			$scan{$ssid}={};
			
			#sets the bssid
			$scan{$ssid}{bssid}=substr($rawscan[$rawscanInt], 34, 17);
			
			#gets everything after the bssid
			my $restofstring=substr($rawscan[$rawscanInt], 51);
			
			#changes multiple spaces into on
			$restofstring =~ s/ +/ /g;
			
			my @rosa=split(/ /, $restofstring);

			#gets the channel
			$scan{$ssid}{channel}=$rosa[0];

			#gets the rate
			$scan{$ssid}{rate}=$rosa[1];

			#gets the signal noise ratio			
			$scan{$ssid}{snr}=$rosa[2];

			#gets the beacon interval			
			$scan{$ssid}{int}=$rosa[3];

			#defines if it is a ESS notwork or not
			if($rosa[4] =~ /E/){
				$scan{$ssid}{ess}="1";
			}else{
				$scan{$ssid}{ess}="0";
			};

			#defines if it is in IBSS/ad-hoc mode or not
			if($rosa[4] =~ /I/){
				$scan{$ssid}{ibss}="1";
			}else{
				$scan{$ssid}{ibss}="0";
			};

			#defines if any sort of encryption is in use
			if($rosa[4] =~ /P/){
				$scan{$ssid}{privacy}="1";
			}else{
				$scan{$ssid}{privacy}="0";
			};

			#defines if the network is using short preamble or not
			if($rosa[4] =~ /S/){
				$scan{$ssid}{"short preamble"}="1";
			}else{
				$scan{$ssid}{"short preabmle"}="0";
			};

			#defines if any sort of short time slot or not
			if($rosa[4] =~ /s/){
				$scan{$ssid}{"short time slot"}="1";
			}else{
				$scan{$ssid}{"short time slot"}="0";
			};

			$rawscanInt++;
		};
		
	}else{
#		warn("The first line returned from 'ifconfig -v ".$if." list scan' did not match".
#			'"SSID                              BSSID              CHAN RATE  S:N   INT CAPS\n".');
		return undef;
	};
	
	return %scan;
};

=head2 Scan($interface)

Fetch a list of seen APs, but can only be ran by a super user. This initiates a actual scan.

You may have to potential reassociate with a AP afterwards if you are connected to one.

This function returns undef upon error and upon success a hash. For info on the hash return,
please see the section SCAN RETURN.

=cut

sub Scan{
	my $if=$_[0];
	
	if (!-e "/dev/net/".$if){
		warn("'".$if."' is a non-existant interface.");
		return undef;
	};
	
	my %scan=();
	
	my @rawscan=`ifconfig -v $if scan`;
	
	#tests the first row to see if it matches the expected return for it...
	#if not, assume there was a error and warn...
	if($rawscan[0] eq "SSID                              BSSID              CHAN RATE  S:N   INT CAPS\n"){

		my $rawscanInt=1;
		while(defined($rawscan[$rawscanInt])){
			chomp($rawscan[$rawscanInt]);
			#get the first 34 characters... which will include the 
			my $ssid=substr($rawscan[$rawscanInt], 0, 33);
	
			#remove any trailing spaces. from the ssid
			$ssid=~s/ +$//;
			
			$scan{$ssid}={};
			
			#sets the bssid
			$scan{$ssid}{bssid}=substr($rawscan[$rawscanInt], 34, 17);
			
			#gets everything after the bssid
			my $restofstring=substr($rawscan[$rawscanInt], 51);
			
			#changes multiple spaces into on
			$restofstring =~ s/ +/ /g;
			
			my @rosa=split(/ /, $restofstring);

			#gets the channel
			$scan{$ssid}{channel}=$rosa[0];

			#gets the rate
			$scan{$ssid}{rate}=$rosa[1];

			#gets the signal noise ratio			
			$scan{$ssid}{snr}=$rosa[2];

			#gets the beacon interval			
			$scan{$ssid}{int}=$rosa[3];

			#defines if it is a ESS notwork or not
			if($rosa[4] =~ /E/){
				$scan{$ssid}{ess}="1";
			}else{
				$scan{$ssid}{ess}="0";
			};

			#defines if it is in IBSS/ad-hoc mode or not
			if($rosa[4] =~ /I/){
				$scan{$ssid}{ibss}="1";
			}else{
				$scan{$ssid}{ibss}="0";
			};

			#defines if any sort of encryption is in use
			if($rosa[4] =~ /P/){
				$scan{$ssid}{privacy}="1";
			}else{
				$scan{$ssid}{privacy}="0";
			};

			#defines if the network is using short preamble or not
			if($rosa[4] =~ /S/){
				$scan{$ssid}{"short preamble"}="1";
			}else{
				$scan{$ssid}{"short preabmle"}="0";
			};

			#defines if any sort of short time slot or not
			if($rosa[4] =~ /s/){
				$scan{$ssid}{"short time slot"}="1";
			}else{
				$scan{$ssid}{"short time slot"}="0";
			};

			$rawscanInt++;
		};
		
	}else{
		warn("The first line returned from 'ifconfig -v ".$if." list scan' did not match".
			'"SSID                              BSSID              CHAN RATE  S:N   INT CAPS\n".');
		return undef;
	};
	
	return %scan;
};

=head1 SCAN RETURN

The return is a hash, whose keys are the seen SSIDs. The value of each key is then another hash.
See below for a list of keys for that hash.

=over

=item bssid

The BSSID of the base station in question.

=item channel

The channel the base station is operating on.

=item snr

The signal to noise ratio of a connection.


=item rate

The base rate for the AP. This is what it is set to, not a guarrentee you will get it.

=item int

The beacon interval for the base station.

=item ess

A boolean value for if the AP is in ESS mode or not. This is always defined, even if
not in ESS mode.

=item ibss

A boolean value for if the AP is in IBSS/ad-hoc mode or not. This is always defined, even if
not in IBSS/ad-hoc mode.

=item privacy

Wether or not the AP any sort of encryption enabled. This is always defined, even if
not it is using encryption.

=item short preable

Wether or not the AP is set for short preable. This is always defined, even if
not it set to short preable.

=item short time slot

Wether or not the AP is set for short time slot. This is always defined, even if
not it set to short time slot.

=back

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-interface-wireless-freebsd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Interface-Wireless-FreeBSD>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Interface::Wireless::FreeBSD


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Interface-Wireless-FreeBSD>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Interface-Wireless-FreeBSD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Interface-Wireless-FreeBSD>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Interface-Wireless-FreeBSD>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Net::Interface::Wireless::FreeBSD
