package Parse::Netstat::Search;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Net::CIDR;

=head1 NAME

Parse::Netstat::Search - Searches the connection list in the results returned by Parse::Netstat

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS


    use Parse::Netstat::Search;
    use Parse::Netstat qw(parse_netstat);

    my $res = parse_netstat(output => join("", `netstat -anp`), flavor=>'linux');

    my $search = Parse::Netstat::Search->new();

    $search->set_cidrs( [ '10.0.0.0/24', '192.168.0.0/16' ] );

    my @found=$search->search($res);


Two big things to bet aware of is this module does not currently resulve names and this module
does not handle unix sockets. Unix sockets will just be skipped over.

=head1 methods

=head2 new

This initiates it.

No values are taken.

    my $search=Parse::Netstat::Search->new;

=cut

sub new{
	my $self={
			  perror=>undef,
			  error=>undef,
			  errorString=>'',
			  errorExtra=>{
						   '1'=>'badCIDR',
						   '2' =>'unknownService',
						   },
			  cidrs=>[],
			  protocols=>{},
			  ports=>{},
			  states=>{},
			  };
	bless $self;

	return $self;

}

=head2 get_cidrs

Retrieves the CIDR match list.

The returned value is an array.

    my @CIDRs=$search->get_cidrs;

=cut

sub get_cidrs{
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	return @{ $self->{cidrs} };
}

=head2 get_ports

Gets a list of desired ports.

The returned value is a array. Each item is a port number,
regardless of if it was set based on number or service name.

    my @ports=$search->get_ports;

=cut

sub get_ports{
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	return keys( %{ $self->{ports} } );
}

=head2 get_protocols

Gets a list of desired protocols.

The returned value is a array.

Also if you've passed any named ones to it previously,
this will not return them, but the port number as that
is how they are stored internlly.

    my @protocols=$search->get_protocols;

=cut

sub get_protocols{
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	return keys( %{ $self->{protocols} } );
}

=head2 get_states

Get a list of desired sets.

The returned value is a array.

The returned values are all lowercased. Any trailing
or proceeding whitespace will also have been removed.

    my @states=$search->get_states;

=cut

sub get_states{
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	return keys( %{ $self->{states} } );
}

=head2 search

This runs the search results.

    my @found=$search->search( $res );

=cut

