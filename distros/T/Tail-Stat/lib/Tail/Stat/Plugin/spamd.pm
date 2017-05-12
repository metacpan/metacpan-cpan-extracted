package Tail::Stat::Plugin::spamd;

=head1 NAME

Tail::Stat::Plugin::spamd - Statistics collector for SpamAssassin spamd

=cut

use strict;
use warnings qw(all);


=head1 SYNOPSIS

tstatd -o usr spamd spamd.log


=head1 LOG FORMATS

Plugin search spamd logs for records of two types:

=over

=item C<clean>

spamd: clean message (3.1/5.0) for alex:1004 in 2.3 seconds, 1327 bytes.

=item C<spam>

spamd: identified spam (16.4/5.0) for andrew:1004 in 6.3 seconds, 2937 bytes.

=back


=head1 OPTIONS

=over

=item C<usr>

Turn on collecting per-user statistics.

=back


=head1 STATISTICS

=head2 Overall statistics

=over

=item C<clean_messages>

Total number of messages identified as clean.

=item C<spam_messages>

Total number of messages identified as spam.

=item C<clean_bytes>

Total number of bytes for messages identified as clean.

=item C<spam_bytes>

Total number of bytes for messages identified as spam.

=item C<clean:I<login>>

Total number of messages identified as clean for I<login>
(B<usr> option is required).

=item C<spam:I<login>>

Total number of messages identified as spam for I<login>
(B<usr> option is required).

=back


=head2 Last statistics

=over

=item C<last_clean_messages>

Total number of last messages identified as clean.

=item C<last_spam_messages>

Total number of last messages identified as spam.

=item C<last_clean_bytes>

Total number of bytes from last messages identified as clean.

=item C<last_spam_bytes>

Total number of bytes from last messages identified as spam.

=item C<last_clean_rate>

Total rate of last messages identified as clean.

=item C<last_spam_rate>

Total rate of last messages identified as spam.

=item C<last_clean_elapsed>

Total number of seconds elapsed for processing last messages identified as clean.

=item C<last_spam_elapsed>

Total number of seconds elapsed for processing last messages identified as spam.

=back


=cut


use base qw(Tail::Stat::Plugin);
use List::Util qw(sum);


sub regex { qr{

	spamd:
		\s+
	(?:
		identified\s+(spam)   # 'spam' [0]
		|
		(clean)\s+message     # 'clean' [1]
	)
		\s+
	\(
		([\d\.-]+)            # rate [2]
		/
		([\d\.-]+)            # threshold [3]
	\)
		\s+
	for
		\s+
	(\S+)                     # login [4]
		:
	(\d+)                     # uid [5]
		\s+
	in
		\s+
	([\d\.-]+)                # elapsed time [6]
		\s+
	seconds,
		\s+
	(\d+)                     # message size [7]
		\s
	bytes

}x }


sub process_data {
	my $self = shift;
	my ($ref,$pub,$prv,$win) = @_;

	my $m = $ref->[0] || $ref->[1];

	$pub->{ $m.'_messages' }++;
	$pub->{ $m.'_bytes'} += $ref->[7];
	$pub->{ $m.':'.$ref->[4] }++ if $self->{usr};

	$win->{ $m.'_messages' }++;
	$win->{ $m.'_bytes'} += $ref->[7];
	$win->{ $m.'_rate'} += $ref->[2];
	$win->{ $m.'_elapsed'} += $ref->[6];

	return 1;
}


sub process_window {
	my $self = shift;
	my ($pub,$prv,$wins) = @_;

	for my $m ( qw( clean spam ) ) {
		for my $x ( qw( bytes elapsed messages rate ) ) {
			$pub->{'last_'.$m.'_'.$x} = sum ( map { $_->{$m.'_'.$x} || 0 } @$wins ) || 0;
		}
	}
}


sub stats_zone {
	my ($self,$zone,$pub,$prv,$wins) = @_;

	# required keys defaults
	my %out;
	for my $x ( qw( bytes messages ) ) {
		$out{$_.'_'.$x} = 0 for qw( clean spam );
	}
	for my $x ( qw( bytes elapsed messages rate ) ) {
		$out{'last_'.$_.'_'.$x} = 0 for qw( clean spam );
	}

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

