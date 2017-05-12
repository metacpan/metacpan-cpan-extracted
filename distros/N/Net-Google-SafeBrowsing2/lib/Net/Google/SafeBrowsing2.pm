package Net::Google::SafeBrowsing2;

use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use URI;
use Digest::SHA qw(sha256);
use List::Util qw(first);
use Text::Trim;
use Digest::HMAC_SHA1 qw(hmac_sha1 hmac_sha1_hex);
use MIME::Base64::URLSafe;
use MIME::Base64;
use String::HexConvert;
use File::Slurp;
use IO::Socket::SSL 'inet4' ;


use Exporter 'import';
our @EXPORT = qw(DATABASE_RESET MAC_ERROR MAC_KEY_ERROR INTERNAL_ERROR SERVER_ERROR NO_UPDATE NO_DATA SUCCESSFUL MALWARE PHISHING);

our $VERSION = '1.13';

BEGIN {
    IO::Socket::SSL::set_ctx_defaults(
#         verify_mode => Net::SSLeay->VERIFY_PEER(),
	SSL_verify_mode => 0,
    );
}


=head1 NAME

DEPRECATED. Please use L<Net::Google::SafeBrowsing3> for the Google Safe Browsing v3 API.

Net::Google::SafeBrowsing2 - Perl library for the Google Safe Browsing v2 API. (Google Safe Browsing v1 has been deprecated by Google.)

=head1 SYNOPSIS

  use Net::Google::SafeBrowsing2;
  use Net::Google::SafeBrowsing2::Sqlite;
  
  my $storage = Net::Google::SafeBrowsing2::Sqlite->new(file => 'google-v2.db');
  my $gsb = Net::Google::SafeBrowsing2->new(
	key 	=> "my key", 
	storage	=> $storage,
  );
  
  $gsb->update();
  my $match = $gsb->lookup(url => 'http://www.gumblar.cn/');
  
  if ($match eq MALWARE) {
	print "http://www.gumblar.cn/ is flagged as a dangerous site\n";
  }

  $storage->close();

=head1 DESCRIPTION

Net::Google::SafeBrowsing2 implements the Google Safe Browsing v2 API.

