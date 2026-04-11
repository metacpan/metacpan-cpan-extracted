package Net::Nostr;

use strictures 2;

our $VERSION = '1.000002';

use Net::Nostr::Client;
use Net::Nostr::Relay;

sub client { Net::Nostr::Client->new }

sub relay { Net::Nostr::Relay->new }

1;

__END__

=head1 NAME

Net::Nostr - Perl client and relay library for the Nostr protocol

=head1 SYNOPSIS

    use Net::Nostr;

    # Connect to a relay as a client
    my $client = Net::Nostr->client;
    $client->connect("ws://relay.example.com");

    # Run a relay
    my $relay = Net::Nostr->relay;
    $relay->run('127.0.0.1', 8080);

=head1 DESCRIPTION

Net::Nostr is a Perl implementation of the Nostr protocol that provides both
client and relay functionality. Most of the useful functionality lives in the
individual modules listed below -- start with L<Net::Nostr::Key> for identity
management and L<Net::Nostr::Event> for creating events.

=head1 CLASS METHODS

=head2 client

    my $client = Net::Nostr->client;

Convenience factory that returns a new L<Net::Nostr::Client> instance.
Equivalent to C<< Net::Nostr::Client->new >>.

=head2 relay

    my $relay = Net::Nostr->relay;

Convenience factory that returns a new L<Net::Nostr::Relay> instance.
Equivalent to C<< Net::Nostr::Relay->new >>.

=head1 MODULES

=over 4

=item L<Net::Nostr::AppData> - NIP-78 arbitrary custom app data

=item L<Net::Nostr::AppHandler> - NIP-89 recommended application handlers

=item L<Net::Nostr::Article> - NIP-23 long-form content

=item L<Net::Nostr::Badge> - NIP-58 badges

=item L<Net::Nostr::Bech32> - NIP-19 bech32-encoded entities

=item L<Net::Nostr::Blossom> - NIP-B7 Blossom media server lists

=item L<Net::Nostr::Calendar> - NIP-52 calendar events

=item L<Net::Nostr::Channel> - NIP-28 public chat channels

=item L<Net::Nostr::ClassifiedListing> - NIP-99 classified listings

=item L<Net::Nostr::Client> - WebSocket client for connecting to Nostr relays

=item L<Net::Nostr::Comment> - NIP-22 comment threading

=item L<Net::Nostr::Community> - NIP-72 moderated communities

=item L<Net::Nostr::Deletion> - NIP-09 event deletion requests

=item L<Net::Nostr::DirectMessage> - NIP-17 private direct messages

=item L<Net::Nostr::DVM> - NIP-90 data vending machine

=item L<Net::Nostr::Encryption> - NIP-44 versioned encrypted payloads

=item L<Net::Nostr::Event> - Nostr event serialization, ID computation, and verification

=item L<Net::Nostr::ExternalId> - NIP-73 external content IDs

=item L<Net::Nostr::FileMetadata> - NIP-94 file metadata events

=item L<Net::Nostr::Filter> - Filter objects for querying events

=item L<Net::Nostr::FollowList> - NIP-02 follow list management

=item L<Net::Nostr::GiftWrap> - NIP-59 gift wrap encryption

=item L<Net::Nostr::Git> - NIP-34 git collaboration

=item L<Net::Nostr::Group> - NIP-29 relay-based groups

=item L<Net::Nostr::HttpAuth> - NIP-98 HTTP auth

=item L<Net::Nostr::Identifier> - NIP-05 DNS-based internet identifiers

=item L<Net::Nostr::Key> - Secp256k1 keypair management and BIP-340 Schnorr signatures

=item L<Net::Nostr::KeyEncrypt> - NIP-49 private key encryption

=item L<Net::Nostr::Label> - NIP-32 labeling

=item L<Net::Nostr::List> - NIP-51 lists and sets

=item L<Net::Nostr::LiveActivity> - NIP-53 live activities

=item L<Net::Nostr::Marketplace> - NIP-15 Nostr Marketplace

=item L<Net::Nostr::MediaAttachment> - NIP-92 media attachments

=item L<Net::Nostr::Message> - Protocol message serialization and parsing

=item L<Net::Nostr::Mention> - NIP-27 text note references

=item L<Net::Nostr::Metadata> - NIP-24 extra metadata fields and tags

=item L<Net::Nostr::MintDiscovery> - NIP-87 ecash mint discoverability

