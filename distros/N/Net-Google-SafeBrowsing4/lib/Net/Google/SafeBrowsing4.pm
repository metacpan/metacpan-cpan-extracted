package Net::Google::SafeBrowsing4;

use strict;
use warnings;

use Carp;
use Digest::SHA qw(sha256);
use Exporter qw(import);
use HTTP::Message;
use JSON::XS;
use List::Util qw(first);
use LWP::UserAgent;
use MIME::Base64;
use Text::Trim;
use Time::HiRes qw(time);

use Net::Google::SafeBrowsing4::URI;

our @EXPORT = qw(DATABASE_RESET INTERNAL_ERROR SERVER_ERROR NO_UPDATE NO_DATA SUCCESSFUL);

our $VERSION = '0.7';

=head1 NAME

Net::Google::SafeBrowsing4 - Perl extension for the Google Safe Browsing v4 API.

=head1 SYNOPSIS

	use Net::Google::SafeBrowsing4;
	use Net::Google::SafeBrowsing4::Storage::File;

	my $storage = Net::Google::SafeBrowsing4::Storage::File->new(path => '.');
	my $gsb = Net::Google::SafeBrowsing4->new(
		key 	=> "my key",
		storage	=> $storage,
		logger	=> Log::Log4perl->get_logger();
	);

	$gsb->update();
	my @matches = $gsb->lookup(url => 'http://ianfette.org/');

	if (scalar(@matches) > 0) {
		print("http://ianfette.org/ is flagged as a dangerous site\n");
	}

	$storage->close();

=head1 DESCRIPTION

Net::Google::SafeBrowsing4 implements the Google Safe Browsing v4 API.

The Google Safe Browsing database must be stored and managed locally. L<Net::Google::SafeBrowsing4::Storage::File> uses files as the storage back-end. Other storage mechanisms (databases, memory, etc.) can be added and used transparently with this module.

The source code is available on github at L<https://github.com/juliensobrier/Net-Google-SafeBrowsing4>.

If you do not need to inspect more than 10,000 URLs a day, you can use Net::Google::SafeBrowsing4::Lookup with the Google Safe Browsing v4 Lookup API which does not require to store and maintain a local database.


IMPORTANT: Google Safe Browsing v4 requires an API key from Google: https://developers.google.com/safe-browsing/v4/get-started.


=head1 CONSTANTS

Several constants are exported by this module:

=over 4

=item DATABASE_RESET

Google requested to reset (empty) the local database.

=item INTERNAL_ERROR

An internal error occurred.

=item SERVER_ERROR

The server sent an error back to the client.

=item NO_UPDATE

No update was performed, probably because it is too early to make a new request to Google Safe Browsing.

=item NO_DATA

No data was sent back by Google to the client, probably because the database is up to date.

=item SUCCESSFUL

The update operation was successful.


=back

=cut

use constant {
	DATABASE_RESET					=> -6,  # local database too old
	INTERNAL_ERROR					=> -3,	# internal/parsing error
	SERVER_ERROR					=> -2,	# server sent an error back
	NO_UPDATE					=> -1,	# no update (too early)
	NO_DATA						=>  0,	# no data sent
	SUCCESSFUL					=>  1,	# data sent
};


=head1 CONSTRUCTOR


=head2 new()

Create a Net::Google::SafeBrowsing4 object

	my $gsb = Net::Google::SafeBrowsing4->new(
		key	=> "my key",
		storage	=> Net::Google::SafeBrowsing4::Storage::File->new(path => '.'),
		lists	=> ["*/ANY_PLATFORM/URL"],
	);

Arguments

=over 4

=item base

Safe Browsing base URL. https://safebrowsing.googleapis.com by default

=item key

Required. Your Google Safe Browsing API key

=item storage

Required. Object which handles the storage for the Google Safe Browsing database. See L<Net::Google::SafeBrowsing4::Storage> for more details.

=item lists

Optional. The Google Safe Browsing lists to handle. By default, handles all lists.

=item logger

Optional. L<Log::Log4perl> compatible object reference. By default this option is unset, making Net::Google::SafeBrowsing4 silent.

