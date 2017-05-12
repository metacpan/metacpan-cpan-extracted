package Tail::Stat::Plugin::cvsupd;

=head1 NAME

Tail::Stat::Plugin::cvsupd - Statistics collector for CVSupd server

=cut

use strict;
use warnings qw(all);


=head1 SYNOPSIS

tstatd cvsupd cvsupd.log


=head1 LOG FORMATS

Plugin search cvsupd logs for records of three types:

=over

=item C<connect>

 +1088 root@host.domain.com [CSUP_1_0/17.0]

=item C<update>

 =1088 [2597Kin+1797Kout] ports-all/cvs

=item C<disconnect>

 -1088 [2597Kin+1797Kout] Finished successfully

=back


=head1 STATISTICS

=head2 Overall statistics

=over

=item C<clients>

Total number of received clients connections.

=item C<client:I<version>>

Total number of connections received with client I<version>.

=item C<collections>

Total number of requsted collections.

=item C<collection:I<collection>>

Total number of updates of I<collection>.

=item C<bytes_in>

Total traffic received.

=item C<bytes_out>

Total traffic sent.

=item C<status:I<status>>

Total number of disconnects with I<status>.

=back

=cut


use base qw(Tail::Stat::Plugin);
use List::Util qw(sum);

sub regex { qr{

	(?:
		(\+)                      # operation [0]
		(\d+)                     # connection [1]
			\s+
		(\S+)                     # user [2]
			\@
		(\S+)                     # host [3]
			\s+
		\[([^\]]+)\]              # version [4]
	|
		(=)                       # operation [5]
		(\d+)                     # connection [6]
			\s+
		\[(\d+)Kin\+(\d+)Kout\]   # traffic [7],[8]
			\s+
		(\S+)                     # collection [9]
	|
		(-)                       # operation [10]
		(\d+)                     # connection [11]
			\s+
		\[(\d+)Kin\+(\d+)Kout\]   # traffic [12],[13]
			\s+
		(.+)                      # status [14]
	)
	$

}x }


sub process_data {
	my $self = shift;
	my ($ref,$pub,$prv,$win) = @_;

	if ( $ref->[0] ) {
		# connect
		$pub->{ clients }++;
		$win->{ clients }++;
		$pub->{ 'client:' . $ref->[4] }++;
	} elsif ( $ref->[5] ) {
		# collection
		$pub->{ collections }++;
		$win->{ collections }++;
		$ref->[9] =~ s{:}{_}g;
		$pub->{ 'collection:' . $ref->[9] }++;
	} elsif ( $ref->[10] ) {
		# disconnect
		$pub->{ bytes_in }  += 1024 * $ref->[12];
		$pub->{ bytes_out } += 1024 * $ref->[13];
		$win->{ bytes_in }  += 1024 * $ref->[12];
		$win->{ bytes_out } += 1024 * $ref->[13];
		$ref->[14] =~ s{:}{_}g;
		$pub->{ 'status:' . $ref->[14] }++;
	}
}


sub process_window {
	my $self = shift;
	my ($pub,$prv,$wins) = @_;

	for my $m ( qw( clients collections bytes_in bytes_out ) ) {
		$pub->{'last_' . $m } = sum ( map { $_->{ $m } || 0 } @$wins ) || 0;
	}
}


sub stats_zone {
	my ($self,$zone,$pub,$prv,$wins) = @_;

	# required keys defaults
	my %out = ( ( map { $_ => 0 } qw(
		clients
		collections
		bytes_in
		bytes_out

		last_clients
		last_collections
		last_bytes_in
		last_bytes_out
	) ), %$pub );

	map { $_ . ': ' . $out{ $_ } } sort keys %out;
}


=head1 AUTHOR

Oleg A. Mamontov, C<< <oleg@mamontov.net> >>


=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

