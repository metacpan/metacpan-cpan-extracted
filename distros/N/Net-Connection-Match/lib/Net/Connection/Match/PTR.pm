package Net::Connection::Match::PTR;

use 5.006;
use strict;
use warnings;
use Net::DNS;

=head1 NAME

Net::Connection::Match::PTR - Runs a PTR check against a Net::Connection object.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Net::Connection::Match::PTR;
    use Net::Connection;
    
    # The *_ptr feilds do not need populated.
    # If left undef, they will be resulved using Net::DNS::Resolver
    my $connection_args={
                         foreign_host=>'10.0.0.1',
                         foreign_port=>'22',
                         foreign_ptr=>'foo.foo',
                         local_host=>'10.0.0.2',
                         local_port=>'12322',
                         local_ptr=>'foo.bar',
                         proto=>'tcp4',
                         state=>'ESTABLISHED',
                        };
    
    my $conn=Net::Connection->new( $connection_args );
    
    # All three don't need specified, but
    # Atleast one of them must be and must not be a empty array.
    my %args=(
              ptrs=>[
                     'foo.bar',
                      ],
              lptrs=>[
                      'a.foo.bar',
                       ],
              fptrs=>[
                      'b.foo.bar',
                       ],
              );
    
    my $checker=Net::Connection::Match::Ports->new( \%args );
    
    if ( $checker->match( $conn ) ){
        print "It matches.\n";
    }

=head1 METHODS

=head2 new

This intiates the object.

    my %args=(
              ptrs=>[
                     'foo.bar',
                      ],
              lptrs=>[
                      'a.foo.bar',
                       ],
              fptrs=>[
                      'b.foo.bar',
                       ],
              );
    
    my $checker=Net::Connection::Match::Ports->new( \%args );


=head3 args

Atleast one of the following need used.

=keys ptrs

This is a array of PTRs to match in for either foreign
or local side.

=keys fptrs

This is a array of PTRs to match in for the foreign side.

=keys lptrs

This is a array of PTRs to match in for the local side.

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	# run some basic checks to make sure we have the minimum stuff required to work
	if (
		( ! defined( $args{ptrs} ) ) &&
		( ! defined( $args{fptrs} ) ) &&
		( ! defined( $args{lptrs} ) )
		){
		die ('No [fl]ptrs key specified in the argument hash');
	}
	if (
		(
		 defined( $args{ptrs} ) &&
		 ( ! defined( $args{ptrs}[0] ) )
		 ) &&
		(
		 defined( $args{lptrs} ) &&
		 ( ! defined( $args{lptrs}[0] ) )
		 ) &&
		(
		 defined( $args{fptrs} ) &&
		 ( ! defined( $args{fptrs}[0] ) )
		 )
		){
		die ('No ports defined in the in any of the [fl]ptrs array');
	}

    my $self = {
				ptrs=>{},
				fptrs=>{},
				lptrs=>{},
				resolver=>Net::DNS::Resolver->new,
				};
    bless $self;

	##
	## These are all stored as lower case to make matching easier.
	##

	# Process the ports for matching either
	my $ptrs_int=0;
	if ( defined( $args{ptrs} ) ){
		while (defined( $args{ptrs}[$ptrs_int] )) {
			$self->{ptrs}{ $args{ptrs}[$ptrs_int] }=lc( $args{ptrs}[$ptrs_int] );

			$ptrs_int++;
		}
	}

	# Process the ports for matching local ports
	$ptrs_int=0;
	if ( defined( $args{lptrs} ) ){
		while (defined( $args{lptrs}[$ptrs_int] )) {
			$self->{lptrs}{ $args{lptrs}[$ptrs_int] }=lc( $args{lptrs}[$ptrs_int] );

			$ptrs_int++;
		}
	}

	# Process the ports for matching foreign ports
	$ptrs_int=0;
	if ( defined( $args{fptrs} ) ){
		while (defined( $args{fptrs}[$ptrs_int] )) {
			$self->{fptrs}{ $args{fptrs}[$ptrs_int] }=lc( $args{fptrs}[$ptrs_int] );

			$ptrs_int++;
		}
	}

	return $self;
}

=head2 match

Checks if a single Net::Connection object matches the stack.

One argument is taken and that is a Net::Connection object.

The returned value is a boolean.

If the *_ptr feilds for the object are undef, L<Net::DNS::Resolver>
will be used for resolving the address.

    if ( $checker->match( $conn ) ){
        print "The connection matches.\n";
    }

=cut

sub match{
	my $self=$_[0];
	my $object=$_[1];

	if ( !defined( $object ) ){
		return 0;
	}

	if ( ref( $object ) ne 'Net::Connection' ){
		return 0;
	}

	my $l_ptr=$object->local_ptr;
	my $f_ptr=$object->foreign_ptr;

	if ( defined( $l_ptr ) ){
		# If we have one, convert it to lower case for easier processing.
		$l_ptr=lc( $l_ptr )
	}else{
		# We don't have it. Uppercase default will prevent it from being matched.
		$l_ptr='NOTFOUND';
		# See if we can look it up.
		my $answer=$self->{resolver}->search( $object->local_host );
		if ( defined( $answer->{answer}[0] ) &&
			 ( ref( $answer->{answer}[0] ) eq 'Net::DNS::RR::PTR' )
			){
			$l_ptr=lc($answer->{answer}[0]->ptrdname);
		}
	}

	if ( defined( $f_ptr ) ){
		# If we have one, convert it to lower case for easier processing.
		$f_ptr=lc( $f_ptr )
	}else{
		# We don't have it. Uppercase default will prevent it from being matched.
		$f_ptr='NOTFOUND';
		# See if we can look it up.
		my $answer=$self->{resolver}->search( $object->foreign_host );
		if ( defined( $answer->{answer}[0] ) &&
			 ( ref( $answer->{answer}[0] ) eq 'Net::DNS::RR::PTR' )
			){
			$f_ptr=lc($answer->{answer}[0]->ptrdname);
		}
	}

	# If we matched exactly, we found it.
	if (
		defined( $self->{ptrs}{ $l_ptr } ) ||
		defined( $self->{ptrs}{ $f_ptr } ) ||
		defined( $self->{lptrs}{ $l_ptr } ) ||
		defined( $self->{fptrs}{ $f_ptr } )
		){
		return 1;
	}

	return 0;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-connection-match at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Connection-Match>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Connection::Match


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Connection-Match>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Connection-Match>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-Connection-Match>

=item * Search CPAN

L<https://metacpan.org/release/Net-Connection-Match>

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

1; # End of Net::Connection::Match
