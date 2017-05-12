package Net::Wireless::802_11::AP;

use warnings;
use strict;
use base 'Error::Helper';

=head1 NAME

Net::Wireless::802_11::AP - Provides a OO representation to 802.11 AP based on WPA supplicant.

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';


=head1 SYNOPSIS

    use Net::Wireless::802_11::AP;

    my $foo = Net::Wireless::802_11::AP->new({ ssid=>'"foo"' });

    #scan for value for scan_ssid
    $foo->setKey('scan_ssid', '1');

    #set the key management and key
    $foo->setKey( 'key_mgmt', 'WPA-PSK' );
    $foo->setKey( 'psk', '"bar..."' );

    #gets the ssid
    my $ssid=$foo->getKey( 'ssid' );

    #get the bssid
    my $bssid=$foo->getKey( 'bssid' );
    if( defined($bssid) ){
        print 'BSSID='.$bssid."\n";
    }else{
        print "No BSSID set.\n";
    }

=head1 METHODS

=head2 new

This initiates the object.

One arguement is required and it is the a hash reference to initiate
the object with.

The hash reference has one required value and that is 'ssid'. This is
SSID of the base station in question.

The others may be any valid key for a configured AP in wpa_supplicant.conf.
For more information, please see wpa_supplicant.conf(5).

There is one break from this and this is the key 'networkID'. This represents the
numeric ID used for with wpa_cli to reference that configured AP.

    my $new=$foo=Net::Wireless::802_11::AP->new( { ssid=>'"foo"' } );

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	
	my $self={
		perror=>undef,
		error=>undef,
		errorString=>'',
		ssid=>undef,
		scan_ssid=>undef,
		bssid=>undef,
		priority=>undef,
		mode=>undef,
		proto=>undef,
		key_mgmt=>undef,
		auth_alg=>undef,
		pairwise=>undef,
		group=>undef,
		psk=>undef,
		eapol_flags=>undef,
		eap=>undef,
		identity=>undef,
		anonymous_identity=>undef,
		mixed_cell=>undef,
		password=>undef,
		ca_cert=>undef,
		client_cert=>undef,
		private_key=>undef,
		private_key_passwd=>undef,
		dh_file=>undef,
		subject_match=>undef,
		phase1=>undef,
		phase2=>undef,
		ca_cert2=>undef,
		client_cert2=>undef,
		private_key2=>undef,
		private_key2_passwd=>undef,
		dh_file2=>undef,
		subject_match2=>undef,
		eappsk=>undef,
		nai=>undef,
		server_nai=>undef,
		pac_file=>undef,
		eap_workaround=>undef,
		networkID=>undef,
		wep_tx_keyidx=>undef,
		wep_key0=>undef,
		wep_key1=>undef,
		wep_key2=>undef,
		wep_key4=>undef,
		valid=>{
			ssid=>1,
			scan_ssid=>1,
			bssid=>1,
			priority=>1,
			mode=>1,
			proto=>1,
			key_mgmt=>1,
			auth_alg=>1,
			pairwise=>1,
			group=>1,
			psk=>1,
			eapol_flags=>1,
			eap=>1,
			identity=>1,
			anonymous_identity=>1,
			mixed_cell=>1,
			password=>1,
			ca_cert=>1,
			client_cert=>1,
			private_key=>1,
			private_key_passwd=>1,
			dh_file=>1,
			subject_match=>1,
			phase1=>1,
			phase2=>1,
			ca_cert2=>1,
			client_cert2=>1,
			private_key2=>1,
			private_key2_passwd=>1,
			dh_file2=>1,
			subject_match2=>1,
			eappsk=>1,
			nai=>1,
			server_nai=>1,
			pac_file=>1,
			eap_workaround=>1,
			networkID=>1,
			wep_tx_keyidx=>1,
			wep_key0=>1,
			wep_key1=>1,
			wep_key2=>1,
			wep_key4=>1,
		},
		wpaKeys=>{
			ssid=>1,
			scan_ssid=>1,
			bssid=>1,
			priority=>1,
			mode=>1,
			proto=>1,
			key_mgmt=>1,
			auth_alg=>1,
			pairwise=>1,
			group=>1,
			psk=>1,
			eapol_flags=>1,
			eap=>1,
			identity=>1,
			anonymous_identity=>1,
			mixed_cell=>1,
			password=>1,
			ca_cert=>1,
			client_cert=>1,
			private_key=>1,
			private_key_passwd=>1,
			dh_file=>1,
			subject_match=>1,
			phase1=>1,
			phase2=>1,
			ca_cert2=>1,
			client_cert2=>1,
			private_key2=>1,
			private_key2_passwd=>1,
			dh_file2=>1,
			subject_match2=>1,
			eappsk=>1,
			nai=>1,
			server_nai=>1,
			pac_file=>1,
			eap_workaround=>1,
			wep_tx_keyidx=>1,
			wep_key0=>1,
			wep_key1=>1,
			wep_key2=>1,
			wep_key4=>1,
		}
	};
	bless $self;

	#down syncs everything from the args hash to the object
	my $int=0;
	my @keys=keys(%args);
	while( defined( $keys[$int] ) ){
		if(! defined( $self->{valid}{$keys[$int]} ) ){
			$self->{perror}=1;
			$self->{error}=2;
			$self->{errorString}='"'.$keys[$int].'" is not a valid key';
		}

		$self->{$keys[$int]}=$args{$keys[$int]};

		$int++;
	}

	#make sure we have a SSID
	if( ! defined( $self->{ssid} ) ){
		$self->{error}=1;
		$self->{perror}=1;
		$self->{errorString}='No SSID specified';
		return $self;
	}
	
	return $self;
}