=item perf

Optional. Set to 1 to enable performance information logging. Needs a I<logger>, performance information will be logged on DEBUG level.

=item version

Optional. Google Safe Browsing version. 4 by default

=item http_agent

Optional. L<LWP::UserAgent> to use for HTTPS requests. Use this option for advanced networking options,
like L<proxies or local addresses|/"PROXIES AND LOCAL ADDRESSES">.

=item http_timeout

Optional. Network timeout setting for L<LWP::UserAgent> (60 seconds by default)

=item http_compression

Optional. List of accepted compressions for HTTP response. Enabling all supported compressions reported by L<HTTP::Message> by default.


=item max_hash_request 

Optional. maximum number of full hashes to request. (500 by default)

=back

=cut

sub new {
	my ($class, %args) = @_;

	my $self = {
		base		=> 'https://safebrowsing.googleapis.com',
		lists		=> [],
		all_lists	=> [],
		key		=> '',
		version		=> '4',
		last_error	=> '',
		perf		=> 0,
		logger		=> undef,
		storage		=> undef,

		http_agent	=> LWP::UserAgent->new(),
		http_timeout	=> 60,
		http_compression => '' . HTTP::Message->decodable(),
		
		max_hash_request => 500,

		%args,
	};

	if (!$self->{key}) {
		$self->{logger} && $self->{logger}->error("Net::Google::SafeBrowsing4 needs an API key!");
		return undef;
	}

	if (!$self->{http_agent}) {
		$self->{logger} && $self->{logger}->error("Net::Google::SafeBrowsing4 needs an LWP::UserAgent!");
		return undef;
	}
	$self->{http_agent}->timeout($self->{http_timeout});
	$self->{http_agent}->default_header("Content-Type" => "application/json");
	$self->{http_agent}->default_header("Accept-Encoding" => $self->{http_compression});

	if (!$self->{storage}) {
		$self->{logger} && $self->{logger}->error("Net::Google::SafeBrowsing4 needs a Storage object!");
		return undef;
	}

	if (ref($self->{lists}) ne 'ARRAY') {
		$self->{lists} = [$self->{lists}];
	}

	$self->{base} = join("/", $self->{base}, "v" . $self->{version});

	bless($self, $class);
	return $self;
}

=head1 PUBLIC FUNCTIONS


=head2 update()

Performs a database update.

	$gsb->update();

Returns the status of the update (see the list of constants above): INTERNAL_ERROR, SERVER_ERROR, NO_UPDATE, NO_DATA or SUCCESSFUL

This function can handle multiple lists at the same time. If one of the lists should not be updated, it will automatically skip it and update the other one. It is faster to update all lists at once rather than doing them one by one.


Arguments

=over 4

=item lists

Optional. Update specific lists. Use the list(s) from new() by default. List are in the format "MALWARE/WINDOWS/URLS" or "*/WINDOWS/*" where * means all possible values.


=item force

Optional. Force the update (1). Disabled by default (0).

Be careful if you set this option to 1 as too frequent updates might result in the blacklisting of your API key.

=back

=cut

