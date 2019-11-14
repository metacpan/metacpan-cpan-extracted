package Net::DHCP::Config::Utilities::Generator::ISC_DHCPD;

use 5.006;
use strict;
use warnings;
use Template;
use Net::DHCP::Config::Utilities::Options;
use String::ShellQuote;

=head1 NAME

Net::DHCP::Config::Utilities::Generator::ISC_DHCPD - Generates a config for ISC DHCPD from the supplied subnets.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';


=head1 SYNOPSIS

    use Net::DHCP::Config::Utilities::Generator::ISC_DHCPD;
    
    my $options={
                 output=>'./dhcp/dhcpd.conf',
                 header=>'./dhcp/header.tt',
                 footer=>'./dhcp/footer.tt',
                 args=>{},
                 };
    
    my $generator = Net::DHCP::Config::Utilities::Subnet->new( $options );
    
    eval{
        $generator->generate( $dhcp_util );
    };
    if ( $@ ){
        # do something upon error
        die ( $@ );
    }
    
    # just return it and don't write it output
     my $config;
     eval{
        $config=$generator->generate( $dhcp_util );
    };
    if ( $@ ){
        # do something upon error
        die ( $@ );
    }
    print $config;

=head1 METHODS

=head2 new

This initiates the object.

    my $options={
                 output=>'./dhcp/dhcpd.conf',
                 header=>'./dhcp/header.tt',
                 footer=>'./dhcp/footer.tt',
                 vars=>{},
                 };
    
    my $generator = Net::DHCP::Config::Utilities::Generator::ISC_DHCPD->new( $options );

=head3 args

=head4 output

This is the file to write the output too.

=head4 header

This is the header template to use.

=head4 footer

This is the footer teomplate to use.

=head4 vars

This is a hash containing values to pass to L<Template>
as the \%vars value for when calling L<Template>->process.

=cut

sub new {
	my %args;
	if ( defined( $_[1] ) ){
		%args=%{$_[1]};
	}

	# make sure we have all the required variables
	# also make sure footer, output, and header are not all the same files
	if ( !defined( $args{header} ) ){
		die( 'No header file specified' );
	}elsif( !defined( $args{footer} ) ){
		die( 'No footer file specified' );
	}elsif( !defined( $args{output} ) ){
		die( 'No output file specified' );
	}elsif( !defined( $args{vars} ) ){
		die( 'No vars hash defined' );
	}elsif( ! -f $args{header} ){
		die( '"'.$args{header}.'" does not exist or is not a file');
	}elsif( ! -f $args{footer} ){
		die( '"'.$args{footer}.'" does not exist or is not a file');
	}elsif( ref( $args{vars} ) ne 'HASH' ){
		die( '$args{vars} is not a hash' );
	}elsif( $args{footer} eq $args{header} ){
		die( '$args{footer} and $args{header} are both the same, "'.$args{footer}.'",' );
	}elsif( $args{footer} eq $args{output} ){
		die( '$args{footer} and $args{output} are both the same, "'.$args{footer}.'",' );
	}elsif( $args{header} eq $args{output} ){
		die( '$args{header} and $args{output} are both the same, "'.$args{header}.'",' );
	}

	my $self={
			  vars=>$args{vars},
			  footer=>$args{footer},
			  header=>$args{header},
			  output=>$args{output},
			  options=>Net::DHCP::Config::Utilities::Options->new,
			  };
	bless $self;

	return $self;
}

=head2 generate

This gnerates the config for ISC DHCPD.

There are two options taken.

The first and mandatory is a L<Net::DHCP::Config::Utilities> object
that contains the subnets that we want to generate a config for.

The second is we want to write the output to the file or not. This is
optional and if set to true no output will be writen.

This will return a string with the generated config.

If it is being outputed to a file, then ISC DHCPD will be called
as 'dhcpd -t -cf $output' to lint it. It will die if it exits
with a non-zero value.

    eval{
        $generator->generate( $dhcp_util );
    };
    if ( $@ ){
        # do something upon error
        die ( $@ );
    }

    # just return it and don't write it output
     my $config;
     eval{
        $config=$generator->generate( $dhcp_util );
    };
    if ( $@ ){
        # do something upon error
        die ( $@ );
    }
    print $config;

=cut

sub generate{
	my $self=$_[0];
	my $object=$_[1];
	my $no_write=$_[2];

	if ( ref( $object ) ne 'Net::DHCP::Config::Utilities' ){
		die( 'The passed object is not a "Net::DHCP::Config::Utilities", but "'.ref( $object ).'"' );
	}

	# init the template object and then process the header/footer
	my $template=Template->new({
								EVAL_PERL=>1,
								INTERPOLATE=>1,
								POST_CHOMP=>1,
							   });
	my $header;
	$template->process( $self->{header}, $self->{vars}, \$header )
	|| die( 'Failed to process the header, "'.$self->{header}.'"... '.$template->error );
	my $footer;
	$template->process( $self->{footer}, $self->{vars}, \$footer )
	|| die( 'Failed to process the footer, "'.$self->{footer}.'"... '.$template->error );

	my $middle='';

	my @subnets=sort( $object->subnet_list );
	foreach my $base ( @subnets ){
		my $subnet=$object->subnet_get( $base );

		my $desc=$subnet->desc_get;
		if ( $desc ne '' ){
			$desc='# '.$desc."\n";
		}

		$middle=$middle.$desc.'subnet '.$base.' netmask '.$subnet->mask_get." {\n";

		# add any required ranges
		# unless you have static IPs in the footer you really need ranges
		my @ranges=sort( $subnet->range_get );
		foreach my $range ( @ranges ){
			$middle=$middle.'    range '.$range.";\n";
		}

		my @options=sort( $subnet->options_list );
		foreach my $option ( @options ){
			my $value=$subnet->option_get( $option );
			my $long=$self->{options}->get_long( $option );
			if ( defined ( $value ) ){
				# handle the tftp boot stuff specially thanks to ISC DHCPD not appending
				# option to those values for some bloody unknown reason
				if (
					($option eq 'next-server') ||
					($option eq 'tftp-server')
					){
					$middle=$middle.'    next-server'.$value.";\n";
				}elsif(
					   ($option eq 'filename') ||
					   ($option eq 'bootfile')
					   ){
					$middle=$middle.'    filename'.$value.";\n";
				}else{
					$middle=$middle.'    option '.$long.' '.$value.";\n";
				}
			}
		}

		$middle=$middle."}\n\n";
	}

	if ( ! $no_write ){
		my $fh;
		open( $fh, '>', $self->{output} ) or die( 'Can not open "'.$self->{output}.'" for writing output to,,, C errno='.$! );
		print $fh $header.$middle.$footer;
		close( $fh );

		# 2> /dev/null used to prevent this from being noisy
		my $dhcpd_bin=`/bin/sh -c 'which dhcpd 2> /dev/null'`;
		if ( $? == 0 ){
			my $quoted=shell_quote( $self->{output} );
			my $check=`/bin/sh -c 'dhcpd -t -cf $quoted 2> /dev/null'`;
			if ( $? != 0 ){
				die('Failed to lint the output file,"'.$self->{output}.'",');
			}
		}
	}

	return $header.$middle.$footer;
}

=head1 TEMPLATES

A good base header template is as below.

    default-lease-time 600;
    max-lease-time 7200;
    
    ddns-update-style none;
    
    authoritative;
    
    option web-proxy code 252 = text;
    
    log-facility local7;
    

In general the footer will be left empty.
It is largely for use if you have like static hosts.

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
