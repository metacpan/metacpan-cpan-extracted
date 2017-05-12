#!/usr/bin/perl
use Net::Gnutella;
use Data::Dumper;
use IO::File;
use strict;
use vars qw/$gnutella $shared_timestamp $shared_size @shared_files %shared_words %common_words %current_downloads %current_connects/;

use constant SERVER_ADDRESS       => "198.142.4.65";
use constant SERVER_PORT          => 6348;
use constant SERVER_SPEED         => 128000;

use constant SHARED_FILE_LIST     => "list.txt";

use constant MAX_CONNECTS         => 2;

use constant MAX_DOWNLOADS        => 6;
use constant MAX_DOWNLOADS_PER_IP => 2;

printf STDERR "%s: Starting server\n", scalar localtime;

$gnutella = new Net::Gnutella;

my $server = $gnutella->new_server(
	Server  => SERVER_ADDRESS,
	Port    => SERVER_PORT,
	Allow   => GNUTELLA_CONNECT|GNUTELLA_REQUEST,
	Debug   => 2,
);

$gnutella->add_handler("connected",         \&on_connect);
$gnutella->add_handler("disconnect",        \&on_disconnect);
$gnutella->add_handler("ping",              \&on_ping);
$gnutella->add_handler("query",             \&on_query);
$gnutella->add_handler("download_req",      \&on_download_req);
$gnutella->add_handler("download_complete", \&on_download_end);
$gnutella->add_handler("download_error",    \&on_download_end);

load_shared_files();

$gnutella->schedule("1m", \&send_ping);
$gnutella->schedule("1m", \&load_shared_files);
$gnutella->start;

# One level keepalive ping
#
sub send_ping {
	my $ping = Net::Gnutella::Packet::Ping->new(
		Msgid => $gnutella->id,
		TTL   => 1,
	);

	foreach my $conn ($gnutella->connections) {
		$conn->send_packet($ping);
	}

	$gnutella->schedule("1m", \&send_ping);
}

sub on_connect {
	my ($self) = @_;

	my $ip = $self->ip;

	unless (allowed_to_connect($ip)) {
		$self->disconnect;
		return;
	}

	$current_connects{ $ip }++;

	printf STDERR "%s: Connection from %s\n", scalar localtime, $ip;

	my $ping = Net::Gnutella::Packet::Ping->new(
		Msgid => $gnutella->id,
	);

	$self->send_packet($ping);
}

sub on_disconnect {
	my ($self) = @_;

	my $ip = $self->ip;

	printf STDERR "%s: Disconnect from %s\n", scalar localtime, $ip;

	$current_connects{ $ip }--;
}

sub on_ping {
	my ($self, $event) = @_;

	my $pong = Net::Gnutella::Packet::Pong->new(
		Msgid => $event->packet->msgid,

		Ip    => SERVER_ADDRESS,
		Port  => SERVER_PORT,
		Count => scalar(@shared_files),
		Size  => int($shared_size / 1024),
	);

	$self->send_packet($pong);
}

sub on_query {
	my ($self, $event) = @_;

	my $packet = $event->packet;
	my @tokens = tokenise($packet->query);

	unless (scalar @tokens) {
		return;
	}

	my $results = find_by_tokens(@tokens);

	unless (defined $results) {
		return;
	}

	my $reply = Net::Gnutella::Packet::Reply->new(
		Msgid   => $packet->msgid,

		Ip      => SERVER_ADDRESS,
		Port    => SERVER_PORT,
		Speed   => SERVER_SPEED,
		Results => $results,
		Guid    => $gnutella->id,
	);

	$self->send_packet($reply);
}

sub on_download_req {
	my ($self, $event) = @_;

	my $request = $event->packet;

	if ($request->method eq 'GET' and $request->url->path =~ m|/get/(\d+)/(.+)|) {
		my ($index, $file) = ($1, $2);

		if (my $filename = find_by_index($index, $file)) {
			my $ip = $self->ip;

			if (allowed_to_download($ip)) {
				my $offset = $1 if $request->headers->header("Range") =~ /^bytes=(\d+)-$/;

				if ($self->send_file($filename, $offset)) {
printf STDERR "%s: Uploading file '%s' to %s\n", scalar localtime, $file, $ip;

					$current_downloads{ $ip }++;
				}
			} else {
				$self->send_error(503); # SERVICE UNAVAILABLE
			}
		} else {
print "not found [$index] [$file]\n";
			$self->send_error(404); # NOT FOUND
		}
	} elsif ($request->method eq 'GET' and $request->url->path =~ m|/admin(?:/(.*))?|) {
		my $page = $1 || "menu.html";

		if ($page eq "menu.html") {
			$self->send_page(<<EOPAGE);
<H1>Gnutella menu</H1>

<LI> <A HREF="/admin/shared.html">List all shared files (by keyword)</A>
<LI> <A HREF="/admin/connections.html">List all connections</A>
<LI> <A HREF="/admin/hosts.html">List host cache</A>
EOPAGE
		} elsif ($page eq "shared.html") {
			$self->send_page(Dumper(\%shared_words));
		} elsif ($page eq "connections.html") {
			$self->send_page("<PRE>".Dumper(\%current_connects, \%current_downloads)."</PRE>");
		} elsif ($page eq "hosts.html") {
			$self->send_page("<PRE>".Dumper($gnutella->{_host_cache})."</PRE>");
		} else {
			$self->send_error(404); # NOT FOUND
		}
	} else {
		$self->send_error(403); # FORBIDDEN
	}
}

