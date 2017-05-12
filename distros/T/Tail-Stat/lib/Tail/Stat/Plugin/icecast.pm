package Tail::Stat::Plugin::icecast;

=head1 NAME

Tail::Stat::Plugin::icecast - Statistics collector for Icecast streaming server

=cut

use strict;
use warnings 'all';


=head1 SYNOPSIS

tstatd icecast error.log


=head1 LOG FORMATS

Plugin search icecast error logs for records like:

=over

=item C<listener count>

 INFO source/source_main listener count on /mv128.mp3 now 73

=back


=head1 STATISTICS

=head2 Overall statistics

=over

=item C<online:I<stream>>

Current number of connected clients.

=item C<enter:I<stream>>

Total number of clients connects.

=item C<leave:I<stream>>

Total number of clients disconnects.

=back

=cut


use base 'Tail::Stat::Plugin';


sub regex { qr{

	(?:
		INFO                      # just a marker
			\s+
		source/source_main        # is it same for all servers?
			\s+
		listener\scount\son
			\s+
		/(\S+)                    # stream [0]
			\s+
		now
			\s+
		(\d+)                     # users [1]
	)
	$

}x }


sub process_data {
	my $self = shift;
	my ($ref,$pub,$prv,$win) = @_;

	my $was = $pub->{ 'online:' . $ref->[0] } || 0;
	$pub->{ 'online:' . $ref->[0] } = $ref->[1];

	return $pub->{ 'enter:' . $ref->[0] } += $ref->[1] - $was
		if $ref->[1] > $was;
	return $pub->{ 'leave:' . $ref->[0] } += $was - $ref->[1]
		if $ref->[1] < $was;
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

