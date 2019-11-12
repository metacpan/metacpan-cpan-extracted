package Net::DHCP::Config::Utilities::INI_loader;

use 5.006;
use strict;
use warnings;
use Config::Tiny;
use File::Find::Rule;
use Net::DHCP::Config::Utilities::Subnet;

=head1 NAME

Net::DHCP::Config::Utilities::INI_loader - Loads subnet configurations from a INI file.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use Net::DHCP::Config::Utilities::INI_loader;
    use Net::DHCP::Config::Utilities;
    
    my $dhcp_util = Net::DHCP::Config::Utilities->new;
    
    my $loader = Net::DHCP::Config::Utilities::INI_loader->new( $dhcp_util );
    
    eval{
        $loader->load_file( $file );
    };
    if ( $@ ){
        # do something upon error
        die( $@ );
    }

=head1 METHODS

=head2 new

This initiates the object.

One argument is required and that is a Net::DHCP::Config::Utilities
object to operate on.

    use Net::DHCP::Config::Utilities;
    
    my $dhcp_util = Net::DHCP::Config::Utilities->new;
    
    my $loader = Net::DHCP::Config::Utilities::INI_loader->new( $dhcp_util );

=cut

sub new {
	my $obj=$_[1];

	if ( ref( $obj ) ne 'Net::DHCP::Config::Utilities' ){
		die( 'No Net::DHCP::Config::Utilities object passed or wrong ref type' );
	}

	my $self={
			  obj=>$obj,
			  };
	bless $self;

	return $self;
}

=head2 load_file

This loads a specific file in question.

One argument is taken and that is the path to the INI file.

If this encounter any errors, it will die.

    eval{
        $load->load_file( $file );
    };
    if ( $@ ){
        # do something upon error
        die( $@ );
    }

=cut

sub load_file{
	my $self=$_[0];
	my $file=$_[1];

	if ( ! defined( $file ) ){
		die( 'No file specified' );
	}elsif( ! -f $file ){
		die( '"'.$file.'" is not a file or does not exist' );
	}

	my $ini = Config::Tiny->read( $file );
	if ( ! defined( $ini ) ){
		die( 'Failed to read "'.$file.'"' );
	}

	foreach my $key ( keys( %{ $ini } ) ){
		if ( $key ne '_' ){
			# set base here, incase it is explicitly set later in the section
			my $options={
						 base=>$key,
						 };

			# process each one as we need to real in the range variables
			foreach my $option_key ( keys( %{ $ini->{$key} } ) ){
				if ( $option_key =~ /^range/ ){
					# each range variable needs to be treated specially
					# as they all need loaded into a array
					if ( !defined $options->{ranges} ){
						$options->{ranges}=[ $ini->{$key}{$option_key} ];
					}else{
						push( @{ $options->{ranges} }, $ini->{$key}{$option_key} );
					}
				}else{
					$options->{$option_key} = $ini->{$key}{$option_key};
				}
			}

			my $subnet;
			eval{
				$subnet = Net::DHCP::Config::Utilities::Subnet->new( $options );
			};
			if ( $@ ){
				die('Failed to create a subnet for the section "'.$key.'"... '.$@);
			}

			eval{
				$self->{obj}->subnet_add( $subnet );
			};
			if ( $@ ){
				die( 'Failed to add the subnet in the section "'.$key.'"... '.$@ );
			}
		}
	}

	return 1;
}

=head2 load_dir

This loads the specified directory.

Two arguments are taken.

The first and required is the directory to load.

The second and optional is the name glob to use. If none
is specified then '*.dhcp.ini' is used.

Upon error, this will die.

    my $loaded;
    eval{
        $loaded = $load_dir->load_dir{ $dir };
    };
    if( $@ ){
        die( 'Failed to load... '.$@ );
    }else{
        print "Loaded ".$loaded." files.";
    }

=cut

sub load_dir{
	my $self=$_[0];
	my $dir=$_[1];
	my $name=$_[2];

	if ( ! defined( $dir ) ){
		die( 'No directory specified' );
	}elsif( ! -d $dir ){
		die( '"'.$dir.'" is not a directory or does not exist' );
	}

	if ( !defined( $name ) ){
		$name='*.dhcp.ini';
	}

	my @files=File::Find::Rule->file()
	->name( $name )
	->in( $dir );

	if( ! defined( $files[0] ) ){
		return 0;
	}

	my $count=1;
	my $total=$#files + 1;
	foreach my $file ( @files ){
		eval{
			$self->load_file( $file );
		};
		if ( $@ ){
			die( 'Failed on "'.$file.'", '.$count.' of '.$total.'... '.$@  );
		}

		$count++;
	}

	return $total;
}

=head1 INI EXPECTATIONS

Each sesction of a INI file is treated as its own subnet.

The variable/values taken must be understood by L<Net::DHCP::Config::Utilities::Subnet>.

If the variable base is not specified, the section name is used.

Any variable matching /^range/ is added to the ranges array used when creating the subnet.

    [10.0.0.0]
    mask=255.255.0.0
    dns=10.0.0.1 , 10.0.10.1
    desc=a /16
    routers=10.0.0.1
    
    [foo]
    base=192.168.0.0
    mask=255.255.0.0
    dns=10.0.0.1 , 10.0.10.1
    routers=192.168.0.1
    range=192.168.0.100 192.168.0.200

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