# Decrement counters
#
sub on_download_end {
	my ($self) = @_;

	my $ip = $self->ip;

	printf STDERR "%s: Upload complete to '%s'\n", scalar localtime, $ip;

	$current_downloads{ $ip }--;
}

sub allowed_to_connect {
	my $ip = shift;

	my $count = 0;
	$count += $current_connects{$_} foreach keys %current_connects;

	return 1 if $ip =~ /^198\.142\.4\.6[567]$/;
	return if $count >= MAX_CONNECTS;
	return 1;
}

# Returns true (1) if download permitted
#
sub allowed_to_download {
	my $ip = shift;

	my $count = 0;
	$count += $current_downloads{$_} foreach keys %current_downloads;

	return 1 if $ip =~ /^198\.142\.4\.6[567]$/;
	return if $count >= MAX_DOWNLOADS;
	return if $current_downloads{ $ip } >= MAX_DOWNLOADS_PER_IP;
	return 1;
}

# Returns full path if the filename shared at index matches...
#
sub find_by_index {
	my ($index, $filename) = @_;
	my $full = $shared_files[$index]->[0];

	return unless length $full;
	return unless -f $full;

	my $file = (File::Spec->splitpath($full))[2];

	return $full if $file eq $filename;
	return;
}

# Returns filenames which are in the lists for the union of tokens
#
sub find_by_tokens {
	my @tokens = @_;
	my %count;
	my @ret;

	foreach my $token (@tokens) {
		$count{$_}++ foreach @{ $shared_words{$token} || [] }
	}

	foreach my $index (grep { $count{$_} == scalar(@tokens) } keys %count) {
		my $full = $shared_files[$index]->[0];
		my $size = $shared_files[$index]->[1];
		my $file = (File::Spec->splitpath($full))[2];

		push @ret, [ $index, $size, $file ];
	}

	return unless scalar @ret;
	return \@ret;
}

# Loads shared file list if newer than previous version
#
sub load_shared_files {
	my $new_timestamp = (stat(SHARED_FILE_LIST))[9];

	if ($shared_timestamp == $new_timestamp) {
		$gnutella->schedule("1m", \&load_shared_files);
		return;
	}

	printf STDERR "%s: Reading list of shared files (%d != %d)\n", scalar localtime, $shared_timestamp, $new_timestamp;

	@shared_files = ();

	my $fh = new IO::File SHARED_FILE_LIST, O_RDONLY;
	push @shared_files, [ split /\t/ ] foreach grep { chomp; not /^#/ } <$fh>;
	undef $fh;

	printf STDERR "%s: Building token list\n", scalar localtime;

	build_token_list();

	printf STDERR "%s: Done\n", scalar localtime;

	$shared_timestamp = $new_timestamp;

	$gnutella->schedule("1m", \&load_shared_files);
}

# Builds hash of shared files
#
sub build_token_list {
	%shared_words = ();
	$shared_size  = 0;

	for (my $i = 0; $i <= $#shared_files; $i++) {
		my $file = $shared_files[$i]->[0];
		my $size = $shared_files[$i]->[1] ||= -s $file;

		$shared_size += $size;

		foreach (tokenise($file)) {
			push @{$shared_words{$_}}, $i;

			if (scalar @{$shared_words{$_}} > 256) {
				delete $shared_words{$_};
				$common_words{$_} = 1;
			}
		}
	}
}

# Return an array containing all alpha strings of more
#  than two characters length (all elements are lowercase)
#
# 10,000/sec on 333Mhz Celeron
#
sub tokenise {
	my $line = lc shift;
	my %seen;

	$line =~ s/[^a-z]+/ /g;

	foreach (split(" ", $line)) {
		next if length $_ < 3;

		$seen{$_} = 1 unless exists $common_words{$_};
	}

	return keys %seen;
}
