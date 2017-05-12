package Protocol::BitTorrent::Metainfo;
{
  $Protocol::BitTorrent::Metainfo::VERSION = '0.004';
}
use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';
use POSIX qw(floor ceil strftime);
use List::Util qw(sum);
use Try::Tiny;
use URI;
use URI::QueryParam;
use Digest::SHA qw(sha1);
use Convert::Bencode_XS qw();
use parent qw(Protocol::BitTorrent::Bencode);

=head1 NAME

Protocol::BitTorrent::Metainfo - support for metainfo as found in .torrent files

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Protocol::BitTorrent::Metainfo;
 print Protocol::BitTorrent::Metainfo->new->parse_info(...)->announce_url;

=head1 DESCRIPTION

See L<Protocol::BitTorrent> for top-level documentation.

=cut

use constant PEER_ID_LENGTH => 20;

=head1 METHODS

=cut

=head2 new

Instantiate a new metainfo object.

Takes the following named parameters:

=over 4

=item * announce - tracker URL for announcing peers

=item * comment - optional comment for this torrent

=item * encoding - encoding for the torrent, typically UTF8

=back

=cut

sub new {
	my $self = bless { }, shift;
	my %args = @_;

	$self->{$_} = delete $args{$_} for qw(announce comment encoding created);
	$self->{files} ||= [ ];
	die "Unknown metainfo parameter: $_\n" for sort keys %args;
	return $self;
}

=head2 parse_info

Parse the given metainfo structure to populate a new object. Used when
reading an existing torrent file:

 my $data = File::Slurp::read_file($filename, { binmode => ':raw' });
 $data = Protocol::BitTorrent::Metainfo->bdecode($data);
 my $torrent = Protocol::BitTorrent::Metainfo->new->parse_info($data);

=cut

sub parse_info {
	my $self = shift;
	my $info = shift;

	$self->$_($info->{$_}) for grep exists $info->{$_}, qw(announce comment encoding);
	$self->{created} = $info->{'creation date'} if exists $info->{'creation date'};
	if(exists $info->{info}) {
		my @files;
		if($info->{info}->{files}) {
			$self->{root_path} = $info->{info}{name};
			foreach my $f (@{$info->{info}{files}}) {
				push @files, {
					length => $f->{length},
					name => join '/', @{$f->{path}},
				};
			}
		} else {
			push @files, +{
				map { $_ => $info->{info}->{$_} } qw(name length)
			};
		}
		$self->{files} = \@files;
		$self->{piece_length} = $info->{info}->{'piece length'};
		$self->{pieces} = $info->{info}->{pieces};
		$self->{is_private} = $info->{info}->{private} if exists $info->{info}->{private};
	}
	return $self;
}

sub root_path {
	my $self = shift;
	if(@_) {
		$self->{root_path} = shift;
		return $self
	}
	return $self->{root_path};
}

=head2 infohash

Returns the infohash for this torrent. Defined as the 20-character SHA1
hash of the info data.

=cut

sub infohash {
	my $self = shift;
	return sha1(
		try {
			$self->bencode($self->file_info)
		} catch {
			require Data::Dumper;
			die "Invalid infohash data: $_ from " . Data::Dumper::Dumper($self->file_info) . "\n"
		}
	);
}

=head2 file_info

Returns or updates the info data (referred to as an 'info dictionary' in the spec).

=cut

sub file_info {
	my $self = shift;
	unless(exists $self->{info}) {
		$self->{info} = {
			'piece length'	=> $self->piece_length,
			'pieces'	=> $self->pieces,
		};
		$self->{info}->{private} = $self->is_private if $self->has_private_flag;
		if($self->files == 1) {
			my ($file) = $self->files;
			$self->{info}{name} = $file->{name};
			$self->{info}{length} = $file->{length};
		} else {
			$self->{info}{name} = $self->root_path;
			$self->{info}{files} = [];
			foreach my $file ($self->files) {
				push @{ $self->{info}{files} }, {
					'length' => $file->{length},
					'path' => [ split m{/}, $file->{name} ],
				}
			}
		}
	}
	return $self->{info};
}

=head2 peer_id

Returns the current peer ID. This is a 20-character string used to
differentiate peers connecting to a torrent.

Will generate a new peer ID if one has not already been assigned.

