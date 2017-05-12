package Net::Google::SafeBrowsing3;

use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use URI;
use Digest::SHA qw(sha256);
use List::Util qw(first);
use Text::Trim;
use MIME::Base64::URLSafe;
use MIME::Base64;
use String::HexConvert;
use IO::Socket::SSL 'inet4';
use Google::ProtocolBuffers;
use Data::Dumper;

use Exporter 'import';
our @EXPORT = qw(DATABASE_RESET INTERNAL_ERROR SERVER_ERROR NO_UPDATE NO_DATA SUCCESSFUL MALWARE PHISHING UNWANTED LANDING DISTRIBUTION);


BEGIN {
    IO::Socket::SSL::set_ctx_defaults(
#         verify_mode => Net::SSLeay->VERIFY_PEER(),
			SSL_verify_mode => 0,
    );
}

our $VERSION = '0.7';

Google::ProtocolBuffers->parse("
	message ChunkData {
		required int32 chunk_number = 1;

		// The chunk type is either an add or sub chunk.
		enum ChunkType {
			ADD = 0;
			SUB = 1;
		}
		optional ChunkType chunk_type = 2 [default = ADD];

		// Prefix type which currently is either 4B or 32B.  The default is set
		// to the prefix length, so it doesn't have to be set at all for most
		// chunks.
		enum PrefixType {
			PREFIX_4B = 0;
			FULL_32B = 1;
		}
		optional PrefixType prefix_type = 3 [default = PREFIX_4B];

		// Stores all SHA256 add or sub prefixes or full-length hashes. The number
		// of hashes can be inferred from the length of the hashes string and the
		// prefix type above.
		optional bytes hashes = 4;

		// Sub chunks also encode one add chunk number for every hash stored above.
		repeated int32 add_numbers = 5 [packed = true];

	}
	",
	{create_accessors => 0 }
);

Google::ProtocolBuffers->parse("
	message MalwarePatternType {
		enum PATTERN_TYPE {
			LANDING = 1;
			DISTRIBUTION = 2;
		}

		required PATTERN_TYPE pattern_type = 1;
	}
	",
	{create_accessors => 0 }
);

# TODO ###################################################
#Todo: request full hashes: seperate 32bytes for 4bytes
# Todo: optimize lookup_suffix, 1 search for all lists

=head1 NAME

Net::Google::SafeBrowsing3 - Perl extension for the Google Safe Browsing v3 API. (Google Safe Browsing v2 has been deprecated by Google.)

