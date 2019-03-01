package Parse::Netstat::Search::Sort;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Net::IP;

=head1 NAME

Parse::Netstat::Search::Sort - Sorts the returned array from Parse::Netstat::Search.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use Parse::Netstat::Search;
    use Parse::Netstat::Search::Sort;
    use Parse::Netstat qw(parse_netstat);

    my $res = parse_netstat(output => join("", `netstat -n`), tcp=>1, udp=>1, unix=>0,  flavor=>$^O);

    my $pn-search=Parse::Netstat::Search->new;

    my @found=$pn-search->search( $res );

    my $sorter = Parse::Netstat::Search::Sort->new;

    @found = $sorter->sort( \@found );

The supported sort methods are as below.

    host_f     Host, Foreign (default)
    host_l     Host, Local
    port_f     Port, Foriegn
    port_l     Port, Local
    state      State
    protocol   Protocol
    q_r        Queue, Receive
    q_s        Queue, Send
    none       No sorting is done.

These dual sort can take noticably longer than the ones above.

    host_ff    Host, Foreign First
    host_lf    Host, Local First
    port_ff    Port, Foreign First
    port_lf    Port, Local First
    q_rf       Queue, Receive First
    q_sf       Queue, Send First

=head1 Methods

=head2 new

Initiates the object.

    my $sorter=Parse::Netstat::Search->new;

=cut

sub new{
	my $self={
			  perror=>undef,
			  error=>undef,
			  errorString=>'',
			  errorExtra=>{
						   1 => 'badSort',
						   2 => 'badArray',
						   },
			  sort=>'host_f',
			  invert=>undef,
			  sort_check=>{
						   host_ff=>1,
						   host_lf=>1,
						   host_f=>1,
						   host_l=>1,
						   port_ff=>1,
						   port_lf=>1,
						   port_f=>1,
						   port_l=>1,
						   state=>1,
						   protocol=>1,
						   q_rf=>1,
						   q_sf=>1,
						   q_r=>1,
						   q_s=>1,
						   none=>1,
						   }
			  };
	bless $self;

	return $self;
}

=head2 get_sort

This returns the current sort method.

    my $sort=$pnc->get_sort;

=cut

sub get_sort{
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	return $self->{sort};
}

=head2 set_sort

This sets the sort method to be used and if it should
be inverted.

The first argument is the sort method name and the second is a
boolean on if it should be inverted or not.

Leaving either undef resets the undef value back to the default.

The supported sorting methods are as below.

    $ sorter->set_sort( $sort_method );
    if( $sorter->error ){
        warn( '"'.$sort_method.'"' is not a valid sort method );
    }
    
    # reset to defaults
    $sorter->set_sort
    
    # Set the sort method to host_f and invert.
    $sorter->set_sort( 'host_f' )

=cut

sub set_sort{
	my $self=$_[0];
	my $sort=$_[1];

	if( ! $self->errorblank ){
		return undef;
	}

	if (!defined( $sort ) ){
		$sort='host_f';
	}

	if (! defined( $self->{sort_check}{$sort} ) ){
		$self->{error}=1;
		$self->{errorString}='"'.$sort.'" is not a valid sort type';
		$self->warn;
		return undef;
	}
	
	$self->{sort}=$sort;

	return 1;
}

=head2 sort

Sorts the provided array from Parse::Netstat::Search.

    my @sorted=$sorter->sort( \@found );

=cut

