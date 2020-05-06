package Net::DHCP::Config::Utilities::INI_check;

use 5.006;
use strict;
use warnings;
use Config::Tiny;
use File::Find::Rule;
use Net::CIDR;
use Net::CIDR::Set;
#use Net::DHCP::Config::Utilities::Options;

=head1 NAME

Net::DHCP::Config::Utilities::INI_check - Runs various checks for DHCP info stored via INI.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Net::DHCP::Config::Utilities::Options
    use Data::Dumper;

    my $ini_checker;
    eval { $ini_checker=Net::DHCP::Config::Utilities::INI_check->new( $dir )) };
    if ( $@ ){
        die "Initing the checker failed with... ".$@;
    }

    my %overlaps;
    eval { %overlaps = $ini_checker->overlap_check; };
    if ($@){
        warn('Overlap check failed... ');
    }else{
        use Data::Dumper;
        $Data::Dumper::Terse=1;
        print Dumper( \%overlaps );
    }

=head1 METHODS

=head2 new

This initiates the object.

One arguments is required and that is the directory to process.

The section optional argument is the glob to use to match the files to process.
If left undefined, "*.dhcp.ini" is used.

    my $checker;
    eval { $checker=Net::DHCP::Config::Utilities::INI_check->new( $dir )) };
    if ( $@ ){
        die "Initing the checker failed with... ".$@;
    }

=cut

sub new {
	my $dir  = $_[1];
	my $name = $_[2];

	if ( !defined($dir) ) {
		die 'No directory defined';
	}
	elsif ( !-d $dir ) {
		die '"' . $dir . '" is not a dir';
	}

	if ( !defined($name) ) {
		$name = '*.dhcp.ini';
	}

	my $self = {
		dir  => $dir,
		name => $name,
	};
	bless $self;

	return $self;
}

=head2 overlap_check

Finds every DHCP INI file in the directory file in the directory and
checks for overlaps.

    $returned{$file}{$section}{$file_containing_conflicts}[$sections]

The returned values is a hash. $file is the name of file containing the checked
subnet. $subnet is the name of subnet in conflict. $file_containing_conflicts them
the name of the file containing the conflict. $sections is the name of the INI
sections in the previously mentioned file containing the conflict.

    my %overlaps;
    eval { %overlaps = $ini_checker->overlap_check; };
    if ($@){
        warn('Overlap check failed... ');
    }else{
        use Data::Dumper;
        $Data::Dumper::Terse=1;
        print Dumper( \%overlaps );
    }

=cut

sub overlap_check {
	my $self = $_[0];

	# the files to find
	my @files = File::Find::Rule->file()->name( $self->{name} )->in( $self->{dir} );

	# make ainitial pass through, loading them all
	my %loaded;
	foreach my $file (@files) {
		my $ini;

		#$ini = Config::Tiny->new;
		#my $parsed_it;
		eval { $ini = Config::Tiny->read($file) };
		if ( $@ || $! ) {

			# die if we can't load any of them
			if ($@) {
				die 'Died parsing "' . $file . '"... ' . $@;
			}
			else {
				die 'Error parsing "' . $file . '"... ' . $ini->errstr;

			}
		}
		$loaded{$file} = $ini;
	}

	my %to_return;

	# go through and check each file
	foreach my $file ( keys(%loaded) ) {
		my @ini_keys_found = keys( %{ $loaded{$file} } );
		my %subnets;
		foreach my $current_key (@ini_keys_found) {
			my $ref_test = $loaded{$file}->{$current_key};

			# if it is a hash and has a subnet mask, add it to the list
			if ( ( ref($ref_test) eq 'HASH' )
				&& defined( $loaded{$file}->{$current_key}{mask} ) )
			{
				$subnets{$current_key} = 1;
			}
		}

		# Config::Tiny uses _ for variables not in a section
		# This really should never be true as there is no reason for this section
		# to contain the mask variable.
		if ( defined( $subnets{_} ) ) {
			delete( $subnets{_} );
		}

		# check each subnet in the current file
		foreach my $current_subnet ( keys(%subnets) ) {
			my $subnet = $current_subnet;
			my $mask   = $loaded{$file}->{$current_subnet}{mask};

			# if we have a base specified, use it instead of the section name
			if ( defined( $loaded{$file}->{$current_subnet}{base} ) ) {
				$subnet = $loaded{$file}->{$current_subnet}{base};
			}

			# try to generate a CIDR
			my $cidr;
			eval { $cidr = Net::CIDR::addrandmask2cidr( $subnet, $mask ); };

			# only process this subnet if we can generate a CIDR
			if ( !$@ && defined($cidr) ) {

				# go through and test the current subnet against each file
				foreach my $in_file ( keys(%loaded) ) {

					# only ignore this subnet if it is found
					my $ignore;
					if ( $in_file eq $file ) {
						$ignore = $current_subnet;
					}

					# look for overlaps
					my @overlaps = $self->cidr_in_file( $cidr, $in_file, $ignore );

					# handle the overlaps if found, adding it to the return data
					if ( defined( $overlaps[0] ) ) {

						if ( !defined( $to_return{$file} ) ) {
							$to_return{$file} = {};
						}
						if ( !defined( $to_return{$file}{$current_subnet} ) ) {
							$to_return{$file}{$current_subnet} = {};
						}
						$to_return{$file}{$current_subnet}{$in_file} = \@overlaps;
					}
				}
			}
		}
	}

	return %to_return;
}

