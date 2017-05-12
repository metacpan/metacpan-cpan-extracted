package Net::Wireless::802_11::WPA::CLI::Helper;

use warnings;
use strict;
use base 'Error::Helper';
use Net::Wireless::802_11::AP;
use Net::Wireless::802_11::WPA::CLI;

=head1 NAME

Net::Wireless::802_11::WPA::CLI::Helper - Provides various helper functions for working with Net::Wireless::802_11::WPA::CLI.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Net::Wireless::802_11::WPA::CLI::Helper;
    use Net::Wireless::802_11::WPA::CLI;

    my $cli=Net::Wireless::802_11::WPA::CLI->new;

    my $foo = Net::Wireless::802_11::WPA::CLI::Helper->new($cli);
    ...

=head1 METHODS

=head2 new

This initializes the object.

There is one argument taken and that is a Net::Wireless::802_11::WPA::CLI object.
If not specified, a Net::Wireless::802_11::WPA::CLI object is initiated
with the defaults.

    my $foo=Net::Wireless::802_11::WPA::CLI::Helper->new($cli);
    if ( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
	}

=cut

sub new{
	my $cli=$_[1];

	my $self={
		error=>undef,
		errorString=>'',
		perror=>undef,
	};
	bless $self;

	if( !defined( $cli ) ){
		$cli=Net::Wireless::802_11::WPA::CLI->new;
		if( $cli->error ){
			$self->{perror}=1;
			$self->{error}=1;
			$self->{errorString}='No object specified and failed to initiate one. '.
				'error="'.$cli->error.'" '.
				'errorString="'.$cli->errorString.'"';
			$self->warn;
			return $self;
		}
	}

	#make sure a valid cli object is specified
	if ( ref($cli) ne 'Net::Wireless::802_11::WPA::CLI' ){
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='No Net::Wireless::802_11::WPA::CLI specified';
		$self->warn;
		return $self;
	}

	$self->{cli}=$cli;

	return $self;
}

=head2 apObj2network

This writes a Net::Wireless::802_11::AP to a network ID.

