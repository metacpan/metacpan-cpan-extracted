package Net::DHCP::Config::Utilities;

use 5.006;
use strict;
use warnings;
use Net::CIDR::Overlap;

=head1 NAME

Net::DHCP::Config::Utilities - Utility for helping generate configs for DHCP servers and manage subnets.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

Please note that this only supports IPv4 currently.

    use Net::DHCP::Config::Utilities;
    use Net::DHCP::Config::Utilities::INI_loader;
    
    my $dhcp_util = Net::DHCP::Config::Utilities->new;
    
    # load stuff from a file
    my $loader = Net::DHCP::Config::Utilities::INI_loader->new( $dhcp_util );
    eval{
        $loader->load_file( $file );
    };
    if ( $@ ){
        # do something upon error
        die( $@ );
    }
    
    # create and add a new subnet
    my $options={
                 base=>'10.0.0.0',
                 mask=>'255.255.255.0',
                 dns=>'10.0.0.1 , 10.0.10.1',
                 desc=>'a example subnet',
                 };
    my $subnet = Net::DHCP::Config::Utilities::Subnet->new( $options );
    eval{
        $dhcp_util->subnet_add( $subnet );
    };
    if ( $@ ){
        # do something upon error
        die( $@ );
    }

    my @subnets=$dhcp_util->subnet_list;
    print "Subnets:\n".join("\n", @subnets)."\n";

=head1 METHODS

=head2 new

This iniates the object. No arguments are taken
and this will always succeed.

    my $dhcp_util = Net::DHCP::Config::Utilities->new;

=cut

sub new {
	my $self={
			  nco=>Net::CIDR::Overlap->new,
			  subnets=>{},
			  };
	bless $self;

	return $self;
}

=head2 subnet_add

This adds a new L<Net::DHCP::Config::Utilities::Subnet> object, provided
it does not over lap any existing ones. If the same base/mask has been
added previously, the new will over write the old.

One object is taken and that is the L<Net::DHCP::Config::Utilities::Subnet>
to add.

This will die upon failure.

    eval{
       $dhcp_util->subnet_add( $subnet );
    };
    if ( $@ ){
        die( $@.' prevented the subnet from being added' );
    }

=cut

sub subnet_add{
	my $self=$_[0];
	my $subnet=$_[1];

	if ( ref( $subnet ) ne 'Net::DHCP::Config::Utilities::Subnet' ){
		die( 'No subnet specified or not a Net::DHCP::Config::Utilities::Subnet' );
	}

	# check if it already exists
	my $base=$subnet->base_get;
	my $mask=$subnet->mask_get;
	if ( defined( $self->{subnets}{$base} ) ){
		my $current_mask=$self->{subnets}{$base}->mask_get;
		# if it already exists with a different mask, don't readd it
		if ( $mask ne $current_mask ){
			die ( '"'.$base.'" already exists with the mask "'.$current_mask.'" can not readd it with the mask "'.$mask.'"' );
		}
		$self->{subnets}{$base}=$subnet;
		return 1;
	}

	my $cidr=$subnet->cidr;

	# make sure this subnet does not overlap with any existing ones
	eval{
		$self->{nco}->compare_and_add( $cidr, 0, 0 );
	};
	if ( $@ ){
		die( '"'.$cidr.'" overlaps one or more exists subnets... '.$@ );
	}

	$self->{subnets}{$base}=$subnet;

	return 1;
}

=head2 subnet_get

This returns the requested the subnet.

One option is taken and that is the base of the subnet desired.

If the requested subnet is not found, this will die.

The returned value is a L<Net::DHCP::Config::Utilities::Subnet>
object.

    my $subnet=$dhcp_util->subnet_get;
    if ( $@ ){
        die( $@ );
    }

=cut

sub subnet_get{
	my $self=$_[0];
	my $base=$_[1];

	if (! defined( $base ) ){
		die( 'No base specified' );
	}

	if ( !defined( $self->{subnets}{ $base } ) ){
		die( '"'.$base.'" does not exist' );
	}

	return $self->{subnets}{ $base };
}

=head2 subnet_list

Returns a list of the subnet bases.

    my @subnets=$dhcp_util->subnet_list;

=cut

sub subnet_list{
	return keys( %{ $_[0]->{subnets} } );
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-dhcp-config-utilities at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-DHCP-Config-Utilities>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::DHCP::Config::Utilities


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-DHCP-Config-Utilities>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-DHCP-Config-Utilities>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-DHCP-Config-Utilities>

=item * Search CPAN

L<https://metacpan.org/release/Net-DHCP-Config-Utilities>

=item * Git Repository

L<https://github.com/VVelox/Net-DHCP-Config-Utilities>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::DHCP::Config::Utilities