=head2 cidr_in_file

This goes through the INI file and checks the subnets there for any
overlap with the specified CIDR.

Two arguments are required. The first is the CIDR to check for and the
second is the INI DHCP file to check for overlaps in.

Any subnets with bad base/mask that don't convert properly to a CIDR
are skipped.

The returned value is a array reference of any found conflicts.

    my $overlaps=$ini_check->cidr_in_file( $cidr, $file );
    if ( defined( $overlaps->[0] ) ){
        print "Overlap(s) found\n";
    }

=cut

sub cidr_in_file {
	my $self   = $_[0];
	my $cidr   = $_[1];
	my $file   = $_[2];
	my $ignore = $_[3];

	# make sure they are both defined before going any further
	if (   ( !defined($cidr) )
		|| ( !defined($file) ) )
	{
		die 'Either CIDR or file undefined';
	}

	# make sure the CIDR has a /, the next test will pass regardless
	if ( $cidr !~ /\// ) {
		die 'The value passed for the CIDR does not contain a /';
	}

	# make sure the CIDR is valid
	my $cidr_test;
	eval { $cidr_test = Net::CIDR::cidrvalidate($cidr); };
	if ( $@ || ( !defined($cidr_test) ) ) {
		die '"' . $cidr . '" is not a valid CIDR';
	}

	# make sure we can read the INI file
	my $ini;
	eval { $ini = Config::Tiny->read($file); };
	if ( $@ || $! ) {
		my $extra_dead = '';
		if ($@) {
			$extra_dead = '... ' . $@;
		}
		else {
			$extra_dead = '... ' . $ini->errstr;
		}
		die 'Failed to load the INI file';
	}

	# build a list of the sections with masks
	my @ini_keys_found = keys( %{$ini} );
	my %subnets;
	foreach my $current_key (@ini_keys_found) {
		my $ref_test = $ini->{$current_key};

		# if it is a hash and has a subnet mask, add it to the list
		if ( ( ref($ref_test) eq 'HASH' )
			&& defined( $ini->{$current_key}{mask} ) )
		{
			$subnets{$current_key} = 1;
		}
	}

	# Config::Tiny uses _ for variables not in a section
	# This really should never be true as there is no reason for this section
	# to contain the mask variable.
	if ( defined( $subnets{_} ) ) {
		delete( $subnets{_} );
	}

	# If a ignore is specified, remove it, if it is defined
	if (   defined($ignore)
		&& defined( $subnets{$ignore} ) )
	{
		delete( $subnets{$ignore} );
	}

	# holds the overlaps
	my @overlaps;

	# go through and test each CIDR
	foreach my $subnet_current ( keys(%subnets) ) {
		my $subnet = $subnet_current;
		my $mask   = $ini->{$subnet_current}{mask};

		if ( defined( $ini->{$subnet_current}{base} ) ) {
			$subnet = $ini->{$subnet_current}{base};
		}

		my $cidr_other;
		eval { $cidr_other = Net::CIDR::addrandmask2cidr( $subnet, $mask ); };
		if ( !$@ ) {

			my $set = Net::CIDR::Set->new($cidr);

			if ( $set->contains_any($cidr_other) ) {
				push( @overlaps, $subnet_current );
			}
		}
	}

	return @overlaps;
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

This software is Copyright (c) 2020 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Net::DHCP::Config::Utilities
