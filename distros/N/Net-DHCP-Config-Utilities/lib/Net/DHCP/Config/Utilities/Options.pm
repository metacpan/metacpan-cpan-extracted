package Net::DHCP::Config::Utilities::Options;

use 5.006;
use strict;
use warnings;
use Net::CIDR;

=head1 NAME

Net::DHCP::Config::Utilities::Options - Helper utilities for working with DHCP options.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use Net::DHCP::Config::Utilities::Options;
    
    my $dhcp_options=Net::DHCP::Config::Utilities::Options->new;
    
    my $options=$dhcp_options->get_options;
    use Data::Dumper;
    print Dumper( $options );

    my $error=$dhcp_options->validate_option( 'dns', '192.168.0.1 , 10.10.10.10' );
    if ( defined( $error ) ){
        die( $error );
    }

=head1 METHODS

=head2 new

Initiates the object.

    my $dhcp_options=Net::DHCP::Config::Utilities::Options->new;

=cut

sub new {
	my $self={
			  options=>{
						'mask'=>{
								 'code'=>'0',
								 'multiple'=>'0',
								 'type'=>'ip',
								 'long'=>'subnet-mask',
								 },
						'time-offset'=>{
										'code'=>'1',
										'multiple'=>'0',
										'type'=>'int',
										'long'=>'time-offset',
										},
						'routers'=>{
									'code'=>'3',
									'multiple'=>'1',
									'type'=>'ip',
									'long'=>'routers',
									},
						'ntp'=>{
								'code'=>'4',
								'multiple'=>'1',
								'type'=>'ip',
								'long'=>'time-servers',
								},
						'dns'=>{
								'code'=>'6',
								'multiple'=>'1',
								'type'=>'ip',
								'long'=>'domain-name-servers',
								},
						'root'=>{
								 'code'=>'17',
								 'multiple'=>'0',
								 'type'=>'txt',
								 'long'=>'root-path',
								 },
						'mtu'=>{
								'code'=>'26',
								'multiple'=>'0',
								'type'=>'int',
								'long'=>'interface-mtu',
								},
						'broadcast'=>{
									  'code'=>'28',
									  'multiple'=>'0',
									  'type'=>'ip',
									  'long'=>'broadcast-address',
									  },
						'lease-time'=>{
									   'code'=>'51',
									   'multiple'=>'0',
									   'type'=>'int',
									   'long'=>'dhcp-lease-time',
									   },
						'tftp-server'=>{
										'code'=>'66',
										'multiple'=>'0',
										'type'=>'txt',
										'long'=>'next-server',
										},
						'bootfile'=>{
									 'code'=>'67',
									 'multiple'=>'0',
									 'type'=>'txt',
									 'long'=>'filename',
									 },
						'v4-access-domain'=>{
									 'code'=>'213',
									 'multiple'=>'0',
									 'type'=>'txt',
									 'long'=>'v4-access-domain',
											 },
						'web-proxy'=>{
									  'code'=>'252',
									  'multiple'=>'0',
									  'type'=>'txt',
									  'long'=>'web-rpoxy',
									 },
						},
			  long_to_short=>{
							  'filename'=>'bootfile',
							  'next-server'=>'tftp-server',
							  'dhcp-lease-time'=>'lease-time',
							  'interface-mtr'=>'mtu',
							  'root-path'=>'root',
							  'domain-name-servers'=>'dns',
							  'time-servers'=>'ntp',
							  'broadcast-address'=>'broadcast',
							  'subnet-mask'=>'mask',
							  },
			  };
	bless $self;

	return $self;
}

=head2 get_code

Returns the DHCP code value for a option.

One option is taken and that is the option name.

If the option name is not found or is undef,
then undef is returned.

    # you can use the long name
    print 'subnet-mask: '.$dhcp_options->get_code('subnet-mask')."\n";
    # or the easier to remember short name
    print 'mask: '.$dhcp_options->get_code('mask')."\n";

=cut

sub get_code{
	my $self=$_[0];
	my $option=$_[1];

	# need a value to proceed
	if ( !defined( $option ) ){
		return undef;
	}

	# if we find this, grab the short version
	if ( defined( $self->{long_to_short}{$option} ) ){
		$option=$self->{long_to_short}{$option};
	}

	if ( !defined( $self->{options}{$option} ) ){
		return undef;
	}

	return $self->{options}{$option}{code};
}

=head2 get_long

Returns the long option name for the specified option.

One argument is taken and that is the option name.

If the option name is not found or is undef,
then undef is returned.

    print 'root: '.$dhcp_options->get_long('root')."\n";
    print 'mask: '.$dhcp_options->get_long('mask')."\n";
    print 'mtu: '.$dhcp_options->get_long('mtu')."\n";
    print 'routers: '.$dhcp_options->get_long('routers')."\n";

=cut

sub get_long{
	my $self=$_[0];
	my $option=$_[1];

	# need a value to proceed
	if ( !defined( $option ) ){
		return undef;
	}

	# if we find this, grab the short version
	if ( defined( $self->{long_to_short}{$option} ) ){
		$option=$self->{long_to_short}{$option};
	}

	if ( !defined( $self->{options}{$option} ) ){
		return undef;
	}

	return $self->{options}{$option}{long};
}


=head2 get_multiple

Returns if multiple values are supported by this option.

    0 = single value
    1 = multiple values

One option is taken and that is the option name.

If the option name is not found or is undef,
then undef is returned.

    # you can use the long name
    print 'subnet-mask: '.$dhcp_options->get_multiple('subnet-mask')."\n";
    # or the easier to remember short name
    print 'mask: '.$dhcp_options->get_multiple('mask')."\n";

    if ( $dhcp_options->get_multiple('dns') ){
        print "Multiple values are supported... exanple\n".
              "10.10.10.1 , 10.10.10.2\n";
    }