One argument is taken and that is the Net::Wireless::802_11::AP
object. It requires the variable 'networkID' to be specified. This
is the network ID that it will be writen to.

    $foo->apObj2network($ap);
    if ($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub apObj2network{
	my $self=$_[0];
	my $ap=$_[1];

	if(!$self->errorblank){
		return undef;
	}

	if(!defined( $ap )){
		$self->{error}=2;
		$self->{errorString}='No Net::Wireless::802_11::AP defined';
		$self->warn;
		return undef;
	}

	if( ref($ap) ne 'Net::Wireless::802_11::AP' ){
		$self->{error}=2;
		$self->{errorString}='The passed object is not a Net::Wireless::802_11::AP';
		$self->warn;
		return undef;
	}

	#figure out what the network ID is
	my $nid=$ap->getKey('networkID');
	if(defined( $nid )){
		if( ! $self->NIDexists($nid) ){
			$self->{error}=4;
			$self->{errorString}='The network ID, "'.$nid.'", does not exist';
			$self->warn;
			return undef;
		}
	}else{
		$self->{error}=6;
		$self->{errorString}='The variable "networkID" is not present in the Net::Wireless::802_11::AP object';
		$self->warn;
		return undef;
	}

	my @WPAkeys=$ap->listWPAkeys;
	my $int=0;
	while( defined( $WPAkeys[$int] ) ){
		my $value=$ap->getKey( $WPAkeys[$int] );

		if( defined( $value ) ){
			$self->{cli}->set_network( $nid, $WPAkeys[$int], $value );
		}

		$int++;
	}
	
	return 1;
}

=head2 network2APobj

This converts a specified configured network to a
Net::Wireless::802_11::AP object.

One agrument is required and it is a network ID.

    my %APobj=$foo->network2APobj('0');
    if ($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub network2APobj{
	my $self=$_[0];
	my $nid=$_[1];

	if(!$self->errorblank){
		return undef;
	}

	if(!defined($nid)){
		$self->{error}=2;
		$self->{errorString}='No network ID specified';
		$self->warn;
		return undef;
	}

	if( $nid !~ /^[0123456789]*$/ ){
		$self->{error}=2;
		$self->{errorString}='The network ID is not specified';
		$self->warn;
		return undef;
	}

	if(!$self->NIDexists($nid)){
		$self->{error}=4;
		$self->{errorString}='The network ID, "'.$nid.'", does not exist';
		$self->warn;
		return undef;
	}
	
	my $ssid=$self->{cli}->get_network($nid, 'ssid');
	if(!defined( $ssid )){
		$self->{error}=5;
		$self->{errorString}='Unable to get the SSID for "'.$nid.'"';
		$self->warn;
		return undef;
	}

	my $ap=Net::Wireless::802_11::AP->new({ ssid=>$ssid, networkID=>$nid });

	$ap->setKey('networkID', $nid);
	
	my @WPAkeys=$ap->listWPAkeys;
	my $int=0;
	while( defined( $WPAkeys[$int] ) ){
		my $value=$self->{cli}->get_network($nid, $WPAkeys[$int]);

		if(defined($value)){
			$ap->setKey($WPAkeys[$int], $value);
		}

		$int++;
	}

	return $ap;
}

=head2 networks2APobjs

This converts all configured networks to a hash of
Net::Wireless::802_11::AP objects. The keys used is
the network ID.

    my %APobj=$foo->networks2APobj;
    if ($foo->error){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub networks2APobjs{
	my $self=$_[0];

	if(!$self->errorblank){
		return undef;
	}

	my %networks=$self->{cli}->list_networks;
	if($self->{cli}->error){
		$self->{error}=3;
		$self->{errorString}='Net::Wireless::802_11::WPA::CLI errored. '.
			'error="'.$self->{cli}->error.'" '.
			'errorString="'.$self->{cli}->errorString.'"';
		$self->warn;
		return undef;
	}

	my @NIDs=keys(%networks);

	my $int=0;
	my %toreturn;
	while( defined($NIDs[$int]) ){
		my $ap=$self->network2APobj($NIDs[$int]);

		if( ! $self->error ){
			$toreturn{$NIDs[$int]}=$ap;
		}

		$int++;
	}
	
	return %toreturn;
}

=head2 NIDexists

This verifies a that a network ID exists.

One argument is taken and it is the numeric network ID.

The returned value is boolean.

    my $exists=$foo->NIDexists('0');
    if( $foo->error ){
        warn('Error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub NIDexists{
	my $self=$_[0];
	my $nid=$_[1];

	if(!$self->errorblank){
		return undef;
	}

	if(!defined($nid)){
		$self->{error}=2;
		$self->{errorString}='No network ID specified';
		$self->warn;
		return undef;
	}

	if( $nid !~ /^[0123456789]*$/ ){
		$self->{error}=2;
		$self->{errorString}='The network ID is not specified';
		$self->warn;
		return undef;
	}

	my %networks=$self->{cli}->list_networks;
	if( $self->{cli}->error ){
		$self->{error}=3;
		$self->{errorString}='Net::Wireless::802_11::WPA::CLI errored. '.
			'error="'.$self->{cli}->error.'" '.
			'errorString="'.$self->{cli}->errorString.'"';
		$self->warn;
		return undef;
	}

	return defined( $networks{$nid} );
}

=head1 ERROR CODES

=head2 1

No Net::Wireless::802_11::WPA::CLI::Helper specified or initialize a new instance.

This is a permanent error.

=head2 2

There was an error with the argument.

=head2 3

Net::Wireless::802_11::WPA::CLI errored.

=head2 4

The network ID does not exist.

=head2 5

Unable to fetch a SSID for a network ID.

=head2 6

The Net::Wireless::802_11::AP does not have a the variable 'networkID' specified.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS
"
Please report any bugs or feature requests to C<bug-net-wireless-802_11-wpa-cli-helper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Wireless-802_11-WPA-CLI-Helper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Wireless::802_11::WPA::CLI::Helper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Wireless-802_11-WPA-CLI-Helper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Wireless-802_11-WPA-CLI-Helper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Wireless-802_11-WPA-CLI-Helper>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Wireless-802_11-WPA-CLI-Helper/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::Wireless::802_11::WPA::CLI::Helper
