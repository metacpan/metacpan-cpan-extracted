package Net::LDAP::AutoServer;

use warnings;
use strict;
use Sys::Hostname;
use Net::LDAP;
use Net::DNS::Resolver;
use Net::DNS::RR::SRV::Helper;

=head1 NAME

Net::LDAP::AutoServer - Automated LDAP server choosing.

=head1 VERSION

Version 0.2.1

=cut

our $VERSION = '0.2.1';


=head1 SYNOPSIS

    use Net::LDAP::AutoServer;

    my $as = Net::LDAP::AutoServer->new();

=head1 METHODS

=head2 new

=head3 args hash

=head4 methods

This is the methods to use to for getting the information.

It is taken in a camma seperated list with the default being
'hostname,dns,devldap,env,user'.

The available values are listed below.

    hostname
    devldap
    env
    user

=cut

sub new{
	my %args;
	if (defined($_[1])) {
		%args=%{$_[1]};
	}
	
	my $self={
			  error=>undef,
			  server=>undef,
			  port=>undef,
			  CAfile=>undef,
			  CApath=>undef,
			  checkCRL=>undef,
			  clientCert=>undef,
			  clientKey=>undef,
			  bind=>undef,
			  pass=>undef,
			  };
	bless $self;

	if (defined($args{methods})) {
		$self->{methods}=$args{methods};
	}else {
		$self->{methods}='hostname,dns,devldap,env,user';
	}

	#runs through the methodes and finds one to use
	my @split=split(/,/, $self->{methods}); #splits them apart at every ','
	my $splitInt=0;
	while (defined($split[$splitInt])){
		#handles it via the env method
		if ($split[$splitInt] eq "devldap") {
			$self->byDevLDAP();
		}

		#handles it via the env method
		if ($split[$splitInt] eq "env") {
			$self->byEnv();
		}

		#handles it if it if using the DNS method
		if ($split[$splitInt] eq "dns") {
			$self->byDNS();
		}

		#handles it if it if using the hostname method
		if ($split[$splitInt] eq "hostname") {
			$self->byHostname();
		}

		#handles it if it if using the user method
		if ($split[$splitInt] eq "user") {
			$self->byUser();
		}

		$splitInt++;
	}

	return $self;
}

=head2 byDevLDAP

This fetches it using /dev/ldap/ if possible.

It will return false if /dev/ldap/ is not a directory
or does not resit.

=head3 POPULATES

    bind
    CAfile
    CApath
    checkCRL
    clientCert
    clientKey
    pass
    port
    server

    my $returned=$autoserver->byDevLDAP;

=cut

sub byDevLDAP{
	my $self=$_[0];

	if (! -d '/dev/ldap/server') {
		return undef;
	}

	my %opts;

	open('SERVER', '<', '/dev/ldap/server');
	$opts{server}=join('', <SERVER>);
	close('SERVER');
	
	open('CAFILE', '<', '/dev/ldap/CAfile');
	$opts{CAfile}=join('', <CAFILE>);
	close('CAFILE');

	open('CAPATH', '<', '/dev/ldap/CApath');
	$opts{CApath}=join('', <CAPATH> );
	close('CAPATH');

	open('CHECKCRL', '<', '/dev/ldap/checkCRL');
	$opts{checkCRL}=join('', <CHECKCRL>);
	close('CHECKCRL');

	open('PORT', '<', '/dev/ldap/port');
	$opts{port}=join('', <PORT>);
	close('PORT');

	open('CLIENTCERT', '<', '/dev/ldap/clientCert');
	$opts{clientCert}=join('', <CLIENTCERT>);
	close('CLIENTCERT');

	open('CLIENTKEY', '<', '/dev/ldap/clientKey');
	$opts{clientKey}=join('', <CLIENTKEY>);
	close('CLIENTKEY');

	open('STARTTLS', '<', '/dev/ldap/startTLS');
	$opts{startTLS}=join('', <STARTTLS>);
	close('STARTTLS');

	my @vars=('server', 'CAfile', 'CApath', 'checkCRL',
			  'port', 'clientCert', 'clientKey', 'startTLS');
	
	#
	my $int=0;
	while (defined( $vars[$int] )) {
		if ( defined($opts{ $vars[$int] }) && ($opts{$vars[$int]} ne 'undef') ) {
			$self->{ $vars[$int] }=$opts{ $vars[$int] };
		}
		
		$int++;
	}

	return 1;
}

=head2 byDNS

This only populates the server field.

This will run s/^[0-9a-zA-Z\-\_]*\./ldap./ over
the hostname then try to connect to it.