sub update {
	my ($self, %args) = @_;
	my $lists = $args{lists} || $self->{lists} || [];
	my $force = $args{force} || 0;

	# Check if it is too early
	my $time = $self->{storage}->next_update();
	if ($time > time() && $force == 0) {
		$self->{logger} && $self->{logger}->debug("Too early to update the local storage");
		return NO_UPDATE;
	}
	else {
		$self->{logger} && $self->{logger}->debug("time for update: $time / ", time());
	}

	my $all_lists = $self->make_lists(lists => $lists);
	my $info = {
		client => {
			clientId => 'Net::Google::SafeBrowsing4',
			clientVersion => $VERSION
		},
		listUpdateRequests => [ $self->make_lists_for_update(lists => $all_lists) ]
	};

	my $last_update = time();

	my $response = $self->{http_agent}->post(
		$self->{base} . "/threatListUpdates:fetch?key=" . $self->{key},
		"Content-Type" => "application/json",
		Content => encode_json($info)
	);

	$self->{logger} && $self->{logger}->trace($response->request()->as_string());
	$self->{logger} && $self->{logger}->trace($response->as_string());

	if (! $response->is_success()) {
		$self->{logger} && $self->{logger}->error("Update request failed");
		$self->update_error('time' => time());
		return SERVER_ERROR;
	}

	my $result = NO_DATA;
	my $json = decode_json($response->decoded_content(encoding => 'none'));
	my @data = @{ $json->{listUpdateResponses} };
	foreach my $list (@data) {
		my $threat = $list->{threatType};		# MALWARE
		my $threatEntry = $list->{threatEntryType};	# URL
		my $platform = $list->{platformType};		# ANY_PLATFORM
		my $update = $list->{responseType};		# FULL_UPDATE

		# save and check the update
		my @hex = ();
		foreach my $addition (@{ $list->{additions} }) {
			my $hashes_b64 = $addition->{rawHashes}->{rawHashes}; # 4 bytes
			my $size = $addition->{rawHashes}->{prefixSize};

			my $hashes = decode_base64($hashes_b64); # hexadecimal
			push(@hex, unpack("(a$size)*", $hashes));
		}

		my @remove = ();
		foreach my $removal (@{ $list->{removals} }) {
			push(@remove, @{ $removal->{rawIndices}->{indices} });
		}

		if (scalar(@hex) > 0) {
			$result = SUCCESSFUL if ($result >= 0);
			@hex = sort {$a cmp $b} @hex; # lexical sort

			my @hashes = $self->{storage}->save(
				list => {
					threatType 		=> $threat,
					threatEntryType		=> $threatEntry,
					platformType		=> $platform
				},
				override	=> ($list->{responseType} eq "FULL_UPDATE") ? 1 : 0,
				add		=> [@hex],
				remove 		=> [@remove],
				'state'		=> $list->{newClientState},
			);

			my $check = trim encode_base64 sha256(@hashes);
			if ($check ne $list->{checksum}->{sha256}) {
				$self->{logger} && $self->{logger}->error("$threat/$platform/$threatEntry update error: checksum does not match: ", $check, " / ", $list->{checksum}->{sha256});
				$self->{storage}->reset(
					list => {
						threatType 		=> $list->{threatType},
						threatEntryType		=> $list->{threatEntryType},
						platformType		=> $list->{platformType}
					}
				);

				$result = DATABASE_RESET;
			}
			else {
				$self->{logger} && $self->{logger}->debug("$threat/$platform/$threatEntry update: checksum match");
			}
		}

		# TODO: handle caching
	}


	my $wait = $json->{minimumWaitDuration};
	my $next = time();
	if ($wait =~ /(\d+)(\.\d+)?s/i) {
		$next += $1;
	}

	$self->{storage}->updated('time' => $last_update, 'next' => $next);

	return $result;
}


=head2 get_lists()

Gets all threat list names from Google Safe Browsing and save them.

	my $lists = $gsb->get_lists();

Returns an array reference of all the lists:

	[
		{
			'threatEntryType' => 'URL',
			'threatType' => 'MALWARE',
			'platformType' => 'ANY_PLATFORM'
		},
		{
			'threatEntryType' => 'URL',
			'threatType' => 'MALWARE',
			'platformType' => 'WINDOWS'
		},
		...
	]

	or C<undef> on error. This method updates C<$gsb->{last_error}> field.

=cut

sub get_lists {
	my ($self) = @_;

	$self->{last_error} = '';
	my $response = $self->{http_agent}->get(
		$self->{base} . "/threatLists?key=" . $self->{key},
		"Content-Type" => "application/json"
	);
	$self->{logger} && $self->{logger}->trace('Request:' . $response->request->as_string());
	$self->{logger} && $self->{logger}->trace('Response:' . $response->as_string());

	if (!$response->is_success()) {
		$self->{last_error} = "get_lists: " . $response->status_line();
		return undef;
	}

	my $info;
	eval {
		$info = decode_json($response->decoded_content(encoding => 'none'));
	};
	if ($@ || ref($info) ne 'HASH') {
		$self->{last_error} = "get_lists: Invalid Response: " . ($@ || "Data is an array and not an object");
		return undef;
	}

	if (!exists($info->{threatLists})) {
		$self->{last_error} = "get_lists: Invalid Response: Data missing the right key";
		return undef;
	}
	
	$self->{storage}->save_lists($info->{threatLists});

	return $info->{threatLists};
}


