package Net::Wireless::802_11::WPA::CLI;

use warnings;
use strict;
use base 'Error::Helper';
use String::ShellQuote;

=head1 NAME

Net::Wireless::802_11::WPA::CLI - Provides a interface to wpa_cli.

=head1 VERSION

Version 2.1.0

=cut

our $VERSION = '2.1.0';


=head1 SYNOPSIS

    use Net::Wireless::802_11::WPA::CLI;

    my $foo = Net::Wireless::802_11::WPA::CLI->new();
    ...

=head1 FUNCTIONS

=head2 new

This initializes the object to be used for making use of wpa_cli.

    my $foo->Net::Wireless::802_11::WPA::CLI->new();
    if( $foo->error ){
	    warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub new {
	my $socket=$_[1];

	my $self = {
		status=>undef,
		error=>undef,
		errorString=>'',
		perror=>undef,
		socket=>'',
		module=>'Net-Wireless-802_11-WPA-CLI',
		capabilities=>{
			eap=>1,
			pairwise=>1,
			group=>1,
			key_mgmt=>1,
			proto=>1,
			auth_alg=>1,
		},
	};
	bless $self;

	if( defined( $socket ) ){
		$self->{socket}='-p '.shell_quote($socket);
	}

	#tests if it is usable.
	my $command='wpa_cli '.$self->{socket}.' status';
	my $status=`$command`;
	if (!$? == 0){
		$self->{error}=1;
		$self->{errorString}='"'.$command.'" failed with "'.$status.'"';
		$self->warn;
		return $self;
	}

	my %statusH=status_breakdown($status);
	if ($self->error){
		$self->{perror}=1;
		return $self;
	};

	$self->{status}=\%statusH;

	return $self;
}

=head2 add_network

This adds a network.

No arguments are taken.

The returned value is a the new network ID.

	$newNetworkID=$foo->add_network;
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub add_network{
	my ($self)= @_;

	if(! $self->errorblank){
		return undef;
	}

	my $returned=$self->run_command('add_network');

	#this means there was a error running wpa_cli
	if($self->error){
		return undef;
	}

	#this means it failed
	if ($returned =~ /.*\nFAIL\n/){
		$self->{error}=5;
		$self->{errorString}='The commaned outputed a status of FAIL, but exited zero';
		return undef;
	}
	
	#remove the first line.
	$returned=~s/.*\n//;
	
	chomp($returned);
	
	return $returned;
}

=head2 bss

This requests additional information about a AP found in
scan_results.

A single argument is required and it is the BSSID.

The returned value is a hash.

=head3 returned hash

=head4 bssid

This is the BSSID in for the base station ID.

=head4 freq

This is the frequency in Mhz.

=head4 beacon_int

This is the beacon interval.

=head4 capabilities

This is the AP capabilities.

=head4 qual

This is the signal quality.

=head4 noise

This is the signal noise level.

=head4 level

This is the RSSI.

=head4 tsf

This is the timing syncronization function.

=head4 ie

This is what ever the ie value is.

=head4 flags

This is the flags for the AP.

=head4 ssid

This is the SSID for the for AP in question.

    my %status=$foo->bss($bssid);
    if( $foo->error ){
	    warn('Error:'.$foo->error.': '.$foo->errorString);
    }
    
=cut

sub bss{
	my ($self, $bssid)= @_;

	if(! $self->errorblank){
		return undef;
	}

	if(! defined( $bssid ) ){
		$self->{error}=4;
		$self->{errorString}='No BSSID specified';
		$self->warn;
		return undef;
	}

	$bssid=lc($bssid);

	#return if the netword ID is not numeric.
	my $macregexp='^[0123456789abcdef][0123456789abcdef]'.
		':[0123456789abcdef][0123456789abcdef]'.
		':[0123456789abcdef][0123456789abcdef]'.
		':[0123456789abcdef][0123456789abcdef]'.
		':[0123456789abcdef][0123456789abcdef]'.
		':[0123456789abcdef][0123456789abcdef]$';
		;
	if ($bssid !~ /$macregexp/){
		$self->{error}=4;
		$self->{errorString}='"'.$bssid.'" does not appear to be a valid BSSID';
		$self->warn;
		return undef;
	}

	my $command='wpa_cli '.$self->{socket}.' bss '.$bssid;
	my $status=`$command`;
	if (!$? == 0){
		$self->{error}=3;
		$self->{errorString}='"'.$command.'" failed with "'.$status.'"';
		$self->warn;
		return undef;
	}

	#this means it failed
	if ($status =~ /.*\nFAIL\n/){
		$self->{error}=5;
		$self->{errorString}='The commaned outputed a status of FAIL, but exited zero';
		return undef;
	}
	
	my %statusH=status_breakdown($status);
	if ($self->error){
		$self->warnString('status_breakdown failed');
		return undef;
	}
	
	$self->{status}={%statusH};
	
	return %statusH;
}

=head2 disconnect

Disconnect and wait for a reassosiate command.

No arguments are taken.

	$return=$foo->disconnect;
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub disconnect{
	my ($self, $bssid)= @_;

	if(! $self->errorblank){
		return undef;
	}

	return $self->run_TF_command('disconnect'. 0);
}

=head2 disable_network

This disables a network ID.

One argument is required and that is the network ID in question.

	$foo->disable_network($networkID)
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub disable_network{
	my ($self, $nid)= @_;

	if(! $self->errorblank){
		return undef;
	}

	#return if the netword ID is not numeric.
	if ($nid !~ /^[0123456789]*$/){
		$self->{error}=4;
		$self->{errorString}='non-numeric network ID used';
		$self->warn;
		return undef;
	}

	return $self->run_TF_command('disable_network '.$nid, 0);
}


=head2 enable_network

This enables a network ID.

One argument is required and that is the network ID to enable.

	$foo->enable_network($networkID)
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub enable_network{
	my ($self, $nid)= @_;

	if(! $self->errorblank){
		return undef;
	}

	#return if the netword ID is not numeric.
	if ($nid !~ /^[0123456789]*$/){
		$self->{error}=4;
		$self->{errorString}='non-numeric network ID used';
		$self->warn;
		return undef;
	}

	return $self->run_TF_command('enable_network '.$nid, 0);
}

=head2 get_capability

This returns the capabilities for the requested item. The capabilities
that can be requested are as below.

    eap
    pairwise
    group
    key_mgmt
    proto
    auth_alg

No arguments are taken.

	my @capabilities=$foo->get_capability('eap');
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub get_capability{
	my ($self, $request)= @_;

	if(! $self->errorblank){
		return undef;
	}

	if(!defined( $request )){
		$self->{error}=4;
		$self->{errorString}='No request specified';
		$self->warn;
		return undef;
	}

	#return if the netword ID is not numeric.
	if(!defined( $self->{capabilities}{$request} )){
		$self->{error}=4;
		$self->{errorString}='"'.$request.'" is not a valid capabilities request item';
		$self->warn;
		return undef;
	}

	my $returned=$self->run_command('get_capability '.$request);

	#this means there was a error running wpa_cli
	if($self->error){
		return undef;
	}

	#this means it failed
	if ($returned =~ /.*\nFAIL\n/){
		$self->{error}=5;
		$self->{errorString}='The commaned outputed a status of FAIL, but exited zero';
		return undef;
	}
	
	my @capabilities;

	my @returnedA=split(/\n/, $returned);

	chomp($returnedA[1]);

	@capabilities=split(/ /, $returnedA[1]);
	
	return @capabilities;
}

=head2 get_network

This gets a variable for for a specific network ID.

Two arguments are taken and that is the network ID and variable.

	$value=$foo->get_network($networkID, $variable);
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub get_network{
	my ($self, $nid, $variable)= @_;

	if(! $self->errorblank){
		return undef;
	}

	#return if the netword ID is not numeric.
	if ($nid !~ /^[0123456789]*$/){
		$self->{error}=4;
		$self->{errorString}='non-numeric network ID used';
		$self->warn;
		return undef;
	}

	my $returned=$self->run_command('get_network '.$nid.' '.$variable);

	#this means there was a error running wpa_cli
	if(!defined($returned)){
		return undef;
	}

	#this means it failed
	if ($returned =~ /.*\nFAIL\n/){
		return undef;
	}
	
	#remove the first line.
	$returned=~s/.*\n//;
	
	return $returned;
}

=head2 list_networks

This lists the configured networks.

No arguments are taken.

The returned value is a hash.

=head3 returned hash.

The keys for the hash is the numeric network ID. Each
item in the hash is a hash. The keys are listed below.

=head4 ssid

This is the SSID of the network in question.

=head4 bssid

This is the BSSID of the network in question. If not specified,
it will be set to 'any'.

=head4 flags

This is the flags for the network. This key may not be defined.

	%return=$foo->list_networks;
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub list_networks{
	my ($self)= @_;

	if(! $self->errorblank){
		return undef;
	}

	my $returned=$self->run_command('list_networks');

	#this means there was a error running wpa_cli
	if($self->error){
		return undef;
	}

	#this means it failed
	if ($returned =~ /.*\nFAIL\n/){
		$self->{error}=5;
		$self->{errorString}='The commaned outputed a status of FAIL, but exited zero';
		return undef;
	}
	
	my @returnedA=split(/\n/, $returned);
	
	#this will be returned
	my %hash=();
	
	my $returnedAint=2;
	while(defined($returnedA[$returnedAint])){
		chomp($returnedA[$returnedAint]);

		my @linesplit=split(/\t/, $returnedA[$returnedAint]);

		my $nid=$linesplit[0];

		$hash{$nid}={};

		if(defined( $linesplit[3] )){
			$hash{$nid}{flags}=$linesplit[3];
		}

		$hash{$nid}{bssid}=$linesplit[2];

		$hash{$nid}{ssid}=$linesplit[1];

		$returnedAint++;
	}
	
	return %hash;
}

=head2 new_password

This sets a new password for a network.

Two arguments are taken. The first is the network ID and
the second is the new password.

	$return=$foo->new_password($networkID, $newpass);
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub new_password{
	my ($self, $nid, $value)= @_;

	if(! $self->errorblank){
		return undef;
	}

	#return if the netword ID is not numeric.
	if ($nid !~ /^[0123456789]*$/){
		$self->{error}=4;
		$self->{errorString}='non-numeric network ID used';
		$self->warn;
		return undef;
	}

	return $self->run_TF_command('new_password '.$nid.' '.$value, 0);
}

=head2 pin

This sets the pin for a network.

Two arguments are taken. The first is the network ID and the second is the pin.

	$foo->pin($networkID, $newpin);
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub pin{
	my ($self, $nid, $value)= @_;

	if(! $self->errorblank){
		return undef;
	}

	#return if the netword ID is not numeric.
	if ($nid !~ /^[0123456789]*$/){
		$self->{error}=4;
		$self->{errorString}='non-numeric network ID used';
		$self->warn;
		return undef;
	}

	return $self->run_TF_command('pin '.$nid.' '.$value, 0);
}

=head2 preauthenticate

Force preauthentication for a BSSID.

One argument is accepted and the is the BSSID in question.

	$foo->preauthenticate($BSSID);
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub preauthenticate{
	my ($self, $bssid)= @_;

	if(! $self->errorblank){
		return undef;
	}

	return $self->run_TF_command('preauthenticate '.$bssid, 0);
}

=head2 reassociate

This saves the current configuration. The user requesting this
does not need write permissions to file being used 

It takes no arguments.

    $foo->reassociate;
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub reassociate{
	my ($self)= @_;

	if(! $self->errorblank){
		return undef;
	}

	return $self->run_TF_command('reassociate', 0);
}

=head2 reconfigure

This causes wpa_supplicant to reread it's configuration file.

No arguments are taken.

	$return=$obj->reconfigure;
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub reconfigure{
	my ($self)= @_;

	if(! $self->errorblank){
		return undef;
	}

	return $self->run_TF_command('reconfigure', 0);
}

=head2 remove_network

This removes the specified network.

One argument is accepted and it the network ID.

	$return=$foo->remove_network($networkID)
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub remove_network{
	my ($self, $nid)= @_;

	if(! $self->errorblank){
		return undef;
	}

	#return if the netword ID is not numeric.
	if ($nid !~ /^[0123456789]*$/){
		$self->{error}=4;
		$self->{errorString}='non-numeric network ID used';
		$self->warn;
		return undef;
	}

	return $self->run_TF_command('remove_network '.$nid, 0);
}

=head2 save_config

This saves the current configuration. The user requesting this
does not need write permissions to file being used 

No arguments are taken.

	my $returned=$foo->save_config;
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub save_config{
	my ($self)= @_;

	if(! $self->errorblank){
		return undef;
	}

	return $self->run_TF_command('save_config');
}

=head2 scan

This requests a new BSS scan.

No arguments are taken.

	my $returned=$foo->scan;
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub scan{
	my ($self)= @_;

	if(! $self->errorblank){
		return undef;
	}

	return $self->run_TF_command('scan');
}

=head2 scan_results

This returns the scan results.

No arguments are taken.

The returned value is a hash.

=head3 returned hash

Each keys of the hash is a BSSID. It's value is another hash
with the keys listed below.

=head4 ssid

This is the SSID for the AP.

=head4 frequency

This is the frequency of the AP. The value is in Mhz.

=head4 signallevel

This is the signal level of the seen AP.

=head4 flags

This is the flags for the AP.

	my %scan=$foo->scan_results;
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }else{
        
        print "BSSID, SSID, FREQ, SIGNAL, FLAGS\n";
        
        my @keys=keys(%scan);
        my $int=0;
        while( defined( $keys[$int] ) ){
            print $keys[$int].', '.$scan{$keys[$int]}{ssid}.', '.
                $scan{$keys[$int]}{frequency}.', '
                .$scan{$keys[$int]}{signal}.', '
                .$scan{$keys[$int]}{flags};
            
            $int++;
        }
    }