=item L<Net::Nostr::Negentropy> - NIP-77 negentropy set reconciliation

=item L<Net::Nostr::Nutzap> - NIP-61 nutzaps (Cashu ecash payments)

=item L<Net::Nostr::Reaction> - NIP-25 reactions

=item L<Net::Nostr::Relay> - WebSocket relay server

=item L<Net::Nostr::RelayAccess> - NIP-43 relay access metadata and requests

=item L<Net::Nostr::RelayAdmin> - NIP-86 relay management API

=item L<Net::Nostr::RelayInfo> - NIP-11 relay information document

=item L<Net::Nostr::RelayList> - NIP-65 relay list metadata

=item L<Net::Nostr::RelayMonitor> - NIP-66 relay discovery and liveness monitoring

=item L<Net::Nostr::RelayStore> - Indexed in-memory event storage for relays

=item L<Net::Nostr::RemoteSigning> - NIP-46 Nostr Remote Signing

=item L<Net::Nostr::Report> - NIP-56 reporting

=item L<Net::Nostr::Repost> - NIP-18 reposts

=item L<Net::Nostr::Thread> - NIP-10 text note threading

=item L<Net::Nostr::Timestamp> - NIP-03 OpenTimestamps attestations

=item L<Net::Nostr::Torrent> - NIP-35 torrents

=item L<Net::Nostr::Wallet> - NIP-60 Cashu wallet state management

=item L<Net::Nostr::WalletConnect> - NIP-47 Nostr Wallet Connect

=item L<Net::Nostr::Wiki> - NIP-54 wiki

=item L<Net::Nostr::Zap> - NIP-57 Lightning Zaps

=back

=head1 SUPPORTED NIPS

Conformance target:
L<nostr-protocol/nips commit 420f0b18|https://github.com/nostr-protocol/nips/commit/420f0b181434c348e487c6ffaa8fea6111c10210>
(2026-04-01).

=over 4

=item L<NIP-01|https://github.com/nostr-protocol/nips/blob/master/01.md> - Basic protocol flow

=item L<NIP-02|https://github.com/nostr-protocol/nips/blob/master/02.md> - Follow list

=item L<NIP-03|https://github.com/nostr-protocol/nips/blob/master/03.md> - OpenTimestamps attestations for events

=item L<NIP-05|https://github.com/nostr-protocol/nips/blob/master/05.md> - Mapping Nostr keys to DNS-based internet identifiers

=item L<NIP-06|https://github.com/nostr-protocol/nips/blob/master/06.md> - Basic key derivation from mnemonic seed phrase

=item L<NIP-09|https://github.com/nostr-protocol/nips/blob/master/09.md> - Event deletion request

=item L<NIP-10|https://github.com/nostr-protocol/nips/blob/master/10.md> - Text notes and threads

=item L<NIP-11|https://github.com/nostr-protocol/nips/blob/master/11.md> - Relay information document

=item L<NIP-13|https://github.com/nostr-protocol/nips/blob/master/13.md> - Proof of Work

=item L<NIP-15|https://github.com/nostr-protocol/nips/blob/master/15.md> - Nostr Marketplace

=item L<NIP-17|https://github.com/nostr-protocol/nips/blob/master/17.md> - Private direct messages

=item L<NIP-18|https://github.com/nostr-protocol/nips/blob/master/18.md> - Reposts

=item L<NIP-19|https://github.com/nostr-protocol/nips/blob/master/19.md> - bech32-encoded entities

=item L<NIP-21|https://github.com/nostr-protocol/nips/blob/master/21.md> - C<nostr:> URI scheme

=item L<NIP-22|https://github.com/nostr-protocol/nips/blob/master/22.md> - Comment

=item L<NIP-23|https://github.com/nostr-protocol/nips/blob/master/23.md> - Long-form content

=item L<NIP-24|https://github.com/nostr-protocol/nips/blob/master/24.md> - Extra metadata fields and tags

=item L<NIP-25|https://github.com/nostr-protocol/nips/blob/master/25.md> - Reactions

=item L<NIP-27|https://github.com/nostr-protocol/nips/blob/master/27.md> - Text note references

=item L<NIP-28|https://github.com/nostr-protocol/nips/blob/master/28.md> - Public chat

=item L<NIP-29|https://github.com/nostr-protocol/nips/blob/master/29.md> - Relay-based groups

=item L<NIP-32|https://github.com/nostr-protocol/nips/blob/master/32.md> - Labeling

