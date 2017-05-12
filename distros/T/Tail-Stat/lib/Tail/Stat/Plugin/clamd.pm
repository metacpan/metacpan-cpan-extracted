package Tail::Stat::Plugin::clamd;

=head1 NAME

Tail::Stat::Plugin::clamd - Statistics collector for ClamAV clamd

=cut

use strict;
use warnings qw(all);


=head1 SYNOPSIS

tstatd -o type clamd clamd.log


=head1 LOG FORMATS

Plugin search clamd logs for records of two types:

=over

=item C<clean>

clamd: /var/spool/exim/scan/1PLMRr-000MyJ-Kg/1PLMRr-000MyJ-Kg.eml: OK

=item C<malware>

clamd: /var/spool/exim/scan/1PLRje-0008yP-U3/1PLRje-0008yP-U3.eml: Exploit.HTML.IFrame-8 FOUND

=back


=head1 OPTIONS

=over

=item C<type>

Turn on collecting per-malware statistics.

=back


=head1 STATISTICS

=head2 Overall statistics

=over

=item C<clean_messages>

Total number of messages identified as clean.

=item C<malware_messages>

Total number of messages identified as malware.

=back


=head2 Last statistics

=over

=item C<last_clean_messages>

Total number of last messages identified as clean.

=item C<last_malware_messages>

Total number of last messages identified as malware.

=item C<last_clean_rate>

Total rate of last messages identified as clean.

=item C<last_malware_rate>

Total rate of last messages identified as malware.

=back


=cut


use base qw(Tail::Stat::Plugin);
use List::Util qw(sum);


sub regex { qr{

	:\s+
	(?:
		(\S+)          # 'malware' [0]
			\s+
		FOUND
		|
		OK
	)
	$

}x }


sub process_data {
	my $self = shift;
	my ($ref,$pub,$prv,$win) = @_;

	my $status = $ref->[0] ? 'malware' : 'clean';

	$pub->{ $status }++;
	$pub->{ 'malware:' . $ref->[0] }++
		if $self->{type} && $status eq 'malware';

	$win->{ $status }++;

	return 1;
}


sub process_window {
	my $self = shift;
	my ($pub,$prv,$wins) = @_;

	for my $m ( qw( clean malware ) ) {
		$pub->{'last_' . $m } = sum ( map { $_->{ $m } || 0 } @$wins ) || 0;
	}
}


sub stats_zone {
	my ($self,$zone,$pub,$prv,$wins) = @_;

	# required keys defaults
	my %out = ( clean => 0, malware => 0 );

	# copy values as is
	$out{$_} += $pub->{$_} for keys %$pub;

	map { $_.': '.$out{$_} } sort keys %out;
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