The library passes most of the unit tests listed in the API documentation. See the documentation (L<http://code.google.com/apis/safebrowsing/developers_guide_v2.html>) for more details about the failed tests.

The Google Safe Browsing database must be stored and managed locally. L<Net::Google::SafeBrowsing2::Sqlite> uses Sqlite as the storage back-end, L<Net::Google::SafeBrowsing2::MySQL> uses MySQL. Other storage mechanisms (databases, memory, etc.) can be added and used transparently with this module.

You may want to look at "Google Safe Browsing v2: Implementation Notes" (L<http://www.zscaler.com/research/Google%20Safe%20Browsing%20v2%20API.pdf>), a collection of notes and real-world numbers about the API. This is intended for people who want to learn more about the API, whether as a user or to make their own implementation.

The source code is available on github at L<https://github.com/juliensobrier/Net-Google-SafeBrowsing2>.

If you do not need to inspect more than 10,000 URLs a day, you can use L<Net::Google::SafeBrowsing2::Lookup> with the Google Safe Browsing v2 Lookup API which does not require to store and maintain a local database.

IMPORTANT: If you start with an empty database, you will need to perform several updates to retrieve all the Google Safe Browsing information. This may require up to 24 hours. This is a limitation of the Google API, not of this module. See "Google Safe Browsing v2: Implementation Notes" at L<http://www.zscaler.com/research/Google%20Safe%20Browsing%20v2%20API.pdf>.

=head1 CONSTANTS

Several  constants are exported by this module:

=over 4

=item DATABASE_RESET

Google requested to reset (empty) the local database.

=item MAC_ERROR

The replies from Google could not be validated with the MAC keys.

=item MAC_KEY_ERROR

The request for the MAC keys failed.

=item INTERNAL_ERROR

An internal error occurred.

=item SERVER_ERROR

The server sent an error back to the client.

=item NO_UPDATE

No update was performed, probably because it is too early to make a new request to Google Safe Browsing.

=item NO_DATA

No data was sent back by Google to the client, probably because the database is up to date.

=item SUCCESSFUL

The operation was successful.

=item MALWARE

Name of the Malware list in Google Safe Browsing (shortcut to 'goog-malware-shavar')

=item PHISHING

Name of the Phishing list in Google Safe Browsing (shortcut to 'googpub-phish-shavar')

=back

=cut

use constant {
	DATABASE_RESET	=> -6,
	MAC_ERROR		=> -5,
	MAC_KEY_ERROR	=> -4,
	INTERNAL_ERROR	=> -3,	# internal/parsing error
	SERVER_ERROR	=> -2, 	# Server sent an error back
	NO_UPDATE		=> -1,	# no update (too early)
	NO_DATA			=> 0, 	# no data sent
	SUCCESSFUL		=> 1,	# data sent
	MALWARE			=> 'goog-malware-shavar',
	PHISHING		=> 'googpub-phish-shavar',
	FULL_HASH_TIME	=> 45 * 60,
	INTERVAL_FULL_HASH_TIME => 'INTERVAL 45 MINUTE',
};


=head1 CONSTRUCTOR

=over 4

=back

=head2 new()

Create a Net::Google::SafeBrowsing2 object

  my $gsb = Net::Google::SafeBrowsing2->new(
	key 	=> "my key", 
	storage	=> Net::Google::SafeBrowsing2::Sqlite->new(file => 'google-v2.db'),
	debug	=> 0,
	mac		=> 0,
	list	=> MALWARE,
  );

Arguments

=over 4

=item server

Safe Browsing Server. https://safebrowsing.clients.google.com/safebrowsing/ by default

=item mac_server

Safe Browsing MAC Server. https://sb-ssl.google.com/safebrowsing/ by default

=item key

Required. Your Google Safe browsing API key

=item storage

Required. Object which handle the storage for the Google Safe Browsing database. See L<Net::Google::SafeBrowsing2::Storage> for more details.

=item list

Optional. The Google Safe Browsing list to handle. By default, handles both MALWARE and PHISHING.

=item mac

Optional. Set to 1 to enable Message Authentication Code (MAC). 0 (disabled) by default.

=item debug

Optional. Set to 1 to enable debugging. 0 (disabled) by default.

The debug output maybe quite large and can slow down significantly the update and lookup functions.

=item errors

Optional. Set to 1 to show errors to STDOUT. 0 (disabled by default).

=item perf

Optional. Set to 1 to show performance information.

=item version

Optional. Google Safe Browsing version. 2.2 by default

=back

=cut

sub new {
	my ($class, %args) = @_;

	my $self = { # default arguments
		server		=> 'https://safebrowsing.clients.google.com/safebrowsing/',
		mac_server	=> 'https://sb-ssl.google.com/safebrowsing/',
		list		=> ['googpub-phish-shavar', 'goog-malware-shavar'],
		key		=> '',
		version		=> '2.2',
		debug		=> 0,
		errors		=> 0,
		last_error	=> '',
		mac		=> 0,
		perf		=> 0,

		%args,
	};

	if (! exists $self->{storage}) {
		use Net::Google::SafeBrowsing2::Storage;
		$self->{storage} = Net::Google::SafeBrowsing2::Storage->new();
	}
	if (ref $self->{list} ne 'ARRAY') {
		$self->{list} = [$self->{list}];
	}

	bless $self, $class or croak "Can't bless $class: $!";
    return $self;
}


=head1 PUBLIC FUNCTIONS

=over 4

=back

=head2 update()

Perform a database update.

  $gsb->update();

Return the status of the update (see the list of constants above): INTERNAL_ERROR, SERVER_ERROR, NO_UPDATE, NO_DATA or SUCCESSFUL

This function can handle two lists at the same time. If one of the list should not be updated, it will automatically skip it and update the other one. It is faster to update two lists at once rather than doing them one by one.

NOTE: If you start with an empty database, you will need to perform several updates to retrieve all the Google Safe Browsing information. This may require up to 24 hours. This is a limitation of the Google API, not of this module. See "Google Safe Browsing v2: Implementation Notes" at L<http://www.zscaler.com/research/Google%20Safe%20Browsing%20v2%20API.pdf>.


Arguments

=over 4

=item list

Optional. Update a specific list. Use the list(s) from new() by default.

=item mac

Optional. Set to 1 to enable Message Authentication Code (MAC). Use the value from new() by default.

=item force

Optional. Force the update (1). Disabled by default (0).

Be careful if you set this option to 1 as too frequent updates might result in the blacklisting of your API key.

=back

=cut

sub update {
	my ($self, %args) 	= @_;
# 	my @lists 		= @{[$args{list}]}	|| @{$self->{list}} || croak "Missing list name\n";
	my $list		= $args{list};
	my $force 		= $args{force}	|| 0;
	my $mac			= $args{mac}	|| $self->{mac}	|| 0;


	my @lists = @{$self->{list}};
	@lists = @{[$args{list}]} if (defined $list);

	my $result = 0;

	# Too early to update?
	my $start = time();
	my $i = 0;
	while ($i < scalar @lists) {
		my $list = $lists[$i];
		my $info = $self->{storage}->last_update(list => $list);
	
		if ($info->{'time'} + $info->{'wait'} > time && $force == 0) {
			$self->debug("Too early to update $list\n");
			splice(@lists, $i, 1);
		}
		else {
			$self->debug("OK to update $list: " . time() . "/" . ($info->{'time'} +  $info->{'wait'}) . "\n");
			$i++;
		}
	}

	if (scalar @lists == 0) {
		$self->debug("Too early to update any list\n");
		return NO_UPDATE;
	}
	$self->perf("OK to update check: " . (time() - $start) . "s\n");
	
	# MAC?
	my $client_key = '';
	my $wrapped_key = '';

	if ($mac) {
		($client_key, $wrapped_key) = $self->get_mac_keys();

		if ($client_key eq '' || $wrapped_key eq '') {
			return MAC_KEY_ERROR;
		}
	}
		


	my $ua = $self->ua;

	my $url = $self->{server} . "downloads?client=api&apikey=" . $self->{key} . "&appver=$VERSION&pver=" . $self->{version};
	$url .= "&wrkey=$wrapped_key" if ($mac);

	my $body = '';
	foreach my $list (@lists) {
		# Report existng chunks
		$start = time();
		my $a_range = $self->create_range(numbers => [$self->{storage}->get_add_chunks_nums(list => $list)]);
		my $s_range = $self->create_range(numbers => [$self->{storage}->get_sub_chunks_nums(list => $list)]);
		$self->perf("Create add and sub ranges: " . (time() - $start) . "s\n");
	
		my $chunks_list = '';
		if ($a_range ne '') {
			$chunks_list .= "a:$a_range";
		}
		if ($s_range ne '') {
			$chunks_list .= ":" if ($a_range ne '');
			$chunks_list .= "s:$s_range";
		}

		$body .= "$list;$chunks_list";
		$body .= ":mac" if ($mac);
		$body .= "\n";
	}

	my $start_req = time();
	my $res = $ua->post($url, Content =>  $body);
	$self->perf("$body\n");

# 	$self->debug($res->request->as_string . "\n" . $res->as_string . "\n");
	$self->debug($res->request->as_string . "\n") if ($self->{debug});
	$self->debug($res->as_string . "\n") if ($self->{debug});
	my $duration_req = time() - $start_req;

	if (! $res->is_success) {
		$self->error("Request failed\n");

		foreach my $list (@lists) {
			$self->update_error('time' => time(), list => $list);
		}

		return SERVER_ERROR;
	}

	my $last_update = time;
	my $wait = 0;

	my @redirections = ();
	my $del_add_duration = 0;
	my $del_sub_duration = 0;
	my $add_range_info = '';

	my @lines = split/\s/, $res->decoded_content;
	$list = '';
	foreach my $line (@lines) {
		if ($line =~ /n:\s*(\d+)\s*$/) {
			$self->debug("Next poll: $1 seconds\n");
			$wait = $1;
		}
		elsif ($line =~ /i:\s*(\S+)\s*$/) {
			$self->debug("List: $1\n");
			$list = $1;
		}
		elsif ($line =~ /u:\s*(\S+),(\S+)\s*$/) {
			$self->debug("Redirection: $1\n");
			$self->debug("MAC: $2\n");
			push(@redirections, [$1, $list, $2]);
		}
		elsif ($line =~ /u:\s*(\S+)\s*$/) {
			$self->debug("Redirection: $1\n");
			push(@redirections, [$1, $list, '']);
		}
		elsif ($line =~ /ad:(\S+)$/) {
			$self->debug("Delete Add Chunks: $1\n");

			my $del_add_start = time();
			$add_range_info = $1 . " $list";
			my @nums = $self->expand_range(range => $1);
			$self->{storage}->delete_add_ckunks(chunknums => [@nums], list => $list);

			# Delete full hash as well
			$self->{storage}->delete_full_hashes(chunknums => [@nums], list => $list);
			$del_add_duration = time() - $del_add_start;

			$result = 1;
		}
		elsif ($line =~ /sd:(\S+)$/) {
			$self->debug("Delete Sub Chunks: $1\n");

			my $del_sub_start = time();
			my @nums = $self->expand_range(range => $1);
			$self->{storage}->delete_sub_ckunks(chunknums => [@nums], list => $list);
			$del_add_duration = time() - $del_sub_start;

			$result = 1;
		}
		elsif ($line =~ /m:(\S+)$/ && $mac) {
			my $hmac = $1;
			$self->debug("MAC of request: $hmac\n");

			# Remove this line for data
			my $data = $res->decoded_content;
			$data =~ s/^m:(\S+)\n//g;

			if (! $self->validate_data_mac(data => $data, key => $client_key, digest => $hmac) ) {
				$self->error("MAC error on main request\n");

				return MAC_ERROR;
			}
		}
		elsif ($line =~ /e:pleaserekey/ && $mac) {
			$self->debug("MAC key has been expired\n");

			$self->{storage}->delete_mac_keys();
			return $self->update(list => $list, force => $force, mac => $mac);
		}
		elsif ($line =~ /r:pleasereset/) {
			$self->debug("Database must be reset\n");

			$self->{storage}->reset(list => $list);

			return DATABASE_RESET;
		}
	}
	$self->debug("\n");
	$self->perf("Handle first request: " . (time() - $last_update) . "s (POST: ${duration_req}s, DEL add: ${del_add_duration}s, DEL sub: ${del_sub_duration}s, ADD range: ${add_range_info})\n");

	$result = 1 if (scalar @redirections > 0);

	$self->perf("Parse redirections: ");
	foreach my $data (@redirections) {
		$start = time();
		my $redirection = $data->[0];
		$list = $data->[1];
		my $hmac = $data->[2];

		$self->debug("Checking redirection https://$redirection ($list)\n");
		$res = $ua->get("https://$redirection");
		if (! $res->is_success) {
			$self->error("Request to $redirection failed\n");

			foreach my $list (@lists) {
				$self->update_error('time' => $last_update, list => $list);
			}

			return SERVER_ERROR;
		}
	
		$self->debug(substr($res->as_string, 0, 250) . "\n\n") if ($self->{debug});
		$self->debug(substr($res->content, 0, 250) . "\n\n") if ($self->{debug});
	
		my $data = $res->content;
		if ($mac && ! $self->validate_data_mac(data => $data, key => $client_key, digest => $hmac) ) {
			$self->error("MAC error on redirection\n");
			$self->debug("Length of data: " . length($data) . "\n");

			return MAC_ERROR;
		}

		my $result = $self->parse_data(data => $data, list => $list);
		if ($result != SUCCESSFUL) {
			foreach my $list (@lists) {
				$self->update_error('time' => $last_update, list => $list);
			}

			return $result;
		}
		$self->perf((time() - $start) . "s ");
	}
	$self->perf("\n");

	foreach my $list (@lists) {
		$self->debug("List update: $last_update $wait $list\n");
		$self->{storage}->updated('time' => $last_update, 'wait' => $wait, list => $list);
	}

	return $result; # ok
}

=head2 import_chunks()

Import add and sub chunks from a file.

  my $result = $gsb->import_chunks(list => MALWARE, file => 'malware.dat');

Return the status of the import: INTERNAL_ERROR or SUCCESSFUL.

This function should be used to initialize an empty back-end storage.


Arguments

=over 4

=item list

Required. Google list to use.

=item file

Required. File that contains the list of chunks. This file can be created with the C<export> function inherited from C<Net::Google::SafeBrowsing2::DBI>.

=back

=cut

sub import_chunks {
	my ($self, %args) 	= @_;
	my $list 			= $args{list}		|| '';
	my $file			= $args{file}		|| "$list.dat";

	my $data = read_file($file, { binmode => ':raw' });

	return $self->parse_data(data => $data, list => $list);

}

=head2 lookup()

Lookup a URL against the Google Safe Browsing database.

  my $match = $gsb->lookup(url => 'http://www.gumblar.cn');

Returns the name of the list if there is any match, returns an empty string otherwise.

Arguments

=over 4

=item list

Optional. Lookup against a specific list. Use the list(s) from new() by default.

=item url

Required. URL to lookup.

=back

=cut

sub lookup {
	my ($self, %args) 	= @_;
	my $list 			= $args{list}		|| '';
	my $url 			= $args{url}		|| return '';

	my @lists = @{$self->{list}};
	@lists = @{[$args{list}]} if ($list ne '');


	# TODO: create our own URI management for canonicalization
	# fix for http:///foo.com (3 ///)
	$url =~ s/^(https?:\/\/)\/+/$1/;



	my $uri = URI->new($url)->canonical;

	my $domain = $uri->host;
	
	my @hosts = $self->canonical_domain_suffixes($domain); # only top-3 in this case

	foreach my $host (@hosts) {
		$self->debug("Domain for key: $domain => $host\n");
		my $suffix = $self->prefix("$host/"); # Don't forget trailing hash
		$self->debug("Host key: " . $self->hex_to_ascii($suffix) . "\n");

		my $match = $self->lookup_suffix(lists => [@lists], url => $url, suffix => $suffix);
		return $match if ($match ne '');
	}

	return '';
}



=head2 get_lists()

Returns the name of all the Google Safe Browsing lists

  my $@lists = $gsb->get_lists();

NOTE: this function is useless in practice because Google includes some lists which cannot be used by the Google Safe Browsing API, like lists used by the Google toolbar.

=cut

sub get_lists {
	my ($self, %args) = @_;

	my $url = $self->{server} . "list?client=api&apikey=" . $self->{key} . "&appver=$VERSION&pver=" . $self->{version};

	my $res = $self->ua->get($url);

	return split/\s/, $res->decoded_content; # 1 list per line
}


=head2 last_error()

Get/Set the last error message.

  print "Last error: ", $gsb->last_error(), "\n";
  $gsb->last_error(''); # Reset last error

NOTE: the last error message might not come from the last call. Returns an empty string if no errors.

=cut

sub last_error {
	my ($self, $message) = @_;

	if (defined $message) {
		$self->{last_error} = $message;
	}
	else {
		return $self->{last_error};
	}
}


=pod

=head1 PRIVATE FUNCTIONS

These functions are not intended to be used externally.

=over 4

=back

=head2 lookup_suffix()

Lookup a host prefix.

=cut

sub lookup_suffix {
	my ($self, %args) 	= @_;
	my $lists 			= $args{lists} 		|| croak "Missing lists\n";
	my $url 			= $args{url}		|| return '';
	my $suffix			= $args{suffix}		|| return '';

	# Calculate prefixes
	my @full_hashes = $self->full_hashes($url); # Get the prefixes from the first 4 bytes
	my @full_hashes_prefix = map (substr($_, 0, 4), @full_hashes);

 	# Local lookup
	my @add_chunks = $self->local_lookup_suffix(lists => $lists, url => $url, suffix => $suffix, full_hashes_prefix => [@full_hashes_prefix]);
	if (scalar @add_chunks == 0) {
		$self->debug("No hit in local lookup\n");
		return '';
	}


	# Check against full hashes
	my $found = '';

	# get stored full hashes
	foreach my $add_chunk (@add_chunks) {
		
		my @hashes = $self->{storage}->get_full_hashes( chunknum => $add_chunk->{chunknum}, timestamp => time() - FULL_HASH_TIME, list => $add_chunk->{list});

		$self->debug("Full hashes already stored for chunk " . $add_chunk->{chunknum} . ": " . scalar @hashes . "\n");
		foreach my $full_hash (@full_hashes) {
			foreach my $hash (@hashes) {
				if ($hash eq $full_hash && defined first { $add_chunk->{list} eq $_ } @$lists) {
					$self->debug("Full hash was found in storage: " . $self->hex_to_ascii($hash) . "\n");
					$found = $add_chunk->{list};
					last;
				}
# 				elsif ($hash ne $full_hash) {
# 					$self->debug($self->hex_to_ascii($hash) . " ne " . $self->hex_to_ascii($full_hash) . "\n\n");
# 				}
			}
			last if ($found ne '');
		}
		last if ($found ne '');
	}

	return $found if ($found ne '');


	# ask for new hashes
	# TODO: make sure we don't keep asking for the same over and over
	my @hashes = $self->request_full_hash(prefixes => [ map($_->{prefix} || $_->{hostkey}, @add_chunks) ]);
	$self->{storage}->add_full_hashes(full_hashes => [@hashes], timestamp => time());

	foreach my $full_hash (@full_hashes) {
		my $hash = first { $_->{hash} eq  $full_hash} @hashes;
		next if (! defined $hash);

		my $list = first { $hash->{list} eq $_ } @$lists;

		if (defined $hash && defined $list) {
# 			$self->debug($self->hex_to_ascii($hash->{hash}) . " eq " . $self->hex_to_ascii($full_hash) . "\n\n");

			$self->debug("Match: " . $self->hex_to_ascii($full_hash)  . "\n");

			return $hash->{list};
		}
# 		elsif (defined $hash) {
# 			$self->debug("hash: " . $self->hex_to_ascii($hash->{hash}) . "\n");
# 			$self->debug("list: " . $hash->{list} . "\n");
# 		}
	}
	
	$self->debug("No match\n");
	return '';
}

=head2 local_lookup_suffix()

Lookup a host prefix in the local database only.

=cut
sub local_lookup_suffix {
	my ($self, %args) 			= @_;
	my $lists 					= $args{lists} 				|| croak "Missing lists\n";
	my $url 					= $args{url}				|| return ();
	my $suffix					= $args{suffix}				|| return ();
	my $full_hashe_list 		= $args{full_hashes}		|| [];
	my $full_hashes_prefix_list = $args{full_hashes_prefix} || [];


	# Step 1: get all add chunks for this host key
	# Do it for all lists
	my @add_chunks = $self->{storage}->get_add_chunks(hostkey => $suffix);
# 	return scalar @add_chunks;
	if (scalar @add_chunks == 0) { # no match
		$self->debug("No host key\n");
		return @add_chunks;
	}

	# Step 2: calculate prefixes if not provided
	# Get the prefixes from the first 4 bytes
	my @full_hashes_prefix = @{$full_hashes_prefix_list};
	if (scalar @full_hashes_prefix == 0) {
		my @full_hashes = @{$full_hashe_list};
		@full_hashes = $self->full_hashes($url) if (scalar @full_hashes == 0);

		@full_hashes_prefix = map (substr($_, 0, 4), @full_hashes);
	}

	# Step 3: filter out add_chunks with prefix
	my $i = 0;
 	while ($i < scalar @add_chunks) {
		if ($add_chunks[$i]->{prefix} ne '') {
			my $found = 0;
			foreach my $hash_prefix (@full_hashes_prefix) {
				if ( $add_chunks[$i]->{prefix} eq $hash_prefix) {
					$found = 1;
					last;
				}
# 				else {
# 					$self->debug( $self->hex_to_ascii($add_chunks[$i]->{prefix}) . " ne " . $self->hex_to_ascii($hash_prefix) . "\n" );
# 				}
			}

			if ($found == 0) {
				$self->debug("No prefix found\n");
				splice(@add_chunks, $i, 1);
			}
			else {
				$i++;
			}
		}
		else {
			$i++;
		}
	}
	if (scalar @add_chunks == 0) {
		$self->debug("No prefix match for any host key\n");
		return @add_chunks;
	}


	# Step 4: get all sub chunks for this host key
	my @sub_chunks = $self->{storage}->get_sub_chunks(hostkey => $suffix);

	foreach my $sub_chunk (@sub_chunks) {
		my $i = 0;
		while ($i < scalar @add_chunks) {
			my $add_chunk = $add_chunks[$i];

			if ($add_chunk->{chunknum} != $sub_chunk->{addchunknum} || $add_chunk->{list} ne $sub_chunk->{list}) {
				$i++;
				next;
			}

			if ($sub_chunk->{prefix} eq $add_chunk->{prefix}) {
				splice(@add_chunks, $i, 1);
			}
			else {
				$i++;
			}
		}
	}

	if (scalar @add_chunks == 0) {
		$self->debug("All add_chunks have been removed by sub_chunks\n");
	}

	return @add_chunks;
}

=head2 local_lookup()

Lookup a URL against the local Google Safe Browsing database URL. This should be used for debugging purpose only. See the lookup for normal use.

  my $match = $gsb->local_lookup(url => 'http://www.gumblar.cn');

Returns the name of the list if there is any match, returns an empty string otherwise.

Arguments

=over 4

=item list

Optional. Lookup against a specific list. Use the list(s) from new() by default.

=item url

Required. URL to lookup.

=back

=cut
sub local_lookup {
	my ($self, %args) 	= @_;
	my $list 			= $args{list}		|| '';
	my $url 			= $args{url}		|| return '';

	my @lists = @{$self->{list}};
	@lists = @{[$args{list}]} if ($list ne '');


	# TODO: create our own URI management for canonicalization
	# fix for http:///foo.com (3 ///)
	$url =~ s/^(https?:\/\/)\/+/$1/;



	my $uri = URI->new($url)->canonical;

	my $domain = $uri->host;
	
	my @hosts = $self->canonical_domain_suffixes($domain); # only top-3 in this case

	foreach my $host (@hosts) {
		$self->debug("Domain for key: $domain => $host\n");
		my $suffix = $self->prefix("$host/"); # Don't forget trailing hash
		$self->debug("Host key: " . $self->hex_to_ascii($suffix) . "\n");

		my @matches = $self->local_lookup_suffix(lists => [@lists], url => $url, suffix => $suffix);
# 		return $matches[0]->{list} if (scalar @matches > 0);
		return $matches[0]->{list} . " " . $matches[0]->{chunknum}  if (scalar @matches > 0);
	}

	return '';

}

=head2 request_key()

Request the Message Authentication Code (MAC) keys

=cut

sub get_mac_keys {
	my ($self, %args) = @_;

	my $keys = $self->{storage}->get_mac_keys();

	if ($keys->{client_key} eq '' || $keys->{wrapped_key} eq '') {
		my ($client_key, $wrapped_key) = $self->request_mac_keys();

# 		$self->debug("Client key: $client_key\n");
		$self->{storage}->add_mac_keys(client_key => $client_key, wrapped_key => $wrapped_key);

		return ($client_key, $wrapped_key);
	}

	return ($keys->{client_key}, $keys->{wrapped_key});
}


=head2 request_mac_keys()

Request the Message Authentication Code (MAC) keys from Google.

=cut

sub request_mac_keys {
	my ($self, %args) = @_;

	my $client_key = '';
	my $wrapped_key = '';

	my $url = $self->{mac_server} . "newkey?client=api&apikey=" . $self->{key} . "&appver=$VERSION&pver=" . $self->{version};

	my $res = $self->ua->get($url);

	if (! $res->is_success) {
		$self->error("Key request failed: " . $res->code . "\n");
		return ($client_key, $wrapped_key);
	}

	

	my $data = $res->decoded_content;
	if ($data =~ s/^clientkey:(\d+)://mi) {
		my $length = $1;
		$self->debug("MAC client key length: $length\n");
		$client_key = substr($data, 0, $length, '');
		$self->debug("MAC client key: $client_key\n");

		substr($data, 0, 1, ''); # remove \n

		if ($data =~ s/^wrappedkey:(\d+)://mi) {
			$length = $1;
			$self->debug("MAC wrapped key length: $length\n");
			$wrapped_key = substr($data, 0, $length, '');
			$self->debug("MAC wrapped key: $wrapped_key\n");

			return (decode_base64($client_key), $wrapped_key);
		}
		else {
			return ('', '');
		}
	}

	return ($client_key, $wrapped_key);
}

=head2 validate_data_mac()

Validate data against the MAC keys.

=cut

sub validate_data_mac {
	my ($self, %args) = @_;
	my $data 			= $args{data}	|| '';
	my $key 			= $args{key}	|| '';
	my $digest			= $args{digest}	|| '';


# 	my $hash = urlsafe_b64encode trim hmac_sha1($data, decode_base64($key));
# 	my $hash = urlsafe_b64encode (trim (hmac_sha1($data, decode_base64($key))));
	my $hash = urlsafe_b64encode(hmac_sha1($data, $key));
	$hash .= '=';

	$self->debug("$hash / $digest\n");
# 	$self->debug(urlsafe_b64encode(hmac_sha1($data, decode_base64($key))) . "\n");
# 	$self->debug(urlsafe_b64encode(trim(hmac_sha1($data, decode_base64($key)))) . "\n");

	return ($hash eq $digest);
}

=head2 update_error()

Handle server errors during a database update.

=cut

sub update_error {
	my ($self, %args) = @_;
	my $time			= $args{'time'}	|| time;
	my $list			= $args{'list'}	|| '';

	my $info = $self->{storage}->last_update(list => $list);
	$info->{errors} = 0 if (! exists $info->{errors});
	my $errors = $info->{errors} + 1;
	my $wait = 0;

	$wait = $errors == 1 ? 60
		: $errors == 2 ? int(30 * 60 * (rand(1) + 1)) # 30-60 mins
	    : $errors == 3 ? int(60 * 60 * (rand(1) + 1)) # 60-120 mins
	    : $errors == 4 ? int(2 * 60 * 60 * (rand(1) + 1)) # 120-240 mins
	    : $errors == 5 ? int(4 * 60 * 60 * (rand(1) + 1)) # 240-480 mins
	    : $errors  > 5 ? 480 * 60
		: 0;

	$self->{storage}->update_error('time' => $time, list => $list, 'wait' => $wait, errors => $errors);

}


=head2 lookup_whitelist()

Lookup a host prefix and suffix in the whitelist (s chunks)

=cut

sub lookup_whitelist {
	my ($self, %args) 	= @_;
	my $suffix 			= $args{suffix}		|| return 0;
	my $prefix 			= $args{prefix}		|| '';
	my $chuknum 		= $args{chunknum}	|| return 0;


	foreach my $schunknum (keys %{ $self->{s_chunks} }) {
		foreach my $chunk ( @{ $self->{s_chunks}->{$schunknum} }) {
			if ($chunk->{host} eq $suffix && ($chunk->{prefix} eq $prefix || $chunk->{prefix} eq '') && $chunk->{add_chunknum} ==  $chuknum) {
				return 1;
			}
		}
	}

	return 0;
}


=head2 ua()

Create LWP::UserAgent to make HTTP requests to Google.

=cut

sub ua {
	my ($self, %args) = @_;

	if (! exists $self->{ua}) {
		my $ua = LWP::UserAgent->new;
  		$ua->timeout(60);

		$self->{ua} = $ua;
	}

	return $self->{ua};
}


=head2 parse_data()

Parse data from a rediration (add and sub chunk information).

=cut

sub parse_data {
	my ($self, %args) 	= @_;
	my $data			= $args{data}		 || '';
	my $list  			= $args{list}		 || '';

	my $chunk_num = 0;
	my $hash_length = 0;
	my $chunk_length = 0;

	while (length $data > 0) {
	# 		print "Length 1: ", length $data, "\n"; # 58748
	
			my $type = substr($data, 0, 2, ''); # s:34321:4:137
	# 		print "Length 1.5: ", length $data, "\n"; # 58746 -2
	
			if ($data  =~ /^(\d+):(\d+):(\d+)\n/sgi) {
				$chunk_num = $1;
				$hash_length = $2;
				$chunk_length = $3;
	
				# shorten data
				substr($data, 0, length($chunk_num) + length($hash_length) + length($chunk_length) + 3, '');
	# 			print "Remove ", length($chunk_num) + length($hash_length) + length($chunk_length) + 3, "\n";
	# 			print "Length 2: ", length $data, "\n"; # 58741 -5
	
				my $encoded = substr($data, 0, $chunk_length, '');
	# 			print "Length 3: ", length $data, "\n"; # 58604 -137
	
				if ($type eq 's:') {
					my @chunks = $self->parse_s(value => $encoded, hash_length => $hash_length);

					$self->{storage}->add_chunks(type => 's', chunknum => $chunk_num, chunks => [@chunks], list => $list); # Must happen all at once => not 100% sure
				}
				elsif ($type eq 'a:') {
					my @chunks = $self->parse_a(value => $encoded, hash_length => $hash_length);
					$self->{storage}->add_chunks(type => 'a', chunknum => $chunk_num, chunks => [@chunks], list => $list); # Must happen all at once => not 100% sure
				}
				else {
					$self->error("Incorrect chunk type: $type, should be a: or s:\n");
					return INTERNAL_ERROR;# failed
				}
	
				$self->debug("$type$chunk_num:$hash_length:$chunk_length OK\n");
			
			}
			else {
				$self->error("could not parse header\n");
				return INTERNAL_ERROR;# failed
			}
		}

	return SUCCESSFUL;
}


=head2 parse_s()

Parse s chunks information for a database update.

=cut

sub parse_s {
	my ($self, %args) 	= @_;
	my $value 			= $args{value}			|| return ();
	my $hash_length 	= $args{hash_length}	|| 4;

	my @data = ();


	while (length $value > 0) {
# 		my $host = $self->hex_to_ascii( substr($value, 0, 4, '') ); # Host hash
		my $host = substr($value, 0, 4, ''); # HEX
# 		print "\t Host key: $host\n";

		my $count = substr($value, 0, 1, ''); # hex value
		$count = ord($count);

# 		my $add_chunk_num_hex;

		if ($count == 0) { # ADDCHUNKNUM only
# 			$self->debug("\nadd_chuknum: " . substr($value, 0, 4) . " => ");
			my $add_chunknum = hex($self->hex_to_ascii( substr($value, 0, 4, '') ) ); #chunk num
# 			$self->debug("$add_chunknum\n");

			push(@data, { host => $host, add_chunknum => $add_chunknum, prefix => '' });

			if ($self->{debug}) {
				$self->debug("\t" . $self->hex_to_ascii($host) . " $add_chunknum\n");
			}
		}
		else { # ADDCHUNKNUM + PREFIX
			for(my $i = 0; $i < $count; $i++) {
# 				my $add_chunknum = $self->hex_to_ascii( substr($value, 0, 4, '') ); #chunk num - ACII
# 				$self->debug("\nadd_chuknum: " . substr($value, 0, 4) . " => ");
				my $add_chunknum = hex($self->hex_to_ascii( substr($value, 0, 4, '') )); # DEC
# 				$self->debug("$add_chunknum\n");

# 				my $prefix = $self->hex_to_ascii( substr($value, 0, $hash_length, '') ); # ASCII
				my $prefix = substr($value, 0, $hash_length, ''); # HEX

				push(@data, { host => $host, add_chunknum => $add_chunknum, prefix =>  $prefix });

				if ($self->{debug}) {
					$self->debug("\t" . $self->hex_to_ascii($host) . " $add_chunknum " . $self->hex_to_ascii($prefix) . "\n");
				}
			}
		}
	}

	return @data;
}


=head2 parse_a()

Parse a chunks information for a database update.

=cut

sub parse_a {
	my ($self, %args) 	= @_;
	my $value 			= $args{value}	|| return ();
	my $hash_length 	= $args{hash_length}	|| 4;

	my @data = ();


	while (length $value > 0) {
# 		my $host = $self->hex_to_ascii( substr($value, 0, 4, '') ); # Host hash
		my $host = substr($value, 0, 4, ''); # HEX
# 		print "\t Host key: $host\n";

		my $count = substr($value, 0, 1, ''); # hex value
		$count = ord($count);


		if ($count > 0) { # ADDCHUNKNUM only
			for(my $i = 0; $i < $count; $i++) {
# 				my $prefix = $self->hex_to_ascii( substr($value, 0, $hash_length, '') ); # ASCII
				my $prefix = substr($value, 0, $hash_length, ''); # HEX

				push(@data, { host => $host, prefix =>  $prefix });

				if ($self->{debug}) {
					$self->debug("\t" . $self->hex_to_ascii($host) . " " . $self->hex_to_ascii($prefix) . "\n");
				}
			}
		}
		else {
			push(@data, { host => $host, prefix =>  '' });

			if ($self->{debug}) {
				$self->debug("\t" . $self->hex_to_ascii($host) . "\n");
			}
		}
	}

	return @data;
}


=head2 hex_to_ascii()

Transform hexadecimal strings to printable ASCII strings. Used mainly for debugging.

  print $gsb->hex_to_ascii('hex value');

=cut

sub hex_to_ascii {
	my ($self, $hex) = @_;

	return String::HexConvert::ascii_to_hex($hex);
# 	my $ascii = '';
# 
# 	while (length $hex > 0) {
# 		$ascii .= sprintf("%02x",  ord( substr($hex, 0, 1, '') ) );
# 	}
# 
# 	return $ascii;
}


=head2 ascii_to_hex()

Transform ASCII strings to hexadecimal strings.

=cut

sub ascii_to_hex {
	my ($self, $ascii) = @_;

	my $hex = '';
	for (my $i = 0; $i < int(length($ascii) / 2); $i++) {
		$hex .= chr hex( substr($ascii, $i * 2, 2) );
	}

	return $hex;
}

=head2 debug()

Print debug output.

=cut

sub debug {
	my ($self, $message) = @_;

	print $message if ($self->{debug} > 0);
}


=head2 error()

Print error message.

=cut

sub error {
	my ($self, $message) = @_;

	print "ERROR - ", $message if ($self->{debug} > 0 || $self->{errors} > 0);
	$self->{last_error} = $message;
}


=head2 error()

Print performance message.

=cut

sub perf {
	my ($self, $message) = @_;

	print $message if ($self->{perf} > 0);
}

=head2 canonical_domain_suffixes()

Find all suffixes for a domain.

=cut

sub canonical_domain_suffixes {
	my ($self, $domain) 	= @_;

	my @domains = ();

	if ($domain =~ /^\d+\.\d+\.\d+\.\d+$/) { # loose check for IP address, should be enough
		return ($domain);
	} 

	my @parts = split/\./, $domain; # take 3 components
	if (scalar @parts >= 3) {
		@parts = splice (@parts, -3, 3);

		push(@domains, join('.', @parts));

		splice(@parts, 0, 1);
	}

	push(@domains, join('.', @parts));

	return @domains;
}


=head2 canonical_domain()

Find all canonical domains a domain.

=cut

sub canonical_domain {
	my ($self, $domain) 	= @_;

	my @domains = ($domain);


	if ($domain =~ /^\d+\.\d+\.\d+\.\d+$/) { # loose check for IP address, should be enough
		return @domains;
	} 

	my @parts = split/\./, $domain;
	splice(@parts, 0, -6); # take 5 top most compoments


	while (scalar @parts > 2) {
		shift @parts;
		push(@domains, join(".", @parts) );
	}

	return @domains;
}

=head2 canonical_path()

Find all canonical paths for a URL.

=cut

sub canonical_path {
	my ($self, $path) 	= @_;

	my @paths = ($path); # return full path
	
	if ($path =~ /\?/) {
		$path =~ s/\?.*$//;

		push(@paths, $path);
	}

	my @parts = split /\//, $path;
	my $previous = '';
	while (scalar @parts > 1 && scalar @paths < 6) {
		my $val = shift(@parts);
		$previous .= "$val/";

		push(@paths, $previous);
	}
	
	return @paths;
}

=head2 canonical()

Find all canonical URLs for a URL.

=cut

sub canonical {
	my ($self, $url) = @_;

	my @urls = ();

# 	my $uri = URI->new($url)->canonical;
	my $uri = $self->canonical_uri($url);
	my @domains = $self->canonical_domain($uri->host);
	my @paths = $self->canonical_path($uri->path_query);

	foreach my $domain (@domains) {
		foreach my $path (@paths) {
			push(@urls, "$domain$path");
		}
	}

	return @urls;
}


=head2 canonical_uri()

Create a canonical URI.

NOTE: URI cannot handle all the test cases provided by Google. This method is a hack to pass most of the test. A few tests are still failing. The proper way to handle URL canonicalization according to Google would be to create a new module to handle URLs. However, I believe most real-life cases are handled correctly by this function.

=cut

sub canonical_uri {
	my ($self, $url) = @_;

	$url = trim $url;

	# Special case for \t \r \n
	while ($url =~ s/^([^?]+)[\r\t\n]/$1/sgi) { } 

	my $uri = URI->new($url)->canonical; # does not deal with directory traversing

# 	$self->debug("0. $url => " . $uri->as_string . "\n");

	
	if (! $uri->scheme() || $uri->scheme() eq '') {
		$uri = URI->new("http://$url")->canonical;
	}

	$uri->fragment('');

	my $escape = $uri->as_string;

	# Reduce double // to single / in path
	while ($escape =~ s/^([a-z]+:\/\/[^?]+)\/\//$1\//sgi) { }


	# Remove empty fragment
	$escape =~ s/#$//;

	# canonial does not handle ../ 
# 	$self->debug("\t$escape\n");
	while($escape =~ s/([^\/])\/([^\/]+)\/\.\.([\/?].*)$/$1$3/gi) {  }
	while($escape =~ s/([^\/])\/([^\/]+)\/\.\.$/$1/gi) {  }

	# May have removed ending /
# 	$self->debug("\t$escape\n");
	$escape .= "/" if ($escape =~ /^[a-z]+:\/\/[^\/\?]+$/);
	$escape =~ s/^([a-z]+:\/\/[^\/]+)(\?.*)$/$1\/$2/gi;
# 	$self->debug("\t$escape\n");

	# other weird case if domain = digits only, try to translate it to IP address
	if ((my $domain = URI->new($escape)->host) =~/^\d+$/) {
		my $ip = Socket::inet_ntoa(Socket::inet_aton($domain));

		$uri = URI->new($escape);
		$uri->host($ip);

		$escape = $uri->as_string;
	}

# 	$self->debug("1. $url => $escape\n");

	# Try to escape the path again
	$url = $escape;
	while (($escape = URI::Escape::uri_unescape($url)) ne $escape) { # wrong for %23 -> #
		$url = $escape;
	}
# 	while (($escape = URI->new($url)->canonical->as_string) ne $escape) { # breask more unit tests than previous
# 		$url = $escape;
# 	}

	# Fix for %23 -> #
	while($escape =~ s/#/%23/sgi) { }

# 	$self->debug("2. $url => $escape\n");

	# Fix over escaping
	while($escape =~ s/^([^?]+)%%(%.*)$/$1%25%25$2/sgi) { }
	while($escape =~ s/^([^?]+)%%/$1%25%25/sgi) { }

	# URI has issues with % in domains, it gets the host wrong

		# 1. fix the host
# 	$self->debug("Domain: " . URI->new($escape)->host . "\n");
	my $exception = 0;
	while ($escape =~ /^[a-z]+:\/\/[^\/]*([^a-z0-9%_.-\/:])[^\/]*(\/.*)$/) {
		my $source = $1;
		my $target = sprintf("%02x", ord($source));

		$escape =~ s/^([a-z]+:\/\/[^\/]*)\Q$source\E/$1%\Q$target\E/;

		$exception = 1;
	}

		# 2. need to parse the path again
	if ($exception && $escape =~ /^[a-z]+:\/\/[^\/]+\/(.+)/) {
		my $source = $1;
		my $target = URI::Escape::uri_unescape($source);

# 		print "Source: $source\n";
		while ($target ne URI::Escape::uri_unescape($target)) {
			$target = URI::Escape::uri_unescape($target);
		}

		
		$escape =~ s/\/\Q$source\E/\/$target/;

		while ($escape =~ s/#/%23/sgi) { } # fragement has been removed earlier
		while ($escape =~ s/^([a-z]+:\/\/[^\/]+\/.*)%5e/$1\&/sgi) { } # not in the host name
# 		while ($escape =~ s/%5e/&/sgi) { } 

		while ($escape =~ s/%([^0-9a-f]|.[^0-9a-f])/%25$1/sgi) { }
	}

# 	$self->debug("$url => $escape\n");
# 	$self->debug(URI->new($escape)->as_string . "\n");

	return URI->new($escape);
}

=head2 full_hashes()

Return all possible full hashes for a URL.

=cut

sub full_hashes {
	my ($self, $url) = @_;

	my @urls = $self->canonical($url);
	my @hashes = ();

	foreach my $url (@urls) {
# 		$self->debug("$url\n");
		push(@hashes, sha256($url));
# 		$self->debug("$url " . $self->hex_to_ascii(sha256($url)) . "\n");
	}

	return @hashes;
}

=head2 prefix()

Return a hash prefix. The size of the prefix is set to 4 bytes.

=cut

sub prefix {
	my ($self, $string) = @_;

	return substr(sha256($string), 0, 4);
}

=head2 request_full_hash()

Request full full hashes for specific prefixes from Google.

=cut

sub request_full_hash {
	my ($self, %args) 	= @_;
	my $prefixes		= $args{prefixes}	|| return ();
	my $size			= $args{size}		|| length $prefixes->[0];

# 	# Handle errors
	my $i = 0;
	my $errors;
	my $delay = sub {
    	my $time = shift;
		if ((time() - $errors->{timestamp}) < $time) {
			splice(@$prefixes, $i, 1);
		}
		else {
			$i++;
		}
	};

	while ($i < scalar @$prefixes) {
		my $prefix = $prefixes->[$i];

		$errors = $self->{storage}->get_full_hash_error(prefix => $prefix);
		if (defined $errors && $errors->{errors} > 2) { # 2 errors is OK
			$errors->{errors} == 3 ? $delay->(30 * 60) # 30 minutes
		    	: $errors->{errors} == 4 ? $delay->(60 * 60) # 1 hour
		      	: $delay->(2 * 60 * 60); # 2 hours
		}
		else {
			$i++;
		}
	}

	my $url = $self->{server} . "gethash?client=api&apikey=" . $self->{key} . "&appver=$VERSION&pver=" . $self->{version};

	my $prefix_list = join('', @$prefixes);
	my $header = "$size:" . scalar @$prefixes * $size;

# 	print @{$args{prefixes}}, "\n";
# 	print $$prefixes[0], "\n"; return;


	my $res = $self->ua->post($url, Content =>  "$header\n$prefix_list");

	if (! $res->is_success) {
		$self->error("Full hash request failed\n");
		$self->debug($res->as_string . "\n");

		foreach my $prefix (@$prefixes) {
			my $errors = $self->{storage}->get_full_hash_error(prefix => $prefix);
			if (defined $errors && (
				$errors->{errors} >=2 			# backoff mode
				|| $errors->{errors} == 1 && (time() - $errors->{timestamp}) > 5 * 60)) { # 5 minutes
					$self->{storage}->full_hash_error(prefix => $prefix, timestamp => time()); # more complicate than this, need to check time between 2 errors
			}
		}

		return ();
	}
	else {
		$self->debug("Full hash request OK\n");

		foreach my $prefix (@$prefixes) {
			$self->{storage}->full_hash_ok(prefix => $prefix, timestamp => time());
		}
	}

	$self->debug($res->request->as_string . "\n");
	$self->debug($res->as_string . "\n");
# 	$self->debug(substr($res->content, 0, 250), "\n\n");

	return $self->parse_full_hashes($res->content);
}

=head2 parse_full_hashes()

Process the request for full hashes from Google.

=cut

sub parse_full_hashes {
	my ($self, $data) 	= @_;

	my @hashes = ();

	# goog-malware-shavar:22428:32\nHEX
	while (length $data > 0) {
		if ($data !~ /^[a-z-]+:\d+:\d+\n/) {
			$self->error("list not found\n");
			return ();
		}
		$data =~ s/^([a-z-]+)://;
		my $list = $1;
		
		$data =~ s/^(\d+)://;
		my $chunknum = $1;

		$data =~ s/^(\d+)\n//;
		my $length = $1;

		my $current = 0;
		while ($current < $length) {
			my $hash = substr($data, 0, 32, '');
			push(@hashes, { hash => $hash, chunknum => $chunknum, list => $list });

			$current += 32;
		}
	}

	return @hashes;
}

=head2 get_a_range()

Get the list of a chunks ranges for a list update.

=cut

sub get_a_range {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}		|| '';

	my @nums = $self->{storage}->get_add_chunks_nums(); # trust storage to torder list, or reorder it here?

	return $self->create_range(numbers => [@nums]);
}

=head2 get_s_range()

Get the list of s chunks ranges for a list update.

=cut

sub get_s_range {
	my ($self, %args) 	= @_;
	my $list			= $args{'list'}		|| '';

	my @nums = $self->{storage}->get_sub_chunks_nums(); # trust storage to torder list, or reorder it here?

	return $self->create_range(numbers => [@nums]);
}

=head2 create_range()

Create a list of ranges (1-3, 5, 7-11) from a list of numbers.

=cut

sub create_range {
	my ($self, %args) 	= @_;
	my $numbers			= $args{numbers}	|| []; # should already be ordered

	return '' if (scalar @$numbers == 0);

	my $range = $$numbers[0];
	my $new_range = 0;
	for(my $i = 1; $i < scalar @$numbers; $i++) {
# 		next if ($$numbers[$i] == $$numbers[$i-1]); # should not happen

		if ($$numbers[$i] != $$numbers[$i-1] + 1) {
			$range .= $$numbers[$i-1] if ($i > 1 && $new_range == 1);
			$range .= ',' . $$numbers[$i];

			$new_range = 0
		}
		elsif ($new_range == 0) {
			$range .= "-";
			$new_range = 1;
		}
	}
	$range .= $$numbers[scalar @$numbers - 1] if ($new_range == 1);

	return $range;
}

=head2 expand_range()

Explode list of ranges (1-3, 5, 7-11) into a list of numbers (1,2,3,5,7,8,9,10,11).

=cut

sub expand_range {
	my ($self, %args) 	= @_;
	my $range			= $args{range}	|| return ();

	my @list = ();
	my @elements = split /,/, $range;

	foreach my $data (@elements) {
		if ($data =~ /^\d+$/) { # single number
			push(@list, $data);
		}
		elsif ($data =~ /^(\d+)-(\d+)$/) {
			my $start = $1;
			my $end = $2;

			for(my $i = $start; $i <= $end; $i++) {
				push(@list, $i);
			}
		}
	}

	return @list;
}


=head1 CHANGELOG

=over 4

=item 1.11

Add dependency on IO::Socket::SSL.
Remove dependency on Net::IPAddress.

=item 1.10

Force IPv4 to solve bug on CentOS.

=item 1.09

Use HTTPS to access safebrowsing.clients.google.com/.

=item 1.07

Add C<import_chunks()> feature to import add chunks and sub chunks from a file.

=item 1.05

No code change. Move C<local_lookup> to PRIVATE FUNCTIONS to avoid confusions.

=item 1.04

Introduce L<Net::Google::SafeBrowsing2::Lookup>. Remind people that Google Safe Browsing v1 has been deprecated by Google.

=item 1.03

The source code is available on github at L<https://github.com/juliensobrier/Net-Google-SafeBrowsing2>.

=item 1.02

Fix uninitialized $self->{errors} variable

=item 1.01

Use String::HexConvert for faster hex_to_ascii.

=item 1.0

Separate the error output from the debug output.

=item 0.9

Fix bug with local whitelisting (sub chunks). Fix the parsing of full hashes.

=item 0.8

Reduce the number of full hash requests.

=item 0.7

Add local_lookup to perform a lookup against the local database only. This function should be used for debugging purpose only.
Small code optimizations.

=item 0.6

Handle local database reset.

=item 0.5

Update documentation.

=item 0.4

Speed update the database update. The first update went down from 20 minutes to 20 minutes.

=item 0.3

Fix typos in the documentation.

Remove dependency on Switch (thanks to Curtis Jewel).

Fix value of FULL_HASH_TIME.

=item 0.2

Add support for Message Authentication Code (MAC)

=back

=head1 SEE ALSO

Source code available at L<https://github.com/juliensobrier/Net-Google-SafeBrowsing2>.

See L<Net::Google::SafeBrowsing2::Storage>, L<Net::Google::SafeBrowsing2::Sqlite> and L<Net::Google::SafeBrowsing2::MySQL> for information on storing and managing the Google Safe Browsing database.

Google Safe Browsing v2 API: L<http://code.google.com/apis/safebrowsing/developers_guide_v2.html>

L<Net::Google::SafeBrowsing> (Google Safe Browsing v1) is deprecated by Google since 12/01/2011.

L<Net::Google::SafeBrowsing2> (Google Safe Browsing v2) will deprecated by Google on 12/01/2014.

=head1 AUTHOR

Julien Sobrier, E<lt>jsobrier@zscaler.comE<gt> or E<lt>julien@sobrier.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Julien Sobrier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
