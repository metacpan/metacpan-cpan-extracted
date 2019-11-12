package Net::CIDR::Overlap;

use 5.006;
use strict;
use warnings;
use Net::CIDR;
use Net::CIDR::Set;

=head1 NAME

Net::CIDR::Overlap - A utility module for helping make sure a list of CIDRs don't overlap.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    my $nco=Net::CIDR::Overlap->new;
    
    # add some subnets
    eval{
        $nco->add( '127.0.0.0/24' );
        $nco->add( '192.168.42.0/24' );
        $nco->add( '10.10.0.0/16' );
    }
    if ( $@ ){
        warn( $@ );
    }
    
    # this will fail as they have already been added
    eval{
        $nco->add( '127.0.0.0/25' );
        $nco->add( '10.10.10/24' );
    }
    if ( $@ ){
        warn( $@ );
    }
    
    # this will fail this is not a valid CIDR
    eval{
        $nco->add( 'foo' );
    }
    if ( $@ ){
        warn( $@ );
    }
    
    # print the subnets we added with out issue
    my $list=$nco->list;
    foreach my $cidr ( @${ $list } ){
        print $cidr."\n";
    }

This works with eithe IPv4 or IPv6. Two instances of L<Net::CIDR::Set>
are maintained, one for IPv4 and one for IPv6.

=head1 METHODS

=head2 new

This initates the object.

    my $nco=Net::CIDR::Overlap->new;

=cut

sub new{
	my $self = {
				set4=>Net::CIDR::Set->new( { type => 'ipv4' } ),
				set6=>Net::CIDR::Set->new( { type => 'ipv6' } ),
				list=>{},
				set4init=>undef,
				set6init=>undef,
				};
	bless $self;

	return $self;
}

=head2 add

This adds a subnet to the set being checked.

Net::CIDR::cidrvalidate is used to validate passed CIDR/IP.

This will die if it is called with a undef value of if validation fails.

This does not check if what is being added overlaps with anything already
added.

    eval{
        $nco->add( $cidr );
    }
    if ( $@ ){
        warn( $@ );
    }

=cut

sub add{
	my $self=$_[0];
	my $cidr=$_[1];

	# makes sure we have a defined+valid valueand get what set we should remove it from
	my $set='set'.$self->ip_type( $cidr );

	$self->{$set}->add( $cidr );
	$self->{list}{$cidr}=1;
	$self->{init}=1;

	return 1;
}

=head2 available

This checks to see if the subnet is available.

There is one required argument and two optional.

The first and required is the CIDR/IP. This will be
validated using Net::CIDR::cidrvalidate.

The second is if to invert the check or not. If set to
true, it will only be added if overlap is found.

The third is if overlap should be any or all. This is boolean
and a value of true sets it to all. The default value is false,
meaning any overlap.

    my $available;
    eval{
        $available=$nco->available( $cidr );
    };
    if ( $@ ){
        # do something to handle the error
        die( 'Most likely a bad CIDR...'.$@ );
    }elsif( ! $available ){
        print "Some or all of the IPs in ".$cidr." are unavailable.\n";
    }

    # this time invert the search and check if all of them are unavailable
    eval{
        $available==$nco->available( $cidr, 1, 1 );
    };
    if ( $@ ){
        # do something to handle the error
        die( 'Most likely a bad CIDR...'.$@ );
    }elsif( $available ){
        print "All of the IPs in ".$cidr." are unavailable.\n";
    }

=cut

sub available{
	my $self=$_[0];
	my $cidr=$_[1];
	my $invert=$_[2];
	my $all=$_[3];

	# makes sure we have a defined+valid valueand get what set we should remove it from
	my $set='set'.$self->ip_type( $cidr );

	# set here so we produce nice output if we die
	if ( !defined( $invert ) ){
		$invert=0;
	}
	if ( !defined( $all ) ){
		$all=0;
	}
	my $valid;
	eval{
		 $valid=Net::CIDR::cidrvalidate($cidr);
	 };
	if (! defined( $valid ) ){
		die $cidr.' is not a valid CIDR or IP';
	}

	my $contains=0;
	if (
		$all &&
		$self->{$set}->contains_all( $cidr )
		){
		$contains=1;
	}elsif(
		   ( ! $all ) &&
		   $self->{$set}->contains_any( $cidr )
		   ){
		$contains=1;
	}

	if ( $invert ){
		$contains = $contains ^ 1;
	}

	if( $contains ){
		return 0;
	}


	return 1;
}

=head2 compare_and_add

This first checks for overlap and then adds it.

There is one required argument and two optional.

The first and required is the CIDR/IP. This will be
validated using Net::CIDR::cidrvalidate.