=cut

sub get_multiple{
	my $self=$_[0];
	my $option=$_[1];

	# need a value to proceed
	if ( !defined( $option ) ){
		return undef;
	}

	# if we find this, grab the short version
	if ( defined( $self->{long_to_short}{$option} ) ){
		$option=$self->{long_to_short}{$option};
	}

	if ( !defined( $self->{options}{$option} ) ){
		return undef;
	}

	return $self->{options}{$option}{multiple};
}

=head2 get_options

Returns a hash ref with the various options.

    my $options=$dhcp_options->get_options;
    foreach my $opt ( keys( %{ $options } ) ){
        print "----\n".
              "option: ".$opt."\n".
              "code: ".$options->{$opt}{'code'}."\n".
              "multiple: ".$options->{$opt}{'multiple'}."\n".
              "type: ".$options->{$opt}{'type'}."\n".
              "long: ".$options->{$opt}{'long'}."\n".
    }

=cut

sub get_options{
	return $_[0]->{options};
}

=head2 get_type

Returns the data type that the option in question is.

    ip  = IP address
    int = integer
    txt = text field that must be defined

One option is taken and that is the option name.

If the option name is not found or is undef,
then undef is returned.

    print 'root: '.$dhcp_options->get_type('root')."\n";
    print 'mask: '.$dhcp_options->get_type('mask')."\n";
    print 'mtu: '.$dhcp_options->get_type('mtu')."\n";

=cut

sub get_type{
	my $self=$_[0];
	my $option=$_[1];

	# need a value to proceed
	if ( !defined( $option ) ){
		return undef;
	}

	# if we find this, grab the short version
	if ( defined( $self->{long_to_short}{$option} ) ){
		$option=$self->{long_to_short}{$option};
	}

	if ( !defined( $self->{options}{$option} ) ){
		return undef;
	}

	return $self->{options}{$option}{type};
}

=head2 valid_option_name

This checks if the option name is valid.

This checks for possible long and short forms.

    if ( ! $dhcp_options->valid_option_name( $option ) ){
        die( $option.' is not a valid option' );
    }


=cut

sub valid_option_name{
	my $self=$_[0];
	my $option=$_[1];

	if ( ! defined( $option ) ){
		return undef;
	}

	if (
		( defined( $self->{options}{$option} ) ) ||
		( defined( $self->{long_to_short}{$option} ) )
		){
		return 1;
	}

	return undef;
}

=head2 validate_options

This validates a option and the value for it.

Twu arguments are taken. The first is the option name
and the third is the value.

If any issues are found a string is returned that describes it.

If there are no issues undef is returned.

This should not be mistaken for sanity checking. This just
makes sure that the data is the correct type for the option.

    my $error=$dhcp_options->validate_option( $option, $value );
    if ( defined( $error ) ){
        die( $error );
    }

=cut

sub validate_option{
	my $self=$_[0];
	my $option=$_[1];
	my $value=$_[2];

	# need a value to proceed
	if ( !defined( $option ) ){
		return 'Option undefined';
	}

	# need a value to proceed
	if ( !defined( $value ) ){
		return 'Option Value undefined';
	}

	# if we find this, grab the short version
	if ( defined( $self->{long_to_short}{$option} ) ){
		$option=$self->{long_to_short}{$option};
	}

	# if this hits, then we don't have a valid name
	if ( !defined( $self->{options}{$option} ) ){
		return '"'.$option.'" was is not a valid option name';
	}

	my $type=$self->{options}{$option}{type};

	# if it is txt type, we have already checked to make sure
	# it is defined
	if ( $type eq 'txt' ){
		return undef;
	}

	# trans form it into a array to simply processing
	my @values;
	if ( $self->{options}{$option}{multiple} ){
		@values=split( /\ *\,\ */, $value );
	}else{
		# multiple values are not taken, just shove the
		# value into the array
		push( @values, $value );
	}

	foreach my $test_value ( @values ){
		if ( $type eq 'int' ){
			if ( $test_value !~ /^[0-9]+$/ ){
				return "'".$test_value."' is not a valid integer";
			}
		}elsif( $type eq 'ip' ){
			eval{
				my @cidrs=Net::CIDR::addr2cidr($test_value);
			};
			if ( $@ ){
				return "'".$test_value."' is not a valid IP";
			}
		}
	}

	return undef;
}

=head1 SUPPORT OPTIONS

This only supports the more commonly used one for now and avoids the out of date ones.

    | Code | Name             | Multi | Type | Long Name           |
    |------|------------------|-------|------|---------------------|
    | 0    | mask             | 0     | IP   | subnet-mask         |
    | 1    | time-offset      | 0     | INT  | time-offset         |
    | 3    | routers          | 1     | IP   | routers             |
    | 4    | ntp              | 1     | IP   | time-servers        |
    | 6    | dns              | 1     | IP   | domain-name-servers |
    | 17   | root             | 0     | TXT  | root-path           |
    | 26   | mtu              | 0     | INT  | interface-mtu       |
    | 28   | broadcast        | 0     | IP   | broadcast-address   |
    | 51   | lease-time       | 0     | INT  | dhcp-lease-time     |
    | 66   | tfp-server       | 0     | TXT  | next-server         |
    | 67   | bootfile         | 0     | TXT  | filename            |
    | 213  | v4-access-domain | 0     | TXT  | v4-access-domain    |
    | 252  | web-proxy        | 0     | TXT  | web-proxy           |

For options that can take multiple values, /\ *\,\ */ is used for the split.

Validation is done as below.

    INT = /^[0-9]+$/
    IP  = If Net::CIDR::addr2cidr can make sense of it.
    TXT = defined

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