=cut

sub scan_results{
	my ($self)= @_;

	if(! $self->errorblank){
		return undef;
	}

	my $returned=$self->run_command('scan_results');

	#this means there was a error running wpa_cli
	if($self->error){
		return undef;
	}

	#this means it failed
	if ($returned =~ /.*\nFAIL\n/){
		$self->{error}=5;
		$self->{errorString}='The commaned outputed a status of FAIL, but exited zero';
		return undef;
	}
	
	my @returnedA=split(/\n/, $returned);
	
	#this will be returned
	my %hash=();
	
	my $returnedAint=2;
	while(defined($returnedA[$returnedAint])){
		chomp($returnedA[$returnedAint]);

		my @linesplit=split(/\t/, $returnedA[$returnedAint]);

		my $bssid=$linesplit[0];

		$hash{$bssid}={};

		$hash{$bssid}{frequency}=$linesplit[1];
		
		$hash{$bssid}{signallevel}=$linesplit[2];

		$hash{$bssid}{flags}=$linesplit[3];

		$hash{$bssid}{ssid}=$linesplit[4];

		$returnedAint++;
	}
	
	return %hash;
}

=head2 select_network

This is the network ID to select, while disabling the others.

One argument is accepted and it is the network ID to select.

	$return=$foo->select_network($networkID)
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub select_network{
	my ($self, $nid)= @_;

	if(! $self->errorblank){
		return undef;
	}

	#return if the netword ID is not numeric.
	if ($nid !~ /^[0123456789]*$/){
		$self->{error}=4;
		$self->{errorString}='non-numeric network ID used';
		$self->warn;
		return undef;
	}

	return $self->run_TF_command('select_network '.$nid, 0);
}