The second is if to invert the check or not. If set to
true, it will only be added if overlap is found.

The third is if overlap should be any or all. This is boolean
and a value of true sets it to all. The default value is false,
meaning any overlap.

    # just add it if there is no overlap
    eval{
        $nco->compare_and_add( $cidr );
    }
    if ( $@ ){
        warn( $@ );
    }

    # this time invert it and use use any for the overlap check
    eval{
        $nco->compare_and_add( $cidr, '1', '0' );
    }
    if ( $@ ){
        warn( $@ );
    }

=cut

sub compare_and_add{
	my $self=$_[0];
	my $cidr=$_[1];
	my $invert=$_[2];
	my $all=$_[3];

	# makes sure we have a defined+valid valueand get what set we should remove it from
	my $set='set'.$self->ip_type( $cidr );

	# set here so we produce nice output if we die
	if ( !defined( $invert ) ){
		$invert=0;
	}
	if ( !defined( $all ) ){
		$all=0;
	}

	if ( ! $self->{$set.'init'} ){
		$self->{$set}->add($cidr);
		$self->{list}{$cidr}=1;
		$self->{$set.'init'}=1;
		return 1;
	}

	my $contains=0;
	if (
		$all &&
		$self->{$set}->contains_all( $cidr )
		){
		$contains=1;
	}elsif(
		   ( ! $all ) &&
		   $self->{$set}->contains_any( $cidr )
		   ){
		$contains=1;
	}

	if ( $invert ){
		$contains = $contains ^ 1;
	}

	if( $contains ){
		die( 'The compare matched... invert='.$invert.' all='.$all );
	}

	$self->{$set}->add($cidr);
	$self->{list}{$cidr}=1;
	$self->{$set.'init'}=1;

	return 1;
}

=head2 exists

This check if the specified value exists in the list or not.

One value is taken and that is a CIDR. If this is not defined,
it will die.

    my $xists;
    eval{
        $nco->exists( $cidr );
    };
    if ( $@ ){

    }elsif( ! $exist ){
        print $cidr." does not exist in the list.\n";
    }else{
        print $cidr." does exist in the list.\n";
    }

=cut

sub exists{
	my $self=$_[0];
	my $cidr=$_[1];

	if (!defined( $cidr )){
		die('No CIDR defined');
	}

	if ( defined( $self->{list}{$cidr} ) ){
		return 1;
	}

	return undef;
}

=head2 list

This returns a array of successfully added items.

    my @list=$nco->list;
    foreach my $cidr ( @list ){
        print $cidr."\n";
    }

=cut

sub list{
	my $self=$_[0];

	return keys( %{ $self->{list} } );
}

=head2 remove

This removes the specified CIDR from the list.

One argument is taken and that is the CIDR to remove.

If the CIDR is not one that has been added, it will error.

Upon any errors, this method will die.

    eval{
        $nco->remove( $cidr );
    };
    if ( $@ ){
        die( 'Did you make sure the $cidr was defined and added previously?' );
    }

=cut

sub remove{
	my $self=$_[0];
	my $cidr=$_[1];

	# makes sure we have a defined+valid valueand get what set we should remove it from
	my $set='set'.$self->ip_type( $cidr );

	if ( !defined( $self->{list}{$cidr} ) ){
		die( '"'.$cidr.'" is not in the list' );
	}

	$self->{$set}->remove( $cidr );
	delete( $self->{list}{$cidr} );

	return 1;
}

=head2 ip_type

This returns either 4 or 6 based on if it is IPv4 or IPv6.

Upon undef or invalid CIDR, this will die.

    my $type=$nco->ip_type( $cidr );
    if ( $type eq '4' ){
        print "It is IPv4\n";
    }else{
        print "It is IPv6\n";
    }

=cut

sub ip_type{
	my $self=$_[0];
	my $cidr=$_[1];

	# make sure we have input
	if (!defined( $cidr )){
		die('No CIDR defined');
	}

	# make sure we are valid
	my $valid;
	eval{
		 $valid=Net::CIDR::cidrvalidate($cidr);
	 };
	if (! defined( $valid ) ){
		die $cidr.' is not a valid CIDR or IP';
	}

	# if it contains a :, then it is IPv6
	if ( $cidr =~ /\:/ ){
		return '6';
	}

	# valid and not IPv6, so IPv4
	return '4';
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-cidr-overlap at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-CIDR-Overlap>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::CIDR::Overlap


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-CIDR-Overlap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-CIDR-Overlap>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-CIDR-Overlap>

=item * Search CPAN

L<https://metacpan.org/release/Net-CIDR-Overlap>

=item * GIT Repository

L<https://github.com/VVelox/Net-CIDR-Overlap>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::CIDR::Overlap
