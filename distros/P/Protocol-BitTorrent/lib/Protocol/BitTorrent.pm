package Protocol::BitTorrent;
# ABSTRACT: abstract implementation of the bittorrent p2p protocol
use strict;
use warnings;
use parent qw(Protocol::BitTorrent::Bencode);
use utf8;

our $VERSION = '0.004';

=head1 NAME

Protocol::BitTorrent - protocol-level support for BitTorrent and .torrent files

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 package BitTorrent::Implementation;
 use Protocol::BitTorrent;
 ...

=head1 DESCRIPTION

This distribution provides handling for the BitTorrent protocol at an abstract
level. Although some utilities are provided for dealing with .torrent files,
the intention is for this class to act as a base for building BitTorrent
client/server/tracker implementations, rather than a complete independent package.
Specifically, no attempt is made to listen or connect to network sockets.

See L<Protocol::BitTorrent::Metainfo> for information on dealing with
.torrent files, and also check the C< examples/ > and C< bin/ > directories
for examples of code using these classes.

An actual working client+tracker implementation can be found in
L<Net::Async::BitTorrent>.

=cut

use Protocol::BitTorrent::Metainfo;

use Convert::Bencode_XS qw();
use Try::Tiny;

=head1 METHODS

=cut

=head2 new

=cut

sub new { bless {}, shift }

=head2 parse_metainfo

Parse .torrent data and return a L<Protocol::BitTorrent::Metainfo> instance.

=cut

sub parse_metainfo {
	my $self = shift;
	my $encoded = shift;

	my $decoded = try {
		$self->bdecode($encoded);
	} catch {
		# Ensure we have a recognisable string at the start of the error message
		die "Parse error: $_\n";
	};
	return Protocol::BitTorrent::Metainfo->new->parse_info($decoded);
}

=head2 generate_metainfo

Wrapper around L<Protocol::BitTorrent::Metainfo> for creating new .torrent data.

=cut

sub generate_metainfo {
	my $self = shift;
	my %args = @_;
	return Protocol::BitTorrent::Metainfo->new(%args);
}

{ # peer type mapping
my %azureus_peer_types = (
	'AG' => 'Ares',
	'A~' => 'Ares',
	'AR' => 'Arctic',
	'AT' => 'Artemis',
	'AX' => 'BitPump',
	'AZ' => 'Azureus',
	'BB' => 'BitBuddy',
	'BC' => 'BitComet',
	'BF' => 'Bitflu',
	'BG' => 'BTG',
	'BL' => 'BitBlinder',
	'BP' => 'BitTorrent Pro',
	'BR' => 'BitRocket',
	'BS' => 'BTSlave',
	'BW' => 'BitWombat',
	'BX' => '~Bittorrent X',
	'CD' => 'Enhanced CTorrent',
	'CT' => 'CTorrent',
	'DE' => 'DelugeTorrent',
	'DP' => 'Propagate Data Client',
	'EB' => 'EBit',
	'ES' => 'electric sheep',
	'FC' => 'FileCroc',
	'FT' => 'FoxTorrent',
	'GS' => 'GSTorrent',
	'HK' => 'Hekate',
	'HL' => 'Halite',
	'HM' => 'hMule',
	'HN' => 'Hydranode',
	'KG' => 'KGet',
	'KT' => 'KTorrent',
	'LC' => 'LeechCraft',
	'LH' => 'LH-ABC',
	'LP' => 'Lphant',
	'LT' => 'libtorrent',
	'lt' => 'libTorrent',
	'LW' => 'LimeWire',
	'MK' => 'Meerkat',
	'MO' => 'MonoTorrent',
	'MP' => 'MooPolice',
	'MR' => 'Miro',
	'MT' => 'MoonlightTorrent',
	'NX' => 'Net Transport',
	'OS' => 'OneSwarm',
	'OT' => 'OmegaTorrent',
	'PD' => 'Pando',
	'PT' => 'PHPTracker',
	'qB' => 'qBittorrent',
	'QD' => 'QQDownload',
	'QT' => 'Qt 4 Torrent example',
	'RT' => 'Retriever',
	'RZ' => 'RezTorrent',
	'S~' => 'Shareaza alpha/beta',
	'SB' => '~Swiftbit',
	'SD' => 'Thunder (aka XunLei)',
	'SM' => 'SoMud',
	'SS' => 'SwarmScope',
	'ST' => 'SymTorrent',
	'st' => 'sharktorrent',
	'SZ' => 'Shareaza',
	'TN' => 'TorrentDotNET',
	'TR' => 'Transmission',
	'TS' => 'Torrentstorm',
	'TT' => 'TuoTu',
	'UL' => 'uLeecher!',
	'UM' => 'µTorrent for Mac',
	'UT' => 'µTorrent',
	'VG' => 'Vagaa',
	'WT' => 'BitLet',
	'WY' => 'FireTorrent',
	'XL' => 'Xunlei',
	'XS' => 'XSwifter',
	'XT' => 'XanTorrent',
	'XX' => 'Xtorrent',
	'ZT' => 'ZipTorrent',
);

=head2 peer_type_from_id

Returns the client type for a given peer_id.

=cut

sub peer_type_from_id {
	my $self = shift;
	my $peer_id = shift;

	# Handle us first
	return "Protocol::BitTorrent v$1.$2" if $peer_id =~ /^-PB(\d)(\d{3})-/;

	# Azureus-style clients
	if($peer_id =~ /^-(..)(....)-/) {
		my $type = $azureus_peer_types{$1} || 'Unknown';
		my $v = join '.', map hex, split //, $2;
		return "$type v$v";
	}
	return 'unknown';
}
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Net::BitTorrent> - seems to be a solid implementation of the
protocol, at time of writing was undergoing some refactoring to switch
to L<Moose> and L<AnyEvent> although development appears to have stalled
for the last year.

=item * L<http://wiki.theory.org/BitTorrentSpecification> - 'unofficial'
spec.

=item * L<http://en.wikipedia.org/wiki/Comparison_of_BitTorrent_tracker_software> - a
list of other BitTorrent software, this list is likely to be more up to
date than this section.

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