sub sort{
	my $self=$_[0];
	my @found;
	if (
		defined( $_[1] ) &&
		( ref($_[1]) eq 'ARRAY' )
		){
		@found=@{ $_[1] };
	}else{
		$self->{error}=2;
		$self->{errorString}='The passed item is either not a array or undefined';
		$self->warn;
		return undef;
	}

	if( ! $self->errorblank ){
		return undef;
	}

	# handle sorting if needed
	if ( $self->{sort} ne 'none' ){
		if( $self->{sort} eq 'host_ff' ){
			@found=sort  {
			    &host_sort_helper( $a->{foreign_host} ) <=>  &host_sort_helper( $b->{foreign_host} ) or
				&host_sort_helper( $a->{local_host} ) <=>  &host_sort_helper( $b->{local_host} )
			} @found;
		}elsif( $self->{sort} eq 'host_lf' ){
			@found=sort  {
				&host_sort_helper( $a->{local_host} ) <=>  &host_sort_helper( $b->{local_host} ) or
			    &host_sort_helper( $a->{foreign_host} ) <=>  &host_sort_helper( $b->{foreign_host} )
			} @found;
		}elsif( $self->{sort} eq 'host_f' ){
			@found=sort  {
			    &host_sort_helper( $a->{foreign_host} ) <=>  &host_sort_helper( $b->{foreign_host} )
			} @found;
		}elsif( $self->{sort} eq 'host_l' ){
			@found=sort  {
				&host_sort_helper( $a->{local_host} ) <=>  &host_sort_helper( $b->{local_host} )
			} @found;
		}elsif( $self->{sort} eq 'port_ff' ){
			@found=sort  {
				&port_sort_helper( $a->{foreign_port} ) <=> &port_sort_helper( $b->{foreign_port} ) or
				&port_sort_helper( $a->{local_port} ) <=> &port_sort_helper( $b->{local_port} )
			} @found;
		}elsif( $self->{sort} eq 'port_lf' ){
			@found=sort  {
				&port_sort_helper( $a->{local_port} ) <=> &port_sort_helper( $b->{local_port} ) or
				&port_sort_helper( $a->{foreign_port} ) <=> &port_sort_helper( $b->{foreign_port} )
			} @found;
		}elsif( $self->{sort} eq 'port_f' ){
			@found=sort  {
				&port_sort_helper( $a->{foreign_port} ) <=> &port_sort_helper( $b->{foreign_port} )
			} @found;
		}elsif( $self->{sort} eq 'port_l' ){
			@found=sort  {
				&port_sort_helper( $a->{local_port} ) <=> &port_sort_helper( $b->{local_port} )
			} @found;
		}elsif( $self->{sort} eq 'state' ){
			@found=sort  {
				$a->{state} cmp  $b->{state}
			} @found;
		}elsif( $self->{sort} eq 'protocol' ){
			@found=sort  {
				$a->{proto} cmp $b->{proto}
			} @found;
		}elsif( $self->{sort} eq 'q_rf' ){
			@found=sort  {
				$a->{recvq} <=> $b->{recvq} or
				$a->{sendq} <=> $b->{sendq}
			} @found;
		}elsif( $self->{sort} eq 'q_sf' ){
			@found=sort  {
				$a->{sendq} <=> $b->{sendq} or
				$a->{recvq} <=> $b->{recvq}
			} @found;
		}elsif( $self->{sort} eq 'q_r' ){
			@found=sort  {
				$a->{recvq} <=> $b->{recvq}
			} @found;
		}elsif( $self->{sort} eq 'q_s' ){
			@found=sort  {
				$a->{sendq} <=> $b->{sendq}
			} @found;
		}
	}

	return @found;
}

=head2 host_sort_helper

Internal function.

Takes a host and converts it to a number.

=cut

sub host_sort_helper{
	if (
		( !defined($_[0]) ) ||
		( $_[0] eq '*' )
		){
		return 0;
	}
	my $host=eval { Net::IP->new( $_[0] )->intip} ;
	if (!defined( $host )){
		return 0;
	}
	return $host;
}

=head2 port_sort_helper

Internal function.

Makes sure a port number is always returned.

=cut

sub port_sort_helper{
	if (
		( !defined($_[0]) ) ||
		( $_[0] eq '*' )
		){
		return 0;
	}
	return $_[0];
}

=head1 ERROR CODES / FLAGS

Error handling is provided by L<Error::Helper>.

=head2 1 / badSort

Invalid value specified for sort.

=head2 2 / badArray

The passed item is not a array.

=head1 AUTHOR

Zame C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-netstat-search-sort at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-Netstat-Search-Sort>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::Netstat::Search::Sort


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Netstat-Search-Sort>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-Netstat-Search-Sort>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Parse-Netstat-Search-Sort>

=item * Search CPAN

L<https://metacpan.org/release/Parse-Netstat-Search-Sort>

=item * Code Rep

L<https://gitea.eesdp.org/vvelox/Parse-Netstat-Search-Sort>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 Zame C. Bowers-Hadley.

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

1; # End of Parse::Netstat::Search::Sort