sub search{
	my $self=$_[0];
	my $res=$_[1];

	if( ! $self->errorblank ){
		return undef;
	}

	#make sure what ever we are passed is sane and very likely a return from Parse::Netdata
	if (
		( ref( $res ) ne 'ARRAY' ) ||
		( ! defined( $res->[2] )  ) ||
		( ! defined( $res->[2]->{active_conns} ) )
		){
		$self->{error}=3;
		$self->{errorString}='$res->[2]->{active_conns} not defiend. Does not appear to be a Parse::Netstat return';
		$self->warn;
		return undef;
	}

	# holds the found results
	my @found;

	# requirements checks, defaulting to not required
	my $port_require=0;
	my $cidr_require=0;
	my $protocol_require=0;
	my $state_require=0;

	# figure out what we need to check for
	if (defined( $self->{cidrs}[0] )){
		$cidr_require=1;
	}
	if (defined( (keys(%{ $self->{ports} }))[0] )){
		$port_require=1;
	}
	if (defined( (keys(%{ $self->{protocols} }))[0] )){
		$protocol_require=1;
	}
	if (defined( (keys(%{ $self->{states} }))[0] )){
		$state_require=1;
	}

	my $res_int=0;
	while ( defined( $res->[2]->{active_conns}->[$res_int] ) ){
		# ignore unix sockets
		if ( $res->[2]->{active_conns}->[$res_int]->{proto} ne 'unix' ){
			my $foreign_port=$res->[2]->{active_conns}->[$res_int]->{foreign_port};
			my $state=$res->[2]->{active_conns}->[$res_int]->{state};
			my $protocol=$res->[2]->{active_conns}->[$res_int]->{proto};
			my $local_port=$res->[2]->{active_conns}->[$res_int]->{local_port};
			my $local_host=$res->[2]->{active_conns}->[$res_int]->{local_host};
			my $foreign_host=$res->[2]->{active_conns}->[$res_int]->{foreign_host};
			my $sendq=$res->[2]->{active_conns}->[$res_int]->{sendq};
			my $recvq=$res->[2]->{active_conns}->[$res_int]->{recvq};

			# checks for making sure a check is meet... defaults to 1
			my $port_meet=1;
			my $cidr_meet=1;
			my $protocol_meet=1;
			my $protocol_search=lc( $protocol );
			my $state_meet=1;
			my $state_search=lc( $state );

			# reset the meet checks
			if ( $port_require ) {
				$port_meet=0;
			}
			if ( $cidr_require ) {
				$cidr_meet=0;
			}
			if ( $protocol_require ) {
				$protocol_meet=0;
			}
			if ( $state_require ) {
				$state_meet=0;
			}

			# checks the forient port against each CIDR
			if (
				$cidr_require &&
				(
				 (
				  ( $foreign_host ne '*' ) &&
				  ( Net::CIDR::cidrlookup( $foreign_host, @{ $self->{cidrs} } ) )
				  ) ||
				 (
				  ( $local_host ne '*' ) &&
				  ( Net::CIDR::cidrlookup( $local_host, @{ $self->{cidrs} } ) )
				  )
				 )
				) {
				$cidr_meet=1;
			}

			# handle it if port checking is required
			if (
				$port_require &&
				(
				 ( defined( $self->{ports}{$foreign_port} ) ) ||
				 ( defined( $self->{ports}{$local_port} ) )
				 )
				) {
				$port_meet=1;
			}

			# check protocol to see if it is one that is required
			if (
				$protocol_require &&
				defined( $self->{protocols}{$protocol_search} )
				){
				$protocol_meet=1;
			}

			# check state to see if it is one that is required
			if (
				$state_require &&
				defined( $self->{states}{$state_search} )
				){
				$state_meet=1;
			}

			# if these are all good, add them
			if (
				$port_meet && $protocol_meet && $cidr_meet && $state_meet
				){
				push( @found, {
							   'foreign_port'=>$foreign_port,
							   'foriegn_host'=>$foreign_host,
							   'local_port'=>$local_port,
							   'local_host'=>$local_host,
							   'sendq'=>$sendq,
							   'recvq'=>$recvq,
							   'proto'=>$protocol,
							   }
					  );
			}

		}

		$res_int++;
	}

	return @found;
}

=head2 set_cidrs

This sets the list of CIDRs to search for
in either the local or remote field.

One value is taken and that is a array ref of CIDRs.

Validating in is done by Net::CIDR::cidrvalidate.

If you are using this, you will want to use -n with netstat
as this module currently does not resolve names.

    # set the desired CIDRs to the contents of @CIDRs
    $search->set_cidrs( \@CIDRs );
    if ( $search->error ){
        warn("Improper CIDR");
    }

    # clear any previously set
    $search->set_cidrs;

=cut

sub set_cidrs{
	my $self=$_[0];
	my @cidrs;
	if ( defined( $_[1] ) ){
		@cidrs=@{ $_[1] };
	}

	if( ! $self->errorblank ){
		return undef;
	}

	#blank it if none is given
	if ( !defined( $cidrs[0] ) ){
		$self->{cidrs}=\@cidrs;
	}

	#chueck each one
	my $cidr_int=0;
	while ( defined( $cidrs[$cidr_int] ) ){
		my $cidr=$cidrs[$cidr_int];
		if ( ! Net::CIDR::cidrvalidate( $cidr ) ){
			$self->{error}=1;
			$self->{errorString}='"'.$cidr.'" is not a valid CIDR according to Net::CIDR::cidrvalidate';
			$self->warn;
			return undef;

		}

		$cidr_int++;
	}

	$self->{cidrs}=\@cidrs;

	return 1;
}

=head2 set_ports

This sets the ports to search for in either
the local or remote field.

One value is taken and that is a array ref of ports.

The ports can be either numeric or by name.

    # Set the desired ports to the contents of @ports.
    $search->set_ports( \@ports );
    if ( $search->error ){
        warn("Bad value in ports array");
    }

    # removes any previous selections
    $search->set_ports;

