package OSLV::Monitor;

use 5.006;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

=head1 NAME

OSLV::Monitor - OS level virtualization monitoring extend for LibreNMS.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use OSLV::Monitor;

    my $monitor = OSLV::Monitor->new();

    eval { $monitor->load; };
    if ($@) {
        print encode_json( { version => 1, data => {}, error => 1, errorString => 'load failed... ' . $@ } ) . "\n";
        exit 1;
    }

    my $data = encode_json( $monitor->run );

    print $data."\n";


=head2 METHODS

Inits the object.

One option is taken and that is a hash ref.

    # init with the cbsd backend
    my $monitor->new(backend=>'FreeBSD');

The keys are list as below.

    - backend :: The name of the backend to use. If undef, it is choosen based on $^O
        freebsd :: FreeBSD
        linux :: cgroups

    - base_dir :: The dir to use for any caches as well as output.
        Default :: /var/cache/oslv_monitor

    - include :: An array of regexps to match names against for seeing if they should
            be included or not. By default everything is return.
        - Default :: ['^.*$']

    - exclude :: An array of regexps to exclude. By default this array is empty. It is
            processed after the include array.
        - Default :: []

    - time_divider :: What to pass to the backend for the time_divider for that if needed.
        Default :: 1000000

=cut

sub new {
	my ( $blank, %opts ) = @_;

	if ( !defined( $opts{time_divider} ) ) {
		$opts{time_divider} = 1000000;
	} else {
		if ( ! looks_like_number( $opts{time_divider} ) ) {
			die('time_divider is not a number');
		}
	}

	if ( !defined( $opts{backend} ) ) {
		$opts{backend} = 'FreeBSD';
		if ( $^O eq 'freebsd' ) {
			$opts{backend} = 'FreeBSD';
		} elsif ( $^O eq 'linux' ) {
			$opts{backend} = 'cgroups';
		}
	}

	if ( !defined( $opts{include} ) ) {
		my @include = ('^.+$');
		$opts{include} = \@include;
	} else {
		if ( !defined( $opts{include}[0] ) ) {
			$opts{include}[0] = '^.+$';
		}

		my $int = 0;
		while ( defined( $opts{include}[$int] ) ) {
			if ( ref( $opts{include}[$int] ) ne '' ) {
				die( 'ref for $opts{include}[' . $int . '] is ' . ref( $opts{include}[$int] ) . ' and not ""' );
			}
			$int++;
		}
	} ## end else [ if ( !defined( $opts{include} ) ) ]

	if ( !defined( $opts{exclude} ) ) {
		my @exclude;
		$opts{exclude} = \@exclude;
	} else {
		my $int = 0;
		while ( defined( $opts{exclude}[$int] ) ) {
			if ( ref( $opts{exclude}[$int] ) ne '' ) {
				die( 'ref for $opts{exclude}[' . $int . '] is ' . ref( $opts{exclude}[$int] ) . ' and not ""' );
			}
			$int++;
		}
	}

	if ( !defined( $opts{base_dir} ) ) {
		$opts{base_dir} = '/var/cache/oslv_monitor';
	}

	if ( !-d $opts{base_dir} ) {
		mkdir( $opts{base_dir} ) || die( $opts{base_dir} . ' was not a directory and could not be created' );
	}

	my $self = {
		time_divider => $opts{time_divider},
		version      => 1,
		backend      => $opts{backend},
		base_dir     => $opts{base_dir},
		include      => $opts{include},
		exclude      => $opts{exclude},
	};
	bless $self;

	return $self;
} ## end sub new

=head2 load

This loads the specified backend.

    eval{ $monitor->load; };
    if ( $@ ){
        print "Failed to load the backend... ".$@;
    }

=cut

sub load {
	my $self = $_[0];

	my $loaded = 0;

	my $backend_test;
	my $usable;
	my $test_string = '
use OSLV::Monitor::Backends::' . $self->{backend} . ';
$backend_test=OSLV::Monitor::Backends::'
		. $self->{backend}
		. '->new(base_dir=>$self->{base_dir}, obj=>$self, time_divider=>$self->{time_divider});
$usable=$backend_test->usable;
';
	eval($test_string);

	if ($usable) {
		$self->{backend_mod} = $backend_test;
		$loaded = 1;
	} else {
		die( 'Failed to load backend... ' . $@ );
	}

	return $loaded;
} ## end sub load

=head2 run

Runs the poller backend and report the results.

If nothing is nothing is loaded, load will be called.

    my $status=$monitor->run;

=cut

sub run {
	my $self = $_[0];

	if ( !defined( $self->{backend_mod} ) ) {
		return {
			version     => $self->{version},
			data        => {},
			error       => 1,
			errorString => 'No module loaded',
		};
	}

	my $to_return_data;
	#	eval { $to_return_data = $self->{backend_mod}->run };
	$to_return_data = $self->{backend_mod}->run;
	if ($@) {
		return {
			version     => $self->{version},
			data        => {},
			error       => 1,
			errorString => 'Failed to run backend... ' . $@,
		};
	}

	$to_return_data->{backend} = $self->{backend};

	return {
		version     => $self->{version},
		data        => $to_return_data,
		error       => 0,
		errorString => ''
	};
} ## end sub run

sub include {
	my $self = $_[0];
	my $name = $_[1];

	# return undef if any of these are true
	if ( !defined($name) ) {
		return 0;
	} elsif ( ref($name) ne '' ) {
		return 0;
	} elsif ( $name eq '' ) {
		return 0;
	}

	# look for mathcing includes
	foreach my $item ( @{ $self->{include} } ) {
		# check if it matches
		if ( $name =~ /$item/ ) {
			# if we got a match check for excludes
			foreach my $item ( @{ $self->{exclude} } ) {
				if ( $name =~ /$item/ ) {
					return 0;
				}
			}
			# if we get here it should means a include matched and no excludes matched
			return 1;
		} ## end if ( $name =~ /$item/ )
	} ## end foreach my $item ( @{ $self->{include} } )

	# if we get here it should mean no includes matched
	return 0;
} ## end sub include

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-oslv-monitor at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=OSLV-Monitor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OSLV::Monitor


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=OSLV-Monitor>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/OSLV-Monitor>

=item * Search CPAN

L<https://metacpan.org/release/OSLV-Monitor>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of OSLV::Monitor