If it can't lookup the hostname or connect,
it returns undef.

Once connected, it will check to see if it is
possible to start TLS.

=head3 POPULATES

    startTLS
    server
    port

=cut

sub byDNS{
	my $self=$_[0];

	my $hostname=hostname;

	$hostname=~s/^[0-9a-zA-Z\-\_]*\./_ldap._tcp./;

	#gets a list of SRV records for the hostname
	my $res=Net::DNS::Resolver->new;
	my $query=$res->query($hostname, "SRV");

	#makes sure something was found
	if (!defined($query)) {
		return undef
	}

	my @records=$query->answer;

	#sorts the records
	my @orderedSRV=SRVorder(\@records);

	#make sure we have one
	if (!defined($orderedSRV[0])) {
		return undef;
	}

	#searches each one for one that works
	my $int=0;
	while (defined($orderedSRV[$int])) {
		my $ldap=Net::LDAP->new($orderedSRV[$int]->{server}, port=>$orderedSRV[$int]->{port} );
		
		#process it, if it worked
		if ($ldap) {
			my $mesg=$ldap->start_tls;
			
			if (!$mesg->is_error) {
				$self->{startTLS}=1;
			}else {
				$self->{startTLS}=undef;
			}
			
			$self->{server}=$orderedSRV[$int]->{server};
			$self->{port}=$orderedSRV[$int]->{port};

			return 1;
		}

		$int++;
	}

	return undef;
}

=head2 byEESDPenv

This will populate as much as possible using enviromental
variables.

=head3 ENVIROMENTAL VARIABLES

EESDP-BindDN
EESDP-CAfile
EESDP-CApath
EESDP-CheckCRL
EESDP-ClientCert
EESDP-ClientKey
EESDP-Port
EESDP-Server
EESDP-StartTLS

=head3 POPULATES

    bind
    CAfile
    CApath
    checkCRL
    clientCert
    clientKey
    port
    server
    startTLS

=cut

sub byEESDPenv{
	my $self=$_[0];

	#sets the bind, if it is defined
	if (defined($ENV{'EESDP-BindDN'})) {
		$self->{bind}=$ENV{'EESDP-BindDN'};
	}

	#sets the CAfile, if it is defined
	if (defined($ENV{'EESDP-CAfile'})) {
		$self->{CAfile}=$ENV{'EESDP-CAfile'};
	}

	#sets the CApath, if it is defined
	if (defined($ENV{'EESDP-CApath'})) {
		$self->{CApath}=$ENV{'EESDP-CApath'};
	}

	#sets the checkCRL, if it is defined
	if (defined($ENV{'EESDP-CheckCRL'})) {
		$self->{clientCert}=$ENV{'EESDP-checkCRL'};
	}

	#sets the clientCert, if it is defined
	if (defined($ENV{'EESDP-ClientCert'})) {
		$self->{clientCert}=$ENV{'EESDP-ClientCert'};
	}

	#sets the clientKey, if it is defined
	if (defined($ENV{'EESDP-ClientKey'})) {
		$self->{clientKey}=$ENV{'EESDP-ClientKey'};
	}

	#sets the port, if it is defined
	if (defined($ENV{'EESDP-Port'})) {
		$self->{port}=$ENV{'EESDP-port'};
	}

	#sets the server, if it is defined
	if (defined($ENV{'EESDP-Server'})) {
		$self->{server}=$ENV{'EESDP-Server'};
	}

	#sets the startTLS, if it is defined
	if (defined($ENV{'EESDP-StartTLS'})) {
		$self->{startTLS}=$ENV{'EESDP-StartTLS'};
	}

	return 1;
}

=head2 byEnv

This will populate as much as possible using enviromental
variables.

=head3 ENVIROMENTAL VARIABLES

    Net::LDAP::AutoServer-bind
    Net::LDAP::AutoServer-CAfile
    Net::LDAP::AutoServer-CApath
    Net::LDAP::AutoServer-checkCRL
    Net::LDAP::AutoServer-clientCert
    Net::LDAP::AutoServer-clientkey
    Net::LDAP::AutoServer-port
    Net::LDAP::AutoServer-server
    Net::LDAP::AutoServer-startTLS

=head3 POPULATES

    bind
    CAfile
    CApath
    checkCRL
    clientCert
    clientKey
    port
    server
    startTLS

=cut

sub byEnv{
	my $self=$_[0];

	my @vars=('bind', 'CAfile', 'CApath', 'checkCRL', 'startTLS',
			  'clientCert', 'clientKey', 'port', 'server');

	my $int=0;
	while (defined($vars[$int])) {
		if (defined($ENV{'Net::LDAP::AutoServer-'.$vars[$int]})) {
			$self->{$vars[$int]}=$ENV{'Net::LDAP::AutoServer-'.$vars[$int]};
		}

		$int++;
	}

	return 1;
}