=cut

sub peer_id {
	my $self = shift;
	if(@_) {
		$self->{peer_id} = shift;
	}
	$self->{peer_id} = $self->generate_peer_id unless exists $self->{peer_id};
	return $self->{peer_id};
}

=head2 generate_peer_id_azureus

Generate a new peer ID using the Azureus style:

 -BT0001-980123456789

Takes the following parameters:

=over 4

=item * $type - the 2-character type, defaults to PB (for "L<Protocol::BitTorrent>").

=item * $version - the 4-character version code, should be numeric although this is not
enforced. Defaults to current package version with . characters stripped.

=item * $suffix - trailing string data to append to the peer ID, defaults to random
decimal digits.

=back

Example invocation:

 $torrent->generate_peer_id_azureus('XX', '0100', '0123148')

=cut

sub generate_peer_id_azureus {
	my $self = shift;
	my $type = shift || 'PB';
	my $version = shift;
	my $suffix = shift || '';

	(($version = $self->VERSION || '') =~ tr/\.//d) unless defined $version;
	$version = "0$version" while length $version < 4;
	my $peer_id = '-' . $type . $version . '-' . $suffix;
	$peer_id .= floor(rand(10)) while length $peer_id < PEER_ID_LENGTH;
	$peer_id = substr $peer_id, 0, PEER_ID_LENGTH if length $peer_id > PEER_ID_LENGTH;
	return $peer_id;
}

=head2 generate_peer_id

Generates a peer ID using the default method (currently Azureus which is the only
defined method, see L</generate_peer_id_azureus>).

=cut

sub generate_peer_id { shift->generate_peer_id_azureus(@_) }

=head2 files

Returns a list of the files in this torrent, or replaces the current list if given
an arrayref.

=cut

sub files {
	my $self = shift;
	if(@_) {
		$self->{files} = shift;
		return $self;
	}
	return map +{ %$_ }, @{$self->{files}};
}

=head2 announce

Get/set tracker announce URL.

=cut

sub announce {
	my $self = shift;
	if(@_) {
		$self->{announce} = shift;
		return $self;
	}
	return $self->{announce};
}

=head2 piece_length

Get/set current piece length. Recommended values seem to be between 256KB and 1MB.

=cut

sub piece_length {
	my $self = shift;
	if(@_) {
		$self->{piece_length} = shift;
		return $self;
	}
	return $self->{piece_length};
}

=head2 total_length

Returns the total length for all files in this torrent.

=cut

sub total_length {
	my $self = shift;
	return sum(map $_->{length}, $self->files) || 0;
}

=head2 total_pieces

Returns the total number of pieces in this torrent, equivalent to
the total length of all files divided by the piece size (and rounded
up to include the last partial piece as required).

=cut

sub total_pieces {
	my $self = shift;
	return ceil($self->total_length / $self->piece_length);
}

=head2 pieces

Returns the combined hash string representing the pieces in this torrent.
Will be a byte string of length L</total_pieces> * 20.

=cut

sub pieces { shift->{pieces} }

=head2 is_private

Returns 1 if this is a private torrent, 0 otherwise.

=cut

sub is_private { shift->{is_private} ? 1 : 0 }

=head2 has_private_flag

Returns true if this torrent has the optional C< private > flag.

=cut

sub has_private_flag { exists shift->{is_private} ? 1 : 0 }

=head2 encoding

Get/set current encoding for metainfo strings.

=cut

sub encoding {
	my $self = shift;
	if(@_) {
		$self->{encoding} = shift;
		return $self;
	}
	return $self->{encoding};
}

=head2 trackers

Get/set trackers. Takes an arrayref when setting, returns a list.

=cut

sub trackers {
	my $self = shift;
	if(@_) {
		$self->{trackers} = shift;
		return $self;
	}
	return @{ $self->{trackers} };
}

=head2 comment

Get/set metainfo comment.

=cut

sub comment {
	my $self = shift;
	if(@_) {
		$self->{comment} = shift;
		return $self;
	}
	return $self->{comment};
}

=head2 created

Get/set creation time of this torrent, as epoch value (seconds since 1st Jan 1970).

=cut

sub created {
	my $self = shift;
	if(@_) {
		$self->{created} = shift;
		return $self;
	}
	return $self->{created};
}

=head2 created_iso8601

Returns the L</created> value as a string in ISO8601 format.

Example:

 2011-04-01T18:04:00

=cut

sub created_iso8601 {
	my $self = shift;
	my $ts = $self->created;
	return undef unless defined $ts;
	return strftime("%Y-%m-%dT%H:%M:%S", gmtime($ts));
}

=head2 created_by

Get/set 'created by' field, indicating who created this torrent.

=cut

sub created_by {
	my $self = shift;
	if(@_) {
		$self->{created_by} = shift;
		return $self;
	}
	return $self->{created_by};
}

=head2 as_metainfo

Returns the object formatted as a metainfo hashref, suitable for
bencoding into a .torrent file.

=cut

sub as_metainfo {
	my $self = shift;
	my %info = (
		announce => $self->announce,
	);
	$info{'creation date'} = $self->created if defined $self->created;
	$info{'comment'} = $self->comment if defined $self->comment;
	$info{'created by'} = $self->created_by if defined $self->created_by;
	die "Undef value for $_" for sort grep !defined($info{$_}), keys %info;

	$info{'created by'} = $self->created_by if defined $self->created_by;
	($info{info}) = $self->files;
	$info{info}{pieces} = $self->pieces;
	return \%info;
}

=head2 add_file

Adds the given file to this torrent. If the torrent already has a file
and is in single mode, will switch to multi mode.

=cut

sub add_file {
	my $self = shift;
	my $filename = shift;
	my $size = -s $filename;
	# $self->piece_length(262144);
	$self->piece_length(1048576);
	my $hash = $self->hash_for_file($filename);

	push @{$self->{files}}, {
		'name'		=> $filename,
		'length'	=> $size,
		'piece length'	=> $self->piece_length,
	};
	$self->{'pieces'} = $hash;
	return $self;
}

=head2 hash_for_file

Returns the SHA1 hash for the pieces in the given file.

=cut

sub hash_for_file {
	my $self = shift;
	my $filename = shift;

	my @piece_hash;
	open my $fh, '<', $filename or die "Failed to open $filename - $!\n";
	my $piece_length = $self->piece_length;
	while($fh->read(my $buf, $piece_length)) {
		push @piece_hash, sha1($buf) if defined $buf && length $buf;
	}
	$fh->close or die $!;
	join '', @piece_hash;
}

=head2 announce_url

Returns the tracker announce URL

Takes the following named parameters:

=over 4

=item * uploaded - number of bytes uploaded so far by this client

=item * downloaded - number of bytes downloaded so far by this client

=item * left - number of bytes left for this client to transfer

=item * port - (optional) the port this client is listening on, defaults to 6881

=item * event - (optional) type of event, can be started, stopped or completed. If
not supplied, this will be treated as an update of a running torrent.

=back

=cut

sub announce_url {
	my $self = shift;
	my %args = @_;

	my $uri = URI->new($self->announce);
	$uri->query_param(info_hash => $self->infohash);
	$uri->query_param(peer_id => $self->peer_id);
	$uri->query_param(port => $args{port} || 6881);
	$uri->query_param(uploaded => $args{uploaded} || 0);
	$uri->query_param(downloaded => $args{downloaded} || 0);
	$uri->query_param(left => $args{left} || 0);
	$uri->query_param(event => $args{event}) if exists $args{event};
	return $uri->as_string;
}

=head2 scrape_url

Returns the scrape URL, if there is one. Scrape URLs are only defined if the L<announce_url>
contains C< /announce > with no subsequent C< / > characters. Returns undef if a scrape URL
cannot be generated.

=cut

sub scrape_url {
	my $self = shift;
	unless(exists $self->{scrape_url}) {
		my $scrape_url;
		my $uri = URI->new($self->announce);
		if((my $path = $uri->path) =~ s{/announce([^/]*)$}{/scrape$1}) {
			$uri->path($path);
			$uri->query_param(info_hash => $self->infohash);
			$scrape_url = $uri->as_string;
		}
		$self->{scrape_url} = $scrape_url;
	}
	return $self->{scrape_url};
}

sub VERSION { require Protocol::BitTorrent; $Protocol::BitTorrent::VERSION }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011-2013. Licensed under the same terms as Perl itself.
