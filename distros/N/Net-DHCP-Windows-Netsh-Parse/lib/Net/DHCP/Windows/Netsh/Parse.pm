package Net::DHCP::Windows::Netsh::Parse;

use 5.006;
use strict;
use warnings;
use JSON;

=head1 NAME

Net::DHCP::Windows::Netsh::Parse - Parses the output from 'netsh dhcp server dump'

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use Net::DHCP::Windows::Netsh::Parse;

    my $parser=Net::DHCP::Windows::Netsh::Parse->new;
    
    eval{
        $parser->parse( $dump );
    };
    if ( $@ ){
        print "It failed with... ".$@."\n";
    }
    
    # no white space
    my $json=$parser->json(0);
    
    # now with useful white space
    $json=$parser->json(0);

=head1 METHODS

=head2 new

This initiates the object.

No arguments are taken.

    my $parser=Net::DHCP::Windows::Netsh::Parse->new;

=cut

sub new {
	my $self={
			  servers=>{},
			  };
	bless $self;

	return $self;
}

=head2 parse

This parses a dump from netsh.

Only one option is taken and that is a string.

Nothing is returned. It will die if it fails to parse.

    eval{
        $parser->parse( $dump );
    };
    if ( $@ ){
        print "It failed with... ".$@."\n";
    }

=cut

sub parse{
	my $self=$_[0];
	my $data=$_[1];

	if ( ! defined( $data ) ){
		die( 'Nothing defined to parse' );
	}

	# break it appart and grab only the relevant lines
	# removing the pointless comments and blank lines
	my @lines=grep( /^Dhcp\ Server/ , split( /\n/, $data ));

	# Don'y really care about lines matching like....
	# Dhcp Server \\winboot Add Class "Default Routing and Remote Access Class" "User class for remote access clients" 525241532e4d6963726f736f6674 0 b
	# Dhcp Server \\winboot Set DatabaseName "dhcp.mdb"
	# Dhcp Server \\winboot Add Optiondef 36 "Ethernet Encapsulation" BYTE 0 comment="0=>client should use ENet V2; 1=> IEEE 802.3" 0
	# Dhcp Server \\winboot v6 Add Class "Microsoft Windows Options" "Microsoft vendor-specific options for Windows Clients" 4d53465420352e30 1 b 311
	# Dhcp Server \\winboot v6 Add Optiondef 21 "SIP Server Domain Name List " STRING 1 comment="Domain Name of SIP servers available to the client " ""
	#
	# set is case sensitive... we want stuff like...
	# Dhcp Server \\winboot set optionvalue 15 STRING "foo.bar"
	@lines=grep( !/^Dhcp\ Server\ [\\A-Za-z\.0-9]+\ Add\ Class/ , @lines );
	@lines=grep( !/^Dhcp\ Server\ [\\A-Za-z\.0-9]+\ v6\ Add\ Class/ , @lines );
	@lines=grep( !/^Dhcp\ Server\ [\\A-Za-z\.0-9]+\ Set/ , @lines );
	@lines=grep( !/^Dhcp\ Server\ [\\A-Za-z\.0-9]+\ Add\ Optiondef/ , @lines );
	@lines=grep( !/^Dhcp\ Server\ [\\A-Za-z\.0-9]+\ v6\ Add\ Optiondef/ , @lines );

	foreach my $line( @lines ){
		# these will always be the same, just need to define something there
		# garbage1=Dhcp garbage2=Server
		my ( $garbage1, $garbage2, $server, $command, $the_rest)=split( /\ +/, $line, 5);

		if ( $command eq 'set' ){
			# Dhcp Server \\winboot set optionvalue 15 STRING "foo.bar"
			# Dhcp Server \\winboot set optionvalue 6 IPADDRESS "10.202.97.1" "10.202.97.2"
			# Dhcp Server \\winboot set optionvalue 66 STRING "10.93.192.10"
			# Dhcp Server \\winboot set optionvalue 67 STRING "linux"
			# Dhcp Server \\winboot set optionvalue 60 STRING "PXEClient"
			my @the_rest=split(/\ +/, $the_rest);

			if (
				( $the_rest[0] eq 'optionvalue' ) &&
				( $the_rest[1] =~ /^[0-9]+$/ ) &&
				defined( $the_rest[3] )
				){

				my @values;
				my $the_rest_location=3;
				while(defined( $the_rest[$the_rest_location] )){
					push(@values, $the_rest[$the_rest_location]);
					$the_rest_location++;
				}

				$self->add_option($server, 'default', $the_rest[1], \@values);
			}
		}elsif( $command eq 'add' ){
			# Dhcp Server \\winboot add scope 10.40.10.0 255.255.254.0 "it.ord" ""
			# Dhcp Server \\winboot add scope 10.31.129.248 255.255.255.248 "ipkvm.sjc" "The NEW ipkvm.sjc after 10.93.180.216/29 was swiped"
			my @the_rest=split(/\ +/, $the_rest, 4);

			if (
				( $the_rest[0] eq 'scope' ) &&
				defined( $the_rest[1] ) &&
				defined( $the_rest[2] )
				){
				$self->add_scope($server, $the_rest[1], $the_rest[2], $the_rest[3]);
			}
		}elsif( $command =~ /^[Ss]cope$/ ){
			# Dhcp Server \\winboot Scope 10.31.110.0 set optionvalue 51 DWORD "1800"
			# Dhcp Server \\winboot Scope 10.31.110.0 set optionvalue 3 IPADDRESS "10.31.110.1"
			my @the_rest=split(/\ +/, $the_rest);

			if (
				( $the_rest[1] eq 'set' ) &&
				( $the_rest[2] eq 'optionvalue' )
				){
				my @values;

				my $the_rest_location=5;
				while(defined( $the_rest[$the_rest_location] )){
					push(@values, $the_rest[$the_rest_location]);
					$the_rest_location++;
				}

				$self->add_option($server, $the_rest[0], $the_rest[3], \@values);
			}
		}
	}
}