=item L<NIP-34|https://github.com/nostr-protocol/nips/blob/master/34.md> - git stuff

=item L<NIP-35|https://github.com/nostr-protocol/nips/blob/master/35.md> - Torrents

=item L<NIP-36|https://github.com/nostr-protocol/nips/blob/master/36.md> - Sensitive Content / Content Warning

=item L<NIP-40|https://github.com/nostr-protocol/nips/blob/master/40.md> - Expiration timestamp

=item L<NIP-42|https://github.com/nostr-protocol/nips/blob/master/42.md> - Authentication of clients to relays

=item L<NIP-43|https://github.com/nostr-protocol/nips/blob/master/43.md> - Relay Access Metadata and Requests

=item L<NIP-44|https://github.com/nostr-protocol/nips/blob/master/44.md> - Encrypted payloads (versioned)

=item L<NIP-45|https://github.com/nostr-protocol/nips/blob/master/45.md> - Event counts

=item L<NIP-46|https://github.com/nostr-protocol/nips/blob/master/46.md> - Nostr Remote Signing

=item L<NIP-47|https://github.com/nostr-protocol/nips/blob/master/47.md> - Nostr Wallet Connect

=item L<NIP-49|https://github.com/nostr-protocol/nips/blob/master/49.md> - Private key encryption

=item L<NIP-50|https://github.com/nostr-protocol/nips/blob/master/50.md> - Search capability

=item L<NIP-51|https://github.com/nostr-protocol/nips/blob/master/51.md> - Lists

=item L<NIP-52|https://github.com/nostr-protocol/nips/blob/master/52.md> - Calendar Events

=item L<NIP-53|https://github.com/nostr-protocol/nips/blob/master/53.md> - Live Activities

=item L<NIP-54|https://github.com/nostr-protocol/nips/blob/master/54.md> - Wiki

=item L<NIP-56|https://github.com/nostr-protocol/nips/blob/master/56.md> - Reporting

=item L<NIP-57|https://github.com/nostr-protocol/nips/blob/master/57.md> - Lightning Zaps

=item L<NIP-58|https://github.com/nostr-protocol/nips/blob/master/58.md> - Badges

=item L<NIP-59|https://github.com/nostr-protocol/nips/blob/master/59.md> - Gift wrap

=item L<NIP-60|https://github.com/nostr-protocol/nips/blob/master/60.md> - Cashu wallets

=item L<NIP-61|https://github.com/nostr-protocol/nips/blob/master/61.md> - Nutzaps

=item L<NIP-65|https://github.com/nostr-protocol/nips/blob/master/65.md> - Relay list metadata

=item L<NIP-66|https://github.com/nostr-protocol/nips/blob/master/66.md> - Relay Discovery and Liveness Monitoring

=item L<NIP-70|https://github.com/nostr-protocol/nips/blob/master/70.md> - Protected Events

=item L<NIP-72|https://github.com/nostr-protocol/nips/blob/master/72.md> - Moderated Communities

=item L<NIP-73|https://github.com/nostr-protocol/nips/blob/master/73.md> - External Content IDs

=item L<NIP-77|https://github.com/nostr-protocol/nips/blob/master/77.md> - Negentropy Syncing

=item L<NIP-78|https://github.com/nostr-protocol/nips/blob/master/78.md> - Arbitrary Custom App Data

=item L<NIP-86|https://github.com/nostr-protocol/nips/blob/master/86.md> - Relay Management API

=item L<NIP-87|https://github.com/nostr-protocol/nips/blob/master/87.md> - Ecash Mint Discoverability

=item L<NIP-89|https://github.com/nostr-protocol/nips/blob/master/89.md> - Recommended Application Handlers

=item L<NIP-90|https://github.com/nostr-protocol/nips/blob/master/90.md> - Data Vending Machine

=item L<NIP-92|https://github.com/nostr-protocol/nips/blob/master/92.md> - Media Attachments

=item L<NIP-94|https://github.com/nostr-protocol/nips/blob/master/94.md> - File Metadata

=item L<NIP-98|https://github.com/nostr-protocol/nips/blob/master/98.md> - HTTP auth

=item L<NIP-99|https://github.com/nostr-protocol/nips/blob/master/99.md> - Classified Listings

=item L<NIP-B7|https://github.com/nostr-protocol/nips/blob/master/B7.md> - Blossom media

=back

NIP-04 (encrypted direct messages) is deprecated and not supported.
Use NIP-44 for encryption instead.

=cut
