package Net::Connection::Sort::port_f;

use 5.006;
use strict;
use warnings;

=head1 NAME

Net::Connection::Sort::port_f - Sorts the connections via the foreign port numerically.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

This currently implements numeric sorting only. For non-numeric sorting using port_fa.

    use Net::Connection::Sort::port_f;
    use Net::Connection;
    use Data::Dumper;
    
     my @objects=(
                  Net::Connection->new({
                                        'foreign_host' => '3.3.3.3',
                                        'local_host' => '4.4.4.4',
                                        'foreign_port' => '23',
                                        'local_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4',
                                        'ports' => 0,
                                        }),
                  Net::Connection->new({
                                        'foreign_host' => '1.1.1.1',
                                        'local_host' => '2.2.2.2',
                                        'foreign_port' => '22',
                                        'local_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4',
                                        'ports' => 0,
                                        }),
                  Net::Connection->new({
                                        'foreign_host' => '5.5.5.5',
                                        'local_host' => '6.6.6.6',
                                        'foreign_port' => '80',
                                        'local_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4',
                                        'ports' => 0,
                                        }),
                  Net::Connection->new({
                                        'foreign_host' => '3.3.3.3',
                                        'local_host' => '4.4.4.4',
                                        'foreign_port' => '21',
                                        'local_port' => '11132',
                                        'sendq' => '1',
                                        'recvq' => '0',
                                        'state' => 'ESTABLISHED',
                                        'proto' => 'tcp4',
                                        'ports' => 0,
                                        }),
                 );
    
    my $sorter=$sorter=Net::Connection::Sort::port_f->new;
    
    @objects=$sorter->sorter( \@objects );
    
    print Dumper( \@objects );

=head1 METHODS

=head2 new

This initiates the module.

No arguments are taken and this will always succeed.

    my $sorter=$sorter=Net::Connection::Sort::port_f->new;

=cut

sub new{
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};


	my $self = {
				};
    bless $self;

	return $self;
}

=head2 sort

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
		$a->foreign_port <=> $b->foreign_port
	} @objects;

	return @objects;
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
