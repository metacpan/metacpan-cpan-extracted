package Net::DHCP::Config::Utilities::Subnet;

use 5.006;
use strict;
use warnings;
use Net::CIDR;
use Net::DHCP::Config::Utilities::Options;
use Net::CIDR::Set;

=head1 NAME

Net::DHCP::Config::Utilities::Subnet - Represents a subnet.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use Net::DHCP::Config::Utilities::Subnet;

    my $options={
                 base=>'10.0.0.0',
                 mask=>'255.255.255.0',
                 dns=>'10.0.0.1 , 10.0.10.1',
                 desc=>'a example subnet',
                 };
    
    my $subnet = Net::DHCP::Config::Utilities::Subnet->new( $options );


=head1 METHODS

=head2 new

This initiates the object.

    my $options={
                 base=>'10.0.0.0',
                 mask=>'255.255.255.0',
                 dns=>'10.0.0.1 , 10.0.10.1',
                 desc=>'a example subnet',
                 };
    
    my $subnet = Net::DHCP::Config::Utilities::Subnet->new( $options );

=cut

sub new {
	my %args;
	if ( defined( $_[1] ) ){
		%args=%{$_[1]};
	}

	# make sure we have the bare minimum to succeed
	if ( !defined( $args{base} ) ){
		die('No base defined');
	}elsif( !defined( $args{mask} ) ){
		die('No mask defined');
	}

	# make sure the base and mask are sane
	my $cidr;
	eval{
		$cidr=Net::CIDR::addrandmask2cidr( $args{base}, $args{mask} );
	};
	if ( $@ ){
		die( 'Base/mask validation failed with... '.$@ );
	}

	if (!defined( $args{desc} )){
		$args{desc}='';
	}

	my $self={
			  ranges=>[],
			  desc=>$args{desc},
			  base=>$args{base},
			  mask=>$args{mask},
			  cidr=>$cidr,
			  options=>{},
			  };
	bless $self;

	# process any specified ranges
	if (defined( $args{ranges} )){
		my $cidr_checker=Net::CIDR::Set->new( $cidr );

		foreach my $range ( @{ $args{ranges} } ){
			my @range_split=split(/\ +/, $range);

			# make sure we have both start and end
			if (
				(!defined( $range_split[0] )) ||
				(!defined( $range_split[1] ))
				){
				die('"'.$range.'" not a properly formed range... Should be "IP IP"');
			}

			# make sure both the top and bottom of the range are in our subnet
			my @cidr_list = Net::CIDR::addr2cidr( $range_split[0] );
			if (! $cidr_checker->contains_all( $cidr_list[0] ) ){
				die('"'.$range_split[0].'" for "'.$range.'" not in the CIDR "'.$cidr.'"');
			}
			@cidr_list = Net::CIDR::addr2cidr( $range_split[1] );
			if (! $cidr_checker->contains_all( $cidr_list[0] ) ){
				die('"'.$range_split[1].'" for "'.$range.'" not in the CIDR "'.$cidr.'"');
			}

			# if we get here, it validated and is safe to add
			push( @{ $self->{ranges} }, $range );
		}
	}

	my $options_helper=Net::DHCP::Config::Utilities::Options->new;
	my $options=$options_helper->get_options;
	delete( $options->{mask} ); # already handled this previously
	foreach my $key ( keys( %{ $options } ) ){
		my $opt=$key;

		# make sure we don't have long and short, if long is different than short
		if (
			defined( $args{ $key } ) &&
			(
			 defined( $args{ $options->{$key}{long} } ) &&
			 ( $args{ $key } ne  $args{ $options->{$key}{long} } )
			 )
			){
			die( '"'.$key.'" and "'.$args{ $options->{$key}{long} }.'" both defined and the desired one to use is ambigous' );
		}

		# figure out if we are using long or short and set $opt appropriately
		if (
			defined( $args{ $options->{$key}{long} } ) &&
			( ! defined( $args{ $key } ) )
			){
			$opt=$options->{$key}{long}
		}

		# finally get around to processing it if we have it
		if ( defined( $args{ $opt } ) ){
			# make sure the value for the option is sane
			my $error=$options_helper->validate_option( $opt, $args{ $opt } );
			if ( defined( $error ) ){
				die('"'.$opt.'" option with value "'.$args{$opt}.'" did not validate... '.$error);
			}
		}

		# if we get here, it validated and is safe to add
		# use $key so we are always saving it here as the short option
		$self->{options}{$key}=$args{$opt};
	}

	return $self;
}

=head2 base_get

This returns the base IP for the subnet.

    my $base_IP=$subnet->base;

=cut

sub base_get{
	return $_[0]->{base};
}

=head2 cidr

Returns the CIDR for the subnet.

    my $cidr=$subnet->cidr;

=cut

sub cidr{
	return $_[0]->{cidr};
}

=head2 desc_get

Returns the description.

If this was not defined when initialized, '' will be returned.

    my $desc=$subnet->desc_get;

=cut

sub desc_get{
	return $_[0]->{desc};
}

=head2 mask_get

This returns the current subnet mask.

    my $mask=$subnet->mask;

=cut

sub mask_get{
	return $_[0]->{mask};
}

=head2 option_get

This returns the requested option.

If the requested option is not set, undef is returned.

Options are always saved internally using the short name, so if an
option has both a long name and shortname, then the short name is used.

    my $option_value=$subnet->option_get( $option );
    if ( !defined( $option_value ) ){
        print $option." is not set\n";
    }

=cut

sub option_get{
	my $self=$_[0];
	my $option=$_[1];

	# this is one that may potentially be requested, but is stored else where
	if ( $option eq 'mask' ){
		return $self->{mask};
	}

	if ( defined( $self->{options}{$option} ) ){
		return $self->{options}{$option}
	}

	return undef;
}

=head2 options_list

This list options that have been set, excluding mask.

    my @options=$subnet->options_list;

=cut

sub options_list{
	return keys( %{ $_[0]->{options} } );
}

=head2 option_set

This sets an option.

Two arguments are taken. The first is the option
and the second is the value. If the value is left undefined,
then the option is deleted.

    eval{
         $subnet->option_set( $option, $value );
    };
    if ( $@ ){
        warn( 'Failed to set option "'.$option.'" with value "'.$value.'"... error='.$@ );
    }

=cut

sub option_set{
	my $self=$_[0];
	my $option=$_[1];
	my $value=$_[2];

	if ( !defined( $option ) ){
		die( 'No option defined' );
	}

	if ( $option eq 'mask' ){
		die( 'Setting subnet mask here is not supported') ;
	}

	# if no value is defined, delete the requested option
	if ( ! defined( $value ) ){
		if ( defined( $self->{options}{$option} ) ){
			delete( $self->{options}{$option} );
		}
		return 1;
	}

	# make sure the specified value is valid
	my $options_helper=Net::DHCP::Config::Utilities::Options->new;
	my $error=$options_helper->validate_option( $option, $value );
	if ( defined( $error ) ){
		die('"'.$option.'" option with value "'.$value.'" did not validate... '.$error);
	}

	$self->{options}{$option}=$value;

	return 1;
}

=head2 range_get

This returns a array with containing the ranges in questions.

    my @ranges=$subnet->get_ranges;
    foreach my $range ( @range ){
       print "range ".$range.";\n"
    }

=cut

sub range_get{
	return @{ $_[0]->{ranges} };
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

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::DHCP::Config::Utilities
