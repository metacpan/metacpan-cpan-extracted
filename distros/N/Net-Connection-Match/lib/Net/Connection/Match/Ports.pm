package Net::Connection::Match::Ports;

use 5.006;
use strict;
use warnings;

=head1 NAME

Net::Connection::Match::Ports - Runs a basic port check against a Net::Connection object.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Net::Connection::Match::Port;
    use Net::Connection;
    
    my $connection_args={
                         foreign_host=>'10.0.0.1',
                         foreign_port=>'22',
                         local_host=>'10.0.0.2',
                         local_port=>'12322',
                         proto=>'tcp4',
                         state=>'ESTABLISHED',
                        };
    
    my $conn=Net::Connection->new( $connection_args );
    
    my %args=(
              ports=>[
                      'smtp',
                      '22',
                      ],
              lports=>[
                       '21',
                       ],
              fports=>[
                       'http',
                       ],
              );
    
    my $checker=Net::Connection::Match::Ports->new( \%args );
    
    if ( $checker->match( $conn ) ){
        print "It matches.\n";
    }

=head1 METHODS

=head2 new

This intiates the object.

It takes a hash reference with atleast one of of the three
possible keys defined. The possible keys are 'ports'(which
matches either side), 'lports'(which matches the local side),
and 'fports'(which matches the foreign side).

The value of each key is a array with either port numbers or
names. If names are given, getservbyname will be called. If
it errors for any of them, it will die.

If the new method fails, it dies.

    my %args=(
              ports=>[
                      'smtp',
                      '22',
                      ],
              lports=>[
                       '21',
                       ],
              fports=>[
                       'http',
                       ],
              );
    
    my $checker=Net::Connection::Match::Ports->new( \%args );

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	# run some basic checks to make sure we have the minimum stuff required to work
	if (
		( ! defined( $args{ports} ) ) &&
		( ! defined( $args{fports} ) ) &&
		( ! defined( $args{lports} ) )
		){
		die ('No [fl]ports key specified in the argument hash');
	}
	if (
		(
		 defined( $args{ports} ) &&
		 ( ! defined( $args{ports}[0] ) )
		 ) &&
		(
		 defined( $args{lports} ) &&
		 ( ! defined( $args{lports}[0] ) )
		 ) &&
		(
		 defined( $args{fports} ) &&
		 ( ! defined( $args{fports}[0] ) )
		 )
		){
		die ('No ports defined in the in any of the [fl]ports array');
	}

    my $self = {
				ports=>{},
				fports=>{},
				lports=>{},
				};
    bless $self;

	# Process the ports for matching either
	my $ports_int=0;
	if ( defined( $args{ports} ) ){
		while (defined( $args{ports}[$ports_int] )) {
			if ( $args{ports}[$ports_int] =~ /^[0-9]+$/ ){
				$self->{ports}{ $args{ports}[$ports_int] }= $args{ports}[$ports_int];
			}else{
				my $port_number=(getservbyname( $args{ports}[$ports_int] , '' ))[2];

				if( !defined( $port_number ) ){
					die("Could not resolve port '".$args{ports}[$ports_int]."' to a number");
				}

				$self->{ports}{$port_number}=$port_number;
			}

			$ports_int++;
		}
	}

	# Process the ports for matching local ports
	$ports_int=0;
	if ( defined( $args{lports} ) ){
		while (defined( $args{lports}[$ports_int] )) {
			if ( $args{lports}[$ports_int] =~ /^[0-9]+$/ ){
				$self->{lports}{ $args{lports}[$ports_int] }= $args{lports}[$ports_int];
			}else{
				my $port_number=(getservbyname( $args{lports}[$ports_int] , '' ))[2];

				if( !defined( $port_number ) ){
					die("Could not resolve port '".$args{lports}[$ports_int]."' to a number");
				}

				$self->{lports}{$port_number}=$port_number;
			}

			$ports_int++;
		}
	}

	# Process the ports for matching foreign ports
	$ports_int=0;
	if ( defined( $args{fports} ) ){
		while (defined( $args{fports}[$ports_int] )) {
			if ( $args{fports}[$ports_int] =~ /^[0-9]+$/ ){
				$self->{fports}{ $args{fports}[$ports_int] }= $args{fports}[$ports_int];
			}else{
				my $port_number=(getservbyname( $args{fports}[$ports_int] , '' ))[2];

				if( !defined( $port_number ) ){
					die("Could not resolve port '".$args{fports}[$ports_int]."' to a number");
				}

				$self->{fports}{$port_number}=$port_number;
			}

			$ports_int++;
		}
	}

	return $self;
}

=head2 match

Checks if a single Net::Connection object matches the stack.

One argument is taken and that is a Net::Connection object.

The returned value is a boolean.

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

	my $lport=$object->local_port;
	my $fport=$object->foreign_port;

	# If either are non-numeric, resolve them if possible
	if ( $lport !~ /^[0-9]+$/ ){
		my $lport_number=(getservbyname( $lport , '' ))[2];
		if ( defined( $lport_number ) ){
			$lport=$lport_number;
		}
	}
	if ( $fport !~ /^[0-9]+$/ ){
		my $fport_number=(getservbyname( $fport , '' ))[2];
		if ( defined( $fport_number ) ){
			$fport=$fport_number;
		}
	}

	# check if this is one of the ones we are looking for
	if (
		defined( $self->{ports}{ $lport } ) ||
		defined( $self->{ports}{ $fport } ) ||
		defined( $self->{lports}{ $lport } ) ||
		defined( $self->{fports}{ $fport } )
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