=head2 getKey

This returns the requested keys.

One value is required and that is the requested key.

Undef is a valid return value for this if the requested key is not defined.

Error checking is not required as long as the requested key is defined and
is valid.

    my $key=$foo->getKey( $key );
    if( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub getKey{
	my $self=$_[0];
	my $key=$_[1];
	
	#try to blank the previous error
	if( ! $self->errorblank ){
		return undef;
	}

	#make sure we have a key
	if(!defined( $key )){
		$self->{error}=3;
		$self->{errorString}='No key specified';
		return undef;
	}

	#make sure it is a valid key
	if(!defiend( $self->{valid}{$key} )){
		$self->{error}=2;
		$self->{errorString}='"'.$key.'" is not a valid key';
		return undef;
	}

	return $self->{key};
}

=head2 listKeys

This returns a list of defined keys.

No arguments are taken.

As long as the new method suceeded, this
method will not error.

    my %APkeys=$foo->listKeys;

=cut

sub listKeys{
	my $self=$_[0];

    #try to blank the previous error
    if( ! $self->errorblank ){
        return undef;
    }

	my %toreturn;

	#check for defined keys
	my @keys=keys( %{ $self->{valid} } );
	my $int=0;
	while( defined( $keys[$int] ) ){
		if( defined( $self->{$keys[$int]} ) ){
			$toreturn{$keys[$int]}=$self->{$keys[$int]};
		}

		$int++;
	}

	return %toreturn;
}

=head2 listValidKeys

This list the valid key possibilities.

The returned value is a array.

    my @validKeys=$foo->listValidKeys;

=cut

sub listValidKeys{
    my $self=$_[0];

    #try to blank the previous error
    if( ! $self->errorblank ){
        return undef;
    }

    return keys( %{ $self->{valid} } );
}

=head2 listWPAkeys

This is very similar to listValidKeys, but it does not include
'networkID', which represents the WPA supplicant network ID in
the config file, but is not a valid key in the the config.

    my @WPAkeys=$foo->listWPAkeys;

=cut

sub listWPAkeys{
    my $self=$_[0];

    #try to blank the previous error
    if( ! $self->errorblank ){
        return undef;
    }

    return keys( %{ $self->{wpaKeys} } );
}

=head2 setKey

This sets a key value.

Two values are taken. The first is the key and is required. The
second is the key value, which may be undefined.

No error checking is required as long as the the key is valid. No
value verification is done at this time.

    $foo->setKey( $key, $value );
    if( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setKey{
    my $self=$_[0];
    my $key=$_[1];
	my $value=$_[2];

    #try to blank the previous error
    if( ! $self->errorblank ){
        return undef;
    }

    #make sure we have a key
    if(!defined( $key )){
        $self->{error}=3;
        $self->{errorString}='No key specified';
        return undef;
    }

    #make sure it is a valid key
    if(!defined( $self->{valid}{$key} )){
        $self->{error}=2;
        $self->{errorString}='"'.$key.'" is not a valid key';
        return undef;
    }

	$self->{$key}=$value;

	return 1;
}

=head1 ERROR CODES

=head2 1

No SSID specified.

=head2 2

Invalid key.

=head2 3

No key specified.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-wireless-802_11-ap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Wireless-802_11-AP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Wireless::802_11::AP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Wireless-802_11-AP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Wireless-802_11-AP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Wireless-802_11-AP>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Wireless-802_11-AP/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::Wireless::802_11::AP