=head1 SYNOPSIS

  use Net::Google::SafeBrowsing3;
  use Net::Google::SafeBrowsing3::Sqlite;
  
  my $storage = Net::Google::SafeBrowsing3::Sqlite->new(file => 'google-v3.db');
  my $gsb = Net::Google::SafeBrowsing3->new(
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

Net::Google::SafeBrowsing3 implements the Google Safe Browsing v3 API.

The library passes most of the unit tests listed in the API documentation. See the documentation (L<https://developers.google.com/safe-browsing/developers_guide_v3>) for more details about the failed tests.

The Google Safe Browsing database must be stored and managed locally. L<Net::Google::SafeBrowsing3::Sqlite> uses Sqlite as the storage back-end, L<Net::Google::SafeBrowsing3::MySQL> uses MySQL. Other storage mechanisms (databases, memory, etc.) can be added and used transparently with this module.

The source code is available on github at L<https://github.com/juliensobrier/Net-Google-SafeBrowsing3>.

If you do not need to inspect more than 10,000 URLs a day, you can use L<Net::Google::SafeBrowsing2::Lookup> with the Google Safe Browsing v2 Lookup API which does not require to store and maintain a local database.

IMPORTANT: If you start with an empty database, you will need to perform several updates to retrieve all the Google Safe Browsing information. This may require up to 24 hours. This is a limitation of the Google API, not of this module.

IMPORTANT: Google Safe Browsing v3 requires a different key than v2.


=head1 CONSTANTS

Several  constants are exported by this module:

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

The operation was successful.

=item MALWARE

Name of the Malware list in Google Safe Browsing (shortcut to 'goog-malware-shavar')

=item PHISHING

Name of the Phishing list in Google Safe Browsing (shortcut to 'googpub-phish-shavar')

=item UNWANTED

Name of the Unwamted Application list in Google Safe Browsing (shortcut to 'goog-unwanted-shavar')

=item LANDING

Landing site.

=item DISTRIBUTION

Distribution site.

=back

=cut

use constant {
	DATABASE_RESET					=> -6,
	INTERNAL_ERROR					=> -3,	# internal/parsing error
	SERVER_ERROR						=> -2, 	# Server sent an error back
	NO_UPDATE								=> -1,	# no update (too early)
	NO_DATA									=> 0, 	# no data sent
	SUCCESSFUL							=> 1,	# data sent
	MALWARE									=> 'goog-malware-shavar',
	PHISHING								=> 'googpub-phish-shavar',
	UNWANTED								=> 'goog-unwanted-shavar',
	LANDING 								=> 1, # Metadata goog-malware-shavar
	DISTRIBUTION						=> 2, # Metadata goog-malware-shavar
};


=head1 CONSTRUCTOR

=over 4

=back

=head2 new()

Create a Net::Google::SafeBrowsing3 object

  my $gsb = Net::Google::SafeBrowsing3->new(
		key 	=> "my key", 
		storage	=> Net::Google::SafeBrowsing3::Sqlite->new(file => 'google-v3.db'),
		debug	=> 0,
		list	=> MALWARE,
  );

Arguments

=over 4

=item server

Safe Browsing Server. https://safebrowsing.google.com/safebrowsing/ by default

=item key

Required. Your Google Safe browsing API key

=item storage

Required. Object which handle the storage for the Google Safe Browsing database. See L<Net::Google::SafeBrowsing3::Storage> for more details.

=item list

Optional. The Google Safe Browsing list to handle. By default, handles both MALWARE and PHISHING.

=item debug

Optional. Set to 1 to enable debugging. 0 (disabled) by default.

The debug output maybe quite large and can slow down significantly the update and lookup functions.

=item errors

Optional. Set to 1 to show errors to STDOUT. 0 (disabled by default).

=item perf

Optional. Set to 1 to show performance information.

=item version

Optional. Google Safe Browsing version. 3.0 by default

=back

=cut

sub new {
	my ($class, %args) = @_;

	my $self = { # default arguments
		server		=> 'https://safebrowsing.google.com/safebrowsing/',
		list			=> [PHISHING, MALWARE, UNWANTED],
		key				=> '',
		version		=> '3.0',
		debug			=> 0,
		errors		=> 0,
		last_error	=> '',
		perf		=> 0,

		%args,
	};

	if (! exists $self->{storage}) {
		use Net::Google::SafeBrowsing3::Storage;
		$self->{storage} = Net::Google::SafeBrowsing3::Storage->new();
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


Arguments

=over 4

=item list

Optional. Update a specific list. Use the list(s) from new() by default.


=item force

Optional. Force the update (1). Disabled by default (0).

Be careful if you set this option to 1 as too frequent updates might result in the blacklisting of your API key.

=back

=cut

sub update {
	my ($self, %args) 	= @_;
	my $list		= $args{list};
	my $force 	= $args{force}	|| 0;

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
	

	my $ua = $self->ua;

	my $url = $self->{server} . "downloads?client=api&key=" . $self->{key} . "&appver=$VERSION&pver=" . $self->{version};

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
		$body .= "\n";
	}

	my $start_req = time();
	my $res = $ua->post($url, Content =>  $body);
	$self->perf("$body\n");

	$self->debug($res->request->as_string, "\n", $res->as_string . "\n");
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

	# API doc: Clients must clear cached full-length hashes each time they send an update request.
	foreach my $list (@lists) {
		$self->{storage}->reset_full_hashes(list => $list);
	}

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
			$del_add_duration = time() - $del_add_start;

			$result = 1;
		}
		elsif ($line =~ /sd:(\S+)$/) {
			$self->debug("Delete Sub Chunks: $1\n");

			my $del_sub_start = time();
			my @nums = $self->expand_range(range => $1);
			$self->{storage}->delete_sub_ckunks(chunknums => [@nums], list => $list);
			$del_sub_duration = time() - $del_sub_start;

			$result = 1;
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

=head2 lookup()

Lookup a URL against the Google Safe Browsing database.

  my $match = $gsb->lookup(url => 'http://www.gumblar.cn');
	my ($match, $type) = $gsb->lookup(url => 'http://www.gumblar.cn');

In scalar context, returns the name of the list if there is any match, returns an empty string otherwise.
In array context, return the name of the list (empty if no match) and the type of malware site (0 if no type specified)

Arguments

=over 4

=item list

Optional. Lookup against a specific list. Use the list(s) from new() by default.

=item url

Required. URL to lookup.

=back

=cut

sub lookup {
	my ($self, %args) = @_;
	my $list 					= $args{list}		|| '';
	my $url 					= $args{url}		|| return '';

	my @lists = @{$self->{list}};
	@lists = @{[$args{list}]} if ($list ne '');


	# TODO: create our own URI management for canonicalization
	# fix for http:///foo.com (3 ///)
	$url =~ s/^(https?:\/\/)\/+/$1/;


	my $uri = URI->new($url)->canonical;
	my ($match, $type) = $self->lookup_suffix(lists => [@lists], url => $url);
	return ($match, $type) if (wantarray);
	return $match
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
	my ($self, %args) = @_;
	my $lists 				= $args{lists} 	|| croak "Missing lists\n";
	my $url 					= $args{url}		|| return '';

	# Calculate prefixes
	my @full_hashes = $self->full_hashes($url);
	my @full_hashes_prefix = map (substr($_, 0, 4), @full_hashes);  # Get the prefixes from the first 4 bytes

 	# Local lookup
	my @add_chunks = $self->local_lookup_suffix(lists => $lists, url => $url, full_hashes => [@full_hashes], full_hashes_prefix => [@full_hashes_prefix]);
	if (scalar @add_chunks == 0) {
		$self->debug("No hit in local lookup\n");
		return ('', 0) if (wantarray);
		return '';
	}

	$self->debug("Found ", scalar(@add_chunks), " add chunk(s) in local database\n");
	foreach my $add (@add_chunks) {
		$self->debug("Chunk: ", $self->hex_to_ascii($add->{prefix}), " - ", $add->{list}, "\n");
	}

	# get stored full hashes
	foreach my $hash (@full_hashes) {
		foreach my $list (@$lists) {
			my @hashes = $self->{storage}->get_full_hashes(hash => $hash, list => $list);
			
			if (scalar @hashes > 0) {
				$self->debug("Full hashes found: ", scalar(@hashes), "\n");
				my $result = pop(@hashes);

				return ($list, $result->{type} || 0) if (wantarray);
				return $list;
			}
		}
	}


	# ask for new hashes
	# TODO: make sure we don't keep asking for the same over and over
	my @hashes = $self->request_full_hash(prefixes => [ map($_->{prefix}, @add_chunks) ]);
	$self->{storage}->add_full_hashes(full_hashes => [@hashes], timestamp => time());

	foreach my $full_hash (@full_hashes) {
		my $hash = first { $_->{hash} eq  $full_hash} @hashes;
		next if (! defined $hash);

		my $list = first { $hash->{list} eq $_ } @$lists;

		if (defined $hash && defined $list) {
# 			$self->debug($self->hex_to_ascii($hash->{hash}) . " eq " . $self->hex_to_ascii($full_hash) . "\n\n");

			$self->debug("Match: " . $self->hex_to_ascii($full_hash)  . "\n");

			return ($hash->{list}, $hash->{type} || 0) if (wantarray);
			return $hash->{list};
		}
# 		elsif (defined $hash) {
# 			$self->debug("hash: " . $self->hex_to_ascii($hash->{hash}) . "\n");
# 			$self->debug("list: " . $hash->{list} . "\n");
# 		}
	}
	
	$self->debug("No match\n");
	return ('', 0) if (wantarray);
	return '';
}

=head2 local_lookup_suffix()

Lookup a host prefix in the local database only.

=cut
sub local_lookup_suffix {
	my ($self, %args) 					= @_;
	my $lists 									= $args{lists} 							|| croak "Missing lists\n";
	my $url 										=	$args{url}								|| return ();
	my $full_hashe_list 				= $args{full_hashes}				|| [];
	my $full_hashes_prefix_list = $args{full_hashes_prefix} || [];



	# Step 1: calculate prefixes if not provided
	# Get the prefixes from the first 4 bytes
	my @full_hashes = @{$full_hashe_list};
	my @full_hashes_prefix = @{$full_hashes_prefix_list};
	if (scalar @full_hashes_prefix == 0) {
		@full_hashes = $self->full_hashes($url) if (scalar @full_hashes == 0);

		@full_hashes_prefix = map (substr($_, 0, 4), @full_hashes);
	}

	# Step 2: get all add chunks for these suffixes
	# Do it for all lists
	my @add_chunks = ();
	foreach my $prefix (@full_hashes_prefix, @full_hashes) {
		push(@add_chunks,  $self->{storage}->get_add_chunks(prefix => $prefix));
	}

	if (scalar @add_chunks == 0) { # no match
		$self->debug("No prefix found\n");
		return @add_chunks;
	}


	# Step 3: get all sub chunks for this host key
	my @sub_chunks = ();
	foreach my $prefix (@full_hashes_prefix, @full_hashes) {
		push(@sub_chunks, $self->{storage}->get_sub_chunks(hostkey => $prefix));
	}

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

Parse data from a redirection (add and sub chunk information).

=cut

sub parse_data {
	my ($self, %args) = @_;
	my $data					= $args{data}		 || '';
	my $list  				= $args{list}		 || '';

	my $chunk_num = 0;
	my $hash_length = 0;
	my $chunk_length = 0;

	while (length $data > 0) {
# 		my $length =  substr($data, 0, 4); # HEX
		my $length = hex $self->hex_to_ascii( substr($data, 0, 4, '') );
		$self->debug("Length: $length\n");
		my $chunk = substr($data, 0, $length, '');
		my $data = ChunkData->decode($chunk);
		$self->debug(Dumper($data), "\n");

		if (! exists($data->{chunk_type}) || $data->{chunk_type} == 0) {
			my @chunks = $self->parse_a(chunk => $data);
			$self->{storage}->add_chunks(type => 'a', chunknum => $data->{chunk_number}, chunks => [@chunks], list => $list);
		}
		else {
			my @chunks = $self->parse_s(chunk => $data);
			$self->{storage}->add_chunks(type => 's', chunknum => $data->{chunk_number}, chunks => [@chunks], list => $list);
		}
	}

	return SUCCESSFUL;
}

=head2 parse_s()

Parse s chunks information for a database update.

=cut

sub parse_s {
	my ($self, %args) 	= @_;
	my $chunk 				= $args{chunk}			|| return ();

# 	{
# 		'add_numbers' => [
# 											161383,
# 											156609,
# 											161686,
# 											159174,
# 											166040,
# 											164187
# 										],
# 		'chunk_type' => 1,
# 		'chunk_number' => 158095,
# 		'hashes' => '  _*���F�E����A��;;v����i'
# 	}

	my @data = ();
	my $prefix_type = $chunk->{prefix_type} || 0;
	my $prefix = $chunk->{hashes} || ''; # HEX
	$self->debug("Hashes length: ", length($prefix), "\n");
	$self->debug("Hashes: ", $self->hex_to_ascii($prefix), "\n") if ($self->{debug});

	my $hash_length = 4;
	$hash_length = 32 if ($prefix_type == 1);
	my @hashes = ();
	while(length($prefix) > 0) {
		push(@hashes, substr($prefix, 0, $hash_length, ''));
	}

	for(my $i = 0; $i < scalar @{ $chunk->{add_numbers} }; $i++) {
		push(@data, { add_chunknum => ${ $chunk->{add_numbers} }[$i], prefix =>  $hashes[$i] });
	}

	return @data;
}


=head2 parse_a()

Parse a chunks information for a database update.

=cut

sub parse_a {
	my ($self, %args) 	= @_;
	my $chunk 				= $args{chunk}			|| return ();

# 	{
# 		'chunk_number' => 166146,
# 		'hashes' => 'Z[�$~�����w5���B�;0����z;�E&�ʳY�H$`-'
# 	}

	my @data = ();
	my $prefix_type = $chunk->{prefix_type} || 0;
	my $prefix = $chunk->{hashes} || ''; # HEX

	my $hash_length = 4;
	$hash_length = 32 if ($prefix_type == 1);

	while(length($prefix) > 0) {
		push(@data, {  prefix =>  substr($prefix, 0, $hash_length, '') });
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
	my ($self, @messages) = @_;

	print join('', @messages) if ($self->{debug} > 0);
}


=head2 error()

Print error message.

=cut

sub error {
	my ($self, $message) = @_;

	print "ERROR - ", $message if ($self->{debug} > 0 || $self->{errors} > 0);
	$self->{last_error} = $message;
}


=head2 perf()

Print performance message.

=cut

sub perf {
	my ($self, @messages) = @_;

	print join('', @messages)if ($self->{perf} > 0);
}


=head2 canonical_domain()

Find all canonical domains a domain.

=cut

sub canonical_domain {
	my ($self, $domain) 	= @_;

	# Remove all leading and trailing dots.
  $domain =~ s/^\.+//;
  $domain =~ s/\.+$//;

	# Replace consecutive dots with a single dot.
	while ($domain =~ s/\.\.+/\./g) { }

	# Lowercase the whole string.
	$domain = lc $domain;

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
	
	# without query string
	if ($path =~ /\?/) {
		$path =~ s/\?.*$//;

		push(@paths, $path);
	}

	my @parts = split /\//, $path;
	if (scalar @parts > 4) {
		@parts = splice(@parts, -4, 4);
	}

# 	if (scalar @parts == 0) {
# 		push(@paths, "/");
# 	}


	my $previous = '';
	while (scalar @parts > 1) {
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
		$self->debug("$url " . $self->hex_to_ascii(sha256($url)) . "\n");
	}

	return @hashes;
}

=head2 request_full_hash()

Request full full hashes for specific prefixes from Google.

=cut

sub request_full_hash {
	my ($self, %args) = @_;
	my $prefixes			= $args{prefixes}	|| return ();
	my $size					= $args{size}			|| length $prefixes->[0];

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

	my $url = $self->{server} . "gethash?client=api&key=" . $self->{key} . "&appver=$VERSION&pver=" . $self->{version};

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

# 	900
# 	goog-malware-shavar:32:2:m
# 	01234567890123456789012345678901987654321098765432109876543210982
# 	AA3

	# cache life time
	my $life = 0;
	if ($data =~ s/^(\d+)\n//) {
		$life = $1;
		$self->debug("Full hash life time: ", $life, "\n");
	}
	else {
		$self->error("Life time not found\n");
	}

	while (length $data > 0) {
		if ($data !~ /^[a-z-]+:\d+:\d+(:m)?\n/gi) { # goog-malware-shavar:32:1:m
			$self->error("list not found\n");
			return ();
		}
		$data =~ s/^([a-z-]+)://;
		my $list = $1;
		
		$data =~ s/^(\d+)://;
		my $length = $1;
		$self->debug("Full hash length: ", $length, "\n");

		$data =~ s/^(\d+)//;
		my $num = $1;
		
		$self->debug("Number of full hashes returned: ", $num, "\n");

		my $metadata = 0;
		if ($data =~ s/:m[\r\n]//) {
			$metadata = 1;
		}

		my $current = 0;
		my @local_hashes = ();
		while ($current < $num) {
			my $hash = substr($data, 0, $length, '');
			push(@local_hashes, { hash => $hash, list => $list, life => $life, type => 0 });

			$current ++;
		}

		if ($metadata) {
			my $count = 0;
			while ($data =~ s/(\d+)[\r\n]//) {
				my $meta_length = $1;

				my $info = substr($data, 0, $meta_length, '');
				$self->debug("Metadata: $info\n");
				my $extra = MalwarePatternType->decode($info);

				# update the type
				my $hash = $local_hashes[$count];
				$hash->{type} = $extra->{pattern_type};
				$local_hashes[$count] = $hash;

				$count++;
			}
		}


		push(@hashes, @local_hashes);
	}

	$self->debug("Number of hashes: ", scalar(@hashes), "\n");
	return @hashes;
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

=item 0.7

Remove \r from metata data

=item 0.6

Many fixes: local database update, lcoal database lookup, full hash response parsing, etc.

=back

=head1 SEE ALSO

See L<Net::Google::SafeBrowsing3> for handling Google Safe Browsing v3.

See L<Net::Google::SafeBrowsing3::Storage> for the list of public functions.

See L<Net::Google::SafeBrowsing3::Sqlite> for a back-end using Sqlite.

Google Safe Browsing v3 API: L<https://developers.google.com/safe-browsing/developers_guide_v3>


=head1 AUTHOR

Julien Sobrier, E<lt>julien@sobrier.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julien Sobrier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
__END__

