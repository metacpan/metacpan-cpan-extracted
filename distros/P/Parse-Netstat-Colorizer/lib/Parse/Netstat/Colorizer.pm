package Parse::Netstat::Colorizer;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Parse::Netstat;
use Parse::Netstat::Search;
use Parse::Netstat::Search::Sort;
use Term::ANSIColor;
use Text::Table;

=head1 NAME

Parse::Netstat::Colorizer - Searches and colorizes the output from Parse::Netstat

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Parse::Netstat;
    use Parse::Netstat::Colorizer;
    
    my $pnc = Parse::Netstat::Colorizer->new();
    
    # don't even bother parsing unix sockets... Parse::Netstat::Search, Parse::Netsat::Search::Sort;
    # and this only currently handle non-unix network connections
    my $res = parse_netstat(output => join("", `netstat -n`), tcp=>1, udp=>1, unix=>0,  flavor=>$^O);
    
    # search only for connections to/from specific networks
    my @networks=('192.168.0.0/24', '10.10.10.0/24');
    my $search=$pnc->get_search;
    $search->set_cidrs( \@networks );
    if ( $search->error ){
        warn( 'One of the passed CIDRs is bad' );
    }
    
    # set it to host local sort
    my $sorter=$pnc->get_sort;
    $sorter->set_sort( 'host_l' );

Sorting and searching is handled via L<Parse::Netsat::Search> and
L<Parse::Netstat::Search::Sort>. Their objects for tweaking can be
fetched via get_sort and get_search.

=head1 METHODS

=head2 new

Creates a new object. This will never error.

    my $pnc->new;

=cut

sub new {
	my $self={
			  perror=>undef,
			  error=>undef,
			  errorString=>'',
			  errorExtra=>{
						   1 => 'badResults',
						   2 => 'searchErrored',
						   3 => 'sortErrored',
						   },
			  os=>$^O,
			  invert=>undef,
			  port_resolve=>1,
			  search=>Parse::Netstat::Search->new,
			  sort=>Parse::Netstat::Search::Sort->new,
			  };
	bless $self;

	return $self;
}

=head1 colorize

This runs the configured search and colorizes
the output.

One value is taken and that is the array ref returned
by Parse::Netstat.

    my $colorized=$pnc->colorize($res);
    if ( $pnc->error ){
        warn( 'Either $res is not valid post a basic check or sorting failed.
    }

=cut

sub colorize{
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
		$self->{error}=1;
		$self->{errorString}='$res->[2]->{active_conns} not defiend. Does not appear to be a Parse::Netstat return';
		$self->warn;
		return undef;
	}

	my @found=$self->{search}->search( $res );

	# sort it all
	@found=$self->{sort}->sort( \@found );
	if ( $self->{sort}->error ){
		$self->{error}=3;
		$self->{errorString}='Sort failed';
		$self->warn;
		return undef;
	}

	# invert if needed
	if ( $self->{invert} ){
		@found=reverse(@found);
	}

	# Holds colorized lines for the table.
	my @colored=([
				 color('underline white').'Proto'.color('reset'),
				 color('underline white').'SendQ'.color('reset'),
				 color('underline white').'RecvQ'.color('reset'),
				 color('underline white').'Local Host'.color('reset'),
				 color('underline white').'Port'.color('reset'),
				 color('underline white').'Remote Host'.color('reset'),
				 color('underline white').'Port'.color('reset'),
				 color('underline white').'State'.color('reset'),
				 ]);

	# process each connection
	my $conn=pop(@found);
	while ( defined( $conn->{local_port} ) ){
		my $port_l=$conn->{local_port};
		my $port_f=$conn->{foreign_port};

		#resolve port numbers if needed
		if ( $self->{port_resolve} ){
			my $port_l_search=getservbyport( $port_l, '' );
			if ( defined( $port_l_search ) ){
				$port_l=$port_l_search;
			}

			# make sure we have have a actual number
			# UDP may not have one of these listed
			if ( $port_f =~ /^\d+$/ ){
				my $port_f_search=getservbyport( $port_f, '' );
				if ( defined( $port_f_search ) ){
					$port_f=$port_f_search;
				}
			}
		}

		my @new_line=(
					  color('BRIGHT_YELLOW').$conn->{proto}.color('reset'),
					  color('BRIGHT_CYAN').$conn->{sendq}.color('reset'),
					  color('BRIGHT_RED').$conn->{recvq}.color('reset'),
					  color('BRIGHT_GREEN').$conn->{local_host}.color('reset'),
					  color('GREEN').$port_l.color('reset'),
					  color('BRIGHT_MAGENTA').$conn->{foreign_host}.color('reset'),
					  color('MAGENTA').$port_f.color('reset'),
					  color('BRIGHT_BLUE').$conn->{state}.color('reset'),
					  );

		push( @colored, \@new_line );

		$conn=pop(@found);
	}

	my $tb = Text::Table->new;

	return $tb->load( @colored );
}

=head2 get_invert

This returns a boolean as to if the return
from the sort is inverted or not.

    my $invert=$pnc->get_invert;

=cut

sub get_invert{
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	return $self->{invert};
}

=head2 get_port_resolve

This gets the port_resolve value, which is if it should try to resolve
port names or not.

The returned value is a boolean and defaults to 1.

    my $port_resolve=$pnc->get_port_resolve;

=cut

sub get_port_resolve{
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	return $self->{port_resolve};
}

=head1 get_search

This returns the Parse::Netstat::Search object.

    my $search=$pnc->get_search;

=cut

sub get_search{
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	return $self->{search};
}

=head1 get_sort

This returns the Parse::Netstat::Search::Sort object.

    my $sorter=$pnc->get_sort;

    # set it to host local sort
    $sorter->set_sort( 'host_l' );

=cut

sub get_sort{
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	return $self->{sort};
}

=head2 set_invert

This sets wether or not it should invert the
returned sort or not.

    # sets it to false, the default
    $pnc->set_invert;

    # the results will be inverted
    $pnc->set_invert;

=cut

sub set_invert{
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	$self->{invert}=$_[1];
}

=head2 set_port_resolve

This sets wether or not the ports should be resolved or not.

One value is taken and that is a perl boolean.

    # sets it to true, the default
    $pnc->set_port_resolve(1);

    # set it false, don't resolve the ports
    $pnc->set_port_resolve;

=cut

sub set_port_resolve{
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	$self->{port_resolve}=$_[1];
}

=head

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>.

=head2 1 / badResults

The passed Parse::Netstat array does not appear to be properly formatted.

=head2 2 / searchErrored

Parse::Netstat::Search->search errored.

=head2 3 / sortErrored

Parse::Netsat::Search::Sort errored.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-netstat-colorizer at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-Netstat-Colorizer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::Netstat::Colorizer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Netstat-Colorizer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-Netstat-Colorizer>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Parse-Netstat-Colorizer>

=item * Search CPAN

L<https://metacpan.org/release/Parse-Netstat-Colorizer>

=item * Code Repo

L<https://gitea.eesdp.org/vvelox/Parse-Netstat-Colorizer>

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

1; # End of Parse::Netstat::Colorizer
