package Tail::Stat::Plugin::nginx;

=head1 NAME

Tail::Stat::Plugin::nginx - Statistics collector for Nginx web-server

=cut

use strict;
use warnings qw(all);


=head1 SYNOPSIS

tstatd -o clf nginx httpd.access_log


=head1 LOG FORMATS

Nginx has predefined (compiled in) log format named B<combined>.
This format defined as:

log_format  combined  '$remote_addr - $remote_user [$time_local] '
                      '"$request" $status $body_bytes_sent '
                      '"$http_referer" "$http_user_agent"';

This format produces such lines:

1.2.3.4 - - [22/Jan/2010:19:34:21 +0300] "GET /foo/ HTTP/1.1" 200 11078 "http://www.rambler.ru/" "Mozilla/5.0 (Windows; U; Windows NT 5.1"

For collecting statistics about request timing, upstream delays and
cache efficiency it's recommended to extend log format:

log_format  extended  '$remote_addr - $remote_user [$time_local] '
                      '"$request" $status $body_bytes_sent '
                      '"$http_referer" "$http_user_agent" '
                      'rt=$request_time ut="$upstream_response_time" '
                      'cs=$upstream_cache_status';

Extended format creates log records like this:

1.2.3.4 - - [22/Jan/2010:19:34:21 +0300] "GET /foo/ HTTP/1.1" 200 11078 "http://www.rambler.ru/" "Mozilla/5.0 (Windows; U; Windows NT 5.1" rt=0.010 ut="2.001, 0.345" cs=MISS


=head1 OPTIONS

=over

=item C<clf>

Simplify regular expression (don't accumulate information about client/upstream timings and cache status).

=back


=head1 STATISTICS

=head2 Overall statistics


=head3 HTTP traffic

=over

=item C<http_request>

Total number of served requests.

=item C<http_byte>

Total number of sent bytes.

=item C<malformed_request>

Total number of malformed requests.

=back


=head3 HTTP methods

=over

=item C<http_method_head>

Total number of served HEAD requests.

=item C<http_method_get>

Total number of served GET requests.

=item C<http_method_inc>

Total number of served subrequests.

=item C<http_method_post>

Total number of served POST requests.

=item C<http_method_other>

Total number of served another types of requests.

=back


=head3 HTTP versions

=over

=item C<http_version_0_9>

Total number of served HTTP/0.9 requests.

=item C<http_version_1_0>

Total number of served HTTP/1.0 requests.

=item C<http_version_1_1>

Total number of served HTTP/1.1 requests.

=item C<http_version_2_0>

Total number of served HTTP/2.0 requests.

=back


=head3 HTTP statuses

=over

=item C<http_status_xxx>

Total number of served requests with status of xxx.

=item C<http_status_1xx>

Total number of served requests with status of 100-199.

=item C<http_status_2xx>

Total number of served requests with status of 200-299.

=item C<http_status_3xx>

Total number of served requests with status of 300-399.

=item C<http_status_4xx>

Total number of served requests with status of 400-499.

=item C<http_status_5xx>

Total number of served requests with status of 500-599.

=back


=head3 Cache statuses

B<NOTE:> available unless C<clf> option in use.

=over

=item C<cache_status_expired>

Total number of served request with cache status EXPIRED.

=item C<cache_status_hit>

Total number of served request with cache status HIT.

=item C<cache_status_miss>

Total number of served request with cache status MISS.

=item C<cache_status_stale>

Total number of served request with cache status STALE.

=item C<cache_status_updating>

Total number of served request with cache status UPDATING.

=back


=head3 Upstream requests

B<NOTE:> available unless C<clf> option in use.

=over

=item C<upstream_request>

Total number of requests proxied to upstreams.

=item C<upstream_next_count>

Total number of switching between upstreams.

=back


=head2 Last statistics


=head3 HTTP traffic

=over

=item C<last_http_request>

Total number of served requests during last window.

=item C<last_http_byte>

Total number of sent bytes during last window.

=item C<last_request_time>

Total amount of time elapsed to serve requests during last window.

B<NOTE:> available unless C<clf> option in use.

=back


=head3 Upstream requests

B<NOTE:> available unless C<clf> option in use.

=over

=item C<last_upstream_request>

Total number of proxied requests during last window.

=item C<last_upstream_time>

Total amount of time elapsed to proxying requests during last window.

=back

=cut


use base qw(Tail::Stat::Plugin);
use List::Util qw(sum);


sub regex {
	my $self = shift;

	my $re = qr{
		^
		(\S+)              # remote address [0]
			\s
		(\S+)              # ident [1]
			\s
		(\S+)              # remote user [2]
			\s
		\[([^\]]+)\]       # time local [3]
			\s
		"(?:               # request
			([A-Z]+)       # http method [4]
				\s+
			(/[^"]*?)      # request uri [5]
			(?:            # http version > 0.9
				\s+
			HTTP/(1\.[01]|2\.0) # http version [6]
			)?
			|
			([^"]*)        # malformed request [7]
		)"
			\s
		([1-5]\d{2})       # http status [8]
			\s
		(\d+|-)            # content length [9]
			\s
		"([^"]*)"          # referrer [10]
			\s
		"([^"]*)"          # user agent [11]
	}x;
	$re .= qr{
		(?:
			\srt=([\d\.]+)   # request time [12]
				|
			\sut="([^"]+)"   # upstream response time [13]
				|
			\scs=(\S+)       # upstream cache status [14]
				|
			.
		)*
	}x unless $self->{clf};

	return $re;
}