=head2 set_network

This sets a variable for for a specific network ID.

Three arguments are taken. The first is the network ID,
the second is the variable to set, and the third is the
value to set it to.

	$foo->set_network($networkID, $variable, $value);
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub set_network{
	my ($self, $nid, $variable, $value)= @_;

	if(! $self->errorblank){
		return undef;
	}

	#return if the netword ID is not numeric.
	if ($nid !~ /^[0123456789]*$/){
		$self->{error}=4;
		$self->{errorString}='non-numeric network ID used';
		$self->warn;
		return undef;
	}

	return $self->run_TF_command('set_network '.$nid.' '.$variable.' '.$value, 0);
}

=head2 status

This function gets the current status from wpa_cli.

No arguments are taken.

    my %status=$foo->status;
    if( $foo->error ){
	    warn('Error:'.$foo->error.': '.$foo->errorString);
    }
    
=cut

sub status{
	my ($self)= @_;

	if(! $self->errorblank){
		return undef;
	}

	my $command='wpa_cli '.$self->{socket}.' status';
	my $status=`$command`;
	if (!$? == 0){
		$self->{error}=3;
		$self->{errorString}='"'.$command.'" failed with "'.$status.'"';
		$self->warn;
		return undef;
	}

	if ($status =~ /.*\nFAIL\n/){
		$self->{error}=5;
		$self->{errorString}='The commaned outputed a status of FAIL, but exited zero';
		return undef;
	}	

	my %statusH=status_breakdown($status);
	if ($self->error){
		$self->warnString('status_breakdown failed');
		return undef;
	}
	
	$self->{status}={%statusH};
	
	return %statusH;
}