=head2 hash_ref

This returns the current hash reference for the parsed data.

    my $hash_ref=$parser->hash_ref;

=cut

sub hash_ref{
	return $_[0]->{servers};
}

=head2 json

This returns the parsed data as JSON.

One option is taken and that is either a 0/1 for
if it should be made nice and pretty.

    # no white space
    my $json=$parser->json(0);
    
    # now with useful white space
    $json=$parser->json(0);

=head1 DATA STRUCTURE

The structure of it is as below for both the return
hash ref or JSON.

   $hostname=>{$scope}=>{
                         $options=>[],
                         mask=>subnet mask,
                         desc=>description,
                        }

Hostname will always have \\ removed, so \\winboot
becomes just winboot.

$scope is going to be the base address of the subnet.

=cut

sub json{
	my $self=$_[0];
	my $pretty=$_[1];

	my $json=JSON->new;
	$json->pretty( $pretty );

	return $json->encode( $self->{servers} );
}

=head1 INTERNAL FUNCTIONS

=head2 add_options

This adds a option for a scope.

    $hostname = Hostname of the DHCP server.
    $scope = scope name
    $option = DHCP option integer
    $values = array ref of values

    $parser->( $hostname, $scope, $option, \@values );

=cut

sub add_option{
	my $self=$_[0];
	my $hostname=$_[1];
	my $scope=$_[2];
	my $option=$_[3];
	my $values=$_[4];

	# make sure we have everything we need
	# split up so we produce a more useful error
	if ( !defined( $hostname ) ){
		die('No hostname specified');
	}elsif( !defined( $scope ) ){
		die('No scope specified');
	}elsif( !defined( $option ) ){
		die('No option specified');
	}elsif( !defined( $values->[0] ) ){
		die('No option specified');
	}

	# skip over lines like this...
	# Dhcp Server \\winboot Scope 10.40.10.0 set optionvalue 51 DWORD user="Default BOOTP Class" "1800"
	if (
		( $option eq '51' ) &&
		( $values->[0] =~ /^[Uu]/ )
		){
		return 1;
	}

	$hostname=~s/^\\+//;

	if ( ! defined( $self->{servers}{$hostname} ) ){
		$self->{servers}{$hostname}={};
	}

	if ( ! defined( $self->{servers}{$hostname}{$scope} ) ){
		$self->{servers}{$hostname}{$scope}={};
	}

	if ( ! defined( $self->{servers}{$hostname}{$scope}{$option} ) ){
		$self->{servers}{$hostname}{$scope}{$option}=[];
	}

	# process each value
	foreach my $value ( @{ $values } ){
		# windows adds " to each of these
		$value=~s/^\"//;
		$value=~s/\"$//;
		push( @{ $self->{servers}{$hostname}{$scope}{$option} }, $value );
	}

	return 1;
}

=head2 add_scope

This adds a new scope.

    $hostname = Hostname of the DHCP server.
    $scope = scope name
    $mask = subnet mask for the scope
    $desc = description

    $parser->( $hostname, $scope, $mask, $desc );

=cut

sub add_scope{
	my $self=$_[0];
	my $hostname=$_[1];
	my $scope=$_[2];
	my $mask=$_[3];
	my $desc=$_[4];

	# make sure we have everything we need
	# split up so we produce a more useful error
	if ( !defined( $hostname ) ){
		die('No hostname specified');
	}elsif( !defined( $scope ) ){
		die('No scope specified');
	}elsif( !defined( $mask ) ){
		die('No subnet mask specified');
	}elsif( !defined( $desc ) ){
		die('No subnet description specified');
	}

	$hostname=~s/^\\+//;

	if ( ! defined( $self->{servers}{$hostname} ) ){
		$self->{servers}{$hostname}={};
	}

	if ( ! defined( $self->{servers}{$hostname}{$scope} ) ){
		$self->{servers}{$hostname}{$scope}={};
	}

	$self->{servers}{$hostname}{$scope}{mask}=$mask;
	$self->{servers}{$hostname}{$scope}{desc}=$desc;

	return 1;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-dhcp-windows-netsh-parse at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-DHCP-Windows-Netsh-Parse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::DHCP::Windows::Netsh::Parse


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-DHCP-Windows-Netsh-Parse>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-DHCP-Windows-Netsh-Parse>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-DHCP-Windows-Netsh-Parse>

=item * Search CPAN

L<https://metacpan.org/release/Net-DHCP-Windows-Netsh-Parse>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::DHCP::Windows::Netsh::Parse