=head2 lookup()

Looks up URL(s) against the Google Safe Browsing database.


Returns the list of hashes along with the list and any metadata that matches the URL(s):

	(
		{
			'lookup_url' => '...',
			'hash' => '...',
			'metadata' => {
				'malware_threat_type' => 'DISTRIBUTION'
			},
			'list' => {
				'threatEntryType' => 'URL',
				'threatType' => 'MALWARE',
				'platformType' => 'ANY_PLATFORM'
			},
			'cache' => '300s'
		},
		...
	)


Arguments

=over 4

=item lists

Optional. Lookup against specific lists. Use the list(s) from new() by default.

=item url

Required. URL to lookup.

=back

=cut

sub lookup {
	my ($self, %args) = @_;
	my $list_expressions = $args{lists} || $self->{lists} || [];
	# List expressions may contain wildcards which need to be expanded
	my $list_names = $self->make_lists(lists => $list_expressions);

	if (!$args{url}) {
		return ();
	}

	if (ref($args{url}) eq '') {
		$args{url} = [ $args{url} ];
	} elsif (ref($args{url}) ne 'ARRAY') {
		$self->{logger} && $self->{logger}->error('Lookup() method accepts a single URI or list of URIs');
		return ();
	}
	$self->{logger} && $self->{logger}->debug(sprintf("Requested to look up %d URIs", scalar(@{$args{url}})));


	# Parse URI(s) and calculate hashes
	my $start;
	$self->{perf} && ($start = time());
	my $urls = {};
	foreach my $url (@{$args{url}}) {
		my $gsb_uri = Net::Google::SafeBrowsing4::URI->new($url);
		if (!$gsb_uri) {
			$self->{logger} && $self->{logger}->error('Failed to parse URI: ' . $url);
			next;
		}
		my $main_uri_hash = $gsb_uri->hash();

		foreach my $sub_url ($gsb_uri->generate_lookupuris()) {
			my $uri_hash = $sub_url->hash();
			$urls->{$uri_hash} = $sub_url;
			$urls->{$uri_hash}{hash} = $uri_hash;
			$urls->{$uri_hash}{parent} = $main_uri_hash;
		}
	}
	$self->{perf} && $self->{logger} && $self->{logger}->debug("Full hashes from URL(s): ", time() - $start,  "s ");

	# Lookup hash prefixes in the local database
	$self->{perf} && ($start = time());
	my $lookup_hashes = { map { $_ => '' } keys(%$urls) };
	$self->{logger} && $self->{logger}->debug(sprintf("Looking up prefixes for %d hashes in local db", scalar(keys(%$lookup_hashes))));
	my @matched_prefixes = $self->{storage}->get_prefixes(hashes => [keys(%$lookup_hashes)], lists => $list_names);
	if (scalar(@matched_prefixes) == 0) {
		$self->{logger} && $self->{logger}->debug("No hit on local hash prefix lookup");
		return ();
	}
	$self->{logger} && $self->{logger}->debug(sprintf(
		"%d hits by %d prefixes in local database",
		scalar(@matched_prefixes),
		scalar(keys(%{ { map { $_->{prefix} => 1 } @matched_prefixes } }) )
	));

	# Mark hashes that were found in prefix db, drop others
	map { $lookup_hashes->{$_->{hash}} = $_->{prefix} } @matched_prefixes;
	map { delete($lookup_hashes->{$_}) if ($lookup_hashes->{$_} eq '') } keys(%$lookup_hashes);
	$self->{perf} && $self->{logger} && $self->{logger}->debug("Find hash prefixes in local db: ", time() - $start,  "s ");


	# Lookup full hashes in the local database
	$self->{perf} && ($start = time());
	$self->{logger} && $self->{logger}->debug(sprintf("Looking up %d full hashes in local db", scalar(keys(%$lookup_hashes))));
	my @results = ();
	foreach my $lookup_hash (keys(%$lookup_hashes)) {
		# @TODO get_full_hashes should be able to look up multiple hashes at once (it could be faster)
		my @hash_matches = $self->{storage}->get_full_hashes(hash => $lookup_hash, lists => $list_names);
		if (scalar(@hash_matches) > 0) {
			push(@results, @hash_matches);

			# Delete all URI hashes that are based of a URI that was found on GSB
			my %found_hashes = map { $_->{hash} => 1 } @hash_matches;
			foreach my $found_hash (keys(%found_hashes)) {
				map {
					delete($lookup_hashes->{$_}) if ($urls->{$_}{parent} eq $urls->{$found_hash}{parent})
				} keys(%$lookup_hashes);
			}
		}
	}
	$self->{logger} && $self->{logger}->debug(sprintf("%d unknown full hashes remained after local lookup", scalar(keys(%$lookup_hashes))));
	$self->{perf} && $self->{logger} && $self->{logger}->debug("Stored hashes lookup: ", time() - $start,  "s ");


	# Download full hashes for the remaining prefixes if needed
	$self->{perf} && ($start = time());
	my %needed_prefixes = map { $_ => 1 } values(%$lookup_hashes);
	if (scalar(keys(%needed_prefixes)) > 0) {
		my @lookup_prefixes = grep { exists($needed_prefixes{$_->{prefix}}) } @matched_prefixes;
		my @retrieved_hashes = $self->request_full_hash(prefixes => [@lookup_prefixes]);
		$self->{perf} && $self->{logger} && $self->{logger}->debug("Full hash request: ", time() - $start,  "s ");

		$start = time();
		my @matches = grep { exists($lookup_hashes->{$_->{hash}}) } @retrieved_hashes;
		push(@results, @matches) if (scalar(@matches) > 0);
		$self->{perf} && $self->{logger} && $self->{logger}->debug("Full hash check: ", time() - $start,  "s ");

		$start = time();
		$self->{storage}->add_full_hashes(hashes => [@retrieved_hashes], timestamp => time());
		$self->{perf} && $self->{logger} && $self->{logger}->debug("Save full hashes: ", time() - $start,  "s ");
	}


	# Map urls to hashes in the resultset
	foreach my $entry (@results) {
		$entry->{lookup_url} = $urls->{$entry->{hash}}->as_string();
		$entry->{original_url} = $urls->{$urls->{$entry->{hash}}->{parent}}->as_string();
	}

	return @results;
}

