package Net::Connection::Sort::host_lf;

use 5.006;
use strict;
use warnings;
use Net::IP;

=head1 NAME

Net::Connection::Sort::host_lf - Sorts the connections via the local host and then foreign host.

=head1 VERSION

Version 0.1.4

=cut

our $VERSION = '0.1.4';


=head1 SYNOPSIS

    use Net::Connection::Sort::host_lf;
    use Net::Connection;
    use Data::Dumper;
    
     my @objects=(
                  Net::Connection->new({
                                        'foreign_host' => '3.3.3.4',
                                        'local_host' => '4.4.4.5',
                                        'foreign_port' => '22',
                                        'local_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4'
                                        }),
                  Net::Connection->new({
                                        'foreign_host' => '1.1.1.1',
                                        'local_host' => '2.2.2.2',
                                        'foreign_port' => '22',
                                        'local_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4'
                                        }),
                  Net::Connection->new({
                                        'foreign_host' => '5.5.5.5',
                                        'local_host' => '6.6.6.6',
                                        'foreign_port' => '22',
                                        'local_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4'
                                        }),
                  Net::Connection->new({
                                        'foreign_host' => '3.3.3.3',
                                        'local_host' => '4.4.4.4',
                                        'foreign_port' => '22',
                                        'local_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4'
                                        }),
                 );
    
    my $sorter=Net::Connection::Sort::host_lf->new;
    
    @objects=$sorter->sorter( \@objects );
    
    print Dumper( \@objects );

=head1 METHODS

=head2 new

This initiates the module.

No arguments are taken and this will always succeed.

    my $sorter=Net::Connection::Sort::host_lf->new;

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

	# Net::IP is not cheap, so the values to sort on are worked out once per
	# connection here instead of once per comparison in the sort block.
	@objects=map { $_->[2] }
		sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] }
		map { [ helper( $_->local_host ), helper( $_->foreign_host ), $_ ] } @objects;

	return @objects;
}

=head2 helper

This is a internal function.

=cut

sub helper{
        if ( !defined($_[0]) ){
			return 0;
        }
        # Link local addresses arrive with a zone id attached, such as
        # fe80::1%eth0. Neither the check below nor Net::IP will take one.
        my $address=$_[0];
        $address=~s/\%.*$//;
        if (
			( $address eq '*' ) ||
			( $address =~ /[g-zG-Z]/ )
			){
			return 0;
        }
        my $host=eval { Net::IP->new( $address )->intip} ;
        if (!defined( $host )){
			return 0;
        }
        return $host;
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