=head2 byHostname

This only populates the server field.

This will run s/^[0-9a-zA-Z\-\_]*\./ldap./ over
the hostname then try to connect to it.

If it can't lookup the hostname or connect,
it returns undef.

Once connected, it will check to see if it is
possible to start TLS.

=head3 POPULATES

    startTLS
    server
    port

=cut

sub byHostname{
	my $self=$_[0];

	my $hostname=hostname;

	$hostname=~s/^[0-9a-zA-Z\-\_]*\./ldap./;

	my ($name,$aliases,$addrtype,$length,@addrs) = gethostbyname($hostname);

	if (!defined($addrs[0])) {
		return undef;
	}

	my $ldap=Net::LDAP->new($hostname);

	if (!$ldap) {
		return undef;
	}
	
	my $mesg=$ldap->start_tls;

	if (!$mesg->is_error) {
		$self->{startTLS}=1;
	}else {
		$self->{startTLS}=undef;
	}

	$self->{port}='389';
	$self->{server}=$hostname;

	return 1;
}

=head2 byUser

This only populates the server field.

This requires $ENV{USER} to be defined. If
it is not, undef is returned.

This looks for '~/.ldappass' and '~/.ldapbind'.

=head3 POPULATES

    bind
    pass

    my $returned=$autoserver->byUser;

=cut

sub byUser{
	my $self=$_[0];

	if (!defined($ENV{USER})) {
		return undef;
	}

	my ($name,$passwd,$uid,$gid,
		$quota,$comment,$gcos,$dir,$shell,$expire)=getpwnam($ENV{USER});

	if (-f $dir.'/.ldapbind') {
		if ( open('USERBIND', '<', $dir.'/.ldapbind') ){
			$self->{bind}=join('', <USERBIND>);
			close('USERBIND');
		}
	}

	if (-f $dir.'/.ldappass') {
		if ( open('USERPASS', '<', $dir.'/.ldappass') ){
			$self->{pass}=join('', <USERPASS>);
			close('USERPASS');
		}
	}

	return 1;
}

=head2 clear

This clears all previous selections.

    $autoserver->clear;

=cut

sub clear{
	my $self=$_[0];
	
	$self->{server}=undef;
	$self->{port}=undef;
	$self->{CAfile}=undef;
	$self->{CApath}=undef;
	$self->{checkCRL}=undef;
	$self->{clientCert}=undef;
	$self->{clientKey}=undef;
	$self->{bind}=undef;
	$self->{pass}=undef;
	
	return 1;
}

=head2 connect

This forms a LDAP connections.

    my ($ldap, $mesg, $success, $errorString)=$autoserver->connect;
    if(!$success){
        if(!$ldap){
            print "Failed to connect to LDAP either bad info or none present.\n";
        }else{
            print "Failed to bind or start TLS.\n".
                  $mesg->error_desc."\n";
        }
    }

=cut

sub connect{
	my $self=$_[0];

	#makes sure we have a server specified
	if (!defined( $self->{server} )) {
		return (undef, undef, undef);
	}

	#connect
	my $error=undef;
	my $ldap=Net::LDAP->new($self->{server}.':'.$self->{port});

	#failed to connect
	if (!$ldap) {
		return ($ldap, undef, undef, $@);
	}

	my $mesg;

	#start TLS if needed 
	if ($self->{startTLS}) {
		$mesg=$ldap->start_tls(
							   capath=>$self->{CApath},
							   cafile=>$self->{CAfile},
							   clientcert=>$self->{clientCert},
							   clientkey=>$self->{clientKey},
							   checkcrl=>$self->{checkCRL},
							   );
		if ($mesg->is_error) {
			return ($ldap, $mesg, undef, $mesg->error_desc);
		}
	}

	#bind and make sure it is successful
	$mesg=$ldap->bind($self->{bind}, password=>$self->{pass});
	if ($mesg->is_error) {
		return ($ldap, $mesg, undef, $mesg->error_desc);
	}

	return ($ldap, $mesg, 1, undef);
}

=head1 /DEV/LDAP

More information about this can be found at the URL below.

L<http://eesdp.org/eesdp/ldap-kmod.html>

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ldap-autoserver at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-AutoServer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::AutoServer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-AutoServer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LDAP-AutoServer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LDAP-AutoServer>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LDAP-AutoServer/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Net::LDAP::AutoServer
