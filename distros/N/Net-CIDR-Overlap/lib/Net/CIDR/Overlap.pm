package Net::CIDR::Overlap;

use 5.006;
use strict;
use warnings;
use Net::CIDR;
use Net::CIDR::Set;

=head1 NAME

Net::CIDR::Overlap - A utility module for helping make sure a list of CIDRs don't overlap.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

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

=head1 METHODS

=head2 new

This initates the object.

No arguments are taken.

This will always succeeed.

    my $nco=Net::CIDR::Overlap->new;

=cut

sub new{
	my $self = {
				set=>Net::CIDR::Set->new,
				list=>[],
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

	if (!defined( $cidr )){
		die('No CIDR defined');
	}

	my $valid;
	eval{
		 $valid=Net::CIDR::cidrvalidate($cidr);
	 };
	if (! defined( $valid ) ){
		die $cidr.' is not a valid CIDR or IP';
	}

	$self->{set}->add( $cidr );

	push( @{ $self->{list} }, $cidr );

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
        $nco->add( $cidr, '1', '0' );
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

	if (!defined( $cidr )){
		die('No CIDR defined');
	}

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
		$self->{set}->contains_all( $cidr )
		){
		$contains=1;
	}elsif(
		   ( ! $all ) &&
		   $self->{set}->contains_any( $cidr )
		   ){
		$contains=1;
	}

	if ( $invert ){
		$contains = $contains ^ 1;
	}

	if( $contains ){
		die( 'The compare matched... invert='.$invert.' all='.$all );
	}

	$self->{set}->add($cidr);
	push( @{ $self->{list} }, $cidr );

	return 1;
}

=head2 list

This returns a array ref of successfully added items.

    my $list=$nco->list;
    foreach my $cidr ( @${ $list } ){
        print $cidr."\n";
    }

=cut

sub list{
	my $self=$_[0];

	return $self->{list};
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

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::CIDR::Overlap