=head2 mib

This gets the MIB variables (dot1x, dot11).

	%return=$foo->mib;
    if( $foo->error ){
	    warn('error:'.$foo->error.': '.$foo->errorString);
	}

=cut

sub mib{
	my ($self)= @_;

	if(! $self->errorblank){
		return undef;
	}

	my $returned=$self->run_command('mib');

	if($self->error){
		return undef;
	}

	#this means it failed
	if ($returned =~ /.*\nFAIL\n/){
		$self->{error}=5;
		$self->{errorString}='The commaned outputed a status of FAIL, but exited zero';
		return undef;
	}
	
	my %hash=status_breakdown($returned, 'mib');
	
	return %hash;
}

=head2 run_TF_command

This runs a arbirary command in which the expected values are
either 'FAIL' or 'OK'. This function is largely intended for internal
use by this module.

It takes two argument. The first is string containing the command and any
arguments for it. The second is what to return on a unknown return.

A status of 'FAIL' will also set a error of 5.

A unknown status will also set a error of 6.

	$returned=$foo->run_TF_command($command, 0);
    if( $foo->error ){
	    warn('error:'.$foo->error.': '.$foo->errorString);
	}

=cut

sub run_TF_command{
	my ($self, $command, $onend)= @_;

	if(! $self->errorblank){
		return undef;
	}

	my $torun='wpa_cli '.$self->{socket}.' '.$command;
	my $status=`$torun`;
	if (!$? == 0){
		$self->{error}=3;
		$self->{errorString}="wpa_cli failed with '".$status."'"."for '".$command."'";
		$self->warn;
		return undef;
	}

	#return 0 upon failure
	if ($status =~ /.*\nFAIL\n/){
		$self->{error}=5;
		$self->{errorString}='The commaned outputed a status of FAIL, but exited zero';
		return 0;
	}

	#return 1 upon success
	if ($status =~ /.*\nOK\n/){
		return 1;
	}

	#unknwon so set error 6
	$self->{error}=6;
	$self->{errorString}='Unknown return of "'.$status.'"';

	return $onend;
}