=cut

sub set_ports{
	my $self=$_[0];
	my @ports;
	if ( defined( $_[1] ) ){
		@ports=@{ $_[1] };
	}

	if( ! $self->errorblank ){
		return undef;
	}

	if ( !defined( $ports[0] ) ){
		$self->{ports}={};
	}

	my $port=pop( @ports );
	my %lookup_hash;
	while( defined( $port ) ){
		my $port_number=$port;
		if ( $port !~ /^\d+$/ ){
			# Find the first matching port number.
			# Does not care what protocol comes up.
			$port_number=(getservbyname( $port , '' ))[2];

			# If it is not defined, we did not find a matching
			# service record for the requested port name.
			if ( !defined( $port_number ) ){
				$self->{error}=2;
				$self->{errorString}='"'.$port.'" was not found as a known service';
				$self->warn;
				return undef;
			}
		}

		$lookup_hash{$port_number}=1;

		$port=pop( @ports );
	}

	#save this for later
	$self->{ports}=\%lookup_hash;

	return 1;
}

=head2 set_protocols

Sets the list of desired protocols to match.

One value is taken and that is a array.

If this is undef, then  previous settings will be cleared.

Lacking of exhaustive list of possible values for the
OSes supported by Parse::Netstat, no santity checking
is done.

Starting and trailing white space is removed.

    # Set the desired ports to the contents of @protocols.
    $search->set_protocols( \@protocols );
    if ( $search->error ){
        warn("Bad value in ports array");
    }

    # removes any previous selections
    $search->set_protocols;

=cut

sub set_protocols{
	my $self=$_[0];
	my @protocols;
	if ( defined( $_[1] ) ){
		@protocols=@{ $_[1] };
	}

	if( ! $self->errorblank ){
		return undef;
	}

	if ( !defined( $protocols[0] ) ){
		$self->{protocols}={};
	}

	my %lookup_hash;
	my $protocol=pop( @protocols );
	while( defined( $protocol ) ){
		$protocol=~s/^[\ \t]*//;
		$protocol=~s/^[\ \t]*//;

		#create a LCed version of the protocol name
		$lookup_hash{ lc( $protocol ) }=1;

		$protocol=pop( @protocols );
	}

	#save it for usage later
	$self->{protocols}=\%lookup_hash;

	return 1;
}

=head2 set_states

Sets the list of desired states to match.

One value is taken and that is a array.

If this is undef, then  previous settings will be cleared.

Lacking of exhaustive list of possible values for the
OSes supported by Parse::Netstat, no santity checking
is done.

Starting and trailing white space is removed.

    # Set the desired ports to the contents of @protocols.
    $search->set_protocols( \@protocols );
    if ( $search->error ){
        warn("Bad value in ports array");
    }

    # removes any previous selections
    $search->set_protocols;

=cut

sub set_states{
	my $self=$_[0];
	my @states;
	if ( defined( $_[1] ) ){
		@states=@{ $_[1] };
	}

	if( ! $self->errorblank ){
		return undef;
	}

	if ( !defined( $states[0] ) ){
		$self->{staes}={};
	}

	my %lookup_hash;
	my $state=pop(@states);
	while ( defined( $state ) ){
		$state=~s/^[\ \t]*//;
		$state=~s/^[\ \t]*//;

		#create a LCed version of the protocol name
		$lookup_hash{ lc( $state ) }=1;

		$state=pop(@states);
	}

	#save it for usage later
	$self->{states}=\%lookup_hash;

	return 1;
}

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>.

=head2 1 / badCIDR

Invalid CIDR passed.

Validation is done by Net::CIDR::cidrvalidate.

=head2 2 / unknownService

Could not look up the port number for the specified service.

=head2 3 / badResults

The passed array does not appear to be properly formatted.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-netstat-search at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-Netstat-Search>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::Netstat::Search


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Netstat-Search>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-Netstat-Search>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Parse-Netstat-Search>

=item * Search CPAN

L<https://metacpan.org/release/Parse-Netstat-Search>

=item * Code Repo

L<http://gitea.eesdp.org/vvelox/Parse-Netstat-Search>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Parse::Netstat::Search