sub process_data {
	my $self = shift;
	my ($ref,$pub,$prv,$win) = @_;

	# don't take into account at all
	return 1 if $ref->[8]==400 || $ref->[8]==408;

	$pub->{http_request}++;
	$win->{http_request}++;

	if ($ref->[4]) {  # method
		$pub->{'http_method_'.$ref->[4]}++;
		if ($ref->[6]) {  # version
			$pub->{'http_version_'.$ref->[6]}++;
		} elsif ($ref->[4] ne 'INC') {
			$pub->{'http_version_0.9'}++;
		}
	} else {
		$pub->{malformed_request}++;
	}

	$pub->{'http_status_'.$ref->[8]}++;

	unless ($ref->[9] eq '-') {
		$pub->{http_byte} += $ref->[9];
		$win->{http_byte} += $ref->[9];
	}

	# extended part
	unless ($self->{clf}) {
		$win->{request_time} += $ref->[12]
			if $ref->[12] &&
			   $ref->[12] < 1_000_000;  # old nginx bug workaround

		if ($ref->[13] && $ref->[13] ne '-') {
			if (index($ref->[13], ',') >= 0 ||
				index($ref->[13], ' : ') >= 0 ) {  # several upstreams
				my @ut = grep { $_ ne '-' } split '(?:, | : )', $ref->[13];
				$pub->{upstream_request} += @ut;
				$win->{upstream_request} += @ut;
				$pub->{upstream_next} += $#ut if @ut;
				$win->{upstream_time} += $_ for @ut;
			} else {  # single upstream
				$pub->{upstream_request}++;
				$win->{upstream_request}++;
				$win->{upstream_time} += $ref->[13];
			}
		}

		$pub->{'cache_status_'.$ref->[14]}++ if $ref->[14] && $ref->[14] ne '-';
	}

	return 1;
}


sub process_window {
	my $self = shift;
	my ($pub,$prv,$wins) = @_;

	for my $x (
		qw( http_request http_byte ),
		$self->{clf} ?
			() :
			qw( request_time upstream_request upstream_time )
		) {
		$pub->{'last_'.$x} = sum ( map { $_->{$x} || 0 } @$wins ) || 0;
	}
}


sub stats_zone {
	my ($self,$zone,$pub,$prv,$wins) = @_;

	# required keys defaults
	my %out = map { $_ => 0 } qw(

		malformed_request

		http_request
		last_http_request

		http_byte
		last_http_byte

		http_method_head
		http_method_get
		http_method_inc
		http_method_post
		http_method_other

		http_version_0_9
		http_version_1_0
		http_version_1_1
		http_version_2_0

		http_status_1xx
		http_status_2xx
		http_status_3xx
		http_status_4xx
		http_status_5xx

	), $self->{clf} ? () : qw(

		last_request_time
		last_upstream_time

		upstream_request
		last_upstream_request

		upstream_next

		cache_status_expired
		cache_status_hit
		cache_status_miss
		cache_status_stale
		cache_status_updating

	);


	# agregate required keys
	for ( keys %$pub ) {

		# http_method
		/^http_method_(HEAD|GET|INC|POST)/ and do {
			$out{'http_method_'. lc $1} += $pub->{$_};
			next;
		};
		/^http_method_/ and do {
			$out{'http_method_other'} += $pub->{$_};
			next;
		};

		# http_status
		/^http_status_([1-5])/ and do {
			$out{'http_status_'. $1.'xx'} += $pub->{$_};
			# particular statuses
			$out{$_} += $pub->{$_};
			next;
		};

		# http_version
		/^http_version_(\S+)/ and do {
			(my $v = $1) =~ s/\./_/g;
			$out{'http_version_'. $v} += $pub->{$_};
			next;
		};

		# extended mode
		unless ($self->{clf}) {
			# cache_status
			/^cache_status_(\S+)/ and do {
				$out{'cache_status_'. lc $1} += $pub->{$_};
				next;
			};

			# copy remainings values as is
			$out{$_} += $pub->{$_};

			next;
		}

		# simple attributes
		/^(?:
			malformed_request |
			http_request      |
			last_http_request |
			http_byte         |
			last_http_byte
		)$/x and do {
			$out{$_} += $pub->{$_};
			next;
		};
	}

	map { $_.': '.$out{$_} } sort keys %out;
}


sub parse_error {
	'notice'
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