=head2 run_command

This runs a arbirary command in which. This function is largely intended for
internal use by this module.

It takes argument, which is string containing the command and any
arguments for it.

UNDEF is returned upon with running wpa_cli. Otherwise the return is the return
from executed command.

	$returned=$foo->run_command($command)
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub run_command{
	my ($self, $command)= @_;

	if(! $self->errorblank){
		return undef;
	}

	my $torun='wpa_cli '.$self->{socket}.' '.$command;
	my $status=`$torun`;
	if (!$? == 0){
		warn("wpa_cli failed with '".$status."'"."for '".$command."'");
		return undef;
	}

	return $status;
}

=head2 status_breakdown

This is a internal function.

=cut

#this is a internal function used by this module
#It breaks down that return from status.
sub status_breakdown{
	my $statusS=$_[0];
	my $type=$_[1];

	my %hash;
	
	my @statusA=split(/\n/, $statusS);
	
	if (!defined($type)){
		$type="status"
	}
	
	if ( $statusA[0] !~ /^Selected interface/){
		return undef;
	}
	
	my @interfaceA=split(/\'/, $statusA[0]);
	
	$hash{interface}=$interfaceA[1];
	
	my $statusAint=1;
	while(defined($statusA[$statusAint])){
		chomp($statusA[$statusAint]);
		my @linesplit=split(/=/, $statusA[$statusAint]);
		$hash{$linesplit[0]}=$linesplit[1];
		
		$statusAint++;
	}
	
	return %hash;
}

=head1 NOTES

This makes use of wpa_cli in a non-interactive form. This means that
interface and otp are not usable.

Better documentation and etc shall be coming shortly. Publishing this and starting work
on something that uses it in it's current form.

=head1 ERROR CODES

=head2 1

Unable to to initialize the object. A wpa_cli status check failed.

This error is permanent.

=head2 2

Status breakdown failed because of a unexpected return.

=head2 3

Command failed and exited with a non-zero.

=head2 4

Invalid argument supplies.

=head2 5

The executed command exited with zero, but still failed.

This error code is not warned for.

=head2 6

Unknown return.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-wireless-802_11--wpa-cli at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Wireless-802_11-WPA-CLI>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Wireless::802_11::WPA::CLI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Wireless-802_11-WPA-CLI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Wireless-802_11-WPA-CLI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Wireless-802_11-WPA-CLI>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Wireless-802_11-WPA-CLI>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2011 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Net::Wireless::802_11::WPA::CLI
