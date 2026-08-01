package Net::Connection::Sort::port_la;

use 5.006;
use strict;
use warnings;

=head1 NAME

Net::Connection::Sort::port_la - Sorts the connections via the local port alphabetically.

=head1 VERSION

Version 0.1.2

=cut

our $VERSION = '0.1.2';


=head1 SYNOPSIS

This sorts on the service name where there is one. Ports without a service
name sort after those with one, numerically. For purely numeric sorting use
port_l.

    use Net::Connection::Sort::port_la;
    use Net::Connection;
    use Data::Dumper;
    
     my @objects=(
                  Net::Connection->new({
                                        'foreign_host' => '3.3.3.3',
                                        'local_host' => '4.4.4.4',
                                        'local_port' => 'FTP',
                                        'foriegn_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4',
                                        'ports' => 0,
                                        }),
                  Net::Connection->new({
                                        'foreign_host' => '1.1.1.1',
                                        'local_host' => '2.2.2.2',
                                        'local_port' => 'SSH',
                                        'foreign_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4',
                                        'ports' => 0,
                                        }),
                  Net::Connection->new({
                                        'foreign_host' => '5.5.5.5',
                                        'local_host' => '6.6.6.6',
                                        'local_port' => 'HTTP',
                                        'foreign_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4',
                                        'ports' => 0,
                                        }),
                  Net::Connection->new({
                                        'foreign_host' => '3.3.3.3',
                                        'local_host' => '4.4.4.4',
                                        'local_port' => 'HTTPS',
                                        'foreign_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4',
                                        'ports' => 0,
                                        }),
                 );
    
    my $sorter=Net::Connection::Sort::port_la->new;
    
    @objects=$sorter->sorter( \@objects );
    
    print Dumper( \@objects );

=head1 METHODS

=head2 new

This initiates the module.

No arguments are taken and this will always succeed.

    my $sorter=Net::Connection::Sort::port_la->new;

=cut

sub new{
	my $self = {
				};
    bless $self;

	return $self;
}

=head2 sorter

This sorts the array of Net::Connection objects.

One object is taken and that is a array of objects.

    @objects=$sorter->sorter( \@objects );
    
    print Dumper( \@objects );

=cut

sub sorter{
	my $self=$_[0];
	my @objects;
	if (
		defined( $_[1] ) &&
		( ref($_[1]) eq 'ARRAY' )
		){
		@objects=@{ $_[1] };
	}else{
		die 'The passed item is either not a array or undefined';
	}

	@objects=sort  {
		my ( $a_nameless, $a_key )=helper( $a );
		my ( $b_nameless, $b_key )=helper( $b );

		# Named ports sort alphabetically ahead of the nameless ones, which
		# sort numerically so port 9 does not end up after port 10. Anything
		# nameless and non-numeric, such as the '*' used for wildcard ports,
		# falls back to a string comparison.
		$a_nameless <=> $b_nameless
			||
		(
		 (
		  $a_nameless &&
		  ( $a_key =~ /^[0-9]+$/ ) &&
		  ( $b_key =~ /^[0-9]+$/ )
		  )
		 ? $a_key <=> $b_key
		 : $a_key cmp $b_key
		 )
	} @objects;

	return @objects;
}

=head2 helper

A internal helper function.

Two items are returned for the connection passed to it. The first is true if
the port has no service name and the second is the value to sort on, either
the service name or the port itself.

=cut

sub helper{
	my $port_name=$_[0]->local_port_name;

	if ( !defined( $port_name ) ){
		return ( 1, $_[0]->local_port );
	}

	return ( 0, $port_name );
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-connection-sort at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Connection-Sort>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Connection::Sort


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Connection-Sort>

=item * Search CPAN

L<https://metacpan.org/release/Net-Connection-Sort>

=item * Git Repo

L<https://gitea.eesdp.org/vvelox/Net-Connection-Sort>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::Connection::Sort