=pod

=head1 PRIVATE FUNCTIONS

These functions are not intended to be used externally.


=head2 make_lists()

Transforms a list from a string expression (eg.: "MALWARE/*/*") into a list object.

=cut

sub make_lists {
	my ($self, %args) = @_;
	my @lists = @{ $args{lists} || $self->{lists} || [] };

	if (scalar(@lists) == 0) {
		if (scalar(@{ $self->{all_lists} }) == 0) {
			my $lists = $self->{storage}->get_lists();
			if (scalar(@$lists) == 0) {
				$lists = $self->get_lists();
			}
			$self->{all_lists} = $lists;
		}
		return $self->{all_lists};
	}

	my @all = ();
	foreach my $list (@lists) {
		$list = uc(trim($list));
		if ($list !~ /^[*_A-Z]+\/[*_A-Z]+\/[*_A-Z]+$/) {
			$self->{logger} && $self->{logger}->error("List expression is in invalid format: $list - It must be in the form of MALWARE/WINDOWS/URL or MALWARE/*/*");
			next;
		}
		if ($list =~ /\*/) {
			my ($threat, $platform, $threatEntry) = split(/\//, $list);

			if (scalar(@{ $self->{all_lists} }) == 0) {
				$self->{all_lists} = $self->get_lists();
			}

			foreach my $original (@{ $self->{all_lists} }) {
				if (
					($threat eq "*" || $original->{threatType} eq $threat) &&
					($platform eq "*" || $original->{platformType} eq $platform) &&
					($threatEntry eq "*" || $original->{threatEntryType} eq $threatEntry))
				{
					push(@all, $original);
				}
			}
		}
		elsif ($list =~ /^([_A-Z]+)\/([_A-Z]+)\/([_A-Z]+)$/) {
			my ($threat, $platform, $threatEntry) = split(/\//, $list);

			push(@all, {
				threatType		=> $threat,
				platformType		=> $platform,
				threatEntryType		=> $threatEntry,
			});
		}
	}

	return [@all];
}


=head2 update_error()

Handle server errors during a database update.

=cut

sub update_error {
	my ($self, %args) = @_;
	my $time = $args{'time'} || time();

	my $info = $self->{storage}->last_update();
	$info->{errors} = 0 if (!exists($info->{errors}));
	my $errors = $info->{errors} + 1;
	my $wait = 0;

	$wait = $errors == 1 ? 60
		: $errors == 2 ? int(30 * 60 * (rand(1) + 1)) # 30-60 mins
		: $errors == 3 ? int(60 * 60 * (rand(1) + 1)) # 60-120 mins
		: $errors == 4 ? int(2 * 60 * 60 * (rand(1) + 1)) # 120-240 mins
		: $errors == 5 ? int(4 * 60 * 60 * (rand(1) + 1)) # 240-480 mins
		: $errors  > 5 ? 480 * 60
		: 0;

	$self->{storage}->update_error('time' => $time, 'wait' => $wait, errors => $errors);
}


=head2 make_lists_for_update()

Formats the list objects for update requests.

=cut

sub make_lists_for_update {
	my ($self, %args) = @_;
	my @lists = @{ $args{lists} };

	for(my $i = 0; $i < scalar(@lists); $i++) {
		$lists[$i]->{'state'} = $self->{storage}->get_state(list => $lists[$i]);
		$lists[$i]->{constraints} = {
			supportedCompressions => ["RAW"]
		};
	}

	return @lists;
}

=head2 request_full_hash()

Requests full full hashes for specific prefixes from Google.

=cut

sub request_full_hash {
	my ($self, %args) = @_;
	my @prefixes = @{ $args{prefixes} || [] };

	my $info = {
		client => {
			clientId => 'Net::Google::SafeBrowsing4',
			clientVersion => $VERSION
		},
	};

	
	my @full_hashes = ();
	while (scalar @prefixes > 0) {
		my @send = splice(@prefixes, 0, $self->{max_hash_request});
	
		my @lists = ();
		my %hashes = ();
		my %threats = ();
		my %platforms = ();
		my %threatEntries = ();
		foreach my $info (@send) {
			if (
				!defined(first {
					$_->{threatType} eq $info->{list}->{threatType} &&
					$_->{platformType} eq $info->{list}->{platformType} &&
					$_->{threatEntryType} eq $info->{list}->{threatEntryType}
				} @lists)
			) {
				push(@lists, $info->{list});
			}

			$hashes{ trim(encode_base64($info->{prefix})) } = 1;
			$threats{ $info->{list}->{threatType} } = 1;
			$platforms{ $info->{list}->{platformType} } = 1;
			$threatEntries{ $info->{list}->{threatEntryType} } = 1;
		}

		# Get state for each list
		$info->{clientStates} = [];
		foreach my $list (@lists) {
			push(@{ $info->{clientStates} }, $self->{storage}->get_state(list => $list));
		}

		$info->{threatInfo} = {
			threatTypes		=> [ keys(%threats) ],
			platformTypes 		=> [ keys(%platforms) ],
			threatEntryTypes 	=> [ keys(%threatEntries) ],
			threatEntries		=> [ map { { hash => $_ } } keys(%hashes) ],
		};

		my $response = $self->{http_agent}->post(
			$self->{base} . "/fullHashes:find?key=" . $self->{key},
			"Content-Type" => "application/json",
			Content => encode_json($info)
		);

		$self->{logger} && $self->{logger}->trace($response->request()->as_string());
		$self->{logger} && $self->{logger}->trace($response->as_string());

		if (! $response->is_success()) {
			$self->{logger} && $self->{logger}->error("Full hash request failed");
			$self->{last_error} = "Full hash request failed";

			# TODO
	#		foreach my $info (keys keys %hashes) {
	#			my $prefix = $info->{prefix};
	#
	#			my $errors = $self->{storage}->get_full_hash_error(prefix => $prefix);
	#			if (defined $errors && (
	#				$errors->{errors} >=2 			# backoff mode
	#				|| $errors->{errors} == 1 && (time() - $errors->{timestamp}) > 5 * 60)) { # 5 minutes
	#					$self->{storage}->full_hash_error(prefix => $prefix, timestamp => time()); # more complicate than this, need to check time between 2 errors
	#			}
	#		}
		}
		else {
			$self->{logger} && $self->{logger}->debug("Full hash request OK");
			
			push(@full_hashes, $self->parse_full_hashes($response->decoded_content(encoding => 'none')));

			# TODO
	#		foreach my $prefix (@$prefixes) {
	#			my $prefix = $info->{prefix};
	#
	#			$self->{storage}->full_hash_ok(prefix => $prefix, timestamp => time());
	#		}
		}
	}

	return @full_hashes;
}

=head2 parse_full_hashes()

Processes the request for full hashes from Google.

=cut

sub parse_full_hashes {
	my ($self, $data) = @_;

	if ($data eq '') {
		return ();
	}

	my $info = decode_json($data);
	if (!exists($info->{matches}) || scalar(@{ $info->{matches} }) == 0) {
		return ();
	}

	my @hashes = ();
	foreach my $match (@{ $info->{matches} }) {
		my $list = {
			threatType		=> $match->{threatType},
			platformType		=> $match->{platformType},
			threatEntryType		=> $match->{threatEntryType},
		};

		my $hash = decode_base64($match->{threat}->{hash});
		my $cache = $match->{cacheDuration};

		my %metadata = ();
		foreach my $extra (@{ $match->{threatEntryMetadata}->{entries} }) {
			$metadata{ decode_base64($extra->{key}) } = decode_base64($extra->{value});
		}

		push(@hashes, { hash => $hash, cache => $cache, list => $list, metadata => { %metadata } });
	}

	# TODO:
	my $wait = $info->{minimumWaitDuration} || 0; # "300.000s",
	$wait =~ s/[a-z]//i;

	my $negativeWait = $info->{negativeCacheDuration} || 0; # "300.000s"
	$negativeWait =~ s/[a-z]//i;

	return @hashes;
}

=head1 PROXIES AND LOCAL ADDRESSES

To use a proxy or select the network interface to use, simply create and set up an L<LWP::UserAgent> object and pass it to the constructor:

	use LWP::UserAgent;
	use Net::Google::SafeBrowsing4;
	use Net::Google::SafeBrowsing4::Storage::File;

	my $ua = LWP::UserAgent->new();
	$ua->env_proxy();

	# $ua->local_address("192.168.0.14");

	my $gsb = Net::Google::SafeBrowsing4->new(
		key		=> "my-api-key",
		storage		=> Net::Google::SafeBrowsing4::Storage::File->new(path => "."),
		http_agent	=> $ua,
	);

Note that the L<Net::Google::SafeBrowsing4> object will override certain LWP properties:

=over

=item timeout

The network timeout will be set according to the C<http_timeout> constructor parameter.

=item Content-Type

The Content-Type default header will be set to I<application/json> for HTTPS Requests.

=item Accept-Encoding

The Accept-Encoding default header will be set according to the C<http_compression> constructor parameter.

=back

=head1 SEE ALSO

See L<Net::Google::SafeBrowsing4::URI> about URI parsing for Google Safe Browsing v4.

See L<Net::Google::SafeBrowsing4::Storage> for the list of public functions.

See L<Net::Google::SafeBrowsing4::Storage::File> for a back-end storage using files.

Google Safe Browsing v4 API: L<https://developers.google.com/safe-browsing/v4/>


=head1 AUTHOR

Julien Sobrier, E<lt>julien@sobrier.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Julien Sobrier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
__END__
